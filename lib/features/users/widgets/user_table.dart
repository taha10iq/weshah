import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/user_service.dart';

class UserTable extends ConsumerWidget {
  const UserTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    return usersAsync.when(
      data: (users) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('الاسم')),
              DataColumn(label: Text('اسم المستخدم')),
              DataColumn(label: Text('الدور')),
              DataColumn(label: Text('الحالة')),
              DataColumn(label: Text('الإجراءات')),
            ],
            rows: users.map((user) {
              return DataRow(
                cells: [
                  DataCell(Text(user.fullName)),
                  DataCell(Text(user.username)),
                  DataCell(Text(user.role == 'admin' ? 'مدير' : 'موظف')),
                  DataCell(
                    Text(
                      user.isActive ? 'نشط' : 'معطل',
                      style: TextStyle(
                        color: user.isActive ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.block),
                      tooltip: 'تعطيل المستخدم',
                      onPressed: user.isActive
                          ? () async {
                              try {
                                await ref
                                    .read(userServiceProvider)
                                    .disableUser(user.id);
                                ref.invalidate(usersProvider);

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم تعطيل المستخدم بنجاح'),
                                  ),
                                );
                              } catch (error) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      userManagementErrorMessage(
                                        error,
                                        fallback: 'تعذر تعطيل المستخدم حالياً.',
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }
                          : null,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          userManagementErrorMessage(
            error,
            fallback: 'تعذر تحميل قائمة المستخدمين حالياً.',
          ),
        ),
      ),
    );
  }
}
