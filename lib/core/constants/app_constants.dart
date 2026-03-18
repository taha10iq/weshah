// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  static const String appName = 'وشاح - نظام إدارة الطلبات';
  static const String supabaseUrl = 'https://abymnfpknybnowlwbveo.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_sK70yHGIcD21m05hpHQliQ_MJO4NxnD';
  static const String storageOrderAttachments = 'order-attachments';

  // Status constants
  static const String statusNew = 'new';
  static const String statusInProgress = 'in_progress';
  static const String statusReady = 'ready';
  static const String statusDelivered = 'delivered';
  static const String statusCancelled = 'cancelled';

  // Sleeve style constants
  static const String sleeveFullPleats = 'full_pleats';
  static const String sleeveNoPleats = 'no_pleats';
  static const String sleeveShoulderOnly = 'shoulder_only';
  static const String sleeveOtherModel = 'other_model';

  static const Map<String, String> statusLabels = {
    'new': 'جديد',
    'in_progress': 'قيد التنفيذ',
    'ready': 'جاهز',
    'delivered': 'تم التسليم',
    'cancelled': 'ملغى',
  };

  static const Map<String, String> sleeveStyleLabels = {
    'full_pleats': 'كامل الكسرات',
    'no_pleats': 'بدون كسرات',
    'shoulder_only': 'كسرة على الكتف فقط',
    'other_model': 'موديل آخر',
  };
}
