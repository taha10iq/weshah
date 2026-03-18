// lib/data/models/order_attachment_model.dart

class OrderAttachmentModel {
  final String id;
  final String orderId;
  final String fileName;
  final String filePath;
  final String? fileUrl;
  final String? fileType;
  final DateTime uploadedAt;

  const OrderAttachmentModel({
    required this.id,
    required this.orderId,
    required this.fileName,
    required this.filePath,
    this.fileUrl,
    this.fileType,
    required this.uploadedAt,
  });

  factory OrderAttachmentModel.fromJson(Map<String, dynamic> json) {
    return OrderAttachmentModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      fileName: json['file_name'] as String,
      filePath: json['file_path'] as String,
      fileUrl: json['file_url'] as String?,
      fileType: json['file_type'] as String?,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'file_name': fileName,
      'file_path': filePath,
      if (fileUrl != null) 'file_url': fileUrl,
      if (fileType != null) 'file_type': fileType,
    };
  }

  bool get isImage {
    final type = fileType?.toLowerCase() ?? '';
    return type.contains('image') ||
        fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.png') ||
        fileName.toLowerCase().endsWith('.gif') ||
        fileName.toLowerCase().endsWith('.webp');
  }
}
