// lib/presentation/screens/orders/order_form_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/datasources/storage_datasource.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/order_detail_model.dart';
import '../../../data/models/customer_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/supabase_provider.dart';
import '../../widgets/common/app_text_field.dart';

class OrderFormScreen extends ConsumerStatefulWidget {
  final String? orderId;
  final String? preselectedCustomerId;

  const OrderFormScreen({super.key, this.orderId, this.preselectedCustomerId});

  @override
  ConsumerState<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends ConsumerState<OrderFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Customer fields
  String? _selectedCustomerId;
  CustomerModel? _selectedCustomer;
  final _customerSearchCtrl = TextEditingController();

  // Order fields
  DateTime _orderDate = DateTime.now();
  String _status = AppConstants.statusNew;
  final _totalPriceCtrl = TextEditingController();
  final _amountPaidCtrl = TextEditingController();
  final _orderNotesCtrl = TextEditingController();

  // Order detail fields
  String? _sleeveStyle;
  bool _addAmericanCap = false;
  final _shoulderWidthCtrl = TextEditingController();
  final _robeLengthCtrl = TextEditingController();
  final _sleeveLengthCtrl = TextEditingController();
  final _headCircCtrl = TextEditingController();
  final _robeColorCtrl = TextEditingController();
  final _embroideryColorCtrl = TextEditingController();
  final _capColorCtrl = TextEditingController();
  final _capTextCtrl = TextEditingController();
  final _rightTextCtrl = TextEditingController();
  final _leftTextCtrl = TextEditingController();
  final _chestTextCtrl = TextEditingController();
  final _sashTextCtrl = TextEditingController();
  final _graduationYearCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');
  final _unitPriceCtrl = TextEditingController();
  final _designNotesCtrl = TextEditingController();
  final _customModelNoteCtrl = TextEditingController();

  // صور مرفقة لحقول النصوص
  XFile? _rightTextImage;
  XFile? _leftTextImage;
  XFile? _chestTextImage;
  XFile? _sashTextImage;
  XFile? _capTextImage;

