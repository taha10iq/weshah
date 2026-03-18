import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/user_service.dart';

class AddUserDialog extends ConsumerStatefulWidget {
  const AddUserDialog({super.key});

  @override
  ConsumerState<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends ConsumerState<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _role = 'employee';
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _loading = true);

    try {
      await ref
          .read(userServiceProvider)
          .addUser(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            fullName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            role: _role,
          );

      if (!mounted) return;

      navigator.pop();
      ref.invalidate(usersProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('تم إنشاء المستخدم بنجاح')),
      );
    } catch (error) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            userManagementErrorMessage(
              error,
              fallback: 'تعذر إنشاء المستخدم حالياً.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة مستخدم'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'الاسم الكامل'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'الاسم الكامل مطلوب' : null,
            ),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
              validator: (v) => v == null || !v.contains('@')
                  ? 'البريد الإلكتروني غير صحيح'
                  : null,
            ),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'رقم الهاتف'),
            ),
            TextFormField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(labelText: 'كلمة المرور'),
              obscureText: true,
              validator: (v) => v == null || v.length < 6
                  ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'
                  : null,
            ),
            DropdownButtonFormField<String>(
              value: _role,
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('مدير')),
                DropdownMenuItem(value: 'employee', child: Text('موظف')),
              ],
              onChanged: (v) => setState(() => _role = v ?? 'employee'),
              decoration: const InputDecoration(labelText: 'الدور'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('إضافة'),
        ),
      ],
    );
  }
}
