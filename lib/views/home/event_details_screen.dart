import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/event_model.dart';
import '../../controllers/event_controller.dart';

class EventDetailsScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends ConsumerState<EventDetailsScreen> {
  bool _descExpanded = false;

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailsProvider(widget.eventId));

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: eventAsync.when(
        data: (event) => _buildBody(context, event),
        loading: () => _buildLoading(),
        error: (e, _) => _buildError(e),
      ),
    );
  }

  Widget _buildBody(BuildContext context, EventModel event) {
    return Stack(
      children: [
        // Scrollable content
        CustomScrollView(
          slivers: [
            // ── Hero image with back + share buttons ──────────────────────
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: const Color(0xFF0D1117),
              elevation: 0,
              leading: _circleButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
              actions: [
                _circleButton(
                  icon: Icons.ios_share_rounded,
                  onTap: () => _shareEvent(event),
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeroImage(event),
              ),
            ),

            // ── Main content card ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D1117),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      // ── Tag chips ───────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            _chip(
                              'HIGH PAY',
                              const Color(0xFF1A3A2A),
                              const Color(0xFF4ADE80),
                            ),
                            _chip(
                              'INSTANT BOOK',
                              const Color(0xFF1A2A3A),
                              const Color(0xFF60A5FA),
                            ),
                            if (event.isUpcoming)
                              _chip(
                                'UPCOMING',
                                const Color(0xFF2A1A3A),
                                const Color(0xFFA78BFA),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Title + Company ─────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              event.company,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Date / Shift / Rate info row ────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF161B22),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.07),
                            ),
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                _infoCell(
                                  icon: Icons.calendar_today_rounded,
                                  label: 'DATE',
                                  value: _formatDate(event.startTime),
                                  color: const Color(0xFF60A5FA),
                                ),
                                _verticalDivider(),
                                _infoCell(
                                  icon: Icons.schedule_rounded,
                                  label: 'SHIFT',
                                  value:
                                      '${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}',
                                  color: const Color(0xFF34D399),
                                ),
                                _verticalDivider(),
                                _infoCell(
                                  icon: Icons.people_rounded,
                                  label: 'SPOTS',
                                  value: event.capacity != null
                                      ? '${event.capacity}'
                                      : '∞',
                                  color: const Color(0xFFFBBF24),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── About the Role ──────────────────────────────────
                      _sectionHeader('About the Role'),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161B22),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.07),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.description ??
                                    'No description provided for this event.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.72),
                                  height: 1.65,
                                ),
                                maxLines: _descExpanded ? null : 4,
                                overflow: _descExpanded
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                              ),
                              if ((event.description?.length ?? 0) > 200) ...[
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _descExpanded = !_descExpanded,
                                  ),
                                  child: Text(
                                    _descExpanded ? 'Show Less' : 'Read More',
                                    style: const TextStyle(
                                      color: Color(0xFF60A5FA),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Requirements ────────────────────────────────────
                      _sectionHeader('Requirements'),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _requirementItem(
                              icon: Icons.verified_user_rounded,
                              title: 'Valid ID Required',
                              subtitle: 'Government-issued identification',
                              color: const Color(0xFF60A5FA),
                            ),
                            const SizedBox(height: 10),
                            _requirementItem(
                              icon: Icons.work_outline_rounded,
                              title: 'Professional Attire',
                              subtitle: 'Smart casual or as specified',
                              color: const Color(0xFF34D399),
                            ),
                            const SizedBox(height: 10),
                            _requirementItem(
                              icon: Icons.star_outline_rounded,
                              title: 'Experience Preferred',
                              subtitle: 'Relevant background is a plus',
                              color: const Color(0xFFFBBF24),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Location ────────────────────────────────────────
                      if (event.location != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _sectionTitle('Location'),
                              if (event.location?.city != 'Unknown')
                                Text(
                                  event.location!.city,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.45),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildMapSection(event),
                        ),
                        const SizedBox(height: 28),
                      ],

                      // Bottom padding for sticky button
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // ── Sticky Apply Now button ───────────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildApplyButton(context, event),
        ),
      ],
    );
  }

  // ── Hero image ────────────────────────────────────────────────────────────
  Widget _buildHeroImage(EventModel event) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image or gradient
        if (event.imagePath != null)
          Image.network(
            event.imagePath!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _gradientHero(event),
          )
        else
          _gradientHero(event),

        // Dark overlay gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                const Color(0xFF0D1117).withValues(alpha: 0.85),
              ],
              stops: const [0.4, 1.0],
            ),
          ),
        ),

        // Status badge bottom-left
        Positioned(bottom: 36, left: 20, child: _statusBadge(event.status)),
      ],
    );
  }

  Widget _gradientHero(EventModel event) {
    final colors = _heroColors(event.status);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.event_rounded,
          size: 80,
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
    );
  }

  List<Color> _heroColors(String status) {
    switch (status) {
      case 'published':
        return [const Color(0xFF0F4C35), const Color(0xFF1A6B4A)];
      case 'pending':
        return [const Color(0xFF4C3A0F), const Color(0xFF6B541A)];
      case 'completed':
        return [const Color(0xFF0F2A4C), const Color(0xFF1A3F6B)];
      default:
        return [const Color(0xFF1A1A2E), const Color(0xFF16213E)];
    }
  }

  // ── Map section ───────────────────────────────────────────────────────────
  Widget _buildMapSection(EventModel event) {
    final hasCoords =
        event.location?.lat != null && event.location?.lng != null;

    return GestureDetector(
      onTap: () => _openMap(event),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF161B22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Map placeholder with grid pattern
              CustomPaint(painter: _MapGridPainter()),

              // Center pin
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF60A5FA),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF60A5FA,
                            ).withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1117).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.location?.address ?? 'View on map',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Tap to open overlay
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF60A5FA).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF60A5FA).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.open_in_new_rounded,
                        size: 12,
                        color: Color(0xFF60A5FA),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasCoords ? 'Open Maps' : 'Search Location',
                        style: const TextStyle(
                          color: Color(0xFF60A5FA),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Apply Now sticky button ───────────────────────────────────────────────
  Widget _buildApplyButton(BuildContext context, EventModel event) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: event.isPublished
              ? () => context.push('/apply/${event.id}', extra: event.title)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E4D6B),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.3),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                event.isPublished ? 'APPLY NOW' : 'NOT AVAILABLE',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              if (event.isPublished) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, size: 16),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _infoCell({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.4),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white.withValues(alpha: 0.08),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF60A5FA),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF60A5FA),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _requirementItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final (color, label) = switch (status) {
      'published' => (const Color(0xFF4ADE80), 'Published'),
      'pending' => (const Color(0xFFFBBF24), 'Pending'),
      'completed' => (const Color(0xFF60A5FA), 'Completed'),
      'cancelled' => (const Color(0xFFF87171), 'Cancelled'),
      _ => (Colors.white54, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Date/time formatters ──────────────────────────────────────────────────
  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> _openMap(EventModel event) async {
    final loc = event.location;
    if (loc == null) return;

    Uri uri;
    if (loc.lat != null && loc.lng != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${loc.lat},${loc.lng}',
      );
    } else if (loc.address != null) {
      final encoded = Uri.encodeComponent(loc.address!);
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encoded',
      );
    } else {
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareEvent(EventModel event) {
    // Share functionality — can be wired to share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing: ${event.title}'),
        backgroundColor: const Color(0xFF1E4D6B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Loading / Error states ────────────────────────────────────────────────
  Widget _buildLoading() {
    return const Scaffold(
      backgroundColor: Color(0xFF0D1117),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF60A5FA))),
    );
  }

  Widget _buildError(Object error) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Color(0xFFF87171),
              ),
              const SizedBox(height: 16),
              const Text(
                'Could not load event',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Map grid painter (decorative placeholder) ─────────────────────────────────
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;

    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw some "road" lines
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, size.height * 0.4),
      Offset(size.width, size.height * 0.4),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, 0),
      Offset(size.width * 0.35, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.7, size.height),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
