import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_client.dart';
import '../models/message_model.dart';
import '../core/utils/result.dart';

/// Messages table name
const String _messagesTable = 'messages';

/// Conversations provider for a user
final conversationsProvider = FutureProvider.autoDispose
    .family<List<ConversationModel>, String>((ref, userId) async {
      final controller = ref.watch(messageControllerProvider);
      final result = await controller.fetchConversations(userId);
      return result.when(success: (c) => c, error: (e) => throw e);
    });

/// Messages for a specific conversation
final conversationMessagesProvider = FutureProvider.autoDispose
    .family<List<MessageModel>, ({String userId, String otherUserId})>((
      ref,
      params,
    ) async {
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
  final SupabaseClient _supabase = Supabase.instance.client;

  MessageController(this.ref);

  /// Send a message
  Future<Result<MessageModel>> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    String? eventId,
  }) async {
    try {
      final data = {
        'sender_id': senderId,
        'receiver_id': receiverId,
        'content': content,
        'event_id': eventId,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from(_messagesTable)
          .insert(data)
          .select()
          .single();

      return Success(MessageModel.fromJson(response));
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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
      final from = page * pageSize;
      final to = from + pageSize - 1;

      final response = await _supabase
          .from(_messagesTable)
          .select()
          .or(
            'and(sender_id.eq.$userId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$userId)',
          )
          .order('created_at', ascending: false)
          .range(from, to);

      final messages = (response as List)
          .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return Success(messages);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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
  Future<Result<List<ConversationModel>>> fetchConversations(
    String userId,
  ) async {
    try {
      // Get all messages involving this user, grouped by the other party
      final sentMessages = await _supabase
          .from(_messagesTable)
          .select('receiver_id, content, created_at, is_read')
          .eq('sender_id', userId)
          .order('created_at', ascending: false);

      final receivedMessages = await _supabase
          .from(_messagesTable)
          .select('sender_id, content, created_at, is_read')
          .eq('receiver_id', userId)
          .order('created_at', ascending: false);

      // Build conversation map
      final Map<String, ConversationModel> conversations = {};

      for (final msg in sentMessages) {
        final otherId = msg['receiver_id'] as String;
        if (!conversations.containsKey(otherId)) {
          conversations[otherId] = ConversationModel(
            otherUserId: otherId,
            lastMessage: msg['content'] as String?,
            lastMessageAt: msg['created_at'] != null
                ? DateTime.parse(msg['created_at'] as String)
                : null,
            unreadCount: 0,
          );
        }
      }

      for (final msg in receivedMessages) {
        final otherId = msg['sender_id'] as String;
        final isRead = msg['is_read'] as bool? ?? false;
        final msgTime = msg['created_at'] != null
            ? DateTime.parse(msg['created_at'] as String)
            : null;

        if (!conversations.containsKey(otherId)) {
          conversations[otherId] = ConversationModel(
            otherUserId: otherId,
            lastMessage: msg['content'] as String?,
            lastMessageAt: msgTime,
            unreadCount: isRead ? 0 : 1,
          );
        } else {
          final existing = conversations[otherId]!;
          // Update if this message is newer
          if (msgTime != null &&
              (existing.lastMessageAt == null ||
                  msgTime.isAfter(existing.lastMessageAt!))) {
            conversations[otherId] = ConversationModel(
              otherUserId: otherId,
              lastMessage: msg['content'] as String?,
              lastMessageAt: msgTime,
              unreadCount: existing.unreadCount + (isRead ? 0 : 1),
            );
          }
        }
      }

      // Fetch user names for conversations
      final otherUserIds = conversations.keys.toList();
      if (otherUserIds.isNotEmpty) {
        final users = await _supabase
            .from(SupabaseTables.users)
            .select('id, name, avatar_path')
            .inFilter('id', otherUserIds);

        for (final user in users) {
          final uid = user['id'] as String;
          if (conversations.containsKey(uid)) {
            final conv = conversations[uid]!;
            conversations[uid] = ConversationModel(
              otherUserId: uid,
              otherUserName: user['name'] as String?,
              otherUserAvatar: user['avatar_path'] as String?,
              lastMessage: conv.lastMessage,
              lastMessageAt: conv.lastMessageAt,
              unreadCount: conv.unreadCount,
            );
          }
        }
      }

      final result = conversations.values.toList()
        ..sort((a, b) {
          if (a.lastMessageAt == null) return 1;
          if (b.lastMessageAt == null) return -1;
          return b.lastMessageAt!.compareTo(a.lastMessageAt!);
        });

      return Success(result);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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
      await _supabase
          .from(_messagesTable)
          .update({'is_read': true})
          .eq('sender_id', otherUserId)
          .eq('receiver_id', currentUserId)
          .eq('is_read', false);

      return Success(null);
    } on PostgrestException catch (e) {
      return Error(
        DatabaseException(message: e.message, code: e.code, originalError: e),
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
