import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../models/message_model.dart';
import '../core/utils/result.dart';

/// Helper class for message params
class MessageParams {
  final String userId;
  final String otherUserId;
  MessageParams({required this.userId, required this.otherUserId});
}

/// Conversations provider
final conversationsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, userId) async {
      final controller = ref.watch(messageControllerProvider);
      final result = await controller.fetchConversations(userId);
      return result.when(success: (c) => c, error: (e) => throw e);
    });

/// Messages between two users provider
final messagesProvider = FutureProvider.autoDispose
    .family<List<MessageModel>, MessageParams>((ref, params) async {
      final controller = ref.watch(messageControllerProvider);
      final result = await controller.fetchMessages(
        userId: params.userId,
        otherUserId: params.otherUserId,
      );
      return result.when(success: (m) => m, error: (e) => throw e);
    });

/// Message controller provider
final messageControllerProvider = Provider((ref) => MessageController(ref));

class MessageController {
  final Ref ref;

  MessageController(this.ref);

  ApiClient get _api => ref.read(apiClientProvider);

  /// Send a message
  Future<Result<MessageModel>> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    String? eventId,
  }) async {
    try {
      final response = await _api.post(
        '/messages',
        data: {
          'receiverId': receiverId,
          'content': content,
          'eventId': eventId,
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return Success(
          MessageModel.fromJson(response.data['data'] as Map<String, dynamic>),
        );
      }

      return Error(AppException(message: 'Failed to send message'));
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to send message',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to send message: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Fetch messages between two users
  Future<Result<List<MessageModel>>> fetchMessages({
    required String userId,
    required String otherUserId,
    int page = 0,
    int pageSize = 50,
  }) async {
    try {
      final response = await _api.get(
        '/messages',
        queryParameters: {
          'otherUserId': otherUserId,
          'page': page + 1,
          'limit': pageSize,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final list = response.data['data'] as List;
        final messages = list
            .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return Success(messages);
      }

      return Success([]);
    } on DioException catch (e) {
      return Error(
        AppException(
          message: e.response?.data?['message'] ?? 'Failed to fetch messages',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch messages: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Fetch conversation list for a user
  Future<Result<List<Map<String, dynamic>>>> fetchConversations(
    String userId,
  ) async {
    try {
      final response = await _api.get('/messages/conversations');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final list = response.data['data'] as List;
        return Success(list.map((e) => e as Map<String, dynamic>).toList());
      }

      return Success([]);
    } on DioException catch (e) {
      return Error(
        AppException(
          message:
              e.response?.data?['message'] ?? 'Failed to fetch conversations',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to fetch conversations: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Mark messages as read from a specific sender
  Future<Result<void>> markConversationAsRead({
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      await _api.patch('/messages/read', data: {'otherUserId': otherUserId});
      return Success(null);
    } on DioException catch (e) {
      return Error(
        AppException(
          message:
              e.response?.data?['message'] ??
              'Failed to mark conversation as read',
          originalError: e,
        ),
      );
    } catch (e, st) {
      return Error(
        AppException(
          message: 'Failed to mark conversation as read: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }
}
