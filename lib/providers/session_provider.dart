import 'package:flutter/material.dart';
import 'package:location/location.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../models/session_model.dart';
import '../utils/date_helpers.dart';
import 'auth_provider.dart';

class SessionProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();

  SessionModel? _currentSession;
  List<SessionModel> _sessions = [];
  bool _isLoading = false;
  String? _error;
  LocationData? _currentLocation;
  AuthProvider? _authProvider;
  String _selectedYear = DateTime.now().year.toString();
  List<String> _availableYears = [];

  // Getters
  SessionModel? get currentSession => _currentSession;
  List<SessionModel> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  LocationData? get currentLocation => _currentLocation;
  bool get hasActiveSession => _currentSession != null;
  String? get currentAdminId => _authProvider?.user?.uid;
  String get selectedYear => _selectedYear;
  List<String> get availableYears => _availableYears;

  // Create new session
  Future<bool> createSession({
    required String companyName,
    required String sessionName,
    required DateTime sessionDate,
    required String startTime,
    required String endTime,
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

      // Get current location
      LocationData? location = await _locationService.getCurrentLocation();
      if (location == null) {
        _setError('Failed to get location. Please enable location services.');
        _setLoading(false);
        return false;
      }

      _currentLocation = location;

      SessionModel session = SessionModel(
        id: '',
        companyName: companyName,
        sessionName: sessionName,
        sessionDate: sessionDate,
        startTime: startTime,
        endTime: endTime,
        adminId: finalAdminId,
        createdAt: DateTime.now(),
        adminLocation: _locationService.positionToMap(location),
      );

      String sessionId = await _firestoreService.createSession(session);
      _currentSession = session.copyWith(id: sessionId);

      // Refresh available years and sessions for current year
      await _loadAvailableYears();
      _loadAdminSessionsForYear(finalAdminId, sessionDate.year.toString());

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Load admin sessions for current selected year
  void loadAdminSessions(String? adminId) {
    String finalAdminId = adminId ?? _authProvider?.user?.uid ?? '';
    
    if (finalAdminId.isNotEmpty) {
      _loadAdminSessionsForYear(finalAdminId, _selectedYear);
    }
  }

  // Load admin sessions for specific year
  void _loadAdminSessionsForYear(String adminId, String year) {
    _firestoreService.getAdminSessions(adminId, year).listen((sessions) {
      _sessions = sessions;
      notifyListeners();
    });
  }

  // Change selected year and reload sessions
  Future<void> changeSelectedYear(String year) async {
    if (_selectedYear != year) {
      _selectedYear = year;
      String finalAdminId = _authProvider?.user?.uid ?? '';
      
      if (finalAdminId.isNotEmpty) {
        _loadAdminSessionsForYear(finalAdminId, year);
      }
      
      notifyListeners();
    }
  }

  // Load available years
  Future<void> _loadAvailableYears() async {
    try {
      _availableYears = await _firestoreService.getAvailableSessionYears();
      
      // Ensure current year is in the list
      String currentYear = DateTime.now().year.toString();
      if (!_availableYears.contains(currentYear)) {
        _availableYears.insert(0, currentYear);
      }
      
      notifyListeners();
    } catch (e) {
      print('Failed to load available years: $e');
    }
  }

  // Load sessions across multiple years
  Future<void> loadAllAdminSessions(String? adminId, {List<String>? years}) async {
    String finalAdminId = adminId ?? _authProvider?.user?.uid ?? '';
    
    if (finalAdminId.isEmpty) return;

    _setLoading(true);
    
    try {
      List<String> yearsToLoad = years ?? _availableYears;
      
      if (yearsToLoad.isEmpty) {
        await _loadAvailableYears();
        yearsToLoad = _availableYears;
      }

      _firestoreService.getAdminSessionsMultipleYears(finalAdminId, yearsToLoad).listen((sessions) {
        _sessions = sessions;
        _setLoading(false);
        notifyListeners();
      });
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Set current session
  Future<void> setCurrentSession(String sessionId, {String? year}) async {
    _setLoading(true);
    _clearError();

    try {
      String sessionYear = year ?? _selectedYear;
      SessionModel? session = await _firestoreService.getSession(sessionId, sessionYear);
      
      if (session != null) {
        _currentSession = session;

        // Update location for current session
        LocationData? location = await _locationService.getCurrentLocation();
        if (location != null) {
          _currentLocation = location;

          // Update session with current location
          await _firestoreService.updateSession(
            sessionId,
            {
              'adminLocation': _locationService.positionToMap(location),
            },
            sessionYear,
          );
        }
      }
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // End current session
  Future<void> endCurrentSession() async {
    if (_currentSession != null) {
      try {
        String sessionYear = _currentSession!.sessionDate.year.toString();
        await _firestoreService.updateSession(
          _currentSession!.id,
          {
            'isActive': false,
          },
          sessionYear,
        );
        _currentSession = null;
        _currentLocation = null;
        notifyListeners();
      } catch (e) {
        _setError(e.toString());
        notifyListeners();
      }
    }
  }

  // Update current location
  Future<void> updateCurrentLocation() async {
    try {
      LocationData? location = await _locationService.getCurrentLocation();
      if (location != null) {
        _currentLocation = location;

        // Update session location if there's an active session
        if (_currentSession != null) {
          String sessionYear = _currentSession!.sessionDate.year.toString();
          await _firestoreService.updateSession(
            _currentSession!.id,
            {
              'adminLocation': _locationService.positionToMap(location),
            },
            sessionYear,
          );
        }

        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
      notifyListeners();
    }
  }

  // Validate session time
  bool isSessionActive() {
    if (_currentSession == null) return false;

    DateTime now = DateTime.now();
    DateTime sessionDate = _currentSession!.sessionDate;

    // Check if it's the same date
    if (!DateHelpers.isSameDay(now, sessionDate)) {
      return false;
    }

    // Parse time strings and check if current time is within session duration
    DateTime? startTime = DateHelpers.parseTime(_currentSession!.startTime);
    DateTime? endTime = DateHelpers.parseTime(_currentSession!.endTime);

    if (startTime == null || endTime == null) return true;

    TimeOfDay currentTime = TimeOfDay.fromDateTime(now);
    TimeOfDay sessionStart = TimeOfDay.fromDateTime(startTime);
    TimeOfDay sessionEnd = TimeOfDay.fromDateTime(endTime);

    int currentMinutes = currentTime.hour * 60 + currentTime.minute;
    int startMinutes = sessionStart.hour * 60 + sessionStart.minute;
    int endMinutes = sessionEnd.hour * 60 + sessionEnd.minute;

    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  // Get session info for display
  String getSessionDisplayInfo() {
    if (_currentSession == null) return 'No active session';

    return '''
Company: ${_currentSession!.companyName}
Session: ${_currentSession!.sessionName}
Date: ${DateHelpers.formatDate(_currentSession!.sessionDate)}
Time: ${_currentSession!.startTime} - ${_currentSession!.endTime}
Location: ${_currentLocation != null ? _locationService.formatLocationString(_currentLocation!) : 'Unknown'}
''';
  }

  // Update method for ProxyProvider
  void update(AuthProvider auth) {
    _authProvider = auth;
    
    // Auto-load sessions when auth changes
    if (auth.isLoggedIn && auth.user?.uid != null) {
      _loadAvailableYears().then((_) {
        loadAdminSessions(auth.user!.uid);
      });
    } else {
      // Clear data when user logs out
      _sessions.clear();
      _currentSession = null;
      _currentLocation = null;
      _availableYears.clear();
      _selectedYear = DateTime.now().year.toString();
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
