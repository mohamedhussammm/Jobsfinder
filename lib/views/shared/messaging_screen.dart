import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/message_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/message_model.dart';

/// Conversations list screen
class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    final conversationsAsync = ref.watch(conversationsProvider(currentUser.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Messages'), centerTitle: true),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: ResponsiveHelper.sp(context, 64),
                    color: AppColors.gray300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.sp(context, 18),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: ResponsiveHelper.screenPadding(context),
            itemCount: conversations.length,
            separatorBuilder: (_, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final conv = conversations[index];
              final otherUserName = conv['otherUserName'] as String? ?? 'User';
              final otherUserId = conv['otherUserId'] as String? ?? '';
              final unreadCount = (conv['unreadCount'] as num?)?.toInt() ?? 0;
              final lastMessage = conv['lastMessage'] as String? ?? '';
              final lastMessageAtStr = conv['lastMessageAt'] as String?;
              final lastMessageAt = lastMessageAtStr != null
                  ? DateTime.tryParse(lastMessageAtStr)
                  : null;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    otherUserName[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(
                  otherUserName,
                  style: TextStyle(
                    fontWeight: unreadCount > 0
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: ResponsiveHelper.sp(context, 15),
                  ),
                ),
                subtitle: Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.sp(context, 13),
                    color: unreadCount > 0
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (lastMessageAt != null)
                      Text(
                        _formatTime(lastMessageAt),
                        style: TextStyle(
                          fontSize: ResponsiveHelper.sp(context, 11),
                          color: AppColors.textTertiary,
                        ),
                      ),
                    if (unreadCount > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveHelper.sp(context, 10),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MessagingScreen(
                        otherUserId: otherUserId,
                        otherUserName: otherUserName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dateTime.day}/${dateTime.month}';
  }
}

/// Individual chat screen
class MessagingScreen extends ConsumerStatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const MessagingScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  ConsumerState<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends ConsumerState<MessagingScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    final messagesAsync = ref.watch(
      messagesProvider(
        MessageParams(userId: currentUser.id, otherUserId: widget.otherUserId),
      ),
    );

    // Mark conversation as read
    ref
        .read(messageControllerProvider)
        .markConversationAsRead(
          currentUserId: currentUser.id,
          otherUserId: widget.otherUserId,
        );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                widget.otherUserName[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(widget.otherUserName),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Start the conversation!',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: ResponsiveHelper.sp(context, 14),
                      ),
                    ),
                  );
                }

                // Reverse so newest at bottom
                final reversed = messages.reversed.toList();

                return ListView.builder(
                  controller: _scrollController,
                  padding: ResponsiveHelper.screenPadding(context),
                  itemCount: reversed.length,
                  itemBuilder: (context, index) {
                    final msg = reversed[index];
                    final isMe = msg.senderId == currentUser.id;
                    return _buildMessageBubble(context, msg, isMe);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),

          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              8,
              MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.gray100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(currentUser.id),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: _isSending
                      ? null
                      : () => _sendMessage(currentUser.id),
                  icon: Icon(
                    Icons.send,
                    color: _isSending ? AppColors.gray300 : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    MessageModel msg,
    bool isMe,
  ) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.gray100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg.content,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.textPrimary,
                fontSize: ResponsiveHelper.sp(context, 14),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: isMe ? Colors.white60 : AppColors.textTertiary,
                fontSize: ResponsiveHelper.sp(context, 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage(String userId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _messageController.clear();

    final controller = ref.read(messageControllerProvider);
    await controller.sendMessage(
      senderId: userId,
      receiverId: widget.otherUserId,
      content: text,
    );

    setState(() => _isSending = false);

    ref.invalidate(
      messagesProvider(
        MessageParams(userId: userId, otherUserId: widget.otherUserId),
      ),
    );
  }
}
