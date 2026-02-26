import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/dark_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/event_model.dart';
import '../../controllers/team_leader_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/stub_providers.dart';
import '../../services/logout_service.dart';
import '../common/skeleton_loader.dart';

class TeamLeaderEventsScreen extends ConsumerWidget {
  const TeamLeaderEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser?.id ?? '';
    final assignmentsAsync = ref.watch(teamLeaderEventsProvider(userId));
    final activeCountAsync = ref.watch(activeAssignmentsCountProvider);
    final completedCountAsync = ref.watch(completedAssignmentsCountProvider);

    return Scaffold(
      backgroundColor: DarkColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Assignments',
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            fontSize: ResponsiveHelper.sp(context, 20),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            color: DarkColors.error,
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
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
                        backgroundColor: DarkColors.error,
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
                await ref.read(logoutProvider).logout();
                if (context.mounted) context.go('/auth');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Row
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Active',
                    value: activeCountAsync.when(
                      data: (count) => count.toString(),
                      loading: () => '...',
                      error: (_, e) => '0',
                    ),
                    icon: Icons.assignment,
                    color: DarkColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Completed',
                    value: completedCountAsync.when(
                      data: (count) => count.toString(),
                      loading: () => '...',
                      error: (_, e) => '0',
                    ),
                    icon: Icons.check_circle,
                    color: DarkColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Events List
            Text('Assigned Events', style: AppTypography.heading3),
            const SizedBox(height: 12),
            assignmentsAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.assignment_ind_outlined,
                            size: 64,
                            color: DarkColors.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No assignments yet',
                            style: AppTypography.body1.copyWith(
                              color: DarkColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return EventAssignmentCard(event: event);
                  },
                );
              },
              loading: () => Column(
                children: List.generate(3, (index) => const SkeletonCard()),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: DarkColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load assignments',
                        style: AppTypography.body1.copyWith(
                          color: DarkColors.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: AppTypography.caption.copyWith(
                          color: DarkColors.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
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
        color: DarkColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DarkColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              color: Colors.white,
              fontSize: ResponsiveHelper.sp(context, 22),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: DarkColors.textSecondary,
              fontSize: ResponsiveHelper.sp(context, 12),
            ),
          ),
        ],
      ),
    );
  }
}

class EventAssignmentCard extends ConsumerWidget {
  final EventModel event;

  const EventAssignmentCard({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        context.go('/event/${event.id}');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DarkColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DarkColors.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: AppTypography.heading3,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.company,
                        style: AppTypography.body2.copyWith(
                          color: DarkColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(event.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    event.status.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      color: _getStatusColor(event.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Details Row
            Row(
              children: [
                Expanded(
                  child: _DetailItem(
                    icon: Icons.location_on,
                    label: event.location?.city ?? 'Unknown',
                  ),
                ),
                Expanded(
                  child: _DetailItem(
                    icon: Icons.calendar_today,
                    label: _formatDate(event.eventDate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Applicants Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${event.applicants} Applicants',
                        style: AppTypography.bodySmall.copyWith(
                          color: DarkColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Capacity: ${event.capacity}',
                        style: AppTypography.labelSmall.copyWith(
                          color: DarkColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          context.push(
                            '/team-leader/applicants/${event.id}?title=${Uri.encodeComponent(event.title)}',
                          );
                        },
                        icon: const Icon(Icons.people, size: 16),
                        label: const Text('Manage'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: DarkColors.accent,
                          side: const BorderSide(color: DarkColors.accent),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.go('/event/${event.id}');
                        },
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('View'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DarkColors.accent,
                          foregroundColor: DarkColors.gray50,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return DarkColors.pending;
      case 'approved':
      case 'active':
        return DarkColors.success;
      case 'completed':
        return DarkColors.completed;
      case 'rejected':
      case 'cancelled':
        return DarkColors.error;
      default:
        return DarkColors.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays > 0 && difference.inDays <= 7) {
      return 'In ${difference.inDays} days';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: DarkColors.accent),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: DarkColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
