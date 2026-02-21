import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/dark_colors.dart';
import '../../core/theme/typography.dart';
import '../../models/event_model.dart';
import '../../controllers/event_controller.dart';
import '../common/skeleton_loader.dart';

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

    return Scaffold(
      backgroundColor: DarkColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Sticky Search Header
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

            // Filters Section
            if (_showFilters)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.location,
                        style: AppTypography.labelLarge.copyWith(
                          color: DarkColors.primary,
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
                                    backgroundColor: DarkColors.gray100,
                                    selectedColor: DarkColors.primary,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : DarkColors.textSecondary,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    side: BorderSide(
                                      color: isSelected
                                          ? DarkColors.primary
                                          : DarkColors.borderColor,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Events List
            eventsAsync.when(
              data: (events) {
                // Apply logic filters
                var filtered = events;
                if (_searchController.text.isNotEmpty) {
                  final query = _searchController.text.toLowerCase();
                  filtered = filtered
                      .where(
                        (e) =>
                            e.title.toLowerCase().contains(query) ||
                            (e.description?.toLowerCase().contains(query) ??
                                false) ||
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
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: DarkColors.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.noEventsFound,
                            style: AppTypography.titleLarge.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.tryAdjustingSearch,
                            style: AppTypography.bodyMedium.copyWith(
                              color: DarkColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _EventSearchCard(event: filtered[i]),
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
              loading: () => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => const SkeletonCard(),
                    childCount: 6,
                  ),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(color: DarkColors.error),
                  ),
                ),
              ),
            ),
          ],
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
  double get minExtent => 88;
  @override
  double get maxExtent => 88;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: DarkColors.background.withValues(alpha: 0.8),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: DarkColors.gray100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: DarkColors.borderColor),
                  ),
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchHint,
                      hintStyle: const TextStyle(
                        color: DarkColors.textSecondary,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: DarkColors.textSecondary,
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
                onTap: onToggleFilters,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: showFilters
                        ? DarkColors.primary
                        : DarkColors.gray100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: DarkColors.borderColor),
                  ),
                  child: Icon(
                    Icons.tune,
                    color: showFilters ? Colors.white : DarkColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) =>
      oldDelegate.showFilters != showFilters ||
      oldDelegate.controller != controller;
}

class _EventSearchCard extends StatelessWidget {
  final EventModel event;

  const _EventSearchCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${DateFormat('h:mm a').format(event.startTime)} - ${DateFormat('h:mm a').format(event.endTime)}';

    return GestureDetector(
      onTap: () => context.push('/event/${event.id}', extra: event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DarkColors.gray100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DarkColors.borderColor),
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
                        imageUrl: event.imagePath!,
                        fit: BoxFit.cover,
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
                          color: DarkColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.spots(event.capacity ?? 0),
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.title,
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white,
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
                        color: DarkColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: DarkColors.textSecondary,
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
                          color: DarkColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location!.address!,
                            style: TextStyle(
                              color: DarkColors.textSecondary,
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
                color: DarkColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right,
                color: DarkColors.primary,
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
      color: DarkColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          label.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: DarkColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}
