// lib/data/datasources/storage_datasource.dart

import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import '../../core/constants/app_constants.dart';

class StorageDataSource {
  final SupabaseClient _client;

  StorageDataSource(this._client);

  Future<Map<String, String>> uploadFile({
    required String orderId,
    required String fileName,
    required Uint8List fileBytes,
    String? contentType,
  }) async {
    final ext = path.extension(fileName).isNotEmpty
        ? path.extension(fileName)
        : '.bin';
    final uniqueName =
        '${orderId}/${DateTime.now().millisecondsSinceEpoch}$ext';

    await _client.storage
        .from(AppConstants.storageOrderAttachments)
        .uploadBinary(
          uniqueName,
          fileBytes,
          fileOptions: FileOptions(
            contentType: contentType ?? 'application/octet-stream',
            upsert: false,
          ),
        );

    // Try public URL first; fall back to a 10-year signed URL for private buckets
    String fileUrl;
    try {
      fileUrl = _client.storage
          .from(AppConstants.storageOrderAttachments)
          .getPublicUrl(uniqueName);
    } catch (_) {
      fileUrl = await _client.storage
          .from(AppConstants.storageOrderAttachments)
          .createSignedUrl(uniqueName, 60 * 60 * 24 * 365 * 10);
    }

    return {'file_path': uniqueName, 'file_url': fileUrl};
  }

  Future<void> deleteFile(String filePath) async {
    await _client.storage.from(AppConstants.storageOrderAttachments).remove([
      filePath,
    ]);
  }

  String getPublicUrl(String filePath) {
    return _client.storage
        .from(AppConstants.storageOrderAttachments)
        .getPublicUrl(filePath);
  }

  Future<String> getSignedUrl(String filePath) async {
    return _client.storage
        .from(AppConstants.storageOrderAttachments)
        .createSignedUrl(filePath, 60 * 60 * 24 * 365); // 1 year
  }

  // ── رفع صورة نص إلى bucket text-images ──────────────────
  Future<String> uploadTextImage({
    required String orderId,
    required String fieldKey, // e.g. 'right', 'left', 'chest', 'sash', 'cap'
    required XFile image,
  }) async {
    final bytes = await image.readAsBytes();
    final ext = path.extension(image.name).isNotEmpty
        ? path.extension(image.name)
        : '.jpg';
    final filePath =
        '$orderId/${fieldKey}_${DateTime.now().millisecondsSinceEpoch}$ext';

    await _client.storage
        .from('text-images')
        .uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(contentType: 'image/jpeg', upsert: true),
        );

    return _client.storage.from('text-images').getPublicUrl(filePath);
  }
}
