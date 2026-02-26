import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../controllers/event_controller.dart';
import '../../../controllers/admin_controller.dart';
import '../../../controllers/analytics_controller.dart';
import '../../../services/file_upload_service.dart';
import '../../../models/event_model.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/theme/dark_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/result.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../common/skeleton_loader.dart';

class AdminEventsScreen extends ConsumerStatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  ConsumerState<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends ConsumerState<AdminEventsScreen> {
  String _statusFilter = 'all'; // 'all', 'pending', 'published', 'cancelled'

  @override
  Widget build(BuildContext context) {
    // For admin, we ideally want ALL events, but for now we might reuse published or pending providers
    // Or simpler: fetch pending requests specifically if filtered, else fetch published
    // Ideally we need a 'getAllEvents' in admin controller, but let's use what we have or combine

    // Using pendingEventsAdminProvider for 'pending' filter
    // Using publishedEventsProvider for 'published' filter

    AsyncValue<List<EventModel>> eventsAsync;
    if (_statusFilter == 'pending') {
      eventsAsync = ref.watch(pendingEventsAdminProvider);
    } else {
      // Fallback for demo: show published events when not pending, or all if we had an all provider
      eventsAsync = ref.watch(publishedEventsProvider(0));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Event Management',
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontSize: ResponsiveHelper.sp(context, 20),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showCreateEventDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Create Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DarkColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Published', 'published'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: DarkColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DarkColors.borderColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: eventsAsync.when(
                data: (events) {
                  if (events.isEmpty) {
                    return Center(
                      child: Text(
                        'No events found',
                        style: AppTypography.body1.copyWith(
                          color: DarkColors.textTertiary,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: events.length,
                    separatorBuilder: (_, i) =>
                        const Divider(color: AppColors.borderColor),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final isMobile = ResponsiveHelper.isPhone(context);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            // Leading Image
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(8),
                                image: event.imagePath != null
                                    ? DecorationImage(
                                        image: CachedNetworkImageProvider(
                                          ref
                                              .read(fileUploadServiceProvider)
                                              .getPublicUrl(event.imagePath!),
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: event.imagePath == null
                                  ? const Icon(
                                      Icons.event,
                                      color: AppColors.textSecondary,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),

                            // Event Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    event.title,
                                    style: AppTypography.body1.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${event.companyId} • ${event.startTime.toString().split(' ')[0]}',
                                    style: TextStyle(
                                      color: DarkColors.textTertiary,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Actions
                            if (isMobile)
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white70,
                                ),
                                color: DarkColors.surface,
                                onSelected: (value) {
                                  switch (value) {
                                    case 'approve':
                                      _approveEvent(event.id);
                                      break;
                                    case 'reject':
                                      _rejectEvent(event.id);
                                      break;
                                    case 'edit':
                                      _showEditEventDialog(context, event);
                                      break;
                                    case 'delete':
                                      _deleteEvent(event.id);
                                      break;
                                    case 'assign':
                                      showDialog(
                                        context: context,
                                        builder: (context) =>
                                            _AssignTeamLeaderDialog(
                                              event: event,
                                            ),
                                      );
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  if (event.status == 'pending') ...[
                                    const PopupMenuItem(
                                      value: 'approve',
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.check_circle,
                                          color: DarkColors.success,
                                          size: 20,
                                        ),
                                        title: Text(
                                          'Approve',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        dense: true,
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'reject',
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.cancel,
                                          color: DarkColors.error,
                                          size: 20,
                                        ),
                                        title: Text(
                                          'Reject',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        dense: true,
                                      ),
                                    ),
                                  ],
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.edit_outlined,
                                        color: DarkColors.accent,
                                        size: 20,
                                      ),
                                      title: Text(
                                        'Edit',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      dense: true,
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'assign',
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.person_add_alt_1,
                                        color: DarkColors.accent,
                                        size: 20,
                                      ),
                                      title: Text(
                                        'Assign TL',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      dense: true,
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.delete_outline,
                                        color: DarkColors.error,
                                        size: 20,
                                      ),
                                      title: Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      dense: true,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildStatusBadge(event.status),
                                  const SizedBox(width: 8),
                                  if (event.status == 'pending') ...[
                                    IconButton(
                                      icon: const Icon(
                                        Icons.check_circle,
                                        color: DarkColors.success,
                                        size: 20,
                                      ),
                                      onPressed: () => _approveEvent(event.id),
                                      tooltip: 'Approve',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.cancel,
                                        color: DarkColors.error,
                                        size: 20,
                                      ),
                                      onPressed: () => _rejectEvent(event.id),
                                      tooltip: 'Reject',
                                    ),
                                  ],
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: DarkColors.accent,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        _showEditEventDialog(context, event),
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.person_add_alt_1,
                                      color: DarkColors.accent,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) =>
                                            _AssignTeamLeaderDialog(
                                              event: event,
                                            ),
                                      );
                                    },
                                    tooltip: 'Assign TL',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: DarkColors.error,
                                      size: 20,
                                    ),
                                    onPressed: () => _deleteEvent(event.id),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => Column(
                  children: List.generate(5, (index) => const SkeletonCard()),
                ),
                error: (e, s) => Center(
                  child: Text(
                    'Error: $e',
                    style: TextStyle(color: DarkColors.error),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _statusFilter = value;
        });
      },
      backgroundColor: Colors.transparent,
      selectedColor: DarkColors.primary.withValues(alpha: 0.2),
      checkmarkColor: DarkColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? DarkColors.primary : Colors.white60,
      ),
      side: BorderSide(
        color: isSelected
            ? DarkColors.primary
            : DarkColors.borderColor.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'published':
        color = DarkColors.success;
        break;
      case 'pending':
        color = DarkColors.warning;
        break;
      case 'cancelled':
        color = DarkColors.error;
        break;
      default:
        color = DarkColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _approveEvent(String id) async {
    await ref.read(eventControllerProvider).approveEvent(id);
    // ignore: unused_result
    ref.refresh(pendingEventsAdminProvider);
    // ignore: unused_result
    ref.refresh(publishedEventsProvider(0));
  }

  Future<void> _rejectEvent(String id) async {
    await ref.read(eventControllerProvider).rejectEvent(id);
    // ignore: unused_result
    ref.refresh(pendingEventsAdminProvider);
  }

  Future<void> _deleteEvent(String id) async {
    final cur = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete this event? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (cur == true && mounted) {
      await ref.read(eventControllerProvider).deleteEvent(id);
      // ignore: unused_result
      ref.refresh(pendingEventsAdminProvider);
      // ignore: unused_result
      ref.refresh(publishedEventsProvider(0));
    }
  }

  void _showCreateEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _EventFormDialog(),
    );
  }

  void _showEditEventDialog(BuildContext context, EventModel event) {
    showDialog(
      context: context,
      builder: (context) => _EventFormDialog(initialEvent: event),
    );
  }
}

class _EventFormDialog extends ConsumerStatefulWidget {
  final EventModel? initialEvent;
  const _EventFormDialog({this.initialEvent});

