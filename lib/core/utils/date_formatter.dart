// lib/core/utils/date_formatter.dart

import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('yyyy/MM/dd', 'ar').format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('yyyy/MM/dd HH:mm', 'ar').format(date);
  }

  static String formatDateOnly(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('yyyy/MM/dd', 'ar').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  static String formatCurrency(double? amount) {
    if (amount == null) return '0 د.ع';
    return '${NumberFormat('#,##0', 'ar').format(amount)} د.ع';
  }

  static String formatNumber(int? number) {
    if (number == null) return '0';
    return NumberFormat('#,##0', 'ar').format(number);
  }
}
