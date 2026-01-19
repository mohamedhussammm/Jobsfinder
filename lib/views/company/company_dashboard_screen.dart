import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/glass.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/company_controller.dart';

class CompanyDashboardScreen extends ConsumerWidget {
  const CompanyDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser?.id ?? '';

    // Fetch company profile first
    final companyAsync = ref.watch(companyProfileProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: Text('Company Dashboard', style: AppTypography.heading2),
        centerTitle: false,
      ),
      body: companyAsync.when(
        data: (company) {
          // Once we have company, we can fetch stats and events
          final eventsAsync = ref.watch(companyEventsProvider(company.id));

          return SingleChildScrollView(
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
                        child: company.logoPath != null
                            ? Image.network(
                                company.logoPath!,
                                width: 32,
                                height: 32,
                              )
                            : Icon(
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
                            Text(
                              'Welcome, ${company.name}',
                              style: AppTypography.heading3,
                            ),
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
                eventsAsync.when(
                  data: (events) {
                    final activeCount = events
                        .where((e) => e.status == 'published')
                        .length;
                    // For demo, assuming verified means active or something similar
                    // In real app, we'd fetch applicants count separately

                    return Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.event,
                            label: 'Active Events',
                            value: activeCount.toString(),
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.people,
                            label: 'Total Events',
                            value: events.length.toString(),
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (_, __) => const Text('Error loading stats'),
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
                          // Show Create Event Dialog (reusing/adapting Admin logic or new one)
                          // For now, simpler implementation for Company
                          _showCreateEventDialog(context, ref, company.id);
                        },
                      ),
                      const Divider(height: 24),
                      _ActionButton(
                        icon: Icons.list_alt,
                        label: 'View My Events',
                        onTap: () {
                          // Navigation to events list
                          // For now, just a snackbar or simple list toggle
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Recent Events Section
                Text('Recent Events', style: AppTypography.heading3),
                const SizedBox(height: 12),
                eventsAsync.when(
                  data: (events) {
                    if (events.isEmpty) {
                      return GlassContainer(
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
                            ],
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: events
                          .take(3)
                          .map(
                            (e) => ListTile(
                              title: Text(
                                e.title,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                e.status,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey,
                                size: 16,
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error loading company profile: $e',
                style: const TextStyle(color: AppColors.error),
              ),
              if (e.toString().contains('COMPANY_NOT_FOUND'))
                ElevatedButton(
                  onPressed: () {
                    // Navigate to create company profile
                    // For now just show message
                  },
                  child: const Text('Create Company Profile'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateEventDialog(
    BuildContext context,
    WidgetRef ref,
    String companyId,
  ) {
    // Basic dialog for creating event request
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Event Request'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Event Title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(companyControllerProvider)
                  .createEventRequest(
                    companyId: companyId,
                    title: titleController.text,
                    description: 'Generated Description',
                    location: null,
                    startTime: DateTime.now().add(const Duration(days: 1)),
                    endTime: DateTime.now().add(
                      const Duration(days: 1, hours: 4),
                    ),
                    capacity: 100,
                    imagePath: null,
                  );
              Navigator.pop(context);
              ref.refresh(companyEventsProvider(companyId));
            },
            child: const Text('Request'),
          ),
        ],
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
