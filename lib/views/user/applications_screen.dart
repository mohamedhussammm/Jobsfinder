import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../controllers/application_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/application_model.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';

class ApplicationsScreen extends ConsumerWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view applications')),
      );
    }

    final applicationsAsync = ref.watch(
      userApplicationsProvider(currentUser.id),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'My Applications',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: applicationsAsync.when(
        data: (applications) {
          if (applications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Applications Yet',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Browse events and apply to get started',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final app = applications[index];
              return _ApplicationCard(application: app);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error: $error',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}

class _ApplicationCard extends ConsumerWidget {
  final ApplicationModel application;

  const _ApplicationCard({required this.application});

  static final _dateFormatter = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.eventTitle,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        application.companyName,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: application.status),
              ],
            ),
            const SizedBox(height: 16),
            
            // Minimal Status History/Details
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 8),
                Text(
                  'Applied: ${_dateFormatter.format(application.appliedAt)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            
            if (application.coverLetter != null && application.coverLetter!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                application.coverLetter!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/event/${application.eventId}');
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('View Event'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                    ),
                  ),
                ),
                if (application.status == 'applied') ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _withdrawApplication(context, ref),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Withdraw'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Remove _formatDate as it's now handled by _dateFormatter

  Future<void> _withdrawApplication(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Application'),
        content: const Text(
          'Are you sure you want to withdraw this application?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final controller = ref.read(applicationControllerProvider);
      await controller.withdrawApplication(application.id);

      // Refresh the list
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        // ignore: unused_result
        ref.refresh(userApplicationsProvider(currentUser.id));
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'applied':
        color = AppColors.info;
        label = 'Applied';
        break;
      case 'shortlisted':
        color = AppColors.warning;
        label = 'Shortlisted';
        break;
      case 'invited':
        color = AppColors.primary;
        label = 'Invited';
        break;
      case 'accepted':
        color = AppColors.success;
        label = 'Accepted';
        break;
      case 'declined':
      case 'rejected':
        color = AppColors.error;
        label = status == 'declined' ? 'Declined' : 'Rejected';
        break;
      default:
        color = AppColors.textSecondary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
