import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String scannedData;
  final String sessionId;
  final String adminId;
  final Map<String, double> adminLocation;
  final DateTime timestamp;
  final String? studentInfo;
  final bool isVerified;

  AttendanceModel({
    required this.id,
    required this.scannedData,
    required this.sessionId,
    required this.adminId,
    required this.adminLocation,
    required this.timestamp,
    this.studentInfo,
    this.isVerified = false,
  });

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return AttendanceModel(
      id: doc.id,
      scannedData: data['scannedData'] ?? '',
      sessionId: data['sessionId'] ?? '',
      adminId: data['adminId'] ?? '',
      adminLocation: Map<String, double>.from(data['adminLocation'] ?? {}),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      studentInfo: data['studentInfo'],
      isVerified: data['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'scannedData': scannedData,
      'sessionId': sessionId,
      'adminId': adminId,
      'adminLocation': adminLocation,
      'timestamp': Timestamp.fromDate(timestamp),
      'studentInfo': studentInfo,
      'isVerified': isVerified,
    };
  }

  AttendanceModel copyWith({
    String? id,
    String? scannedData,
    String? sessionId,
    String? adminId,
    Map<String, double>? adminLocation,
    DateTime? timestamp,
    String? studentInfo,
    bool? isVerified,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      scannedData: scannedData ?? this.scannedData,
      sessionId: sessionId ?? this.sessionId,
      adminId: adminId ?? this.adminId,
      adminLocation: adminLocation ?? this.adminLocation,
      timestamp: timestamp ?? this.timestamp,
      studentInfo: studentInfo ?? this.studentInfo,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
