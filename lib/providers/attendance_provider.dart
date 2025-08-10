import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../models/attendance_model.dart';
import '../models/session_model.dart';
import 'auth_provider.dart';
import 'package:location/location.dart';

class AttendanceProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<AttendanceModel> _attendanceRecords = [];
  bool _isLoading = false;
  String? _error;
  String? _lastScannedData;
  bool _isScanning = false;
  AuthProvider? _authProvider;
  
  // Performance optimization properties
  StreamSubscription<List<AttendanceModel>>? _attendanceSubscription;
  Timer? _batchTimer;
  List<AttendanceModel> _pendingAttendances = [];

  // Getters
  List<AttendanceModel> get attendanceRecords => _attendanceRecords;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastScannedData => _lastScannedData;
  bool get isScanning => _isScanning;
  String? get currentAdminId => _authProvider?.user?.uid;

  // **OPTIMIZED: Submit attendance record with batching**
  Future<bool> submitAttendanceRecord({
    required String scannedData,
    required String sessionId,
    String? adminId,
  }) async {
    try {
      // Use provided adminId or get from auth provider
      String finalAdminId = adminId ?? _authProvider?.user?.uid ?? '';
      
      if (finalAdminId.isEmpty) {
        throw Exception('No admin ID available');
      }

      // Get current location using LocationData
      LocationData? location = await _locationService.getCurrentLocation();
      if (location == null) {
        _setError('Failed to get location. Please enable location services.');
        return false;
      }

      AttendanceModel attendance = AttendanceModel(
        id: '',
        scannedData: scannedData,
        sessionId: sessionId,
        adminId: finalAdminId,
        adminLocation: _locationService.positionToMap(location),
        timestamp: DateTime.now(),
        studentInfo: _extractStudentInfo(scannedData),
        isVerified: true,
      );

      // Add to pending batch
      _pendingAttendances.add(attendance);
      
      // Cancel existing timer
      _batchTimer?.cancel();
      
      // Set timer to submit batch after 2 seconds
      _batchTimer = Timer(const Duration(seconds: 2), () {
        _submitPendingAttendances();
      });
      
      // If batch is full, submit immediately
      if (_pendingAttendances.length >= 5) {
        _batchTimer?.cancel();
        await _submitPendingAttendances();
      }

      _lastScannedData = scannedData;
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // **NEW: Batch submission for better performance**
  Future<void> _submitPendingAttendances() async {
    if (_pendingAttendances.isEmpty) return;

    _setLoading(true);
    try {
      await submitAttendanceBatch(List.from(_pendingAttendances));
      _pendingAttendances.clear();
      _clearError();
    } catch (e) {
      _setError('Failed to submit batch attendance: $e');
    } finally {
      _setLoading(false);
    }
  }

  // **NEW: Batch Firestore operations for better performance**
  Future<void> submitAttendanceBatch(List<AttendanceModel> attendances) async {
    if (attendances.isEmpty) return;

    try {
      WriteBatch batch = _firestore.batch();
      
      for (var attendance in attendances) {
        DocumentReference ref = _firestore.collection('attendance').doc();
        batch.set(ref, attendance.toFirestore());
      }
      
      await batch.commit();
      
      // Update local list
      for (var attendance in attendances) {
        _attendanceRecords.insert(0, attendance.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString()));
      }
      notifyListeners();
      
    } catch (e) {
      print('Batch submission error: $e');
      rethrow;
    }
  }

  // **OPTIMIZED: Load session attendance records with proper cleanup**
  void loadSessionAttendance(String sessionId) {
    _attendanceSubscription?.cancel();
    
    _attendanceSubscription = _firestoreService.getSessionAttendance(sessionId).listen(
      (records) {
        _attendanceRecords = records;
        notifyListeners();
      },
      onError: (error) {
        _setError('Real-time update error: $error');
      },
    );
  }

  // **NEW: Stop listening to attendance updates**
  void stopListeningToAttendance() {
    _attendanceSubscription?.cancel();
    _attendanceSubscription = null;
  }

  // Load attendance by date range
  Future<void> loadAttendanceByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? adminId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      String finalAdminId = adminId ?? _authProvider?.user?.uid ?? '';
      
      if (finalAdminId.isEmpty) {
        throw Exception('No admin ID available');
      }

      List<AttendanceModel> records = await _firestoreService
          .getAttendanceByDateRange(finalAdminId, startDate, endDate);
      _attendanceRecords = records;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Set scanning state
  void setScanning(bool scanning) {
    _isScanning = scanning;
    notifyListeners();
  }

  // **ENHANCED: Process scanned QR/Barcode data with better validation**
  Map<String, dynamic> processScannedData(String rawData) {
    try {
      String? studentId = _extractStudentId(rawData);
      String? studentName = _extractStudentName(rawData);
      bool isValid = _validateScannedData(rawData);

      Map<String, dynamic> processedData = {
        'rawData': rawData,
        'studentId': studentId,
        'studentName': studentName,
        'isValid': isValid,
        'scannedAt': DateTime.now().toIso8601String(),
        'type': _determineDataType(rawData),
      };

      return processedData;
    } catch (e) {
      return {
        'rawData': rawData,
        'error': 'Failed to process data: $e',
        'isValid': false,
        'type': 'error',
      };
    }
  }

  // **NEW: Determine data type**
  String _determineDataType(String data) {
    if (data.startsWith('{') && data.endsWith('}')) return 'json';
    if (data.contains('@')) return 'email';
    if (data.contains('|')) return 'delimited';
    if (RegExp(r'^\d+$').hasMatch(data)) return 'numeric';
    return 'text';
  }

  // **ENHANCED: Validate scanned data with better patterns**
  bool _validateScannedData(String data) {
    if (data.isEmpty) return false;
    
    // Enhanced validation patterns
    String? studentId = _extractStudentId(data);
    if (studentId == null || studentId.isEmpty) return false;
    
    // Check for valid student ID patterns
    RegExp emailPattern = RegExp(r'^\d{8,12}@[a-zA-Z]+\.[a-zA-Z]+\.[a-zA-Z]+$');
    RegExp numericPattern = RegExp(r'^\d{6,12}$');
    
    return emailPattern.hasMatch(studentId) || numericPattern.hasMatch(studentId);
  }

  // **ENHANCED: Extract student ID with multiple format support**
  String? _extractStudentId(String data) {
    // Handle email format (e.g., "202411032@dau.ac.in")
    RegExp emailPattern = RegExp(r'(\d{8,12}@[a-zA-Z]+\.[a-zA-Z]+\.[a-zA-Z]+)');
    Match? emailMatch = emailPattern.firstMatch(data);
    if (emailMatch != null) {
      return emailMatch.group(1);
    }

    // Handle "STUDENT_ID:12345" format
    if (data.contains('STUDENT_ID:')) {
      String id = data.split('STUDENT_ID:')[1].split('|')[0].trim();
      return id.isNotEmpty ? id : null;
    }

    // Handle delimited format with |
    if (data.contains('|')) {
      List<String> parts = data.split('|');
      if (parts.isNotEmpty && parts[0].isNotEmpty) {
        return parts[0].trim();
      }
    }

    // Handle pure numeric format
    RegExp numericPattern = RegExp(r'^\d{6,12}$');
    if (numericPattern.hasMatch(data.trim())) {
      return data.trim();
    }

    // Extract numeric part from mixed data
    RegExp extractNumeric = RegExp(r'\d{6,12}');
    Match? numericMatch = extractNumeric.firstMatch(data);
    if (numericMatch != null) {
      return numericMatch.group(0);
    }

    return null;
  }

  // **ENHANCED: Extract student name with better parsing**
  String? _extractStudentName(String data) {
    if (data.contains('|')) {
      List<String> parts = data.split('|');
      if (parts.length > 1 && parts[1].isNotEmpty) {
        return parts[1].trim();
      }
    }

    // Handle NAME: format
    if (data.contains('NAME:')) {
      String name = data.split('NAME:')[1].split('|')[0].trim();
      return name.isNotEmpty ? name : null;
    }

    return null;
  }

  // **ENHANCED: Extract additional student info**
  String? _extractStudentInfo(String data) {
    Map<String, dynamic> processed = processScannedData(data);

    List<String> info = [];
    
    if (processed['studentId'] != null) {
      info.add('ID: ${processed['studentId']}');
    }
    if (processed['studentName'] != null) {
      info.add('Name: ${processed['studentName']}');
    }
    if (processed['type'] != null) {
      info.add('Type: ${processed['type']}');
    }

    return info.isNotEmpty ? info.join('\n') : data;
  }

  // **ENHANCED: Get attendance statistics with more metrics**
  Map<String, int> getAttendanceStats() {
    DateTime now = DateTime.now();
    
    int totalRecords = _attendanceRecords.length;
    int todayRecords = _attendanceRecords.where((record) {
      DateTime recordDate = record.timestamp;
      return now.year == recordDate.year &&
          now.month == recordDate.month &&
          now.day == recordDate.day;
    }).length;

    return {
      'total': totalRecords,
      'today': todayRecords,
      'thisWeek': _getWeeklyCount(),
      'thisMonth': _getMonthlyCount(),
      'verified': _getVerifiedCount(),
      'pending': _pendingAttendances.length,
    };
  }

  int _getWeeklyCount() {
    DateTime now = DateTime.now();
    DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));

    return _attendanceRecords.where((record) {
      return record.timestamp.isAfter(weekStart);
    }).length;
  }

  int _getMonthlyCount() {
    DateTime now = DateTime.now();
    DateTime monthStart = DateTime(now.year, now.month, 1);

    return _attendanceRecords.where((record) {
      return record.timestamp.isAfter(monthStart);
    }).length;
  }

  // **NEW: Get verified count**
  int _getVerifiedCount() {
    return _attendanceRecords.where((record) => record.isVerified).length;
  }

  // Clear attendance records
  void clearRecords() {
    _attendanceRecords.clear();
    _lastScannedData = null;
    _pendingAttendances.clear();
    notifyListeners();
  }

  // **ENHANCED: Update method for ProxyProvider with proper cleanup**
  void update(AuthProvider auth) {
    _authProvider = auth;
    
    // Clear data when user logs out
    if (!auth.isLoggedIn) {
      clearRecords();
      stopListeningToAttendance();
    }
    
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // **NEW: Proper disposal with cleanup**
  @override
  void dispose() {
    _attendanceSubscription?.cancel();
    _batchTimer?.cancel();
    super.dispose();
  }
}
