class Constants {
  // User Roles
  static const String SUPER_ADMIN = 'super_admin';
  static const String ADMIN = 'admin';

  // Role Check Methods
  static bool isSuperAdmin(String? role) =>
      role?.trim().toLowerCase() == SUPER_ADMIN.toLowerCase();
  static bool isAdmin(String? role) =>
      role?.trim().toLowerCase() == ADMIN.toLowerCase();

  // Collection Names
  static const String USERS_COLLECTION = 'users';
  static const String SESSIONS_COLLECTION = 'sessions';
  static const String ATTENDANCE_COLLECTION = 'attendance_records';

  // Shared Preferences Keys
  static const String USER_ROLE_KEY = 'user_role';
  static const String USER_ID_KEY = 'user_id';

  // Default Values
  static const String DEFAULT_COMPANY = 'Select Company';
  static const int LOCATION_TIMEOUT = 30; // seconds
  static const double LOCATION_ACCURACY = 100; // meters
}
