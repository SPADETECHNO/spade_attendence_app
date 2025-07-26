import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id;
  final String companyName;
  final String sessionName;
  final DateTime sessionDate;
  final String startTime;
  final String endTime;
  final String adminId;
  final DateTime createdAt;
  final bool isActive;
  final Map<String, double>? adminLocation;

  SessionModel({
    required this.id,
    required this.companyName,
    required this.sessionName,
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    required this.adminId,
    required this.createdAt,
    this.isActive = true,
    this.adminLocation,
  });

  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return SessionModel(
      id: doc.id,
      companyName: data['companyName'] ?? '',
      sessionName: data['sessionName'] ?? '',
      sessionDate: (data['sessionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      adminId: data['adminId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      adminLocation: data['adminLocation'] != null 
          ? Map<String, double>.from(data['adminLocation'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'companyName': companyName,
      'sessionName': sessionName,
      'sessionDate': Timestamp.fromDate(sessionDate),
      'startTime': startTime,
      'endTime': endTime,
      'adminId': adminId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'adminLocation': adminLocation,
    };
  }

  SessionModel copyWith({
    String? id,
    String? companyName,
    String? sessionName,
    DateTime? sessionDate,
    String? startTime,
    String? endTime,
    String? adminId,
    DateTime? createdAt,
    bool? isActive,
    Map<String, double>? adminLocation,
  }) {
    return SessionModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      sessionName: sessionName ?? this.sessionName,
      sessionDate: sessionDate ?? this.sessionDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      adminId: adminId ?? this.adminId,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      adminLocation: adminLocation ?? this.adminLocation,
    );
  }
}
