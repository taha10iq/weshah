// lib/presentation/screens/orders/order_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/order_detail_model.dart';
import '../../../data/models/order_attachment_model.dart';
import '../../providers/order_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/status_badge.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderByIdProvider(orderId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: orderAsync.when(
          data: (o) => Text('طلب رقم #${o.orderNumber}'),
          loading: () => const Text('تحميل...'),
          error: (_, __) => const Text('تفاصيل الطلب'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/orders'),
        ),
        actions: [
          orderAsync.when(
            data: (o) => Row(
              children: [
                _StatusChangeButton(order: o),
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: 'تعديل',
                  onPressed: () => context.go('/orders/$orderId/edit'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'حذف',
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: orderAsync.when(
        loading: () =>
            const LoadingWidget(message: 'جاري تحميل تفاصيل الطلب...'),
        error: (e, _) => ErrorWidget2(
          message: e.toString(),
          onRetry: () => ref.invalidate(orderByIdProvider(orderId)),
        ),
        data: (order) => _OrderDetailContent(order: order),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الطلب'),
        content: const Text('هل أنت متأكد من حذف هذا الطلب؟'),
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
          .read(orderNotifierProvider.notifier)
          .deleteOrder(orderId);
      if (success && context.mounted) {
        context.go('/orders');
      }
    });
  }
}

class _StatusChangeButton extends ConsumerWidget {
  final OrderModel order;
  const _StatusChangeButton({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'تغيير الحالة',
      icon: const Icon(Icons.swap_horiz_rounded),
      itemBuilder: (_) => AppConstants.statusLabels.entries
          .where((e) => e.key != order.status)
          .map(
            (e) => PopupMenuItem<String>(
              value: e.key,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.statusColors[e.key],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(e.value, style: GoogleFonts.cairo()),
                ],
              ),
            ),
          )
          .toList(),
      onSelected: (newStatus) async {
        await ref
            .read(orderNotifierProvider.notifier)
            .updateStatus(order.id, newStatus);
      },
    );
  }
}

class _OrderDetailContent extends ConsumerWidget {
  final OrderModel order;
  const _OrderDetailContent({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Order Header
              _OrderHeaderCard(order: order),
              const SizedBox(height: 12),
              // Customer Info
              _CustomerInfoCard(order: order),
              const SizedBox(height: 12),
              // Financial Summary
              _FinancialCard(order: order),
              const SizedBox(height: 12),
              // Order Details (Robe specs)
              if (order.details != null) ...[
                _RobeSpecsCard(details: order.details!),
                const SizedBox(height: 12),
                _TextsColorsCard(details: order.details!),
                const SizedBox(height: 12),
              ],
              // Attachments
              _AttachmentsCard(order: order),
              const SizedBox(height: 12),
              // Notes
              if (order.notes != null && order.notes!.isNotEmpty)
                _NotesCard(notes: order.notes!),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderHeaderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderHeaderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    '#${order.orderNumber}',
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Text(
                    'رقم الطلب',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormatter.formatDate(order.orderDate),
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormatter.formatDateTime(order.createdAt),
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            StatusBadge(status: order.status, large: true),
          ],
        ),
      ),
    );
  }
}

class _CustomerInfoCard extends StatelessWidget {
  final OrderModel order;
  const _CustomerInfoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_rounded, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'بيانات العميل',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.go('/customers/${order.customerId}'),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('عرض ملف العميل'),
                ),
              ],
            ),
            const Divider(height: 16),
            _DetailRow(
              icon: Icons.person_rounded,
              label: 'الاسم',
              value: order.customerName ?? '-',
            ),
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.phone_rounded,
              label: 'الهاتف',
              value: order.customerPhone ?? '-',
            ),
          ],
        ),
      ),
    );
  }
}

