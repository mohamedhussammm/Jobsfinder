import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/responsive.dart';

/// Main shell with bottom navigation bar for normal users
class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  final String currentPath;

  const MainShell({super.key, required this.child, required this.currentPath});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  static const _navItems = [
    _NavItem('/', 'Events', Icons.event_outlined, Icons.event),
    _NavItem(
      '/applications',
      'Apply',
      Icons.assignment_outlined,
      Icons.assignment,
    ),
    _NavItem(
      '/notifications',
      'Alerts',
      Icons.notifications_outlined,
      Icons.notifications,
    ),
    _NavItem('/profile', 'Profile', Icons.person_outline, Icons.person),
  ];

  @override
  void didUpdateWidget(MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncIndex();
  }

  @override
  void initState() {
    super.initState();
    _syncIndex();
  }

  void _syncIndex() {
    final idx = _navItems.indexWhere((item) => item.path == widget.currentPath);
    if (idx >= 0 && idx != _currentIndex) {
      setState(() => _currentIndex = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Material(
        color: Theme.of(context).cardColor,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Nav items
                ...List.generate(_navItems.length, (index) {
                  final item = _navItems[index];
                  final isActive = _currentIndex == index;
                  return _buildNavItem(
                    context,
                    ref,
                    item,
                    isActive,
                    index,
                    currentUser?.id,
                  );
                }),

                // Logout button
                _buildLogoutButton(context, ref),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    WidgetRef ref,
    _NavItem item,
    bool isActive,
    int index,
    String? userId,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => _currentIndex = index);
        context.go(item.path);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: isActive
                      ? Theme.of(context).primaryColor
                      : Colors.white.withValues(alpha: 0.4),
                  size: ResponsiveHelper.iconSize(context),
                ),
                // Notification badge
                if (item.path == '/notifications' && userId != null)
                  _buildNotificationBadge(ref, userId),
              ],
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                item.label,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.sp(context, 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _confirmLogout(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Icon(
          Icons.logout_rounded,
          color: AppColors.error.withValues(alpha: 0.75),
          size: ResponsiveHelper.iconSize(context),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign Out',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to sign out of your session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authControllerProvider).logout();
      if (context.mounted) {
        context.go('/auth');
      }
    }
  }

  Widget _buildNotificationBadge(WidgetRef ref, String userId) {
    final unreadAsync = ref.watch(unreadCountProvider(userId));
    return unreadAsync.when(
      data: (count) {
        if (count == 0) return const SizedBox.shrink();
        return Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
            child: Text(
              count > 9 ? '9+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, e) => const SizedBox.shrink(),
    );
  }
}

class _NavItem {
  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem(this.path, this.label, this.icon, this.activeIcon);
}
