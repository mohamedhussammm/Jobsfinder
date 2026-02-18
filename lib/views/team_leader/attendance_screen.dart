import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/team_leader_controller.dart';
import '../../controllers/application_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/application_model.dart';

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
      appBar: AppBar(
        title: Text('Attendance: ${widget.eventTitle}'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveAttendance,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Save'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
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
                    color: AppColors.gray300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No accepted applicants',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.sp(context, 16),
                      color: AppColors.textSecondary,
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

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isPresent
                        ? AppColors.success
                        : AppColors.borderColor,
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
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.gray100,
                            child: Icon(
                              Icons.person,
                              color: isPresent
                                  ? AppColors.success
                                  : AppColors.gray400,
                              size: ResponsiveHelper.sp(context, 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Applicant',
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper.sp(context, 15),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'ID: ${app.userId.substring(0, 8)}...',
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper.sp(context, 12),
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Rate button — only visible when marked present
                          if (isPresent)
                            IconButton(
                              icon: const Icon(Icons.star_rate_rounded),
                              color: AppColors.warning,
                              tooltip: 'Rate applicant',
                              onPressed: () => _navigateToRate(app),
                            ),
                          Switch(
                            value: isPresent,
                            onChanged: (val) {
                              setState(() => _attendance[app.userId] = val);
                            },
                            activeThumbColor: AppColors.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Attendance label
                      Text(
                        isPresent ? '✓ Present' : '✗ Absent',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.sp(context, 13),
                          fontWeight: FontWeight.w600,
                          color: isPresent
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Notes
                      TextField(
                        controller: _notesControllers[app.userId]!,
                        decoration: InputDecoration(
                          hintText: 'Notes (optional)',
                          filled: true,
                          fillColor: AppColors.gray50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: ResponsiveHelper.sp(context, 13),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _navigateToRate(ApplicationModel app) {
    context.push(
      '/rate/${app.userId}'
      '?name=Applicant'
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
      const SnackBar(
        content: Text('Attendance saved successfully!'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.of(context).pop();
  }
}
