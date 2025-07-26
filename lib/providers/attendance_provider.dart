import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../models/attendance_model.dart';
import '../models/session_model.dart';
import 'auth_provider.dart';
import 'package:location/location.dart';

class AttendanceProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();

  List<AttendanceModel> _attendanceRecords = [];
  bool _isLoading = false;
  String? _error;
  String? _lastScannedData;
  bool _isScanning = false;
  AuthProvider? _authProvider;

  // Getters
  List<AttendanceModel> get attendanceRecords => _attendanceRecords;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastScannedData => _lastScannedData;
  bool get isScanning => _isScanning;
  String? get currentAdminId => _authProvider?.user?.uid;

  // Submit attendance record
  Future<bool> submitAttendanceRecord({
    required String scannedData,
    required String sessionId,
    String? adminId,
  }) async {
    _setLoading(true);
    _clearError();

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
        _setLoading(false);
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

      String recordId = await _firestoreService.createAttendanceRecord(
        attendance,
      );

      // Add to local list
      AttendanceModel newRecord = attendance.copyWith(id: recordId);
      _attendanceRecords.insert(0, newRecord);

      _lastScannedData = scannedData;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Load session attendance records
  void loadSessionAttendance(String sessionId) {
    _firestoreService.getSessionAttendance(sessionId).listen((records) {
      _attendanceRecords = records;
      notifyListeners();
    });
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

  // Process scanned QR/Barcode data
  Map<String, dynamic> processScannedData(String rawData) {
    try {
      Map<String, dynamic> processedData = {
        'rawData': rawData,
        'studentId': _extractStudentId(rawData),
        'studentName': _extractStudentName(rawData),
        'isValid': _validateScannedData(rawData),
        'scannedAt': DateTime.now().toIso8601String(),
      };

      return processedData;
    } catch (e) {
      return {
        'rawData': rawData,
        'error': 'Failed to process data',
        'isValid': false,
      };
    }
  }

  // Validate scanned data
  bool _validateScannedData(String data) {
    if (data.isEmpty) return false;
    return true;
  }

  // Extract student ID from scanned data
  String? _extractStudentId(String data) {
    if (data.contains('STUDENT_ID:')) {
      return data.split('STUDENT_ID:')[1].split('|')[0];
    }

    if (data.contains('|')) {
      List<String> parts = data.split('|');
      if (parts.isNotEmpty) {
        return parts[0];
      }
    }

    return data;
  }

  // Extract student name from scanned data
  String? _extractStudentName(String data) {
    if (data.contains('|')) {
      List<String> parts = data.split('|');
      if (parts.length > 1) {
        return parts[1];
      }
    }

    return null;
  }

  // Extract additional student info
  String? _extractStudentInfo(String data) {
    Map<String, dynamic> processed = processScannedData(data);

    String info = '';
    if (processed['studentId'] != null) {
      info += 'ID: ${processed['studentId']}';
    }
    if (processed['studentName'] != null) {
      info += '\nName: ${processed['studentName']}';
    }

    return info.isNotEmpty ? info : data;
  }

  // Get attendance statistics
  Map<String, int> getAttendanceStats() {
    int totalRecords = _attendanceRecords.length;
    int todayRecords = _attendanceRecords.where((record) {
      DateTime now = DateTime.now();
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

  // Clear attendance records
  void clearRecords() {
    _attendanceRecords.clear();
    _lastScannedData = null;
    notifyListeners();
  }

  // Update method for ProxyProvider
  void update(AuthProvider auth) {
    _authProvider = auth;
    
    // Clear data when user logs out
    if (!auth.isLoggedIn) {
      clearRecords();
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
}
