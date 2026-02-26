import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_config.dart';
import '../core/utils/result.dart';

/// File upload service provider
final fileUploadServiceProvider = Provider((ref) => FileUploadService(ref));

class FileUploadService {
  final Ref ref;

  FileUploadService(this.ref);

  ApiClient get _api => ref.read(apiClientProvider);

  /// Upload avatar image
  Future<Result<String>> uploadAvatar({
    required String fileName,
    required Uint8List bytes,
  }) async {
    return _uploadFile(
      endpoint: ApiEndpoints.uploadAvatar,
      fileName: fileName,
      bytes: bytes,
      fieldName: 'avatar',
    );
  }

  /// Upload CV / resume
  Future<Result<String>> uploadCV({
    required String fileName,
    required Uint8List bytes,
  }) async {
    return _uploadFile(
      endpoint: ApiEndpoints.uploadCv,
      fileName: fileName,
      bytes: bytes,
      fieldName: 'cv',
    );
  }

  /// Upload event image
  Future<Result<String>> uploadEventImage({
    required String fileName,
    required Uint8List bytes,
  }) async {
    return _uploadFile(
      endpoint: ApiEndpoints.uploadEventImage,
      fileName: fileName,
      bytes: bytes,
      fieldName: 'image',
    );
  }

  /// Upload company logo
  Future<Result<String>> uploadCompanyLogo({
    required String fileName,
    required Uint8List bytes,
  }) async {
    return _uploadFile(
      endpoint: ApiEndpoints.uploadCompanyLogo,
      fileName: fileName,
      bytes: bytes,
      fieldName: 'logo',
    );
  }

  /// Generic file upload method
  Future<Result<String>> _uploadFile({
    required String endpoint,
    required String fileName,
    required Uint8List bytes,
    required String fieldName,
  }) async {
    try {
      final response = await _api.uploadFileBytes(
        endpoint,
        bytes: bytes,
        fileName: fileName,
        fieldName: fieldName,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final url =
            response.data['data']?['filePath'] ??
            response.data['data']?['url'] ??
            response.data['data']?['path'] ??
            '';
        return Success(url as String);
      }

      return Error(AppException(message: 'Failed to upload file'));
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Upload failed',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Upload failed: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Upload file from path (for platforms with file system access)
  Future<Result<String>> uploadFromPath({
    required String endpoint,
    required String filePath,
    required String fieldName,
  }) async {
    try {
      final response = await _api.uploadFile(
        endpoint,
        filePath: filePath,
        fieldName: fieldName,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final url =
            response.data['data']?['url'] ??
            response.data['data']?['path'] ??
            '';
        return Success(url as String);
      }

      return Error(AppException(message: 'Failed to upload file'));
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Upload failed',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Upload failed: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Get the public URL for an uploaded file
  String getPublicUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;

    // Ensure it starts with /uploads if it's a relative backend path
    String formattedPath = path;
    if (!path.startsWith('uploads/') && !path.startsWith('/uploads/')) {
      formattedPath = 'uploads/$path';
    }

    final base = ApiConfig.baseUrl.replaceAll('/api', '');
    // Ensure no double slashes if base ends in / or path starts with /
    final cleanBase = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    final cleanPath = formattedPath.startsWith('/')
        ? formattedPath
        : '/$formattedPath';

    return '$cleanBase$cleanPath';
  }

  /// Delete a file from server storage
  Future<Result<void>> deleteFile(String path) async {
    try {
      await _api.delete('/upload', data: {'path': path});
      return Success(null);
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to delete file',
          originalError: e,
        ),
      );
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
}
