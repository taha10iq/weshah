import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../presentation/providers/auth_provider.dart';
import '../services/user_service.dart';
import '../widgets/add_user_dialog.dart';
import '../widgets/user_table.dart';

class UserManagementPage extends ConsumerWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final session = Supabase.instance.client.auth.currentSession;

    // حماية الدخول
    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/login');
        }
      });
      return const SizedBox();
    }

    return profileAsync.when(
      data: (profile) {
        if (profile == null || !profile.isAdmin) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/dashboard');
            }
          });
          return const SizedBox();
        }
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'إدارة المستخدمين',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add),
                      label: const Text('إضافة مستخدم'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const AddUserDialog(),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => ref.invalidate(usersProvider),
                      tooltip: 'تحديث القائمة',
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Expanded(child: UserTable()),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          userManagementErrorMessage(
            error,
            fallback: 'تعذر التحقق من صلاحيات المستخدم الحالية.',
          ),
        ),
      ),
    );
  }
}
