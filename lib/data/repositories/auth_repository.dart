// lib/data/repositories/auth_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  // ── الجلسة الحالية ──────────────────────────────────────
  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  bool get isLoggedIn => currentUser != null;

  // ── تسجيل الدخول عبر Supabase Auth ─────────────────────
  Future<UserProfileModel> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) {
      throw Exception('فشل تسجيل الدخول');
    }
    return await getProfile(response.user!.id);
  }

  // ── تسجيل الدخول عبر public.users (login_user function) ─
  Future<UserProfileModel> loginWithCustomUsers({
    required String username,
    required String password,
  }) async {
    final List<dynamic> rows = await _client.rpc(
      'login_user',
      params: {'p_username': username, 'p_password': password},
    );

    if (rows.isEmpty) {
      throw Exception('اسم المستخدم أو كلمة المرور غير صحيحة');
    }

    // login_user تُرجع avatar_url مباشرة بعد migration 005
    return UserProfileModel.fromCustomUsers(rows.first as Map<String, dynamic>);
  }

  // ── تسجيل الخروج ────────────────────────────────────────
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── جلب بيانات المستخدم ──────────────────────────────────
  Future<UserProfileModel> getProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select('id, full_name, phone, role, is_active')
        .eq('id', userId)
        .single();
    return UserProfileModel.fromJson(data);
  }

  // ── جلب بيانات المستخدم الحالي ───────────────────────────
  Future<UserProfileModel?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      return await getProfile(user.id);
    } catch (_) {
      return null;
    }
  }

  // ── إنشاء موظف جديد (Admin فقط) ──────────────────────────
  Future<void> createEmployee({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String role = 'employee',
  }) async {
    await _client.functions.invoke(
      'create-employee',
      body: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'phone': phone ?? '',
        'role': role,
      },
    );
  }

  // ── جلب كل المستخدمين (Admin فقط) ───────────────────────
  Future<List<UserProfileModel>> getAllProfiles() async {
    final data = await _client
        .from('profiles')
        .select('id, full_name, phone, role, is_active')
        .order('full_name');
    return (data as List)
        .map((e) => UserProfileModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── تحديث اسم المستخدم وصورته ──────────────────────────
  Future<void> updateUserProfile({
    required String userId,
    required String fullName,
    String? avatarUrl,
  }) async {
    final data = <String, dynamic>{
      'full_name': fullName,
      'updated_at': DateTime.now().toIso8601String(),
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
    await _client.from('users').update(data).eq('id', userId);
  }

  // ── تحديث حالة المستخدم ──────────────────────────────────
  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _client.from('profiles').update(data).eq('id', userId);
  }

  // ── تغيير كلمة المرور عبر public.users ──────────────────
  Future<void> changePasswordCustom({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    // التحقق من كلمة المرور القديمة أولاً
    final List<dynamic> check = await _client.rpc(
      'verify_user_password',
      params: {'p_user_id': userId, 'p_password': oldPassword},
    );
    if (check.isEmpty || check.first['valid'] != true) {
      throw Exception('كلمة المرور القديمة غير صحيحة');
    }
    // تحديث كلمة المرور
    await _client.rpc(
      'update_user_password',
      params: {'p_user_id': userId, 'p_new_password': newPassword},
    );
  }

  // ── تغيير كلمة المرور ────────────────────────────────────
  Future<void> changePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  // ── Stream لمراقبة حالة الجلسة ──────────────────────────
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