  @override
  ConsumerState<_EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends ConsumerState<_EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _capacityController = TextEditingController();
  final _salaryController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _benefitsController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagController = TextEditingController();

  String _selectedCompanyId = '';
  String? _selectedCategoryId;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  bool _isUrgent = false;
  final List<String> _tags = [];
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void initState() {
    super.initState();
    if (widget.initialEvent != null) {
      final e = widget.initialEvent!;
      _titleController.text = e.title;
      _descController.text = e.description ?? '';
      _locationController.text = e.location?.address ?? '';
      _capacityController.text = e.capacity?.toString() ?? '';
      _salaryController.text = e.salary?.toString() ?? '';
      _requirementsController.text = e.requirements ?? '';
      _benefitsController.text = e.benefits ?? '';
      _contactEmailController.text = e.contactEmail ?? '';
      _contactPhoneController.text = e.contactPhone ?? '';
      _selectedCompanyId = e.companyId;
      _selectedCategoryId = e.categoryId;
      _startDate = e.startTime;
      _startTime = TimeOfDay.fromDateTime(e.startTime);
      _endDate = e.endTime;
      _endTime = TimeOfDay.fromDateTime(e.endTime);
      _isUrgent = e.isUrgent;
      _tags.addAll(e.tags);
    }
  }

