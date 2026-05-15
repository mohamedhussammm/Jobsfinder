import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/dark_colors.dart';
import '../../models/event_model.dart';
import '../../controllers/event_controller.dart';
import '../../controllers/auth_controller.dart';
import 'package:intl/intl.dart';
import '../../services/file_upload_service.dart';

class EventDetailsScreen extends ConsumerStatefulWidget {
  final String eventId;
  final EventModel? initialEvent;

  const EventDetailsScreen({
    super.key,
    required this.eventId,
    this.initialEvent,
  });

  @override
  ConsumerState<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends ConsumerState<EventDetailsScreen> {
  bool _descExpanded = false;

  static final _dateFormatter = DateFormat('EEE, MMM d, yyyy');
  static final _timeFormatter = DateFormat('hh:mm a');

  String _formatDate(DateTime date) => _dateFormatter.format(date);
  String _formatTime(DateTime date) => _timeFormatter.format(date);

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailsProvider(widget.eventId));
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: eventAsync.when(
        data: (event) => _buildBody(context, event, theme, mq),
        loading: () {
          if (widget.initialEvent != null) {
            return _buildBody(context, widget.initialEvent!, theme, mq);
          }
          return _buildLoading();
        },
        error: (e, _) {
          if (widget.initialEvent != null) {
            return _buildBody(context, widget.initialEvent!, theme, mq);
          }
          return _buildError(e);
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    EventModel event,
    ThemeData theme,
    MediaQueryData mq,
  ) {
    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _HeroSection(event: event, onShare: () => _shareEvent(event)),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _TagsSection(event: event),
                      const SizedBox(height: 16),
                      _TitleSection(event: event),
                      const SizedBox(height: 24),
                      _InfoGridSection(
                        event: event,
                        formatDate: _formatDate,
                        formatTime: _formatTime,
                      ),
                      const SizedBox(height: 28),
                      _DescriptionSection(
                        description: event.description,
                        isExpanded: _descExpanded,
                        onToggle: () =>
                            setState(() => _descExpanded = !_descExpanded),
                      ),
                      const SizedBox(height: 28),
                      if (event.requirements?.isNotEmpty ?? false) ...[
                        _RequirementSection(requirements: event.requirements!),
                        const SizedBox(height: 28),
                      ],
                      if (event.benefits?.isNotEmpty ?? false) ...[
                        _BenefitSection(benefits: event.benefits!),
                        const SizedBox(height: 28),
                      ],
                      if ((event.contactEmail?.isNotEmpty ?? false) ||
                          (event.contactPhone?.isNotEmpty ?? false)) ...[
                        _ContactSection(event: event),
                        const SizedBox(height: 28),
                      ],
                      if (event.location != null) ...[
                        _LocationSection(
                          event: event,
                          onOpenMap: () => _openMap(event),
                        ),
                        const SizedBox(height: 28),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildApplyButton(context, event),
        ),
      ],
    );
  }

  void _showProfileIncompleteDialog(BuildContext context) {
    // Capture the outer screen context before entering the dialog builder
    // so we can safely navigate after the dialog is dismissed.
    final outerContext = context;

    showDialog(
      context: outerContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DarkColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: DarkColors.error),
            SizedBox(width: 12),
            Text('Profile Incomplete', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To apply for events, your profile must be 100% complete. This includes:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '• Profile Photo & Full Name',
              style: TextStyle(color: DarkColors.textSecondary),
            ),
            Text(
              '• Phone Number & Age (16+)',
              style: TextStyle(color: DarkColors.textSecondary),
            ),
            Text(
              '• National ID Number',
              style: TextStyle(color: DarkColors.textSecondary),
            ),
            Text(
              '• National ID Photos (Front & Back)',
              style: TextStyle(color: DarkColors.textSecondary),
            ),
            Text(
              '• Professional CV',
              style: TextStyle(color: DarkColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Later',
              style: TextStyle(color: DarkColors.textTertiary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Dismiss dialog using dialog's own context
              Navigator.of(dialogContext).pop();
              // Navigate using the outer screen context (GoRouter-aware)
              outerContext.push('/edit-profile');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DarkColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Complete Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton(BuildContext context, EventModel event) {
    final user = ref.watch(currentUserProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: event.isPublished
              ? () {
                  if (user == null) {
                    context.push('/auth');
                    return;
                  }

                  if (user.profileCompletion < 1.0) {
                    _showProfileIncompleteDialog(context);
                    return;
                  }

                  context.push('/apply/${event.id}', extra: event.title);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: DarkColors.primary,
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
  void _shareEvent(EventModel event) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing: ${event.title}'),
        backgroundColor: const Color(0xFF1E4D6B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _openMap(EventModel event) {
    final loc = event.location;
    if (loc == null) return;
    final query = loc.lat != null && loc.lng != null
        ? '${loc.lat},${loc.lng}'
        : Uri.encodeComponent(loc.address ?? '');
    launchUrl(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'),
      mode: LaunchMode.externalApplication,
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

class _HeroSection extends ConsumerWidget {
  final EventModel event;
  final VoidCallback onShare;
  const _HeroSection({required this.event, required this.onShare});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: _circleButton(
        context: context,
        icon: Icons.arrow_back_ios_new_rounded,
        onTap: () => Navigator.of(context).pop(),
      ),
      actions: [
        _circleButton(
          context: context,
          icon: Icons.ios_share_rounded,
          onTap: onShare,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (event.imagePath != null)
              CachedNetworkImage(
                imageUrl: ref
                    .read(fileUploadServiceProvider)
                    .getPublicUrl(event.imagePath!),
                fit: BoxFit.cover,
                memCacheHeight: 800,
                placeholder: (context, url) =>
                    _GradientHero(status: event.status),
                errorWidget: (context, url, error) =>
                    _GradientHero(status: event.status),
              )
            else
              _GradientHero(status: event.status),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Theme.of(
                      context,
                    ).scaffoldBackgroundColor.withValues(alpha: 0.85),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 36,
              left: 20,
              child: _StatusBadge(status: event.status),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _circleButton({
  required BuildContext context,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.only(left: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).scaffoldBackgroundColor.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _statusColor(status).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _statusColor(status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: _statusColor(status),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'published':
        return const Color(0xFF4ADE80);
      case 'pending':
        return const Color(0xFFFBBF24);
      case 'completed':
        return const Color(0xFF60A5FA);
      default:
        return Colors.white70;
    }
  }
}

class _GradientHero extends StatelessWidget {
  final String status;
  const _GradientHero({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _heroColors(status),
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
}

class _TagsSection extends StatelessWidget {
  final EventModel event;
  const _TagsSection({required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          if (event.isUrgent)
            _tagChip(
              '🔥 URGENT',
              const Color(0xFF3A1A1A),
              const Color(0xFFF87171),
            ),
          if (event.salary != null && event.salary! > 0)
            _tagChip(
              'SAR ${event.salary!.toStringAsFixed(0)}',
              const Color(0xFF1A3A2A),
              const Color(0xFF4ADE80),
            ),
          _tagChip(
            'Instant Book',
            const Color(0xFF1A2A3A),
            const Color(0xFF60A5FA),
          ),
          if (event.isUpcoming)
            _tagChip(
              'Upcoming',
              const Color(0xFF2A1A3A),
              const Color(0xFFA78BFA),
            ),
          ...event.tags.map(
            (tag) => _tagChip(
              tag.toUpperCase(),
              const Color(0xFF1A2A2A),
              const Color(0xFF67E8F9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagChip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _TitleSection extends StatelessWidget {
  final EventModel event;
  const _TitleSection({required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}

class _InfoGridSection extends StatelessWidget {
  final EventModel event;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatTime;

  const _InfoGridSection({
    required this.event,
    required this.formatDate,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              _infoCell(
                icon: Icons.calendar_today_rounded,
                label: 'Date',
                value: formatDate(event.startTime),
                color: const Color(0xFF60A5FA),
              ),
              _verticalDivider(),
              _infoCell(
                icon: Icons.schedule_rounded,
                label: 'Shift',
                value:
                    '${formatTime(event.startTime)} - ${formatTime(event.endTime)}',
                color: const Color(0xFF34D399),
              ),
              _verticalDivider(),
              _infoCell(
                icon: Icons.people_rounded,
                label: 'CAPACITY',
                value: event.capacity != null ? '${event.capacity}' : '∞',
                color: const Color(0xFFFBBF24),
              ),
            ],
          ),
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 9,
                color: Colors.white38,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withValues(alpha: 0.07),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  final String? description;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _DescriptionSection({
    required this.description,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('About the Role'),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description ?? 'No description provided for this event.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.72),
                      height: 1.65,
                    ),
                    maxLines: isExpanded ? null : 4,
                    overflow: isExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                  ),
                  if ((description?.length ?? 0) > 200) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: onToggle,
                      child: Text(
                        isExpanded ? 'Show Less' : 'Read More',
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
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class _RequirementSection extends StatelessWidget {
  final String requirements;
  const _RequirementSection({required this.requirements});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Requirements'),
        const SizedBox(height: 12),
        _ContentBox(
          icon: Icons.checklist_rounded,
          iconColor: const Color(0xFF60A5FA),
          text: requirements,
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class _BenefitSection extends StatelessWidget {
  final String benefits;
  const _BenefitSection({required this.benefits});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Benefits'),
        const SizedBox(height: 12),
        _ContentBox(
          icon: Icons.card_giftcard_rounded,
          iconColor: const Color(0xFF4ADE80),
          text: benefits,
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class _ContentBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _ContentBox({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.72),
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  final EventModel event;
  const _ContactSection({required this.event});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Contact'),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Column(
              children: [
                if (event.contactEmail?.isNotEmpty ?? false)
                  _contactRow(
                    Icons.email_outlined,
                    event.contactEmail!,
                    const Color(0xFF60A5FA),
                    () => launchUrl(Uri.parse('mailto:${event.contactEmail}')),
                  ),
                if ((event.contactEmail?.isNotEmpty ?? false) &&
                    (event.contactPhone?.isNotEmpty ?? false))
                  const SizedBox(height: 10),
                if (event.contactPhone?.isNotEmpty ?? false)
                  _contactRow(
                    Icons.phone_outlined,
                    event.contactPhone!,
                    const Color(0xFF4ADE80),
                    () => launchUrl(Uri.parse('tel:${event.contactPhone}')),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _contactRow(
    IconData icon,
    String text,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.open_in_new_rounded,
            size: 14,
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

class _LocationSection extends StatelessWidget {
  final EventModel event;
  final VoidCallback onOpenMap;
  const _LocationSection({required this.event, required this.onOpenMap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              if (event.location?.city != 'Unknown')
                Text(
                  event.location!.city,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _MapBox(event: event, onOpenMap: onOpenMap),
      ],
    );
  }
}

class _MapBox extends StatelessWidget {
  final EventModel event;
  final VoidCallback onOpenMap;
  const _MapBox({required this.event, required this.onOpenMap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: onOpenMap,
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).cardColor,
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _MapGridPainter()),
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
                      const SizedBox(height: 8),
                      Text(
                        event.location?.address ?? 'View on map',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
