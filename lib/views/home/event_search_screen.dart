import 'package:flutter/material.dart';
import '../../core/utils/perf_log.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../models/event_model.dart';
import '../../controllers/event_controller.dart';
import '../common/skeleton_loader.dart';
import '../../services/file_upload_service.dart';

class EventSearchScreen extends ConsumerStatefulWidget {
  const EventSearchScreen({super.key});

  @override
  ConsumerState<EventSearchScreen> createState() => _EventSearchScreenState();
}

class _EventSearchScreenState extends ConsumerState<EventSearchScreen> {
  late TextEditingController _searchController;
  String _selectedLocation = 'All';
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    PerfLog.init('EventSearchScreen');
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    PerfLog.dispose('EventSearchScreen');
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    PerfLog.build('EventSearchScreen');
    final eventsAsync = ref.watch(publishedEventsProvider(0));

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _SearchHeaderDelegate(
                controller: _searchController,
                onChanged: (val) => setState(() {}),
                onToggleFilters: () =>
                    setState(() => _showFilters = !_showFilters),
                showFilters: _showFilters,
              ),
            ),
            if (_showFilters) _buildFiltersSection(),
            eventsAsync.when(
              data: (events) => _buildEventsList(events),
              loading: () => _buildLoadingState(),
              error: (e, _) => _buildErrorState(e),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    [
                      'All',
                      'New York',
                      'Los Angeles',
                      'Chicago',
                      'Houston',
                      'Remote',
                    ].map((loc) {
                      final isSelected = _selectedLocation == loc;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(loc),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedLocation = loc);
                            }
                          },
                          backgroundColor: AppColors.backgroundSecondary,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(List<EventModel> events) {
    var filtered = events;
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where(
            (e) =>
                e.title.toLowerCase().contains(query) ||
                (e.description?.toLowerCase().contains(query) ?? false) ||
                e.company.toLowerCase().contains(query),
          )
          .toList();
    }
    if (_selectedLocation != 'All') {
      filtered = filtered
          .where((e) => e.location?.city == _selectedLocation)
          .toList();
    }

    if (filtered.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off,
                size: 64,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 16),
              Text(
                'No events found',
                style: AppTypography.titleLarge.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search to find what you\'re looking for.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => _EventSearchCard(event: filtered[i]),
          childCount: filtered.length,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => const SkeletonCard(),
          childCount: 6,
        ),
      ),
    );
  }

  Widget _buildErrorState(Object e) {
    return SliverFillRemaining(
      child: Center(
        child: Text(
          'Error: $e',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onToggleFilters;
  final bool showFilters;

  _SearchHeaderDelegate({
    required this.controller,
    required this.onChanged,
    required this.onToggleFilters,
    required this.showFilters,
  });

  @override
  double get minExtent => 80;
  @override
  double get maxExtent => 80;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.backgroundPrimary,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: controller,
                autofocus: true,
                onChanged: onChanged,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search events, venues, or roles',
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggleFilters,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: showFilters ? AppColors.primary : AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                Icons.tune,
                color: showFilters ? Colors.white : AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) =>
      oldDelegate.showFilters != showFilters ||
      oldDelegate.controller != controller;
}

class _EventSearchCard extends ConsumerWidget {
  final EventModel event;

  const _EventSearchCard({required this.event});

  static final _timeFormatter = DateFormat('h:mm a');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeStr =
        '${_timeFormatter.format(event.startTime)} - ${_timeFormatter.format(event.endTime)}';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/event/${event.id}', extra: event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 80,
                height: 80,
                child: event.imagePath != null
                    ? CachedNetworkImage(
                        imageUrl: ref
                            .read(fileUploadServiceProvider)
                            .getPublicUrl(event.imagePath!),
                        memCacheHeight:
                            160, // Optimize memory for search thumbnails
                        memCacheWidth: 160,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const SkeletonLoader(
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: 12,
                        ),
                        errorWidget: (_, __, ___) =>
                            _ImagePlaceholder(event.categoryName ?? 'EVENT'),
                      )
                    : _ImagePlaceholder(event.categoryName ?? 'EVENT'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (event.categoryName ?? 'GENERAL').toUpperCase(),
                        style: AppTypography.labelLarge.copyWith(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Open',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.title,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (event.location?.address != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location!.address!,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final String label;
  const _ImagePlaceholder(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          label.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}