  DateTime get _fullStartTime => DateTime(
    _startDate.year,
    _startDate.month,
    _startDate.day,
    _startTime.hour,
    _startTime.minute,
  );

  DateTime get _fullEndTime => DateTime(
    _endDate.year,
    _endDate.month,
    _endDate.day,
    _endTime.hour,
    _endTime.minute,
  );

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag) && _tags.length < 10) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: DarkColors.accent),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: DarkColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Header ────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: DarkColors.accent.withOpacity(0.15),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_available, color: DarkColors.accent),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Create & Publish Event',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ─── Form Body ─────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Basic Info ──
                      _sectionHeader('Basic Information', Icons.info_outline),
                      _CompanyDropdown(
                        selectedId: _selectedCompanyId.isEmpty
                            ? null
                            : _selectedCompanyId,
                        onChanged: (val) =>
                            setState(() => _selectedCompanyId = val ?? ''),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Event Title *',
                          hintText: 'e.g. Warehouse Logistics Sprint',
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Title is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          hintText:
                              'Describe the event, responsibilities, etc.',
                          prefixIcon: Icon(Icons.description),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Description is required'
                            : null,
                      ),

                      // ── Schedule ──
                      _sectionHeader('Schedule', Icons.schedule),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2030),
                                );
                                if (d != null) setState(() => _startDate = d);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Start Date *',
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: _startTime,
                                );
                                if (t != null) setState(() => _startTime = t);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Start Time *',
                                  prefixIcon: Icon(Icons.access_time),
                                ),
                                child: Text(
                                  _startTime.format(context),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate,
                                  firstDate: _startDate,
                                  lastDate: DateTime(2030),
                                );
                                if (d != null) setState(() => _endDate = d);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'End Date *',
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: _endTime,
                                );
                                if (t != null) setState(() => _endTime = t);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'End Time *',
                                  prefixIcon: Icon(Icons.access_time),
                                ),
                                child: Text(
                                  _endTime.format(context),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ── Location ──
                      _sectionHeader('Location', Icons.location_on),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Event Address',
                          hintText: 'e.g. Riyadh, Saudi Arabia',
                          prefixIcon: Icon(Icons.place),
                        ),
                      ),

                      // ── Event Image ──
                      _sectionHeader('Event Image', Icons.image),
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 1200,
                            imageQuality: 85,
                          );
                          if (picked != null) {
                            final bytes = await picked.readAsBytes();
                            setState(() {
                              _selectedImageBytes = bytes;
                              _selectedImageName = picked.name;
                            });
                          }
                        },
                        child: Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: DarkColors.accent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: DarkColors.accent.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: _selectedImageBytes != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(11),
                                      child: Image.memory(
                                        _selectedImageBytes!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Center(
                                          child: Text(
                                            'Error loading image',
                                            style: TextStyle(
                                              color: DarkColors.error,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: GestureDetector(
                                        onTap: () => setState(() {
                                          _selectedImageBytes = null;
                                          _selectedImageName = null;
                                        }),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : (widget.initialEvent?.imagePath != null
                                    ? Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              11,
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl: ref
                                                  .read(
                                                    fileUploadServiceProvider,
                                                  )
                                                  .getPublicUrl(
                                                    widget
                                                        .initialEvent!
                                                        .imagePath!,
                                                  ),
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(Icons.error),
                                            ),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black26,
                                              borderRadius:
                                                  BorderRadius.circular(11),
                                            ),
                                            child: const Center(
                                              child: Text(
                                                'Tap to change image',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  shadows: [
                                                    Shadow(
                                                      blurRadius: 2,
                                                      color: Colors.black,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.cloud_upload_outlined,
                                            size: 36,
                                            color: DarkColors.accent,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Tap to upload event image',
                                            style: TextStyle(
                                              color: DarkColors.accent,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'JPG, PNG up to 10MB',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.4,
                                              ),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      )),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ── Job Details ──
                      _sectionHeader('Job Details', Icons.work_outline),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _capacityController,
                              decoration: const InputDecoration(
                                labelText: 'Capacity (seats)',
                                prefixIcon: Icon(Icons.people),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v != null && v.isNotEmpty) {
                                  final n = int.tryParse(v);
                                  if (n == null || n < 1) return 'Must be ≥ 1';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _salaryController,
                              decoration: const InputDecoration(
                                labelText: 'Salary (SAR)',
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v != null && v.isNotEmpty) {
                                  final n = double.tryParse(v);
                                  if (n == null || n < 0) return 'Must be ≥ 0';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _requirementsController,
                        decoration: const InputDecoration(
                          labelText: 'Requirements',
                          hintText: 'e.g. Must have valid ID, age 18+...',
                          prefixIcon: Icon(Icons.checklist),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _benefitsController,
                        decoration: const InputDecoration(
                          labelText: 'Benefits',
                          hintText: 'e.g. Transportation provided, meals...',
                          prefixIcon: Icon(Icons.card_giftcard),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 2,
                      ),

                      // ── Contact ──
                      _sectionHeader('Contact Information', Icons.contact_mail),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _contactEmailController,
                              decoration: const InputDecoration(
                                labelText: 'Contact Email',
                                prefixIcon: Icon(Icons.email),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v != null &&
                                    v.isNotEmpty &&
                                    !v.contains('@')) {
                                  return 'Invalid email';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _contactPhoneController,
                              decoration: const InputDecoration(
                                labelText: 'Contact Phone',
                                prefixIcon: Icon(Icons.phone),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),

                      // ── Tags & Options ──
                      _sectionHeader('Tags & Options', Icons.label_outline),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _tagController,
                              decoration: InputDecoration(
                                labelText: 'Add Tag',
                                hintText: 'e.g. logistics, part-time',
                                prefixIcon: const Icon(Icons.tag),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: _addTag,
                                ),
                              ),
                              onFieldSubmitted: (_) => _addTag(),
                            ),
                          ),
                        ],
                      ),
                      if (_tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _tags
                              .map(
                                (tag) => Chip(
                                  label: Text(
                                    tag,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  onDeleted: () =>
                                      setState(() => _tags.remove(tag)),
                                  backgroundColor: DarkColors.accent
                                      .withOpacity(0.2),
                                  labelStyle: TextStyle(
                                    color: DarkColors.accent,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('🔥 Urgent Hiring'),
                        subtitle: const Text('Mark this event as urgent'),
                        value: _isUrgent,
                        activeThumbColor: DarkColors.accent,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => setState(() => _isUrgent = v),
                      ),

                      // ── Category ──
                      _sectionHeader('Category', Icons.category),
                      _CategoryDropdown(
                        selectedId: _selectedCategoryId,
                        onChanged: (id) =>
                            setState(() => _selectedCategoryId = id),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // ─── Actions ───────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.initialEvent == null
                          ? 'Create & Publish Event'
                          : 'Edit ${widget.initialEvent!.title}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: Icon(
                      widget.initialEvent == null ? Icons.publish : Icons.save,
                    ),
                    label: Text(
                      widget.initialEvent == null
                          ? 'Create & Publish'
                          : 'Update Event',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;

                      if (_selectedCompanyId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a company organizer'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (_fullEndTime.isBefore(_fullStartTime)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'End date/time must be after start date/time',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Show loading
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (c) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      // Upload image first if selected
                      String? uploadedImagePath =
                          widget.initialEvent?.imagePath;
                      if (_selectedImageBytes != null &&
                          _selectedImageName != null) {
                        final uploadResult = await ref
                            .read(fileUploadServiceProvider)
                            .uploadEventImage(
                              fileName: _selectedImageName!,
                              bytes: _selectedImageBytes!,
                            );
                        uploadResult.when(
                          success: (path) => uploadedImagePath = path,
                          error: (_) {},
                        );
                      }

                      final loc = _locationController.text.trim().isNotEmpty
                          ? LocationData(
                              address: _locationController.text.trim(),
                            )
                          : null;

                      final Result<EventModel> result;
                      if (widget.initialEvent == null) {
                        result = await ref
                            .read(eventControllerProvider)
                            .adminCreateEvent(
                              companyId: _selectedCompanyId,
                              title: _titleController.text.trim(),
                              description: _descController.text.trim(),
                              location: loc,
                              startTime: _fullStartTime,
                              endTime: _fullEndTime,
                              capacity: int.tryParse(_capacityController.text),
                              imagePath: uploadedImagePath,
                              categoryId: _selectedCategoryId,
                              salary: double.tryParse(_salaryController.text),
                              requirements: _requirementsController.text.trim(),
                              benefits: _benefitsController.text.trim(),
                              contactEmail: _contactEmailController.text.trim(),
                              contactPhone: _contactPhoneController.text.trim(),
                              tags: _tags.isNotEmpty ? _tags : null,
                              isUrgent: _isUrgent,
                            );
                      } else {
                        result = await ref
                            .read(eventControllerProvider)
                            .updateEvent(
                              eventId: widget.initialEvent!.id,
                              title: _titleController.text.trim(),
                              description: _descController.text.trim(),
                              location: loc,
                              startTime: _fullStartTime,
                              endTime: _fullEndTime,
                              capacity: int.tryParse(_capacityController.text),
                              imagePath: uploadedImagePath,
                              status: widget.initialEvent!.status,
                              categoryId: _selectedCategoryId,
                              salary: double.tryParse(_salaryController.text),
                              requirements: _requirementsController.text.trim(),
                              benefits: _benefitsController.text.trim(),
                              contactEmail: _contactEmailController.text.trim(),
                              contactPhone: _contactPhoneController.text.trim(),
                              tags: _tags.isNotEmpty ? _tags : null,
                              isUrgent: _isUrgent,
                            );
                      }

                      if (mounted) Navigator.of(context).pop(); // pop loading

                      if (!mounted) return;
                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(context);

                      result.when(
                        success: (event) {
                          nav.pop(); // close form dialog

                          // Refresh both providers
                          // ignore: unused_result
                          ref.refresh(publishedEventsProvider(0));
                          // ignore: unused_result
                          ref.refresh(pendingEventsAdminProvider);
                          // ignore: unused_result
                          ref.refresh(analyticsKPIProvider);

                          // Show success message
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                widget.initialEvent == null
                                    ? 'Event "${event.title}" created!'
                                    : 'Event "${event.title}" updated!',
                              ),
                              backgroundColor: DarkColors.success,
                            ),
                          );
                        },
                        error: (error) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Failed: $error'),
                              backgroundColor: DarkColors.error,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Category dropdown for the Create Event form
class _CategoryDropdown extends ConsumerWidget {
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({required this.selectedId, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return const SizedBox.shrink();
        }
        return DropdownButtonFormField<String>(
          initialValue: selectedId,
          hint: const Text('Category (optional)'),
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('No category')),
            ...categories.map(
              (cat) => DropdownMenuItem(
                value: cat.id,
                child: Text('${cat.icon ?? ''} ${cat.name}'),
              ),
            ),
          ],
          onChanged: onChanged,
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Company dropdown for the Create Event form
class _CompanyDropdown extends ConsumerWidget {
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _CompanyDropdown({required this.selectedId, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(allCompaniesProvider);

    return companiesAsync.when(
      data: (companies) {
        if (companies.isEmpty) {
          return const Text(
            'No companies found. Create one first.',
            style: TextStyle(color: Colors.red),
          );
        }
        return DropdownButtonFormField<String>(
          initialValue: selectedId,
          hint: const Text('Select Company Organizer'),
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Company Organizer *',
            border: OutlineInputBorder(),
          ),
          items: companies
              .map(
                (c) => DropdownMenuItem<String>(
                  value: (c['id'] ?? c['_id']).toString(),
                  child: Text(c['name']?.toString() ?? 'Unknown'),
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Please select an organizer' : null,
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text(
        'Error loading companies',
        style: TextStyle(color: Colors.red),
      ),
    );
  }
}

class _AssignTeamLeaderDialog extends ConsumerStatefulWidget {
  final EventModel event;

  const _AssignTeamLeaderDialog({required this.event});

  @override
  ConsumerState<_AssignTeamLeaderDialog> createState() =>
      _AssignTeamLeaderDialogState();
}

class _AssignTeamLeaderDialogState
    extends ConsumerState<_AssignTeamLeaderDialog> {
  String? _selectedUserId;
  bool _isAssigning = false;

  @override
  Widget build(BuildContext context) {
    // Fetch currently assigned team leaders
    final teamLeadersAsync = ref.watch(
      teamLeadersForEventProvider(widget.event.id),
    );

    return AlertDialog(
      backgroundColor: DarkColors.surface,
      title: Text(
        'Manage Team Leaders\n${widget.event.title}',
        style: const TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            // List of assigned team leaders
            Expanded(
              child: teamLeadersAsync.when(
                data: (leaders) {
                  if (leaders.isEmpty) {
                    return const Center(
                      child: Text('No team leaders assigned'),
                    );
                  }
                  return ListView.builder(
                    itemCount: leaders.length,
                    itemBuilder: (context, index) {
                      final leader = leaders[index];
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Team Leader'),
                        subtitle: Text(
                          'ID: ${leader.userId.substring(0, 8)}...',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          color: DarkColors.error,
                          onPressed: () => _removeLeader(leader.id),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
            ),
            const Divider(),
            // Assign new
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Assign New Team Leader',
                style: AppTypography.titleSmall,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _UserDropdown(
                    onChanged: (val) => setState(() => _selectedUserId = val),
                    selectedId: _selectedUserId,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedUserId == null || _isAssigning
                      ? null
                      : _assignLeader,
                  child: _isAssigning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Assign'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _assignLeader() async {
    if (_selectedUserId == null) return;
    setState(() => _isAssigning = true);

    final result = await ref
        .read(adminControllerProvider)
        .assignTeamLeaderToEvent(
          userId: _selectedUserId!,
          eventId: widget.event.id,
        );

    if (mounted) setState(() => _isAssigning = false);

    result.when(
      success: (_) {
        ref.invalidate(teamLeadersForEventProvider(widget.event.id));
        setState(() => _selectedUserId = null);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Team leader assigned successfully'),
              backgroundColor: DarkColors.success,
            ),
          );
        }
      },
      error: (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to assign: ${e.message}'),
              backgroundColor: DarkColors.error,
            ),
          );
        }
      },
    );
  }

  Future<void> _removeLeader(String id) async {
    final result = await ref
        .read(adminControllerProvider)
        .removeTeamLeaderFromEvent(id);
    result.when(
      success: (_) {
        ref.invalidate(teamLeadersForEventProvider(widget.event.id));
      },
      error: (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove: ${e.message}')),
          );
        }
      },
    );
  }
}

class _UserDropdown extends ConsumerWidget {
  final ValueChanged<String?> onChanged;
  final String? selectedId;

  const _UserDropdown({required this.onChanged, this.selectedId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersFuture = ref.watch(allUsersProvider(0));

    return usersFuture.when(
      data: (allUsers) {
        final teamLeaders = allUsers
            .where((u) => u.role == 'team_leader')
            .toList();

        if (teamLeaders.isEmpty) {
          return const Text('No Team Leaders found');
        }

        return DropdownButtonFormField<String>(
          initialValue: selectedId,
          hint: const Text('Select Team Leader'),
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: teamLeaders.map((user) {
            return DropdownMenuItem(
              value: user.id,
              child: Text(
                '${user.name} (${user.email})',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, s) => Text('Error loading users: $e'),
    );
  }
}
