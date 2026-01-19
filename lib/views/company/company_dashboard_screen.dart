import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/glass.dart';

class CompanyDashboardScreen extends ConsumerWidget {
  const CompanyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: Text('Company Dashboard', style: AppTypography.heading2),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.business,
                      color: AppColors.accent,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome Back!', style: AppTypography.heading3),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your events and applications',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.event,
                    label: 'Active Events',
                    value: '0',
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.people,
                    label: 'Total Applicants',
                    value: '0',
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Text('Quick Actions', style: AppTypography.heading3),
            const SizedBox(height: 12),
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ActionButton(
                    icon: Icons.add_circle,
                    label: 'Create New Event',
                    onTap: () {
                      // TODO: Navigate to create event screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Create Event feature coming soon!'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 24),
                  _ActionButton(
                    icon: Icons.list_alt,
                    label: 'View My Events',
                    onTap: () {
                      // TODO: Navigate to company events list
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Events list feature coming soon!'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 24),
                  _ActionButton(
                    icon: Icons.assignment,
                    label: 'Review Applications',
                    onTap: () {
                      // TODO: Navigate to applications review
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Applications review coming soon!'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recent Events Section
            Text('Recent Events', style: AppTypography.heading3),
            const SizedBox(height: 12),
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_note,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No events yet',
                      style: AppTypography.body1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first event to get started',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.displayLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppTypography.body1)),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
