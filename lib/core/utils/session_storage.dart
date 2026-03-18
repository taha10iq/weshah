// lib/core/utils/session_storage.dart

import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  static const _keyRememberMe = 'remember_me';
  static const _keyUsername = 'saved_username';
  static const _keyPassword = 'saved_password';
  static const _keyUserId = 'saved_user_id';
  static const _keyFullName = 'saved_full_name';
  static const _keyRole = 'saved_role';

  /// حفظ بيانات تسجيل الدخول عند تفعيل "تذكرني"
  static Future<void> saveSession({
    required String username,
    required String password,
    required String userId,
    required String fullName,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, true);
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyPassword, password);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyFullName, fullName);
    await prefs.setString(_keyRole, role);
  }

  /// مسح الجلسة المحفوظة
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRememberMe);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyPassword);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyFullName);
    await prefs.remove(_keyRole);
  }

  /// جلب بيانات الجلسة المحفوظة (إن وجدت)
  static Future<SavedSession?> getSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_keyRememberMe) ?? false;
    if (!remember) return null;

    final username = prefs.getString(_keyUsername);
    final password = prefs.getString(_keyPassword);
    final userId = prefs.getString(_keyUserId);
    final fullName = prefs.getString(_keyFullName);
    final role = prefs.getString(_keyRole);

    if (username == null || password == null || userId == null) return null;

    return SavedSession(
      username: username,
      password: password,
      userId: userId,
      fullName: fullName ?? '',
      role: role ?? 'employee',
    );
  }
}

class SavedSession {
  final String username;
  final String password;
  final String userId;
  final String fullName;
  final String role;

  const SavedSession({
    required this.username,
    required this.password,
    required this.userId,
    required this.fullName,
    required this.role,
  });
}
