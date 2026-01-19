import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/glass.dart';
import '../../models/event_model.dart';
import '../../controllers/event_controller.dart';

class EventSearchScreen extends ConsumerStatefulWidget {
  const EventSearchScreen({super.key});

  @override
  ConsumerState<EventSearchScreen> createState() => _EventSearchScreenState();
}

class _EventSearchScreenState extends ConsumerState<EventSearchScreen> {
  late TextEditingController _searchController;
  String _selectedLocation = 'All';
  final String _selectedSalaryRange = 'All';
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(publishedEventsProvider(0));
    final filteredEvents = eventsAsync.whenData((events) {
      var filtered = events;

      // Filter by search query
      if (_searchController.text.isNotEmpty) {
        filtered = filtered
            .where(
              (event) =>
                  event.title.toLowerCase().contains(
                    _searchController.text.toLowerCase(),
                  ) ||
                  event.description!.toLowerCase().contains(
                    _searchController.text.toLowerCase(),
                  ) ||
                  event.company.toLowerCase().contains(
                    _searchController.text.toLowerCase(),
                  ),
            )
            .toList();
      }

      // Filter by location
      if (_selectedLocation != 'All') {
        filtered = filtered
            .where((event) => event.location == _selectedLocation)
            .toList();
      }

      return filtered;
    });

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: Text('Search Events', style: AppTypography.heading2),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.glassSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() {}),
                    style: AppTypography.body2,
                    decoration: InputDecoration(
                      hintText: 'Search events, companies...',
                      hintStyle: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      prefixIcon: Icon(Icons.search, color: AppColors.accent),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              color: AppColors.textSecondary,
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter Button
                GestureDetector(
                  onTap: () => setState(() => _showFilters = !_showFilters),
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showFilters ? Icons.filter_list : Icons.filter_list,
                          color: _showFilters
                              ? AppColors.accent
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _showFilters ? 'Hide Filters' : 'Show Filters',
                          style: AppTypography.caption.copyWith(
                            color: _showFilters
                                ? AppColors.accent
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filters Section
          if (_showFilters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location',
                    style: AppTypography.body1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                          'All',
                          'New York',
                          'Los Angeles',
                          'Chicago',
                          'Houston',
                          'Remote',
                        ].map((location) {
                          final isSelected = _selectedLocation == location;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedLocation = location),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.accent
                                    : AppColors.glassSecondary,
                                borderRadius: BorderRadius.circular(20),
                                border: isSelected
                                    ? Border.all(
                                        color: AppColors.accent,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: Text(
                                location,
                                style: AppTypography.caption.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

          // Events List
          Expanded(
            child: filteredEvents.when(
              data: (events) {
                if (events.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No events found',
                            style: AppTypography.heading3,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search or filters',
                            style: AppTypography.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return EventSearchCard(event: event);
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
                    Text('Searching events...', style: AppTypography.body2),
                  ],
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load events',
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
          ),
        ],
      ),
    );
  }
}

class EventSearchCard extends StatelessWidget {
  final EventModel event;

  const EventSearchCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      onTap: () => context.go('/event/${event.id}'),
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
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Description Preview
          if (event.description != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                event.description!,
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Details Grid
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

          // Capacity and Applicants
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text(
                    '${event.applicants}/${event.capacity} applied',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    event.rating!.toStringAsFixed(1),
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
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

  const _DetailItem({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.accent),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
