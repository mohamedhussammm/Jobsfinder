import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/dark_colors.dart';
import '../../core/theme/typography.dart';
import '../../models/application_model.dart';
import '../../controllers/application_controller.dart';

class EventApplicantsScreen extends ConsumerWidget {
  final String eventId;
  final String eventTitle;

  const EventApplicantsScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicantsAsync = ref.watch(eventApplicationsProvider(eventId));

    return Scaffold(
      backgroundColor: DarkColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Applicants',
              style: AppTypography.titleLarge.copyWith(color: Colors.white),
            ),
            Text(
              eventTitle,
              style: AppTypography.labelSmall.copyWith(
                color: DarkColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
      body: applicantsAsync.when(
        data: (applicants) {
          if (applicants.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: applicants.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final applicant = applicants[index];
              return _ApplicantCard(
                applicant: applicant,
                eventTitle: eventTitle,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 64,
            color: DarkColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No applicants yet',
            style: AppTypography.body1.copyWith(color: DarkColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: DarkColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load applicants',
              style: AppTypography.body1.copyWith(color: DarkColors.error),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTypography.caption.copyWith(
                color: DarkColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  final ApplicationModel applicant;
  final String eventTitle;

  const _ApplicantCard({required this.applicant, required this.eventTitle});

  @override
  Widget build(BuildContext context) {
    final user = applicant.user;
    final String name = user?.name ?? 'Unknown User';
    final String? avatar = user?.avatarPath;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DarkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DarkColors.borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: DarkColors.accent.withValues(alpha: 0.1),
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(
                          color: DarkColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Status: ${applicant.status}',
                      style: AppTypography.labelSmall.copyWith(
                        color: _getStatusColor(applicant.status),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white54,
                ),
                onPressed: () {
                  if (user?.id != null) {
                    context.push('/profile/${user!.id}');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (user?.id != null) {
                      context.push('/profile/${user!.id}');
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('View Profile'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (user?.id != null) {
                      context.push(
                        '/team-leader/rate'
                        '?applicantId=${user!.id}'
                        '&applicantName=${Uri.encodeComponent(name)}'
                        '&eventId=${applicant.eventId}'
                        '&eventTitle=${Uri.encodeComponent(eventTitle)}',
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DarkColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Rate Usher'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'applied':
        return Colors.blue;
      case 'accepted':
        return DarkColors.success;
      case 'rejected':
        return DarkColors.error;
      default:
        return DarkColors.textTertiary;
    }
  }
}
