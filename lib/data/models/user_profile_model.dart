// lib/data/models/user_profile_model.dart

class UserProfileModel {
  final String id;
  final String fullName;
  final String username;
  final String role;
  final bool isActive;
  final String? avatarUrl;

  const UserProfileModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.role,
    required this.isActive,
    this.avatarUrl,
  });

  bool get isAdmin => role == 'admin';

  factory UserProfileModel.fromCustomUsers(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'].toString(),
      fullName: json['full_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? 'employee',
      isActive: json['is_active'] as bool? ?? true,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel.fromCustomUsers(json);
  }

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'username': username,
    'role': role,
    'is_active': isActive,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
  };

  UserProfileModel copyWith({
    String? fullName,
    String? username,
    String? role,
    bool? isActive,
    String? avatarUrl,
  }) {
    return UserProfileModel(
      id: id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
