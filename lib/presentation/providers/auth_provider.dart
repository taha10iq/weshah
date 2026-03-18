// lib/presentation/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/repositories/auth_repository.dart';
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
    // لا توجد جلسة مستمرة مع custom users — يبدأ بـ null
    return null;
  }

  /// تسجيل الدخول عبر public.users + login_user function
  Future<bool> signIn({
    required String username,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final profile = await ref
          .read(authRepositoryProvider)
          .loginWithCustomUsers(username: username, password: password);
      state = AsyncValue.data(profile);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, UserProfileModel?>(AuthNotifier.new);
