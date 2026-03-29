class UserModel {
  final String id;
  final String firebaseUid;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String provider;
  final String role;
  final String status;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.provider,
    required this.role,
    required this.status,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      firebaseUid: json['firebase_uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['display_name'] ?? '',
      avatarUrl: json['avatar_url'],
      provider: json['provider'] ?? '',
      role: _parseRole(json['role']),
      status: _parseStatus(json['status']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['created_at_unix'] ?? 0) * 1000,
      ),
      lastLoginAt: json['last_login_at_unix'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['last_login_at_unix'] * 1000,
            )
          : null,
    );
  }

  static String _parseRole(dynamic role) {
    if (role is int) {
      switch (role) {
        case 1:
          return 'guest';
        case 2:
          return 'member';
        case 3:
          return 'admin';
        case 4:
          return 'owner';
        default:
          return 'guest';
      }
    }
    return role?.toString() ?? 'guest';
  }

  static String _parseStatus(dynamic status) {
    if (status is int) {
      switch (status) {
        case 1:
          return 'active';
        case 2:
          return 'blocked';
        case 3:
          return 'deleted';
        default:
          return 'active';
      }
    }
    return status?.toString() ?? 'active';
  }

  bool get isAdmin => role == 'admin' || role == 'owner';
  bool get isBlocked => status == 'blocked';
  bool get isActive => status == 'active';
}
