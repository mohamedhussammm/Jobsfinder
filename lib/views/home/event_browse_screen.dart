import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../controllers/event_controller.dart';
import '../../models/event_model.dart';
import '../../core/utils/responsive.dart';
import '../../models/category_model.dart';
import '../common/skeleton_loader.dart';
import '../../services/file_upload_service.dart';

// ─── Colors matching the reference design exactly ───────────────────────────
const _kBg = Color(0xFF111117);
const _kSurface = Color(0xFF1A1A23);
const _kPrimary = Color(0xFF176782);
const _kTextPrimary = Colors.white;
const _kTextSecondary = Color(0xFF94A3B8);
const _kGlassBorder = Color(0x14FFFFFF); // rgba(255,255,255,0.08)

class EventBrowseScreen extends ConsumerStatefulWidget {
  const EventBrowseScreen({super.key});

  @override
  ConsumerState<EventBrowseScreen> createState() => _EventBrowseScreenState();
}

class _EventBrowseScreenState extends ConsumerState<EventBrowseScreen> {
  String? _selectedCategoryId; // null = All

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(
      _selectedCategoryId == null
          ? publishedEventsByCategoryProvider(null)
          : publishedEventsByCategoryProvider(_selectedCategoryId),
    );
    final categoriesAsync = ref.watch(categoriesProvider);
    final heroAsync = ref.watch(publishedEventsByCategoryProvider(null));

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Sticky Search Bar (as SliverAppBar) ─────────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _SearchBarDelegate(),
            ),

            // ── Trending Hero Carousel ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Section header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CURATED LISTINGS',
                                style: AppTypography.labelLarge.copyWith(
                                  fontSize: ResponsiveHelper.sp(context, 10),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.8,
                                  color: _kPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Trending Near You',
                                style: AppTypography.headlineMedium.copyWith(
                                  fontSize: ResponsiveHelper.sp(context, 22),
                                  fontWeight: FontWeight.w900,
                                  color: _kTextPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/search'),
                          child: Text(
                            'See all',
                            style: AppTypography.bodySmall.copyWith(
                              color: _kPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: ResponsiveHelper.sp(context, 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Horizontal hero cards
                  SizedBox(
                    height:
                        MediaQuery.of(context).size.width *
                        1.0625, // aspect ~4/5 for 85% width
                    child: heroAsync.when(
                      data: (events) {
                        if (events.isEmpty) {
                          return const _EmptyHeroPlaceholder();
                        }
                        final displayEvents = events.take(5).toList();
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: displayEvents.length,
                          itemBuilder: (context, i) {
                            return RepaintBoundary(
                              child: _HeroEventCard(
                                event: displayEvents[i],
                                onTap: () => context.push(
                                  '/event/${displayEvents[i].id}',
                                  extra: displayEvents[i],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => SizedBox(
                        height: MediaQuery.of(context).size.width * 1.0625,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: 3,
                          itemBuilder: (context, i) => const SkeletonHeroCard(),
                        ),
                      ),
                      error: (e, _) => Center(
                        child: Text(
                          '$e',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Category Filter Chips ────────────────────────────────────────
            SliverToBoxAdapter(
              child: _CategoryChips(
                categoriesAsync: categoriesAsync,
                selectedCategoryId: _selectedCategoryId,
                onSelected: (id) => setState(() => _selectedCategoryId = id),
              ),
            ),

            // ── Available Shifts Header ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 4,
                  bottom: 12,
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt, color: _kPrimary, size: 22),
                    const SizedBox(width: 6),
                    Text(
                      'Available Shifts',
                      style: AppTypography.headlineMedium.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _kTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Shift List ───────────────────────────────────────────────────
            eventsAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_busy,
                              color: _kTextSecondary,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No shifts available',
                              style: TextStyle(
                                color: _kTextSecondary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => RepaintBoundary(
                        child: _ShiftCard(
                          event: events[i],
                          onTap: () => context.push(
                            '/event/${events[i].id}',
                            extra: events[i],
                          ),
                        ),
                      ),
                      childCount: events.length,
                    ),
                  ),
                );
              },
              loading: () => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => const SkeletonCard(),
                    childCount: 5,
                  ),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(
                  child: Text(
                    'Error loading events',
                    style: TextStyle(color: AppColors.error),
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

// ─── Sticky Search Bar ───────────────────────────────────────────────────────
class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 72;
  @override
  double get maxExtent => 72;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => context.push('/search'),
      child: Container(
        color: const Color(0xEE111117),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kGlassBorder),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(Icons.search, color: _kTextSecondary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search events, venues, or roles',
                        style: TextStyle(
                          color: _kTextSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kGlassBorder),
              ),
              child: Icon(Icons.tune, color: _kTextPrimary, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SearchBarDelegate oldDelegate) => false;
}

// ─── Hero Event Card (Trending Carousel) ─────────────────────────────────────
class _HeroEventCard extends ConsumerWidget {
  final EventModel event;
  final VoidCallback? onTap;

  const _HeroEventCard({required this.event, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = MediaQuery.of(context).size.width * 0.82;
    final dateStr = _formatDateRange(event.startTime, event.endTime);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: Container(
        width: w,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _kSurface,
        ),
        child: Stack(
          children: [
            // Background image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: event.imagePath != null
                  ? Image.network(
                      ref
                          .read(fileUploadServiceProvider)
                          .getPublicUrl(event.imagePath!),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _PlaceholderEventImage(title: event.title),
                    )
                  : _PlaceholderEventImage(title: event.title),
            ),
            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, _kBg.withValues(alpha: 0.85)],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),
            // Date badge top-left
            Positioned(
              top: 14,
              left: 14,
              child: _GlassBadge(
                child: Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            // Pay badge top-right
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  event.capacity != null ? '${event.capacity} spots' : 'Open',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Bottom info panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: _GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _kTextPrimary,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (event.categoryName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFD97706,
                                ).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                event.categoryName!.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (event.location?.address != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 13,
                              color: _kTextSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location!.address!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _kTextSecondary,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final fmt = DateFormat('MMM d');
    if (start.day == end.day && start.month == end.month) {
      return fmt.format(start);
    }
    return '${fmt.format(start)}-${end.day}';
  }
}

// ─── Category Chips ──────────────────────────────────────────────────────────
class _CategoryChips extends StatelessWidget {
  final AsyncValue<List<CategoryModel>> categoriesAsync;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelected;

  const _CategoryChips({
    required this.categoriesAsync,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: categoriesAsync.when(
        data: (categories) => ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            // "All" chip
            _Chip(
              label: 'All Categories',
              isSelected: selectedCategoryId == null,
              onTap: () => onSelected(null),
            ),
            ...categories.map(
              (cat) => _Chip(
                label: cat.name,
                isSelected: selectedCategoryId == cat.id,
                onTap: () => onSelected(cat.id),
              ),
            ),
          ],
        ),
        loading: () =>
            const Center(child: LinearProgressIndicator(color: _kPrimary)),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary : const Color(0xFF1E1E2A),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: isSelected ? _kPrimary : _kGlassBorder),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _kPrimary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveHelper.sp(context, 13),
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : _kTextSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Shift Card ──────────────────────────────────────────────────────────────
class _ShiftCard extends ConsumerWidget {
  final EventModel event;
  final VoidCallback? onTap;

  const _ShiftCard({required this.event, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeStr =
        '${DateFormat('h:mm a').format(event.startTime)} - ${DateFormat('h:mm a').format(event.endTime)}';
    final categoryLabel = event.categoryName ?? event.status.toUpperCase();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kGlassBorder),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 76,
                height: 76,
                child: event.imagePath != null
                    ? CachedNetworkImage(
                        imageUrl: ref
                            .read(fileUploadServiceProvider)
                            .getPublicUrl(event.imagePath!),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const SkeletonCard(),
                        errorWidget: (context, url, error) =>
                            _SmallImagePlaceholder(categoryLabel),
                      )
                    : _SmallImagePlaceholder(categoryLabel),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          categoryLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: ResponsiveHelper.sp(context, 10),
                            fontWeight: FontWeight.w800,
                            color: _kPrimary,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          event.capacity != null
                              ? '${event.capacity} spots'
                              : 'Open',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.sp(context, 13),
                            fontWeight: FontWeight.w800,
                            color: _kTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.sp(context, 15),
                      fontWeight: FontWeight.w800,
                      color: _kTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.sp(context, 11),
                            color: _kTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (event.location?.address != null) ...[
                        Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.sp(context, 11),
                            color: _kTextSecondary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            event.location!.address!,
                            style: TextStyle(
                              fontSize: ResponsiveHelper.sp(context, 11),
                              color: _kTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Chevron
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right,
                color: _kPrimary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────
class _GlassPanel extends StatelessWidget {
  final Widget child;
  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kGlassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  final Widget child;
  const _GlassBadge({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kGlassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PlaceholderEventImage extends StatelessWidget {
  final String title;
  const _PlaceholderEventImage({required this.title});

  @override
  Widget build(BuildContext context) {
    // Generate a gradient based on title hash for visual variety
    final hue = (title.hashCode.abs() % 360).toDouble();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSLColor.fromAHSL(1, hue, 0.5, 0.25).toColor(),
            HSLColor.fromAHSL(1, (hue + 40) % 360, 0.4, 0.15).toColor(),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.event,
          size: 60,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _SmallImagePlaceholder extends StatelessWidget {
  final String label;
  const _SmallImagePlaceholder(this.label);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (label.toLowerCase()) {
      case 'barista':
        icon = Icons.coffee;
        break;
      case 'security':
      case 'event security':
        icon = Icons.security;
        break;
      case 'waitstaff':
      case 'hospitality':
        icon = Icons.restaurant;
        break;
      case 'cleaning':
        icon = Icons.cleaning_services;
        break;
      case 'retail':
        icon = Icons.store;
        break;
      case 'warehouse':
        icon = Icons.warehouse;
        break;
      case 'driving':
        icon = Icons.drive_eta;
        break;
      default:
        icon = Icons.work_outline;
    }
    return Container(
      color: _kPrimary.withValues(alpha: 0.15),
      child: Center(child: Icon(icon, color: _kPrimary, size: 28)),
    );
  }
}

class _EmptyHeroPlaceholder extends StatelessWidget {
  const _EmptyHeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note, size: 48, color: _kTextSecondary),
          const SizedBox(height: 8),
          Text('No trending events', style: TextStyle(color: _kTextSecondary)),
        ],
      ),
    );
  }
}
