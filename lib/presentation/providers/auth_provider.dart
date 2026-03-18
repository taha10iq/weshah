// lib/presentation/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/utils/session_storage.dart';
import 'supabase_provider.dart';

// ── Repository Provider ────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(supabaseClientProvider));
});

// ── حالة المصادقة الحالية (Supabase Auth) ───────────────
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges;
});

// ── بيانات المستخدم الحالي (Supabase Auth) ──────────────
final currentProfileProvider = FutureProvider<UserProfileModel?>((ref) async {
  ref.watch(authStateProvider);
  return ref.read(authRepositoryProvider).getCurrentProfile();
});

// ── هل المستخدم مسجل دخول؟ (custom users) ───────────────
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).valueOrNull != null;
});

// ── Notifier لعمليات المصادقة عبر public.users ───────────
class AuthNotifier extends AsyncNotifier<UserProfileModel?> {
  @override
  Future<UserProfileModel?> build() async {
    // محاولة استعادة الجلسة المحفوظة عند "تذكرني"
    final saved = await SessionStorage.getSavedSession();
    if (saved == null) return null;
    try {
      final profile = await ref
          .read(authRepositoryProvider)
          .loginWithCustomUsers(
            username: saved.username,
            password: saved.password,
          );
      return profile;
    } catch (_) {
      await SessionStorage.clearSession();
      return null;
    }
  }

  /// تسجيل الدخول عبر public.users + login_user function
  Future<bool> signIn({
    required String username,
    required String password,
    bool rememberMe = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final profile = await ref
          .read(authRepositoryProvider)
          .loginWithCustomUsers(username: username, password: password);
      if (rememberMe) {
        await SessionStorage.saveSession(
          username: username,
          password: password,
          userId: profile.id,
          fullName: profile.fullName,
          role: profile.role,
        );
      } else {
        await SessionStorage.clearSession();
      }
      state = AsyncValue.data(profile);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  Future<void> signOut() async {
    await SessionStorage.clearSession();
    state = const AsyncValue.data(null);
  }

  /// تحديث الاسم والصورة وتحديث الحالة مباشرة
  Future<void> updateProfile({
    required String fullName,
    String? avatarUrl,
  }) async {
    final profile = state.valueOrNull;
    if (profile == null) return;
    await ref
        .read(authRepositoryProvider)
        .updateUserProfile(
          userId: profile.id,
          fullName: fullName,
          avatarUrl: avatarUrl,
        );
    state = AsyncValue.data(
      profile.copyWith(
        fullName: fullName,
        avatarUrl: avatarUrl ?? profile.avatarUrl,
      ),
    );
    // تحديث الجلسة المحفوظة إن وجدت
    final saved = await SessionStorage.getSavedSession();
    if (saved != null) {
      await SessionStorage.saveSession(
        username: saved.username,
        password: saved.password,
        userId: profile.id,
        fullName: fullName,
        role: profile.role,
      );
    }
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, UserProfileModel?>(AuthNotifier.new);
