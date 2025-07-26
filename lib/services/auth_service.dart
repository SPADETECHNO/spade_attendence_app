import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // First authenticate with Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Then fetch the user document from Firestore
      final userDoc = await _firestore
          .collection(Constants.USERS_COLLECTION)
          .doc(credential.user?.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        throw Exception('User not found in database');
      }

      // Return the credential without trying to cast user details
      return credential;
    } on FirebaseAuthException catch (e) {
      String message = _getErrorMessage(e.code);
      throw Exception('Login failed: $message');
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Invalid password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      default:
        return 'Authentication failed';
    }
  }

  // Register new user
  Future<UserCredential?> registerWithEmailAndPassword(
    String email,
    String password,
    String role,
    String? assignedBy,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      if (result.user != null) {
        await createUserDocument(result.user!, role, assignedBy);
      }

      return result;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Create user document in Firestore
  Future<void> createUserDocument(
    User user,
    String role,
    String? assignedBy,
  ) async {
    UserModel userModel = UserModel(
      id: user.uid,
      email: user.email!,
      role: role,
      displayName: user.displayName,
      createdAt: DateTime.now(),
      isActive: true,
      assignedBy: assignedBy,
    );

    await _firestore
        .collection(Constants.USERS_COLLECTION)
        .doc(user.uid)
        .set(userModel.toFirestore());
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(Constants.USERS_COLLECTION)
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String displayName) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);

        // Update Firestore document
        await _firestore
            .collection(Constants.USERS_COLLECTION)
            .doc(user.uid)
            .update({'displayName': displayName});
      }
    } catch (e) {
      throw Exception('Profile update failed: ${e.toString()}');
    }
  }
}
