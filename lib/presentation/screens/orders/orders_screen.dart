// lib/presentation/screens/orders/orders_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/status_badge.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(orderFilterProvider);
    final ordersAsync = ref.watch(ordersListProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('الطلبات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(ordersListProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/orders/new'),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'طلب جديد',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search
                TextField(
                  controller: _searchCtrl,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'بحث برقم الطلب، الاسم أو الهاتف...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: filters.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref
                                  .read(orderFilterProvider.notifier)
                                  .setSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (v) =>
                      ref.read(orderFilterProvider.notifier).setSearch(v),
                  style: GoogleFonts.cairo(),
                ),
                const SizedBox(height: 8),
                // Status filter chips
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'الكل',
                        selected: filters.status == null,
                        onTap: () => ref
                            .read(orderFilterProvider.notifier)
                            .setStatus(null),
                      ),
                      ...AppConstants.statusLabels.entries.map(
                        (e) => _FilterChip(
                          label: e.value,
                          selected: filters.status == e.key,
                          color: AppTheme.statusColors[e.key],
                          onTap: () => ref
                              .read(orderFilterProvider.notifier)
                              .setStatus(e.key),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Orders List
          Expanded(
            child: ordersAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 5,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: ShimmerCard(),
                ),
              ),
              error: (e, _) => ErrorWidget2(
                message: e.toString(),
                onRetry: () => ref.invalidate(ordersListProvider),
              ),
              data: (orders) => orders.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.assignment_outlined,
                      title: 'لا توجد طلبات',
                      subtitle:
                          filters.searchQuery.isNotEmpty ||
                              filters.status != null
                          ? 'لا توجد نتائج تطابق الفلتر المحدد'
                          : 'أضف أول طلب بالضغط على الزر أدناه',
                      action:
                          (filters.searchQuery.isEmpty &&
                              filters.status == null)
                          ? ElevatedButton.icon(
                              onPressed: () => context.go('/orders/new'),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('إنشاء طلب'),
                            )
                          : null,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: orders.length,
                      itemBuilder: (context, i) => _OrderCard(order: orders[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.primaryColor;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? chipColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? chipColor : AppTheme.borderColor,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final remaining = order.remainingAmount;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go('/orders/${order.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Order number
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${order.orderNumber}',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customerName ?? 'عميل غير معروف',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            order.customerPhone ?? '',
                            style: GoogleFonts.cairo(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.calendar_today_rounded,
                      label: DateFormatter.formatDate(order.orderDate),
                    ),
                    const Spacer(),
                    _InfoChip(
                      icon: Icons.payments_rounded,
                      label: DateFormatter.formatCurrency(order.totalPrice),
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(width: 8),
                    if (remaining > 0)
                      _InfoChip(
                        icon: Icons.account_balance_wallet_rounded,
                        label:
                            'متبقي: ${DateFormatter.formatCurrency(remaining)}',
                        color: AppTheme.warningColor,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color = AppTheme.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
