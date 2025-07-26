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

  // Getters
  SessionModel? get currentSession => _currentSession;
  List<SessionModel> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  LocationData? get currentLocation => _currentLocation;
  bool get hasActiveSession => _currentSession != null;
  String? get currentAdminId => _authProvider?.user?.uid;

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

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Load admin sessions
  void loadAdminSessions(String? adminId) {
    String finalAdminId = adminId ?? _authProvider?.user?.uid ?? '';
    
    if (finalAdminId.isNotEmpty) {
      _firestoreService.getAdminSessions(finalAdminId).listen((sessions) {
        _sessions = sessions;
        notifyListeners();
      });
    }
  }

  // Set current session
  Future<void> setCurrentSession(String sessionId) async {
    _setLoading(true);
    _clearError();

    try {
      SessionModel? session = await _firestoreService.getSession(sessionId);
      if (session != null) {
        _currentSession = session;

        // Update location for current session
        LocationData? location = await _locationService.getCurrentLocation();
        if (location != null) {
          _currentLocation = location;

          // Update session with current location
          await _firestoreService.updateSession(sessionId, {
            'adminLocation': _locationService.positionToMap(location),
          });
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
        await _firestoreService.updateSession(_currentSession!.id, {
          'isActive': false,
        });
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
          await _firestoreService.updateSession(_currentSession!.id, {
            'adminLocation': _locationService.positionToMap(location),
          });
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
      loadAdminSessions(auth.user!.uid);
    } else {
      // Clear data when user logs out
      _sessions.clear();
      _currentSession = null;
      _currentLocation = null;
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
