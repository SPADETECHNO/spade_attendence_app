import 'package:cloud_firestore/cloud_firestore.dart';

class AdminModel {
  final String id;
  final String email;
  final String? displayName;
  final bool isActive;
  final String assignedBy;
  final DateTime assignedAt;
  final List<String> permissions;
  final Map<String, dynamic>? lastKnownLocation;

  AdminModel({
    required this.id,
    required this.email,
    this.displayName,
    this.isActive = true,
    required this.assignedBy,
    required this.assignedAt,
    this.permissions = const ['scan_attendance', 'create_session'],
    this.lastKnownLocation,
  });

  factory AdminModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return AdminModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      isActive: data['isActive'] ?? true,
      assignedBy: data['assignedBy'] ?? '',
      assignedAt: (data['assignedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      permissions: List<String>.from(data['permissions'] ?? ['scan_attendance', 'create_session']),
      lastKnownLocation: data['lastKnownLocation'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'isActive': isActive,
      'assignedBy': assignedBy,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'permissions': permissions,
      'lastKnownLocation': lastKnownLocation,
    };
  }

  AdminModel copyWith({
    String? id,
    String? email,
    String? displayName,
    bool? isActive,
    String? assignedBy,
    DateTime? assignedAt,
    List<String>? permissions,
    Map<String, dynamic>? lastKnownLocation,
  }) {
    return AdminModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isActive: isActive ?? this.isActive,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedAt: assignedAt ?? this.assignedAt,
      permissions: permissions ?? this.permissions,
      lastKnownLocation: lastKnownLocation ?? this.lastKnownLocation,
    );
  }
}
