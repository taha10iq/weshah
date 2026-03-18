// lib/presentation/screens/customers/customer_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/customer_model.dart';
import '../../providers/customer_provider.dart';
import '../../providers/supabase_provider.dart';
import '../../widgets/common/app_text_field.dart';
import 'package:uuid/uuid.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final String? customerId;
  const CustomerFormScreen({super.key, this.customerId});

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _loading = false;

  bool get isEditing => widget.customerId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadCustomer());
    }
  }

  Future<void> _loadCustomer() async {
    final repo = ref.read(customerRepositoryProvider);
    try {
      final customer = await repo.getCustomerById(widget.customerId!);
      _nameCtrl.text = customer.fullName;
      _phoneCtrl.text = customer.phone;
      _addressCtrl.text = customer.address ?? '';
      _notesCtrl.text = customer.notes ?? '';
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل بيانات العميل: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final customer = CustomerModel(
      id: widget.customerId ?? const Uuid().v4(),
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final notifier = ref.read(customerNotifierProvider.notifier);
    bool success;
    if (isEditing) {
      success = await notifier.updateCustomer(customer);
    } else {
      final result = await notifier.createCustomer(customer);
      success = result != null;
      if (success && mounted) {
        context.go('/customers/${result.id}');
        return;
      }
    }

    if (mounted) {
      setState(() => _loading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'تم تحديث بيانات العميل بنجاح'
                  : 'تم إضافة العميل بنجاح',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.pop();
      } else {
        final error = ref.read(customerNotifierProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل بيانات العميل' : 'إضافة عميل جديد'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AppTheme.primaryColor.withOpacity(
                              0.1,
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppTheme.primaryColor,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isEditing
                                ? 'تعديل بيانات العميل'
                                : 'بيانات العميل الجديد',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Form Fields
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المعلومات الأساسية',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Divider(height: 24),
                          AppTextField(
                            label: 'الاسم الكامل *',
                            hint: 'أدخل الاسم الكامل للعميل',
                            controller: _nameCtrl,
                            validator: (v) =>
                                Validators.required(v, 'اسم العميل'),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'رقم الهاتف *',
                            hint: 'أدخل رقم الهاتف',
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            validator: Validators.phone,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'العنوان',
                            hint: 'أدخل عنوان العميل (اختياري)',
                            controller: _addressCtrl,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'ملاحظات',
                            hint: 'أي ملاحظات إضافية (اختياري)',
                            controller: _notesCtrl,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Submit Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              isEditing
                                  ? Icons.save_rounded
                                  : Icons.add_circle_rounded,
                            ),
                      label: Text(
                        isEditing ? 'حفظ التغييرات' : 'إضافة العميل',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('إلغاء'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