class _FinancialCard extends StatelessWidget {
  final OrderModel order;
  const _FinancialCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.payments_rounded,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'المعلومات المالية',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                Expanded(
                  child: _FinanceBox(
                    label: 'السعر الإجمالي',
                    value: DateFormatter.formatCurrency(order.totalPrice),
                    color: AppTheme.primaryColor,
                    icon: Icons.monetization_on_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FinanceBox(
                    label: 'المدفوع',
                    value: DateFormatter.formatCurrency(order.amountPaid),
                    color: AppTheme.successColor,
                    icon: Icons.check_circle_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FinanceBox(
                    label: 'المتبقي',
                    value: DateFormatter.formatCurrency(order.remainingAmount),
                    color: order.remainingAmount > 0
                        ? AppTheme.warningColor
                        : AppTheme.successColor,
                    icon: order.remainingAmount > 0
                        ? Icons.account_balance_wallet_rounded
                        : Icons.done_all_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _FinanceBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RobeSpecsCard extends StatelessWidget {
  final OrderDetailModel details;
  const _RobeSpecsCard({required this.details});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.straighten_rounded,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'مواصفات الروب',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: 16),
            // Sleeve style
            if (details.sleeveStyle != null)
              _DetailRow(
                icon: Icons.style_rounded,
                label: 'نوع الروب',
                value:
                    AppConstants.sleeveStyleLabels[details.sleeveStyle] ??
                    details.sleeveStyle!,
              ),
            if (details.customModelNote != null &&
                details.customModelNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.note_rounded,
                label: 'وصف الموديل',
                value: details.customModelNote!,
              ),
            ],
            if (details.addAmericanCap) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.accentColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'طاقية أمريكية مضافة',
                      style: GoogleFonts.cairo(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Measurements grid
            Text(
              'المقاسات:',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                if (details.shoulderWidthCm != null)
                  _MeasureChip(
                    label: 'عرض الكتف',
                    value: '${details.shoulderWidthCm} سم',
                  ),
                if (details.robeLengthCm != null)
                  _MeasureChip(
                    label: 'طول الروب',
                    value: '${details.robeLengthCm} سم',
                  ),
                if (details.sleeveLengthCm != null)
                  _MeasureChip(
                    label: 'طول الكم',
                    value: '${details.sleeveLengthCm} سم',
                  ),
                if (details.headCircumferenceCm != null)
                  _MeasureChip(
                    label: 'محيط الرأس',
                    value: '${details.headCircumferenceCm} سم',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Quantity & Price
            Row(
              children: [
                _InfoBadge(label: 'الكمية', value: '${details.quantity} قطعة'),
                const SizedBox(width: 8),
                _InfoBadge(
                  label: 'سعر الوحدة',
                  value: DateFormatter.formatCurrency(details.unitPrice),
                ),
                const SizedBox(width: 8),
                if (details.lineTotal != null)
                  _InfoBadge(
                    label: 'إجمالي السطر',
                    value: DateFormatter.formatCurrency(details.lineTotal!),
                    color: AppTheme.primaryColor,
                  ),
              ],
            ),
            if (details.graduationYear != null &&
                details.graduationYear!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.school_rounded,
                label: 'سنة التخرج',
                value: details.graduationYear!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MeasureChip extends StatelessWidget {
  final String label;
  final String value;
  const _MeasureChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _InfoBadge({
    required this.label,
    required this.value,
    this.color = AppTheme.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 13,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextsColorsCard extends StatelessWidget {
  final OrderDetailModel details;
  const _TextsColorsCard({required this.details});

  bool get _hasAnyText =>
      (details.robeColor?.isNotEmpty ?? false) ||
      (details.embroideryColor?.isNotEmpty ?? false) ||
      (details.capColor?.isNotEmpty ?? false) ||
      (details.capText?.isNotEmpty ?? false) ||
      (details.capTextImageUrl?.isNotEmpty ?? false) ||
      (details.rightSideText?.isNotEmpty ?? false) ||
      (details.rightTextImageUrl?.isNotEmpty ?? false) ||
      (details.leftSideText?.isNotEmpty ?? false) ||
      (details.leftTextImageUrl?.isNotEmpty ?? false) ||
      (details.chestText?.isNotEmpty ?? false) ||
      (details.chestTextImageUrl?.isNotEmpty ?? false) ||
      (details.sashText?.isNotEmpty ?? false) ||
      (details.sashTextImageUrl?.isNotEmpty ?? false) ||
      (details.designNotes?.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    if (!_hasAnyText) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.color_lens_rounded,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'النصوص والألوان',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: 16),
            if (details.robeColor?.isNotEmpty ?? false)
              _DetailRow(
                icon: Icons.circle_rounded,
                label: 'لون الروب',
                value: details.robeColor!,
              ),
            if (details.embroideryColor?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.circle_rounded,
                label: 'لون التطريز',
                value: details.embroideryColor!,
              ),
            ],
            if (details.capColor?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.circle_rounded,
                label: 'لون القبعة',
                value: details.capColor!,
              ),
            ],
            // ── النص على القبعة + صورته ──────────────────────────
            if ((details.capText?.isNotEmpty ?? false) ||
                (details.capTextImageUrl?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 8),
              _TextWithImage(
                icon: Icons.text_fields_rounded,
                label: 'النص على القبعة',
                text: details.capText,
                imageUrl: details.capTextImageUrl,
              ),
            ],
            // ── نص اليمين + صورته ───────────────────────────────
            if ((details.rightSideText?.isNotEmpty ?? false) ||
                (details.rightTextImageUrl?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 8),
              _TextWithImage(
                icon: Icons.text_fields_rounded,
                label: 'نص اليمين',
                text: details.rightSideText,
                imageUrl: details.rightTextImageUrl,
              ),
            ],
            // ── نص اليسار + صورته ───────────────────────────────
            if ((details.leftSideText?.isNotEmpty ?? false) ||
                (details.leftTextImageUrl?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 8),
              _TextWithImage(
                icon: Icons.text_fields_rounded,
                label: 'نص اليسار',
                text: details.leftSideText,
                imageUrl: details.leftTextImageUrl,
              ),
            ],
            // ── نص الصدر + صورته ────────────────────────────────
            if ((details.chestText?.isNotEmpty ?? false) ||
                (details.chestTextImageUrl?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 8),
              _TextWithImage(
                icon: Icons.text_fields_rounded,
                label: 'النص على ظهر الوشاح',
                text: details.chestText,
                imageUrl: details.chestTextImageUrl,
              ),
            ],
            // ── نص الوشاح + صورته ───────────────────────────────
            if ((details.sashText?.isNotEmpty ?? false) ||
                (details.sashTextImageUrl?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 8),
              _TextWithImage(
                icon: Icons.text_fields_rounded,
                label: 'النص على جانب القبعة',
                text: details.sashText,
                imageUrl: details.sashTextImageUrl,
              ),
            ],
            if (details.designNotes?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.notes_rounded,
                label: 'ملاحظات التصميم',
                value: details.designNotes!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── صف نص + صورة مرفقة مع إمكانية التكبير ──────────────────────────
class _TextWithImage extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? text;
  final String? imageUrl;

  const _TextWithImage({
    required this.icon,
    required this.label,
    this.text,
    this.imageUrl,
  });

  void _openFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                width: double.infinity,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // النص
        if (text?.isNotEmpty ?? false)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      text!,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        // الصورة المرفقة
        if (imageUrl?.isNotEmpty ?? false) ...[
          if (text?.isNotEmpty ?? false) const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _openFullImage(context, imageUrl!),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: imageUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 140,
                        color: Colors.grey[100],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 140,
                        color: Colors.grey[100],
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: AppTheme.textSecondary,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    // label overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.zoom_in_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              text?.isNotEmpty ?? false ? 'صورة $label' : label,
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AttachmentsCard extends ConsumerStatefulWidget {
  final OrderModel order;
  const _AttachmentsCard({required this.order});

  @override
  ConsumerState<_AttachmentsCard> createState() => _AttachmentsCardState();
}

class _AttachmentsCardState extends ConsumerState<_AttachmentsCard> {
  bool _uploading = false;

  Future<void> _pickAndUpload({bool designOnly = false}) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: !designOnly,
      type: FileType.custom,
      allowedExtensions: designOnly
          ? ['jpg', 'jpeg', 'png', 'webp']
          : ['jpg', 'jpeg', 'png', 'pdf', 'webp', 'gif'],
      withData: true,
    );
    if (result == null) return;
    setState(() => _uploading = true);
    for (final file in result.files) {
      if (file.bytes == null) continue;
      final name = designOnly
          ? 'تصميم_${DateTime.now().millisecondsSinceEpoch}.${file.extension ?? 'jpg'}'
          : file.name;
      await ref
          .read(orderNotifierProvider.notifier)
          .uploadAttachment(
            orderId: widget.order.id,
            fileName: name,
            fileBytes: file.bytes!.toList(),
            contentType: _getMimeType(file.extension ?? ''),
          );
    }
    setState(() => _uploading = false);
  }

  String _getMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    final attachments = widget.order.attachments;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.attach_file_rounded,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'المرفقات',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (_uploading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton.icon(
                    onPressed: () => _pickAndUpload(designOnly: true),
                    icon: const Icon(Icons.design_services_rounded, size: 18),
                    label: const Text('صورة التصميم'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
              ],
            ),
            const Divider(height: 16),
            if (attachments.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.folder_open_rounded,
                        size: 40,
                        color: AppTheme.borderColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'لا توجد مرفقات',
                        style: GoogleFonts.cairo(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Design images shown prominently first
              Builder(
                builder: (context) {
                  final designFiles = attachments
                      .where((a) => a.fileName.startsWith('تصميم_'))
                      .toList();
                  final otherFiles = attachments
                      .where((a) => !a.fileName.startsWith('تصميم_'))
                      .toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (designFiles.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.design_services_rounded,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'صور التصميم',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 200,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1,
                              ),
                          itemCount: designFiles.length,
                          itemBuilder: (_, i) => _AttachmentTile(
                            attachment: designFiles[i],
                            orderId: widget.order.id,
                            isDesign: true,
                          ),
                        ),
                        if (otherFiles.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 4),
                        ],
                      ],
                      if (otherFiles.isNotEmpty) ...[
                        if (designFiles.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'مرفقات أخرى',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 150,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1,
                              ),
                          itemCount: otherFiles.length,
                          itemBuilder: (_, i) => _AttachmentTile(
                            attachment: otherFiles[i],
                            orderId: widget.order.id,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttachmentTile extends ConsumerWidget {
  final OrderAttachmentModel attachment;
  final String orderId;
  final bool isDesign;
  const _AttachmentTile({
    required this.attachment,
    required this.orderId,
    this.isDesign = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: attachment.isImage && attachment.fileUrl != null
          ? () => showDialog(
              context: context,
              builder: (_) => Dialog(
                backgroundColor: Colors.black,
                child: Stack(
                  children: [
                    InteractiveViewer(
                      child: CachedNetworkImage(
                        imageUrl: attachment.fileUrl!,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDesign ? AppTheme.primaryColor : AppTheme.borderColor,
                width: isDesign ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: attachment.isImage && attachment.fileUrl != null
                  ? CachedNetworkImage(
                      imageUrl: attachment.fileUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (_, __) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.broken_image_rounded,
                        color: AppTheme.textSecondary,
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.description_rounded,
                            size: 36,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              attachment.fileName,
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          // Design badge
          if (isDesign)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'تصميم',
                  style: GoogleFonts.cairo(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          // Delete button
          Positioned(
            top: 4,
            left: 4,
            child: GestureDetector(
              onTap: () async {
                bool confirmed = false;
                await showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('حذف المرفق'),
                    content: const Text('هل تريد حذف هذا المرفق؟'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          confirmed = false;
                          Navigator.of(dialogContext).pop();
                        },
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                        ),
                        onPressed: () {
                          confirmed = true;
                          Navigator.of(dialogContext).pop();
                        },
                        child: const Text('حذف'),
                      ),
                    ],
                  ),
                );
                if (confirmed) {
                  await ref
                      .read(orderNotifierProvider.notifier)
                      .deleteAttachment(
                        attachment.id,
                        attachment.filePath,
                        orderId,
                      );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppTheme.errorColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ), // end inner Stack
    ); // end GestureDetector
  }
}

class _NotesCard extends StatelessWidget {
  final String notes;
  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notes_rounded, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'ملاحظات الطلب',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: 16),
            Text(notes, style: GoogleFonts.cairo(fontSize: 14, height: 1.6)),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
          ),
        ),
        Expanded(child: Text(value, style: GoogleFonts.cairo(fontSize: 13))),
      ],
    );
  }
}
