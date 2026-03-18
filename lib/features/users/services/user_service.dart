import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/user_profile_model.dart';

class UserManagementException implements Exception {
  final String message;

  const UserManagementException(this.message);

  @override
  String toString() => message;
}

final userServiceProvider = Provider<UserService>((ref) => UserService());
final usersProvider = FutureProvider<List<UserProfileModel>>(
  (ref) => ref.read(userServiceProvider).getUsers(),
);

class UserService {
  UserService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<UserProfileModel>> getUsers() async {
    try {
      final response = await _client
          .from('profiles')
          .select('id, full_name, phone, role, is_active')
          .order('full_name');

      return (response as List)
          .map(
            (item) => UserProfileModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (error) {
      throw UserManagementException(
        _mapPostgrestError(
          error,
          fallbackMessage: 'تعذر تحميل قائمة المستخدمين حالياً.',
        ),
      );
    } catch (_) {
      throw const UserManagementException(
        'تعذر تحميل قائمة المستخدمين حالياً.',
      );
    }
  }

  Future<void> addUser({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    try {
      await _client.functions.invoke(
        'create-employee',
        body: {
          'email': email,
          'password': password,
          'full_name': fullName,
          'phone': phone,
          'role': role,
        },
      );
    } on FunctionException catch (error) {
      throw UserManagementException(_mapFunctionError(error));
    } on PostgrestException catch (error) {
      throw UserManagementException(
        _mapPostgrestError(
          error,
          fallbackMessage: 'تعذر إنشاء المستخدم حالياً.',
        ),
      );
    } catch (_) {
      throw const UserManagementException('تعذر إنشاء المستخدم حالياً.');
    }
  }

  Future<void> disableUser(String userId) async {
    try {
      await _client
          .from('profiles')
          .update({'is_active': false})
          .eq('id', userId);
    } on PostgrestException catch (error) {
      throw UserManagementException(
        _mapPostgrestError(
          error,
          fallbackMessage: 'تعذر تعطيل المستخدم حالياً.',
        ),
      );
    } catch (_) {
      throw const UserManagementException('تعذر تعطيل المستخدم حالياً.');
    }
  }
}

String userManagementErrorMessage(
  Object error, {
  String fallback = 'حدث خطأ غير متوقع.',
}) {
  if (error is UserManagementException) {
    return error.message;
  }

  if (error is PostgrestException) {
    return _mapPostgrestError(error, fallbackMessage: fallback);
  }

  if (error is FunctionException) {
    return _mapFunctionError(error);
  }

  return fallback;
}

String _mapPostgrestError(
  PostgrestException error, {
  required String fallbackMessage,
}) {
  final message = error.message.toLowerCase();
  final details = error.details?.toString().toLowerCase() ?? '';
  final hint = error.hint?.toLowerCase() ?? '';

  if (error.code == '42501' ||
      message.contains('permission') ||
      details.contains('permission') ||
      hint.contains('policy')) {
    return 'ليست لديك صلاحية لتنفيذ هذا الإجراء.';
  }

  if (error.code == '23505' ||
      message.contains('duplicate') ||
      details.contains('duplicate')) {
    return 'البيانات المدخلة موجودة مسبقاً.';
  }

  if (error.code == 'PGRST116' || message.contains('no rows')) {
    return 'لم يتم العثور على بيانات المستخدم المطلوبة.';
  }

  if (message.contains('network') || details.contains('network')) {
    return 'تعذر الاتصال بالخادم حالياً.';
  }

  return fallbackMessage;
}

String _mapFunctionError(FunctionException error) {
  final details = error.details;
  final message = switch (details) {
    final Map<dynamic, dynamic> data => [
      data['message'],
      data['error'],
      data['details'],
    ].whereType<String>().join(' ').toLowerCase(),
    final String text => text.toLowerCase(),
    _ => (error.reasonPhrase ?? '').toLowerCase(),
  };

  if (error.status == 401 || error.status == 403) {
    return 'ليست لديك صلاحية لإضافة المستخدمين.';
  }

  if (error.status == 404) {
    return 'دالة إنشاء المستخدم غير منشورة على Supabase.';
  }

  if (error.status == 409 ||
      message.contains('already') ||
      message.contains('exists') ||
      message.contains('registered') ||
      message.contains('duplicate')) {
    return 'البريد الإلكتروني مستخدم مسبقاً.';
  }

  if (message.contains('invalid email')) {
    return 'البريد الإلكتروني غير صالح.';
  }

  if (message.contains('password')) {
    return 'كلمة المرور غير مطابقة للمتطلبات.';
  }

  if (message.contains('missing supabase function secrets') ||
      message.contains('service role')) {
    return 'إعدادات دالة إنشاء المستخدم غير مكتملة على الخادم.';
  }

  return 'تعذر إنشاء المستخدم حالياً. حاول مرة أخرى.';
}
