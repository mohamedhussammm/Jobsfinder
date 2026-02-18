import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/result.dart';

/// File upload service provider
final fileUploadServiceProvider = Provider((ref) => FileUploadService());

class FileUploadService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Storage bucket names
  static const String _cvBucket = 'cvs';
  static const String _avatarBucket = 'avatars';
  static const String _eventImageBucket = 'event-images';

  /// Upload a CV file for a user
  Future<Result<String>> uploadCV({
    required String userId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      final ext = fileName.split('.').last;
      final path = '$userId/cv_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _supabase.storage
          .from(_cvBucket)
          .uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(
              contentType: _getMimeType(ext),
              upsert: true,
            ),
          );

      return Success(path);
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to upload CV: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Upload an event image
  Future<Result<String>> uploadEventImage({
    required String eventId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      final ext = fileName.split('.').last;
      final path =
          '$eventId/image_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _supabase.storage
          .from(_eventImageBucket)
          .uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(
              contentType: _getMimeType(ext),
              upsert: true,
            ),
          );

      return Success(path);
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to upload event image: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Upload a user avatar
  Future<Result<String>> uploadAvatar({
    required String userId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      final ext = fileName.split('.').last;
      final path = '$userId/avatar.$ext';

      await _supabase.storage
          .from(_avatarBucket)
          .uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(
              contentType: _getMimeType(ext),
              upsert: true,
            ),
          );

      return Success(path);
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to upload avatar: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get the public URL for a stored file
  String getPublicUrl(String bucket, String path) {
    return _supabase.storage.from(bucket).getPublicUrl(path);
  }

  /// Get a signed URL for private files (e.g., CVs)
  Future<Result<String>> getSignedUrl(
    String bucket,
    String path, {
    int expiresIn = 3600,
  }) async {
    try {
      final url = await _supabase.storage
          .from(bucket)
          .createSignedUrl(path, expiresIn);
      return Success(url);
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to get signed URL: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Delete a file from storage
  Future<Result<void>> deleteFile(String bucket, String path) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
      return Success(null);
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to delete file: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Determine MIME type from file extension
  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}
