import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/session_model.dart';
import '../models/attendance_model.dart';
import '../models/admin_model.dart';
import '../utils/constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper method to get current year
  String _getCurrentYear() {
    return DateTime.now().year.toString();
  }

  // Helper method to extract year from date
  String _getYearFromDate(DateTime date) {
    return date.year.toString();
  }

  // User operations (unchanged)
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(Constants.USERS_COLLECTION)
          .doc(user.id)
          .set(user.toFirestore());
    } catch (e) {
      throw Exception('Failed to create user: ${e.toString()}');
    }
  }

  Future<UserModel?> getUser(String uid) async {
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
      throw Exception('Failed to get user: ${e.toString()}');
    }
  }

  Stream<List<AdminModel>> getAdmins(String superAdminId) {
    return _firestore
        .collection(Constants.USERS_COLLECTION)
        .where('role', isEqualTo: Constants.ADMIN)
        .where('assignedBy', isEqualTo: superAdminId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AdminModel.fromFirestore(doc)).toList());
  }

  // Session operations - UPDATED for year-based structure
  Future<String> createSession(SessionModel session) async {
    try {
      String year = _getYearFromDate(session.date);
      DocumentReference docRef = await _firestore
          .collection(Constants.SESSIONS_COLLECTION)
          .doc(year)
          .collection('sessions')
          .add(session.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create session: ${e.toString()}');
    }
  }

  Future<SessionModel?> getSession(String sessionId, [String? year]) async {
    try {
      String sessionYear = year ?? _getCurrentYear();
      DocumentSnapshot doc = await _firestore
          .collection(Constants.SESSIONS_COLLECTION)
          .doc(sessionYear)
          .collection('sessions')
          .doc(sessionId)
          .get();

      if (doc.exists) {
        return SessionModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get session: ${e.toString()}');
    }
  }

  // Get sessions for specific year
  Stream<List<SessionModel>> getAdminSessions(String adminId, [String? year]) {
    String sessionYear = year ?? _getCurrentYear();
    return _firestore
        .collection(Constants.SESSIONS_COLLECTION)
        .doc(sessionYear)
        .collection('sessions')
        .where('adminId', isEqualTo: adminId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SessionModel.fromFirestore(doc)).toList());
  }

  // Get sessions across multiple years
  Stream<List<SessionModel>> getAdminSessionsMultipleYears(
    String adminId, 
    List<String> years,
  ) async* {
    List<SessionModel> allSessions = [];
    
    for (String year in years) {
      QuerySnapshot snapshot = await _firestore
          .collection(Constants.SESSIONS_COLLECTION)
          .doc(year)
          .collection('sessions')
          .where('adminId', isEqualTo: adminId)
          .orderBy('createdAt', descending: true)
          .get();
      
      List<SessionModel> yearSessions = snapshot.docs
          .map((doc) => SessionModel.fromFirestore(doc))
          .toList();
      
      allSessions.addAll(yearSessions);
    }
    
    // Sort all sessions by creation date
    allSessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield allSessions;
  }

  Future<void> updateSession(String sessionId, Map<String, dynamic> data, [String? year]) async {
    try {
      String sessionYear = year ?? _getCurrentYear();
      await _firestore
          .collection(Constants.SESSIONS_COLLECTION)
          .doc(sessionYear)
          .collection('sessions')
          .doc(sessionId)
          .update(data);
    } catch (e) {
      throw Exception('Failed to update session: ${e.toString()}');
    }
  }

  // Get all available years that have sessions
  Future<List<String>> getAvailableSessionYears() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(Constants.SESSIONS_COLLECTION)
          .get();
      
      List<String> years = snapshot.docs
          .map((doc) => doc.id)
          .where((id) => RegExp(r'^\d{4}$').hasMatch(id))
          .toList();
      
      years.sort((a, b) => b.compareTo(a)); // Sort descending (newest first)
      return years;
    } catch (e) {
      throw Exception('Failed to get available years: ${e.toString()}');
    }
  }

  // Attendance operations - UPDATED to work with year-based sessions
  Future<String> createAttendanceRecord(AttendanceModel attendance) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(Constants.ATTENDANCE_COLLECTION)
          .add(attendance.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create attendance record: ${e.toString()}');
    }
  }

  Stream<List<AttendanceModel>> getSessionAttendance(String sessionId) {
    return _firestore
        .collection(Constants.ATTENDANCE_COLLECTION)
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AttendanceModel.fromFirestore(doc)).toList());
  }

  Future<List<AttendanceModel>> getAttendanceByDateRange(
    String adminId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(Constants.ATTENDANCE_COLLECTION)
          .where('adminId', isEqualTo: adminId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AttendanceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get attendance records: ${e.toString()}');
    }
  }

  // Admin operations (unchanged)
  Future<void> assignAdmin(String email, String superAdminId) async {
    try {
      AdminModel admin = AdminModel(
        id: '', // Will be set by Firestore
        email: email,
        assignedBy: superAdminId,
        assignedAt: DateTime.now(),
        isActive: true,
      );

      await _firestore
          .collection(Constants.USERS_COLLECTION)
          .add(admin.toFirestore());
    } catch (e) {
      throw Exception('Failed to assign admin: ${e.toString()}');
    }
  }

  Future<void> updateAdminStatus(String adminId, bool isActive) async {
    try {
      await _firestore
          .collection(Constants.USERS_COLLECTION)
          .doc(adminId)
          .update({'isActive': isActive});
    } catch (e) {
      throw Exception('Failed to update admin status: ${e.toString()}');
    }
  }
}
