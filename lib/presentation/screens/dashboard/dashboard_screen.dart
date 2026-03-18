// lib/presentation/screens/dashboard/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/dashboard_stats_model.dart';
import '../../providers/order_provider.dart';
import '../../widgets/common/loading_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
            onPressed: () => ref.invalidate(dashboardStatsProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const LoadingWidget(message: 'جاري تحميل الإحصائيات...'),
        error: (e, _) => ErrorWidget2(
          message: e.toString(),
          onRetry: () => ref.invalidate(dashboardStatsProvider),
        ),
        data: (stats) => _DashboardContent(stats: stats),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardStatsModel stats;
  const _DashboardContent({required this.stats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WelcomeHeader(),
          const SizedBox(height: 24),
          // Main Stats Cards
          Text(
            'الإحصائيات الرئيسية',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 700 ? 4 : 2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: constraints.maxWidth > 700 ? 1.6 : 1.4,
                children: [
                  _StatCard(
                    title: 'إجمالي العملاء',
                    value: DateFormatter.formatNumber(stats.totalCustomers),
                    icon: Icons.people_rounded,
                    color: AppTheme.primaryColor,
                    onTap: () => context.go('/customers'),
                  ),
                  _StatCard(
                    title: 'إجمالي الطلبات',
                    value: DateFormatter.formatNumber(stats.totalOrders),
                    icon: Icons.assignment_rounded,
                    color: AppTheme.secondaryColor,
                    onTap: () => context.go('/orders'),
                  ),
                  _StatCard(
                    title: 'إجمالي الإيرادات',
                    value: DateFormatter.formatCurrency(stats.totalRevenue),
                    icon: Icons.monetization_on_rounded,
                    color: AppTheme.successColor,
                  ),
                  _StatCard(
                    title: 'المبالغ المتبقية',
                    value: DateFormatter.formatCurrency(stats.totalRemaining),
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppTheme.warningColor,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          // Orders by Status
          Text(
            'الطلبات حسب الحالة',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 700 ? 5 : 2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: constraints.maxWidth > 700 ? 1.6 : 1.4,
                children: [
                  _StatCard(
                    title: 'جديد',
                    value: DateFormatter.formatNumber(stats.newOrders),
                    icon: Icons.fiber_new_rounded,
                    color: AppTheme.statusColors['new']!,
                    onTap: () => context.go('/orders'),
                  ),
                  _StatCard(
                    title: 'قيد التنفيذ',
                    value: DateFormatter.formatNumber(stats.inProgressOrders),
                    icon: Icons.pending_rounded,
                    color: AppTheme.statusColors['in_progress']!,
                    onTap: () => context.go('/orders'),
                  ),
                  _StatCard(
                    title: 'جاهز',
                    value: DateFormatter.formatNumber(stats.readyOrders),
                    icon: Icons.check_circle_rounded,
                    color: AppTheme.statusColors['ready']!,
                    onTap: () => context.go('/orders'),
                  ),
                  _StatCard(
                    title: 'تم التسليم',
                    value: DateFormatter.formatNumber(stats.deliveredOrders),
                    icon: Icons.local_shipping_rounded,
                    color: AppTheme.statusColors['delivered']!,
                    onTap: () => context.go('/orders'),
                  ),
                  _StatCard(
                    title: 'ملغى',
                    value: DateFormatter.formatNumber(stats.cancelledOrders),
                    icon: Icons.cancel_rounded,
                    color: AppTheme.statusColors['cancelled']!,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          // Quick Actions
          Text('إجراءات سريعة', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.person_add_rounded,
                  label: 'إضافة عميل جديد',
                  color: AppTheme.primaryColor,
                  onTap: () => context.go('/customers/new'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.add_circle_rounded,
                  label: 'إنشاء طلب جديد',
                  color: AppTheme.secondaryColor,
                  onTap: () => context.go('/orders/new'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً بك 👋',
                  style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'نظام وشاح لإدارة طلبات الروب',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormatter.formatDate(DateTime.now()),
                  style: GoogleFonts.cairo(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.school_rounded, color: Colors.white30, size: 60),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: AppTheme.cardShadow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                ],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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
