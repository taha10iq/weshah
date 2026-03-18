// lib/data/models/user_profile_model.dart

class UserProfileModel {
  final String id;
  final String fullName;
  final String username;
  final String role;
  final bool isActive;

  const UserProfileModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.role,
    required this.isActive,
  });

  bool get isAdmin => role == 'admin';

  factory UserProfileModel.fromCustomUsers(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'].toString(),
      fullName: json['full_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? 'employee',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  // للتوافق مع الكود القديم
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel.fromCustomUsers(json);
  }

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'username': username,
    'role': role,
    'is_active': isActive,
  };

  UserProfileModel copyWith({
    String? fullName,
    String? username,
    String? role,
    bool? isActive,
  }) {
    return UserProfileModel(
      id: id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}
