import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/analytics_model.dart';
import '../../controllers/analytics_controller.dart';
import '../../controllers/event_controller.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/shadows.dart';
import 'users/admin_users_screen.dart';
import 'applications/admin_applications_screen.dart';
import 'events/admin_events_screen.dart';
import '../../controllers/auth_controller.dart';
import '../../core/utils/responsive.dart';
import '../common/skeleton_loader.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/file_upload_service.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          _getTitle(_selectedIndex),
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            color: AppColors.error,
            onPressed: () => _confirmLogout(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _AdminOverviewTab(),
          AdminEventsScreen(),
          AdminApplicationsScreen(),
          AdminUsersScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.backgroundTertiary,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Apps'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
        ],
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Admin Dashboard';
      case 1:
        return 'Manage Events';
      case 2:
        return 'Manage Applications';
      case 3:
        return 'Manage Users';
    }
    return 'Admin';
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundTertiary,
        title: const Text(
          'Sign Out',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to sign out of your session?',
          style: TextStyle(color: AppColors.textSecondary),
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
}

class _AdminOverviewTab extends ConsumerWidget {
  const _AdminOverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsKPIProvider);
    final pendingEventsAsync = ref.watch(pendingEventsAdminProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(analyticsKPIProvider);
        ref.invalidate(pendingEventsAdminProvider);
        return Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Cards (Error handled in internal widget)
            analyticsAsync.when(
              data: (kpi) => _buildKPICards(context, kpi),
              loading: () => const _LoadingKPICards(),
              error: (error, st) => const SizedBox.shrink(), 
            ),
            
            // Repeat the error handling here or use a specific widget
            if (analyticsAsync.hasError)
               _buildKPIErrorState(context, ref, analyticsAsync.error.toString()),

            const SizedBox(height: 24),
  
            // Pending Events Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pending Event Requests',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: ResponsiveHelper.sp(context, 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            pendingEventsAsync.when(
              data: (events) => events.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return _buildPendingEventCard(context, ref, event);
                      },
                    ),
              loading: () => const _LoadingEventList(),
              error: (error, st) => Text(
                'Error loading events: $error',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIErrorState(BuildContext context, WidgetRef ref, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.errorLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  error,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ref.invalidate(analyticsKPIProvider);
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry Analytics'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICards(BuildContext context, AnalyticsKPI kpi) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KPICard(
                title: 'Total Users',
                value: kpi.totalUsers.toString(),
                icon: Icons.people_outline_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KPICard(
                title: 'Live Events',
                value: kpi.totalEvents.toString(),
                icon: Icons.auto_awesome_motion_rounded,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KPICard(
                title: 'Applications',
                value: kpi.totalApplications.toString(),
                icon: Icons.assignment_turned_in_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KPICard(
                title: 'Platform Rating',
                value: kpi.averageRating.toStringAsFixed(1),
                icon: Icons.star_outline_rounded,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.done_all_rounded,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No new event requests to review right now.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingEventCard(
    BuildContext context,
    WidgetRef ref,
    dynamic event,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor, width: 1),
        boxShadow: [AppShadows.sm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.imagePath != null)
                Container(
                  width: 50,
                  height: 50,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(
                        ref
                            .read(fileUploadServiceProvider)
                            .getPublicUrl(event.imagePath!),
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 50,
                  height: 50,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundTertiary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.event, color: AppColors.gray400),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${event.status.toUpperCase()}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Pending',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KPICard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: ResponsiveHelper.sp(context, 20),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
              fontSize: ResponsiveHelper.sp(context, 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingKPICards extends StatelessWidget {
  const _LoadingKPICards();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _shimmerCard()),
            const SizedBox(width: 12),
            Expanded(child: _shimmerCard()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _shimmerCard()),
            const SizedBox(width: 12),
            Expanded(child: _shimmerCard()),
          ],
        ),
      ],
    );
  }

  Widget _shimmerCard() {
    return const SkeletonLoader(
      height: 120,
      width: double.infinity,
      borderRadius: 12,
    );
  }
}

class _LoadingEventList extends StatelessWidget {
  const _LoadingEventList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => const SkeletonLoader(
          height: 100,
          width: double.infinity,
          borderRadius: 12,
        ),
      ),
    );
  }
}
