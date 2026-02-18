import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/notification_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/colors.dart';

import '../../core/utils/responsive.dart';
import '../../models/notification_model.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    final notificationsAsync = ref.watch(
      userNotificationsProvider(currentUser.id),
    );
    final unreadAsync = ref.watch(unreadCountProvider(currentUser.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          unreadAsync.when(
            data: (count) => count > 0
                ? TextButton.icon(
                    onPressed: () => _markAllAsRead(currentUser.id),
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('Mark All Read'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, e) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userNotificationsProvider(currentUser.id));
          ref.invalidate(unreadCountProvider(currentUser.id));
        },
        child: notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.separated(
              padding: ResponsiveHelper.screenPadding(context),
              itemCount: notifications.length,
              separatorBuilder: (_, i) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _buildNotificationCard(notifications[index]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text('Error: $error', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(userNotificationsProvider(currentUser.id));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: ResponsiveHelper.sp(context, 64),
            color: AppColors.gray300,
          ),
          SizedBox(height: ResponsiveHelper.sp(context, 16)),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: ResponsiveHelper.sp(context, 18),
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: ResponsiveHelper.sp(context, 8)),
          Text(
            'You\'ll be notified about updates here',
            style: TextStyle(
              fontSize: ResponsiveHelper.sp(context, 14),
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteNotification(notification.id),
      child: Card(
        elevation: notification.isRead ? 0 : 2,
        color: notification.isRead ? AppColors.surface : AppColors.primaryLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleNotificationTap(notification),
          child: Padding(
            padding: ResponsiveHelper.cardPadding(context),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: ResponsiveHelper.sp(context, 40),
                  height: ResponsiveHelper.sp(context, 40),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(
                      notification.type,
                    ).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: ResponsiveHelper.sp(context, 20),
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title ?? 'Notification',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.sp(context, 14),
                          fontWeight: notification.isRead
                              ? FontWeight.w500
                              : FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message ?? '',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.sp(context, 13),
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatTime(notification.createdAt),
                        style: TextStyle(
                          fontSize: ResponsiveHelper.sp(context, 11),
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Unread indicator
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'invite':
        return Icons.mail_outline;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'declined':
        return Icons.cancel_outlined;
      case 'message':
        return Icons.chat_bubble_outline;
      case 'rating':
        return Icons.star_outline;
      case 'application_status':
        return Icons.assignment_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'invite':
        return AppColors.info;
      case 'accepted':
        return AppColors.success;
      case 'declined':
        return AppColors.error;
      case 'message':
        return AppColors.primary;
      case 'rating':
        return AppColors.accent;
      case 'application_status':
        return AppColors.secondary;
      default:
        return AppColors.gray500;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Future<void> _markAllAsRead(String userId) async {
    final controller = ref.read(notificationControllerProvider);
    await controller.markAllAsRead(userId);
    ref.invalidate(userNotificationsProvider(userId));
    ref.invalidate(unreadCountProvider(userId));
  }

  Future<void> _deleteNotification(String notificationId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;
    final controller = ref.read(notificationControllerProvider);
    await controller.deleteNotification(notificationId);
    ref.invalidate(userNotificationsProvider(currentUser.id));
    ref.invalidate(unreadCountProvider(currentUser.id));
  }

  void _handleNotificationTap(NotificationModel notification) async {
    // Mark as read
    if (!notification.isRead) {
      final controller = ref.read(notificationControllerProvider);
      await controller.markAsRead(notification.id);
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        ref.invalidate(userNotificationsProvider(currentUser.id));
        ref.invalidate(unreadCountProvider(currentUser.id));
      }
    }

    // Navigate based on type and related_id
    // Navigation based on notification type is handled by the router
  }
}
