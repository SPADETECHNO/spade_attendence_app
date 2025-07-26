import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isSuperAdmin => Constants.isSuperAdmin(_userModel?.role);
  bool get isAdmin => Constants.isAdmin(_userModel?.role);
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _initAuth();
  }

  void _initAuth() {
    print("Initializing auth state...");
    _authService.authStateChanges.listen((User? user) async {
      print("Auth state changed: ${user?.email}");
      _user = user;
      
      if (user != null) {
        try {
          _setLoading(true);
          _userModel = await _authService.getUserData(user.uid);
          print("User model loaded: ${_userModel?.role}");
        } catch (e) {
          print("Error loading user data: $e");
          _error = e.toString();
        } finally {
          _setLoading(false);
        }
      } else {
        _userModel = null;
        print("User signed out");
      }
      
      _isInitialized = true;
      notifyListeners();
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      _userModel = await _authService.getUserData(uid);
    } catch (e) {
      _error = e.toString();
    }
  }

  // Sign in
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      print("Attempting sign in for: $email");
      UserCredential? result = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      
      if (result != null && result.user != null) {
        await _loadUserData(result.user!.uid);
        print("Sign in successful, user role: ${_userModel?.role}");
        
        if (_userModel == null || _userModel?.role == null) {
          throw Exception('Invalid user role');
        }
        
        _setLoading(false);
        return true;
      }
      
      print("Sign in failed: no user credential");
      _setLoading(false);
      return false;
    } catch (e) {
      print("Sign in error: $e");
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Register
  Future<bool> register(
    String email,
    String password,
    String role,
    String? assignedBy,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      UserCredential? result = await _authService.registerWithEmailAndPassword(
        email,
        password,
        role,
        assignedBy,
      );
      
      if (result != null) {
        await _loadUserData(result.user!.uid);
        _setLoading(false);
        return true;
      }
      
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _user = null;
      _userModel = null;
      _clearError();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Update profile
  Future<bool> updateProfile(String displayName) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.updateUserProfile(displayName);
      if (_userModel != null) {
        _userModel = _userModel!.copyWith(displayName: displayName);
      }
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Send password reset
  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
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
