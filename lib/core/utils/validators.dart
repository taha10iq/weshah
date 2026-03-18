// lib/core/utils/validators.dart

class Validators {
  Validators._();

  static String? required(String? value, [String fieldName = 'هذا الحقل']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName مطلوب';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'رقم الهاتف مطلوب';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-\+]'), '');
    if (cleaned.length < 9 || cleaned.length > 15) {
      return 'رقم الهاتف غير صحيح';
    }
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'رقم الهاتف يجب أن يحتوي على أرقام فقط';
    }
    return null;
  }

  static String? positiveNumber(String? value, [String fieldName = 'القيمة']) {
    if (value == null || value.trim().isEmpty) return null;
    final number = double.tryParse(value);
    if (number == null) return '$fieldName يجب أن يكون رقماً';
    if (number < 0) return '$fieldName يجب أن يكون موجباً';
    return null;
  }

  static String? positiveInteger(String? value, [String fieldName = 'الكمية']) {
    if (value == null || value.trim().isEmpty) return null;
    final number = int.tryParse(value);
    if (number == null) return '$fieldName يجب أن يكون رقماً صحيحاً';
    if (number <= 0) return '$fieldName يجب أن يكون أكبر من صفر';
    return null;
  }
}
