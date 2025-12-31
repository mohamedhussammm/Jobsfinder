import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/glass.dart';
import '../../models/application_model.dart';
import '../../controllers/application_controller.dart';

class ApplicationsScreenTab extends ConsumerWidget {
  const ApplicationsScreenTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(
      userApplicationsProvider('current_user_id'),
    ); // TODO: Get actual user ID

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: Text('My Applications', style: AppTypography.heading2),
        centerTitle: false,
      ),
      body: applicationsAsync.when(
        data: (applications) {
          if (applications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_ind_outlined,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text('No applications yet', style: AppTypography.heading3),
                    const SizedBox(height: 8),
                    Text(
                      'Apply to events to see them here',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/search'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Find Events'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final application = applications[index];
              return ApplicationCard(application: application);
            },
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.accent),
              ),
              const SizedBox(height: 16),
              Text('Loading applications...', style: AppTypography.body2),
            ],
          ),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to load applications',
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ApplicationCard extends ConsumerWidget {
  final ApplicationModel application;

  const ApplicationCard({Key? key, required this.application})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _getStatusColor(application.status);

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.eventTitle,
                      style: AppTypography.heading3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      application.companyName,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  application.status.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Application Details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.glassSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(
                  label: 'Applied On',
                  value: _formatDate(application.appliedAt),
                  icon: Icons.calendar_today,
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  label: 'Status',
                  value: _getStatusLabel(application.status),
                  icon: Icons.info,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Cover Letter Preview
          if (application.coverLetter != null &&
              application.coverLetter!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cover Letter',
                  style: AppTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.glassSecondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    application.coverLetter!,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Handle view details
                  },
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (application.status.toLowerCase() == 'pending')
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Application withdrawn'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    },
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Withdraw'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error.withOpacity(0.2),
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
            ],
          ),

          // Status Message
          const SizedBox(height: 12),
          _StatusMessage(status: application.status),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'reviewed':
        return AppColors.accent;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Awaiting Review';
      case 'accepted':
        return 'Congratulations!';
      case 'rejected':
        return 'Application Declined';
      case 'reviewed':
        return 'Under Review';
      default:
        return 'Unknown';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: AppTypography.body1.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _StatusMessage extends StatelessWidget {
  final String status;

  const _StatusMessage({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    late String message;
    late Color color;
    late IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        message = 'Your application is being reviewed. Check back soon!';
        color = AppColors.warning;
        icon = Icons.schedule;
        break;
      case 'accepted':
        message = 'Great! You\'ve been selected for this event.';
        color = AppColors.success;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        message = 'Thank you for applying. Keep trying!';
        color = AppColors.error;
        icon = Icons.cancel;
        break;
      case 'reviewed':
        message = 'Your application is under active review.';
        color = AppColors.accent;
        icon = Icons.visibility;
        break;
      default:
        return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.caption.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
