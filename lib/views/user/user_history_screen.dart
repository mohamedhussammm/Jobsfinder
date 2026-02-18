import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/application_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/responsive.dart';

class UserHistoryScreen extends ConsumerWidget {
  const UserHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    final applicationsAsync = ref.watch(
      userApplicationsProvider(currentUser.id),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('History'), centerTitle: true),
      body: applicationsAsync.when(
        data: (apps) {
          // Filter to completed/accepted/declined
          final history = apps
              .where(
                (a) =>
                    a.status == 'accepted' ||
                    a.status == 'declined' ||
                    a.status == 'rejected',
              )
              .toList();

          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: ResponsiveHelper.sp(context, 64),
                    color: AppColors.gray300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No history yet',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.sp(context, 18),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your completed and past applications will appear here',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.sp(context, 14),
                      color: AppColors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: ResponsiveHelper.screenPadding(context),
            itemCount: history.length,
            separatorBuilder: (_, i) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final app = history[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.borderColor),
                ),
                child: Padding(
                  padding: ResponsiveHelper.cardPadding(context),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 48,
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
                              'Application #${app.id.substring(0, 8)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: ResponsiveHelper.sp(context, 14),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Applied ${app.appliedAt.day}/${app.appliedAt.month}/${app.appliedAt.year}',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.sp(context, 12),
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(
                            app.status,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          app.status.toUpperCase(),
                          style: TextStyle(
                            color: _statusColor(app.status),
                            fontWeight: FontWeight.w700,
                            fontSize: ResponsiveHelper.sp(context, 11),
                          ),
                        ),
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

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return AppColors.success;
      case 'rejected':
      case 'declined':
        return AppColors.error;
      default:
        return AppColors.gray400;
    }
  }
}