  bool _loading = false;
  bool get isEditing => widget.orderId != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.preselectedCustomerId != null) {
      _selectedCustomerId = widget.preselectedCustomerId;
      _loadPreselectedCustomer();
    }
    if (isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrder());
    }
    // Auto-calculate remaining
    _totalPriceCtrl.addListener(_updateLineTotal);
    _unitPriceCtrl.addListener(_updateLineTotal);
    _quantityCtrl.addListener(_updateLineTotal);
  }

  void _updateLineTotal() {
    setState(() {});
  }

  Future<void> _loadPreselectedCustomer() async {
    try {
      final repo = ref.read(customerRepositoryProvider);
      final customer = await repo.getCustomerById(
        widget.preselectedCustomerId!,
      );
      setState(() {
        _selectedCustomer = customer;
        _customerSearchCtrl.text = customer.fullName;
      });
    } catch (_) {}
  }

  Future<void> _loadOrder() async {
    final repo = ref.read(orderRepositoryProvider);
    try {
      final order = await repo.getOrderById(widget.orderId!);
      _selectedCustomerId = order.customerId;
      _orderDate = order.orderDate;
      _status = order.status;
      _totalPriceCtrl.text = order.totalPrice.toStringAsFixed(2);
      _amountPaidCtrl.text = order.amountPaid.toStringAsFixed(2);
      _orderNotesCtrl.text = order.notes ?? '';

      // Load customer
      try {
        final repo2 = ref.read(customerRepositoryProvider);
        final c = await repo2.getCustomerById(order.customerId);
        _selectedCustomer = c;
        _customerSearchCtrl.text = c.fullName;
      } catch (_) {}

      if (order.details != null) {
        final d = order.details!;
        _sleeveStyle = d.sleeveStyle;
        _addAmericanCap = d.addAmericanCap;
        _shoulderWidthCtrl.text = d.shoulderWidthCm?.toString() ?? '';
        _robeLengthCtrl.text = d.robeLengthCm?.toString() ?? '';
        _sleeveLengthCtrl.text = d.sleeveLengthCm?.toString() ?? '';
        _headCircCtrl.text = d.headCircumferenceCm?.toString() ?? '';
        _robeColorCtrl.text = d.robeColor ?? '';
        _embroideryColorCtrl.text = d.embroideryColor ?? '';
        _capColorCtrl.text = d.capColor ?? '';
        _capTextCtrl.text = d.capText ?? '';
        _rightTextCtrl.text = d.rightSideText ?? '';
        _leftTextCtrl.text = d.leftSideText ?? '';
        _chestTextCtrl.text = d.chestText ?? '';
        _sashTextCtrl.text = d.sashText ?? '';
        _graduationYearCtrl.text = d.graduationYear ?? '';
        _quantityCtrl.text = d.quantity.toString();
        _unitPriceCtrl.text = d.unitPrice.toStringAsFixed(2);
        _designNotesCtrl.text = d.designNotes ?? '';
        _customModelNoteCtrl.text = d.customModelNote ?? '';
      }
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل بيانات الطلب: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customerSearchCtrl.dispose();
    _totalPriceCtrl.dispose();
    _amountPaidCtrl.dispose();
    _orderNotesCtrl.dispose();
    _shoulderWidthCtrl.dispose();
    _robeLengthCtrl.dispose();
    _sleeveLengthCtrl.dispose();
    _headCircCtrl.dispose();
    _robeColorCtrl.dispose();
    _embroideryColorCtrl.dispose();
    _capColorCtrl.dispose();
    _capTextCtrl.dispose();
    _rightTextCtrl.dispose();
    _leftTextCtrl.dispose();
    _chestTextCtrl.dispose();
    _sashTextCtrl.dispose();
    _graduationYearCtrl.dispose();
    _quantityCtrl.dispose();
    _unitPriceCtrl.dispose();
    _designNotesCtrl.dispose();
    _customModelNoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _orderDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ar'),
    );
    if (date != null) setState(() => _orderDate = date);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0);
      return;
    }
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار العميل'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    // ── رفع صور النصوص إلى Supabase Storage ─────────────────
    final storage = StorageDataSource(ref.read(supabaseClientProvider));
    // نستخدم orderId مؤقت للمسار قبل الإنشاء
    final tempOrderId =
        widget.orderId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';

    Future<String?> uploadIfExists(XFile? file, String key) async {
      if (file == null) return null;
      try {
        return await storage.uploadTextImage(
          orderId: tempOrderId,
          fieldKey: key,
          image: file,
        );
      } catch (_) {
        return null;
      }
    }

    final rightUrl = await uploadIfExists(_rightTextImage, 'right');
    final leftUrl = await uploadIfExists(_leftTextImage, 'left');
    final chestUrl = await uploadIfExists(_chestTextImage, 'chest');
    final sashUrl = await uploadIfExists(_sashTextImage, 'sash');
    final capUrl = await uploadIfExists(_capTextImage, 'cap');

    // ─────────────────────────────────────────────────────────
    final totalPrice = double.tryParse(_totalPriceCtrl.text) ?? 0;
    final amountPaid = double.tryParse(_amountPaidCtrl.text) ?? 0;

    final order = OrderModel(
      id: widget.orderId ?? '',
      orderNumber: 0,
      customerId: _selectedCustomerId!,
      orderDate: _orderDate,
      status: _status,
      totalPrice: totalPrice,
      amountPaid: amountPaid,
      remainingAmount: totalPrice - amountPaid,
      notes: _orderNotesCtrl.text.trim().isEmpty
          ? null
          : _orderNotesCtrl.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final detail = OrderDetailModel(
      id: '',
      orderId: widget.orderId ?? '',
      sleeveStyle: _sleeveStyle,
      addAmericanCap: _addAmericanCap,
      shoulderWidthCm: double.tryParse(_shoulderWidthCtrl.text),
      robeLengthCm: double.tryParse(_robeLengthCtrl.text),
      sleeveLengthCm: double.tryParse(_sleeveLengthCtrl.text),
      headCircumferenceCm: double.tryParse(_headCircCtrl.text),
      robeColor: _robeColorCtrl.text.trim().isEmpty
          ? null
          : _robeColorCtrl.text.trim(),
      embroideryColor: _embroideryColorCtrl.text.trim().isEmpty
          ? null
          : _embroideryColorCtrl.text.trim(),
      capColor: _capColorCtrl.text.trim().isEmpty
          ? null
          : _capColorCtrl.text.trim(),
      capText: _capTextCtrl.text.trim().isEmpty
          ? null
          : _capTextCtrl.text.trim(),
      rightSideText: _rightTextCtrl.text.trim().isEmpty
          ? null
          : _rightTextCtrl.text.trim(),
      leftSideText: _leftTextCtrl.text.trim().isEmpty
          ? null
          : _leftTextCtrl.text.trim(),
      chestText: _chestTextCtrl.text.trim().isEmpty
          ? null
          : _chestTextCtrl.text.trim(),
      sashText: _sashTextCtrl.text.trim().isEmpty
          ? null
          : _sashTextCtrl.text.trim(),
      graduationYear: _graduationYearCtrl.text.trim().isEmpty
          ? null
          : _graduationYearCtrl.text.trim(),
      quantity: int.tryParse(_quantityCtrl.text) ?? 1,
      unitPrice: double.tryParse(_unitPriceCtrl.text) ?? 0,
      designNotes: _designNotesCtrl.text.trim().isEmpty
          ? null
          : _designNotesCtrl.text.trim(),
      customModelNote: _customModelNoteCtrl.text.trim().isEmpty
          ? null
          : _customModelNoteCtrl.text.trim(),
      rightTextImageUrl: rightUrl,
      leftTextImageUrl: leftUrl,
      chestTextImageUrl: chestUrl,
      sashTextImageUrl: sashUrl,
      capTextImageUrl: capUrl,
    );

    final notifier = ref.read(orderNotifierProvider.notifier);
    bool success;
    String? newOrderId;

    if (isEditing) {
      success = await notifier.updateOrder(
        order.copyWith(id: widget.orderId),
        details: detail.copyWith(orderId: widget.orderId),
      );
      newOrderId = widget.orderId;
    } else {
      final created = await notifier.createOrder(order, details: detail);
      success = created != null;
      newOrderId = created?.id;
    }

    if (mounted) {
      setState(() => _loading = false);
      if (success && newOrderId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'تم تحديث الطلب بنجاح' : 'تم إنشاء الطلب بنجاح',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.go('/orders/$newOrderId');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء حفظ الطلب'),
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
        title: Text(isEditing ? 'تعديل الطلب' : 'طلب جديد'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppTheme.accentColor,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(
              text: 'بيانات الطلب',
              icon: Icon(Icons.assignment_rounded, size: 18),
            ),
            Tab(
              text: 'المواصفات',
              icon: Icon(Icons.straighten_rounded, size: 18),
            ),
            Tab(
              text: 'النصوص والألوان',
              icon: Icon(Icons.color_lens_rounded, size: 18),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OrderBasicTab(state: this),
                  _MeasurementsTab(state: this),
                  _TextsColorsTab(state: this),
                ],
              ),
            ),
            // Submit Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
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
                                    : Icons.check_circle_rounded,
                              ),
                        label: Text(
                          isEditing ? 'حفظ التعديلات' : 'إنشاء الطلب',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tab 1: Basic Order Info
class _OrderBasicTab extends StatefulWidget {
  final _OrderFormScreenState state;
  const _OrderBasicTab({required this.state});

  @override
  State<_OrderBasicTab> createState() => _OrderBasicTabState();
}

class _OrderBasicTabState extends State<_OrderBasicTab> {
  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final totalPrice = double.tryParse(s._totalPriceCtrl.text) ?? 0;
    final amountPaid = double.tryParse(s._amountPaidCtrl.text) ?? 0;
    final remaining = totalPrice - amountPaid;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customer Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'بيانات العميل',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Divider(height: 20),
                      // Customer search autocomplete
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'العميل *',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Autocomplete<CustomerModel>(
                            displayStringForOption: (c) => c.fullName,
                            optionsBuilder: (value) async {
                              if (value.text.length < 2) return [];
                              final repo = s.ref.read(
                                customerRepositoryProvider,
                              );
                              try {
                                return await repo.searchCustomers(value.text);
                              } catch (_) {
                                return [];
                              }
                            },
                            onSelected: (customer) {
                              s.setState(() {
                                s._selectedCustomerId = customer.id;
                                s._selectedCustomer = customer;
                              });
                            },
                            initialValue: TextEditingValue(
                              text: s._selectedCustomer?.fullName ?? '',
                            ),
                            fieldViewBuilder: (ctx, ctrl, fn, onSubmitted) =>
                                TextFormField(
                                  controller: ctrl,
                                  focusNode: fn,
                                  textDirection: TextDirection.rtl,
                                  decoration: InputDecoration(
                                    hintText: 'ابحث باسم العميل أو هاتفه...',
                                    prefixIcon: const Icon(
                                      Icons.person_search_rounded,
                                    ),
                                    suffixIcon: s._selectedCustomer != null
                                        ? const Icon(
                                            Icons.check_circle_rounded,
                                            color: AppTheme.successColor,
                                          )
                                        : null,
                                  ),
                                  validator: (_) =>
                                      s._selectedCustomerId == null
                                      ? 'يرجى اختيار العميل'
                                      : null,
                                  style: GoogleFonts.cairo(),
                                ),
                            optionsViewBuilder: (ctx, onSelected, options) {
                              return Align(
                                alignment: Alignment.topRight,
                                child: Material(
                                  elevation: 4,
                                  borderRadius: BorderRadius.circular(8),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxHeight: 250,
                                      maxWidth: 400,
                                    ),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder: (_, i) {
                                        final c = options.elementAt(i);
                                        return ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: AppTheme
                                                .primaryColor
                                                .withOpacity(0.1),
                                            child: Text(
                                              c.fullName[0],
                                              style: GoogleFonts.cairo(
                                                color: AppTheme.primaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            c.fullName,
                                            style: GoogleFonts.cairo(),
                                          ),
                                          subtitle: Text(
                                            c.phone,
                                            style: GoogleFonts.cairo(
                                              fontSize: 12,
                                            ),
                                          ),
                                          onTap: () => onSelected(c),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      if (s._selectedCustomer != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.phone_rounded,
                                size: 16,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                s._selectedCustomer!.phone,
                                style: GoogleFonts.cairo(fontSize: 13),
                              ),
                              if (s._selectedCustomer!.address != null &&
                                  s._selectedCustomer!.address!.isNotEmpty) ...[
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 16,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    s._selectedCustomer!.address!,
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Order Details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'بيانات الطلب',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Divider(height: 20),
                      // Date & Status row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تاريخ الطلب *',
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: s._pickDate,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: AppTheme.borderColor,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 18,
                                          color: AppTheme.primaryColor,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          DateFormat(
                                            'yyyy/MM/dd',
                                          ).format(s._orderDate),
                                          style: GoogleFonts.cairo(
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppDropdownField<String>(
                              label: 'حالة الطلب *',
                              value: s._status,
                              items: AppConstants.statusLabels.entries
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e.key,
                                      child: Text(
                                        e.value,
                                        style: GoogleFonts.cairo(fontSize: 14),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  s.setState(() => s._status = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Prices
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'السعر الإجمالي',
                              hint: '0.00',
                              controller: s._totalPriceCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                              validator: (v) =>
                                  Validators.positiveNumber(v, 'السعر'),
                              onChanged: (_) => s.setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              label: 'المبلغ المدفوع',
                              hint: '0.00',
                              controller: s._amountPaidCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                              validator: (v) =>
                                  Validators.positiveNumber(v, 'المبلغ'),
                              onChanged: (_) => s.setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Remaining amount display
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: remaining > 0
                              ? AppTheme.warningColor.withOpacity(0.1)
                              : AppTheme.successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: remaining > 0
                                ? AppTheme.warningColor.withOpacity(0.3)
                                : AppTheme.successColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'المبلغ المتبقي:',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${NumberFormat('#,##0', 'ar').format(remaining)} د.ع',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: remaining > 0
                                    ? AppTheme.warningColor
                                    : AppTheme.successColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'ملاحظات عامة على الطلب',
                        hint: 'أي ملاحظات عامة...',
                        controller: s._orderNotesCtrl,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tab 2: Measurements
class _MeasurementsTab extends StatefulWidget {
  final _OrderFormScreenState state;
  const _MeasurementsTab({required this.state});

  @override
  State<_MeasurementsTab> createState() => _MeasurementsTabState();
}

class _MeasurementsTabState extends State<_MeasurementsTab> {
  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              // Sleeve Style
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نوع الروب',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Divider(height: 20),
                      // Sleeve style options as radio buttons
                      ...AppConstants.sleeveStyleLabels.entries.map((e) {
                        return RadioListTile<String>(
                          title: Text(e.value, style: GoogleFonts.cairo()),
                          value: e.key,
                          groupValue: s._sleeveStyle,
                          onChanged: (v) =>
                              s.setState(() => s._sleeveStyle = v),
                          activeColor: AppTheme.primaryColor,
                          contentPadding: EdgeInsets.zero,
                        );
                      }),
                      if (s._sleeveStyle == AppConstants.sleeveOtherModel) ...[
                        const SizedBox(height: 8),
                        AppTextField(
                          label: 'وصف الموديل',
                          hint: 'اكتب وصف الموديل المطلوب...',
                          controller: s._customModelNoteCtrl,
                          maxLines: 2,
                        ),
                      ],
                      const SizedBox(height: 8),
                      // American cap checkbox
                      CheckboxListTile(
                        title: Text(
                          'إضافة طاقية أمريكية',
                          style: GoogleFonts.cairo(),
                        ),
                        subtitle: Text(
                          'إضافة طاقية أمريكية مع الروب',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        value: s._addAmericanCap,
                        onChanged: (v) =>
                            s.setState(() => s._addAmericanCap = v!),
                        activeColor: AppTheme.primaryColor,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Measurements
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المقاسات (بالسنتيمتر)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'عرض الكتف',
                              hint: 'سم',
                              controller: s._shoulderWidthCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              suffixIcon: const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Align(
                                  widthFactor: 1,
                                  alignment: Alignment.center,
                                  child: Text('سم'),
                                ),
                              ),
                              validator: (v) =>
                                  Validators.positiveNumber(v, 'عرض الكتف'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              label: 'طول الروب',
                              hint: 'سم',
                              controller: s._robeLengthCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (v) =>
                                  Validators.positiveNumber(v, 'طول الروب'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'طول الكم',
                              hint: 'سم',
                              controller: s._sleeveLengthCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (v) =>
                                  Validators.positiveNumber(v, 'طول الكم'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              label: 'محيط الرأس',
                              hint: 'سم',
                              controller: s._headCircCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (v) =>
                                  Validators.positiveNumber(v, 'محيط الرأس'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'سنة التخرج',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AppTextField(
                        label: '',
                        hint: 'مثال: 2024',
                        controller: s._graduationYearCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tab 3: Texts & Colors
class _TextsColorsTab extends StatefulWidget {
  final _OrderFormScreenState state;
  const _TextsColorsTab({required this.state});

  @override
  State<_TextsColorsTab> createState() => _TextsColorsTabState();
}

class _TextsColorsTabState extends State<_TextsColorsTab> {
  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              // Colors
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الألوان',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Divider(height: 20),
                      AppTextField(
                        label: 'لون الروب',
                        hint: 'مثال: أسود، كحلي...',
                        controller: s._robeColorCtrl,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'لون التطريز',
                        hint: 'مثال: ذهبي، فضي...',
                        controller: s._embroideryColorCtrl,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'لون القبعة',
                        hint: 'مثال: أسود...',
                        controller: s._capColorCtrl,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'النص على القبعة',
                        hint: 'اكتب النص المراد على القبعة...',
                        controller: s._capTextCtrl,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      _ImageAttachButton(
                        image: s._capTextImage,
                        onPick: (f) => setState(() => s._capTextImage = f),
                        onRemove: () => setState(() => s._capTextImage = null),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Texts
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'النصوص والكتابة',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Divider(height: 20),
                      AppTextField(
                        label: 'النص على اليمين',
                        hint: 'الكتابة على الجانب الأيمن...',
                        controller: s._rightTextCtrl,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      _ImageAttachButton(
                        image: s._rightTextImage,
                        onPick: (f) => setState(() => s._rightTextImage = f),
                        onRemove: () =>
                            setState(() => s._rightTextImage = null),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'النص على اليسار',
                        hint: 'الكتابة على الجانب الأيسر...',
                        controller: s._leftTextCtrl,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      _ImageAttachButton(
                        image: s._leftTextImage,
                        onPick: (f) => setState(() => s._leftTextImage = f),
                        onRemove: () => setState(() => s._leftTextImage = null),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'النص على الصدر / الوسط',
                        hint: 'الكتابة على الصدر أو المنطقة الوسطى...',
                        controller: s._chestTextCtrl,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      _ImageAttachButton(
                        image: s._chestTextImage,
                        onPick: (f) => setState(() => s._chestTextImage = f),
                        onRemove: () =>
                            setState(() => s._chestTextImage = null),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'النص على الوشاح',
                        hint: 'الكتابة على الوشاح...',
                        controller: s._sashTextCtrl,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      _ImageAttachButton(
                        image: s._sashTextImage,
                        onPick: (f) => setState(() => s._sashTextImage = f),
                        onRemove: () => setState(() => s._sashTextImage = null),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Design Notes
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ملاحظات التصميم',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Divider(height: 20),
                      AppTextField(
                        label: 'ملاحظات إضافية على التصميم',
                        hint:
                            'أي تفاصيل إضافية على التصميم أو المتطلبات الخاصة...',
                        controller: s._designNotesCtrl,
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── زر إرفاق صورة مع معاينة (متوافق مع Web) ────────────────────────
class _ImageAttachButton extends StatefulWidget {
  final XFile? image;
  final void Function(XFile file) onPick;
  final VoidCallback onRemove;

  const _ImageAttachButton({
    required this.image,
    required this.onPick,
    required this.onRemove,
  });

  @override
  State<_ImageAttachButton> createState() => _ImageAttachButtonState();
}

class _ImageAttachButtonState extends State<_ImageAttachButton> {
  Uint8List? _previewBytes;

  @override
  void initState() {
    super.initState();
    if (widget.image != null) _loadPreview();
  }

  @override
  void didUpdateWidget(_ImageAttachButton old) {
    super.didUpdateWidget(old);
    if (widget.image?.path != old.image?.path) _loadPreview();
  }

  Future<void> _loadPreview() async {
    if (widget.image == null) {
      if (mounted) setState(() => _previewBytes = null);
      return;
    }
    final bytes = await widget.image!.readAsBytes();
    if (mounted) setState(() => _previewBytes = bytes);
  }

  Future<void> _pick(BuildContext context) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('التقاط صورة'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('اختيار من المعرض'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked != null) widget.onPick(picked);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.image == null) {
      return OutlinedButton.icon(
        onPressed: () => _pick(context),
        icon: const Icon(Icons.attach_file_rounded, size: 18),
        label: const Text('إرفاق صورة'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryColor,
          side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
      );
    }

    // معاينة الصورة باستخدام Image.memory (متوافق مع Web)
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(9),
            ),
            child: _previewBytes != null
                ? Image.memory(
                    _previewBytes!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  )
                : const SizedBox(
                    width: 72,
                    height: 72,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.image!.name,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.red, size: 20),
            tooltip: 'حذف الصورة',
            onPressed: widget.onRemove,
          ),
        ],
      ),
    );
  }
}
