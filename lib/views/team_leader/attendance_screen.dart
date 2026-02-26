import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/team_leader_controller.dart';
import '../../controllers/application_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/dark_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/responsive.dart';
import '../../models/application_model.dart';
import '../common/skeleton_loader.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventTitle;

  const AttendanceScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  final Map<String, bool> _attendance = {};
  final Map<String, TextEditingController> _notesControllers = {};
  bool _isSaving = false;

  @override
  void dispose() {
    for (final c in _notesControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final applicantsAsync = ref.watch(
      eventApplicationsProvider(widget.eventId),
    );

    return Scaffold(
      backgroundColor: DarkColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Attendance: ${widget.eventTitle}',
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            fontSize: ResponsiveHelper.sp(context, 18),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: _isSaving ? null : _saveAttendance,
              icon: Icon(
                Icons.check_circle_outline,
                size: 18,
                color: _isSaving
                    ? DarkColors.textTertiary
                    : DarkColors.secondary,
              ),
              label: Text(
                'Save',
                style: TextStyle(
                  color: _isSaving
                      ? DarkColors.textTertiary
                      : DarkColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: applicantsAsync.when(
        data: (applications) {
          // Filter to accepted applicants only
          final accepted = applications
              .where((a) => a.status == 'accepted')
              .toList();

          if (accepted.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: ResponsiveHelper.sp(context, 64),
                    color: DarkColors.textTertiary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No accepted applicants',
                    style: AppTypography.bodyLarge.copyWith(
                      color: DarkColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: ResponsiveHelper.screenPadding(context),
            itemCount: accepted.length,
            separatorBuilder: (_, i) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final app = accepted[index];
              _attendance.putIfAbsent(app.userId, () => false);
              _notesControllers.putIfAbsent(
                app.userId,
                () => TextEditingController(),
              );

              final isPresent = _attendance[app.userId]!;

              return InkWell(
                onTap: () => context.push('/profile/${app.user?.id}'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: DarkColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPresent
                          ? DarkColors.secondary.withValues(alpha: 0.5)
                          : DarkColors.borderColor,
                    ),
                  ),
                  child: Padding(
                    padding: ResponsiveHelper.cardPadding(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: ResponsiveHelper.sp(context, 20),
                              backgroundColor: isPresent
                                  ? DarkColors.secondary.withValues(alpha: 0.1)
                                  : DarkColors.gray100,
                              backgroundImage: app.user?.avatarPath != null
                                  ? NetworkImage(app.user!.avatarPath!)
                                  : null,
                              child: app.user?.avatarPath == null
                                  ? Icon(
                                      Icons.person,
                                      color: isPresent
                                          ? DarkColors.secondary
                                          : DarkColors.textTertiary,
                                      size: ResponsiveHelper.sp(context, 20),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Applicant',
                                    style: AppTypography.titleMedium.copyWith(
                                      color: Colors.white,
                                      fontSize: ResponsiveHelper.sp(
                                        context,
                                        15,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'ID: ${app.userId.substring(0, 8)}...',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: DarkColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Rate button — only visible when marked present
                            if (isPresent)
                              IconButton(
                                icon: const Icon(Icons.star_rate_rounded),
                                color: DarkColors.accent,
                                tooltip: 'Rate applicant',
                                onPressed: () => _navigateToRate(app),
                              ),
                            Switch(
                              value: isPresent,
                              onChanged: (val) {
                                setState(() => _attendance[app.userId] = val);
                              },
                              activeTrackColor: DarkColors.secondary.withValues(
                                alpha: 0.5,
                              ),
                              activeThumbColor: DarkColors.secondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Attendance label
                        Text(
                          isPresent ? '✓ Present' : '✗ Absent',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isPresent
                                ? DarkColors.secondary
                                : DarkColors.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Notes
                        TextField(
                          controller: _notesControllers[app.userId]!,
                          decoration: InputDecoration(
                            hintText: 'Notes (optional)',
                            hintStyle: TextStyle(
                              color: DarkColors.textTertiary,
                            ),
                            filled: true,
                            fillColor: DarkColors.gray100.withValues(
                              alpha: 0.5,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: DarkColors.borderColor,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: DarkColors.borderColor,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white,
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => ListView.separated(
          padding: ResponsiveHelper.screenPadding(context),
          itemCount: 5,
          separatorBuilder: (_, i) => const SizedBox(height: 8),
          itemBuilder: (context, index) => const SkeletonCard(),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _navigateToRate(ApplicationModel app) {
    context.push(
      '/rate/${app.userId}'
      '?name=${Uri.encodeComponent(app.user?.name ?? 'Applicant')}'
      '&event=${Uri.encodeComponent(widget.eventTitle)}'
      '&eventId=${widget.eventId}',
    );
  }

  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      setState(() => _isSaving = false);
      return;
    }

    final controller = ref.read(teamLeaderControllerProvider);

    for (final entry in _attendance.entries) {
      if (entry.value) {
        await controller.markAttendance(
          eventId: widget.eventId,
          userId: entry.key,
          present: true,
        );
      }
    }

    setState(() => _isSaving = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Attendance saved successfully!'),
        backgroundColor: DarkColors.success,
      ),
    );

    Navigator.of(context).pop();
  }
}
