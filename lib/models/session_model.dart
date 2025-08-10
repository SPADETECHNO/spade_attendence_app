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

  DateTime get date => sessionDate;

  // **NEW: Get year from session date for year-based organization**
  String get year => sessionDate.year.toString();

  // **NEW: Check if session is from current year**
  bool get isCurrentYear => sessionDate.year == DateTime.now().year;

  // **NEW: Get formatted date string**
  String get formattedDate => '${sessionDate.day}/${sessionDate.month}/${sessionDate.year}';

  // **NEW: Get display name with year context**
  String get displayName => isCurrentYear 
      ? sessionName
      : '$sessionName (${sessionDate.year})';

  // **NEW: Check if session is today**
  bool get isToday {
    DateTime now = DateTime.now();
    return sessionDate.year == now.year &&
           sessionDate.month == now.month &&
           sessionDate.day == now.day;
  }

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
      // **NEW: Add year field for easier querying (optional)**
      'year': sessionDate.year,
    };
  }

  // **ENHANCED: copyWith with better null handling**
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

  // **NEW: JSON serialization support**
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'sessionName': sessionName,
      'sessionDate': sessionDate.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'adminId': adminId,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'adminLocation': adminLocation,
      'year': sessionDate.year,
    };
  }

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] ?? '',
      companyName: json['companyName'] ?? '',
      sessionName: json['sessionName'] ?? '',
      sessionDate: DateTime.parse(json['sessionDate'] ?? DateTime.now().toIso8601String()),
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      adminId: json['adminId'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
      adminLocation: json['adminLocation'] != null 
          ? Map<String, double>.from(json['adminLocation'])
          : null,
    );
  }

  // **NEW: Comparison and equality**
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionModel &&
        other.id == id &&
        other.companyName == companyName &&
        other.sessionName == sessionName &&
        other.sessionDate == sessionDate &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.adminId == adminId &&
        other.createdAt == createdAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      companyName,
      sessionName,
      sessionDate,
      startTime,
      endTime,
      adminId,
      createdAt,
      isActive,
    );
  }

  @override
  String toString() {
    return 'SessionModel(id: $id, companyName: $companyName, sessionName: $sessionName, sessionDate: $sessionDate, year: $year, isActive: $isActive)';
  }
}
