import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/application_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/application_model.dart';

class UserDashboardScreen extends ConsumerWidget {
  const UserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    final applicationsAsync = ref.watch(
      userApplicationsProvider(currentUser.id),
    );
    final unreadAsync = ref.watch(unreadCountProvider(currentUser.id));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userApplicationsProvider(currentUser.id));
          ref.invalidate(unreadCountProvider(currentUser.id));
        },
        child: CustomScrollView(
          slivers: [
            // Greeting Header
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  ResponsiveHelper.screenPadding(context).left,
                  MediaQuery.of(context).padding.top + 24,
                  ResponsiveHelper.screenPadding(context).right,
                  24,
                ),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row with avatar and notifications
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: ResponsiveHelper.avatarRadius(context),
                              backgroundColor: Colors.white24,
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: ResponsiveHelper.sp(context, 28),
                              ),
                            ),
                            SizedBox(width: ResponsiveHelper.sp(context, 12)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: ResponsiveHelper.sp(context, 14),
                                  ),
                                ),
                                Text(
                                  currentUser.name ?? 'User',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: ResponsiveHelper.sp(context, 22),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Stack(
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).pushNamed('/notifications');
                              },
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                              ),
                              iconSize: ResponsiveHelper.sp(context, 28),
                            ),
                            unreadAsync.when(
                              data: (count) => count > 0
                                  ? Positioned(
                                      right: 6,
                                      top: 6,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: AppColors.error,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          count > 9 ? '9+' : '$count',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: ResponsiveHelper.sp(
                                              context,
                                              10,
                                            ),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                              loading: () => const SizedBox.shrink(),
                              error: (_, e) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveHelper.sp(context, 20)),

                    // Rating display
                    if (currentUser.ratingAvg > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: AppColors.accent,
                              size: ResponsiveHelper.sp(context, 18),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${currentUser.ratingAvg.toStringAsFixed(1)} Rating',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: ResponsiveHelper.sp(context, 14),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              ' (${currentUser.ratingCount} reviews)',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: ResponsiveHelper.sp(context, 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Stats Cards
            SliverPadding(
              padding: ResponsiveHelper.screenPadding(context),
              sliver: SliverToBoxAdapter(
                child: applicationsAsync.when(
                  data: (apps) {
                    final applied = apps
                        .where((a) => a.status == 'applied')
                        .length;
                    final accepted = apps
                        .where((a) => a.status == 'accepted')
                        .length;
                    final total = apps.length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: ResponsiveHelper.sp(context, 16)),
                        Text(
                          'Your Activity',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.sp(context, 18),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.sp(context, 12)),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cols = ResponsiveHelper.kpiCardsPerRow(
                              context,
                            ).clamp(2, 3);
                            final spacing = 12.0;
                            final cardWidth =
                                (constraints.maxWidth - (cols - 1) * spacing) /
                                cols;

                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: [
                                _buildStatCard(
                                  context,
                                  'Total Applied',
                                  '$total',
                                  Icons.assignment_outlined,
                                  AppColors.primary,
                                  cardWidth,
                                ),
                                _buildStatCard(
                                  context,
                                  'Pending',
                                  '$applied',
                                  Icons.hourglass_empty,
                                  AppColors.pending,
                                  cardWidth,
                                ),
                                _buildStatCard(
                                  context,
                                  'Accepted',
                                  '$accepted',
                                  Icons.check_circle_outline,
                                  AppColors.success,
                                  cardWidth,
                                ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: ResponsiveHelper.sp(context, 24)),

                        // Quick Actions
                        Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.sp(context, 18),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.sp(context, 12)),
                        _buildQuickAction(
                          context,
                          'Browse Events',
                          'Find new job opportunities',
                          Icons.search,
                          AppColors.primary,
                          () => Navigator.of(context).pushNamed('/'),
                        ),
                        const SizedBox(height: 8),
                        _buildQuickAction(
                          context,
                          'My Applications',
                          'Track your applications',
                          Icons.assignment_outlined,
                          AppColors.info,
                          () =>
                              Navigator.of(context).pushNamed('/applications'),
                        ),
                        const SizedBox(height: 8),
                        _buildQuickAction(
                          context,
                          'My Ratings',
                          'See your received ratings',
                          Icons.star_outline,
                          AppColors.accent,
                          () => Navigator.of(context).pushNamed('/ratings'),
                        ),
                        const SizedBox(height: 8),
                        _buildQuickAction(
                          context,
                          'Edit Profile',
                          'Update your information',
                          Icons.person_outline,
                          AppColors.secondary,
                          () =>
                              Navigator.of(context).pushNamed('/edit-profile'),
                        ),

                        SizedBox(height: ResponsiveHelper.sp(context, 24)),

                        // Recent Applications
                        if (apps.isNotEmpty) ...[
                          Text(
                            'Recent Applications',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.sp(context, 18),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: ResponsiveHelper.sp(context, 12)),
                          ...apps
                              .take(3)
                              .map((app) => _buildRecentAppCard(context, app)),
                        ],
                      ],
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) =>
                      Center(child: Text('Error loading data: $e')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 0,
        color: color.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: ResponsiveHelper.cardPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: ResponsiveHelper.sp(context, 24)),
              SizedBox(height: ResponsiveHelper.sp(context, 8)),
              Text(
                value,
                style: TextStyle(
                  fontSize: ResponsiveHelper.sp(context, 24),
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: ResponsiveHelper.sp(context, 12),
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderColor),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.sp(context, 14),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: ResponsiveHelper.sp(context, 12),
            color: AppColors.textTertiary,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.gray400),
      ),
    );
  }

  Widget _buildRecentAppCard(BuildContext context, ApplicationModel app) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: _statusColor(app.status),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Application',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.sp(context, 14),
                    ),
                  ),
                  Text(
                    'Applied ${app.appliedAt.day}/${app.appliedAt.month}/${app.appliedAt.year}',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.sp(context, 11),
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(app.status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                app.status.toUpperCase(),
                style: TextStyle(
                  color: _statusColor(app.status),
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.sp(context, 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return AppColors.success;
      case 'rejected':
      case 'declined':
        return AppColors.error;
      case 'shortlisted':
      case 'invited':
        return AppColors.info;
      default:
        return AppColors.pending;
    }
  }
}
