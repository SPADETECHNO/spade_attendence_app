import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String role;
  final DateTime createdAt;
  final bool isActive;
  final String? assignedBy;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    required this.role,
    required this.createdAt,
    required this.isActive,
    this.assignedBy,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) throw Exception('Document data is null');

    final Map<String, dynamic> mapData = data as Map<String, dynamic>;

    // Handle timestamp conversion safely
    DateTime createdDate;
    try {
      createdDate = (mapData['createdAt'] as Timestamp).toDate();
    } catch (e) {
      createdDate = DateTime.now(); // Fallback to current date if invalid
    }

    return UserModel(
      id: doc.id,
      email: mapData['email'] as String? ?? '',
      displayName: mapData['displayName'] as String?,
      role: mapData['role'] as String? ?? '',
      createdAt: createdDate,
      isActive: mapData['isActive'] as bool? ?? true,
      assignedBy: mapData['assignedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'assignedBy': assignedBy,
    };
  }

  UserModel copyWith({String? displayName, bool? isActive}) {
    return UserModel(
      id: this.id,
      email: this.email,
      displayName: displayName ?? this.displayName,
      role: this.role,
      createdAt: this.createdAt,
      isActive: isActive ?? this.isActive,
      assignedBy: this.assignedBy,
    );
  }
}
