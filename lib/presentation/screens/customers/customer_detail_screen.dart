// lib/presentation/screens/customers/customer_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/order_model.dart';
import '../../providers/customer_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/status_badge.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerByIdProvider(customerId));
    final ordersAsync = ref.watch(ordersByCustomerProvider(customerId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('تفاصيل العميل'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/customers'),
        ),
        actions: [
          customerAsync.when(
            data: (c) => IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'تعديل',
              onPressed: () => context.go('/customers/$customerId/edit'),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'حذف',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.go('/orders/new', extra: {'customerId': customerId}),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'طلب جديد',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: customerAsync.when(
        loading: () => const LoadingWidget(message: 'جاري التحميل...'),
        error: (e, _) => ErrorWidget2(message: e.toString()),
        data: (customer) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Text(
                          customer.fullName.isNotEmpty
                              ? customer.fullName[0]
                              : '?',
                          style: GoogleFonts.cairo(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        customer.fullName,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      if (customer.phone.isNotEmpty)
                        _InfoRow(
                          icon: Icons.phone_rounded,
                          label: 'رقم الهاتف',
                          value: customer.phone,
                        ),
                      if (customer.address != null &&
                          customer.address!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.location_on_rounded,
                          label: 'العنوان',
                          value: customer.address!,
                        ),
                      ],
                      if (customer.notes != null &&
                          customer.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.notes_rounded,
                          label: 'ملاحظات',
                          value: customer.notes!,
                        ),
                      ],
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'تاريخ الإضافة',
                        value: DateFormatter.formatDate(customer.createdAt),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Orders
              Text(
                'طلبات العميل',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ordersAsync.when(
                loading: () => const LoadingWidget(),
                error: (e, _) => ErrorWidget2(message: e.toString()),
                data: (orders) => orders.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.assignment_outlined,
                        title: 'لا توجد طلبات بعد',
                        subtitle: 'أضف أول طلب لهذا العميل',
                      )
                    : Column(
                        children: orders
                            .map((o) => _OrderMiniCard(order: o))
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف العميل'),
        content: const Text(
          'هل أنت متأكد من حذف هذا العميل؟ سيتم حذف جميع طلباته أيضاً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      final success = await ref
          .read(customerNotifierProvider.notifier)
          .deleteCustomer(customerId);
      if (success && context.mounted) {
        context.go('/customers');
      }
    });
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        Expanded(child: Text(value, style: GoogleFonts.cairo(fontSize: 13))),
      ],
    );
  }
}

class _OrderMiniCard extends StatelessWidget {
  final OrderModel order;
  const _OrderMiniCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Text(
              '#${order.orderNumber}',
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          title: Text(
            'طلب رقم ${order.orderNumber}',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            DateFormatter.formatDate(order.orderDate),
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusBadge(status: order.status),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_back_ios_rounded, size: 14),
            ],
          ),
          onTap: () => context.go('/orders/${order.id}'),
        ),
      ),
    );
  }
}
