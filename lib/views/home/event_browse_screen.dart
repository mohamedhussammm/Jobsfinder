import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../controllers/event_controller.dart';
import 'event_card.dart';

class EventBrowseScreen extends ConsumerWidget {
  const EventBrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(publishedEventsProvider(0));

    return Scaffold(
      appBar: AppBar(
        title: Text('Events', style: AppTypography.heading2),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      drawer: Drawer(
        backgroundColor: AppColors.darkBg,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.accent,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text('Welcome!', style: AppTypography.heading3),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.person_outline,
                color: AppColors.textSecondary,
              ),
              title: Text('Profile', style: AppTypography.body1),
              onTap: () {
                Navigator.pop(context); // Close drawer
                // Navigate to profile
                context.push('/profile');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.work_outline,
                color: AppColors.textSecondary,
              ),
              title: Text('My Applications', style: AppTypography.body1),
              onTap: () {
                Navigator.pop(context);
                context.push('/applications');
              },
            ),
            Divider(color: AppColors.textSecondary.withOpacity(0.2)),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text(
                'Logout',
                style: AppTypography.body1.copyWith(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                // Logout logic
                context.go('/auth');
              },
            ),
          ],
        ),
      ),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No events available',
                    style: AppTypography.body1.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return EventCard(event: event);
            },
          );
        },
        loading: () =>
            Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Error loading events',
                style: AppTypography.body1.copyWith(color: AppColors.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
