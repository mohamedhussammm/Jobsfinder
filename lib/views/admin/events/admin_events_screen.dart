import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../controllers/event_controller.dart';
import '../../../controllers/admin_controller.dart';
import '../../../models/company_model.dart';
import '../../../models/event_model.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class AdminEventsScreen extends ConsumerStatefulWidget {
  const AdminEventsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends ConsumerState<AdminEventsScreen> {
  String _statusFilter = 'all'; // 'all', 'pending', 'published', 'cancelled'
  String _searchQuery = '';

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
              Text(
                'Event Management',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showCreateEventDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Create Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filters
          Row(
            children: [
              _buildFilterChip('All', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Pending', 'pending'),
              const SizedBox(width: 8),
              _buildFilterChip('Published', 'published'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: eventsAsync.when(
                data: (events) {
                  if (events.isEmpty) {
                    return Center(
                      child: Text(
                        'No events found',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: events.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: AppColors.borderColor),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            image: event.imagePath != null
                                ? DecorationImage(
                                    image: NetworkImage(event.imagePath!),
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
                        title: Text(
                          event.title,
                          style: AppTypography.body1.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '${event.companyId} • ${event.startTime.toString().split(' ')[0]}',
                          style: TextStyle(color: AppColors.textTertiary),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildStatusBadge(event.status),
                            const SizedBox(width: 8),
                            if (event.status == 'pending') ...[
                              IconButton(
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                ),
                                onPressed: () => _approveEvent(event.id),
                                tooltip: 'Approve',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.cancel,
                                  color: AppColors.error,
                                ),
                                onPressed: () => _rejectEvent(event.id),
                                tooltip: 'Reject',
                              ),
                            ],
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.error,
                              ),
                              onPressed: () => _deleteEvent(event.id),
                            ),
                          ],
                        ),
                        onTap: () {
                          // Show details dialog
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(
                  child: Text(
                    'Error: $e',
                    style: TextStyle(color: AppColors.error),
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
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'published':
        color = AppColors.success;
        break;
      case 'pending':
        color = AppColors.warning;
        break;
      case 'cancelled':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
    ref.refresh(pendingEventsAdminProvider);
    ref.refresh(publishedEventsProvider(0));
  }

  Future<void> _rejectEvent(String id) async {
    await ref.read(eventControllerProvider).rejectEvent(id);
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
    if (cur == true) {
      await ref.read(eventControllerProvider).deleteEvent(id);
      ref.refresh(pendingEventsAdminProvider);
      ref.refresh(publishedEventsProvider(0));
    }
  }

  void _showCreateEventDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => _CreateEventDialog());
  }
}

class _CreateEventDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends ConsumerState<_CreateEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _capacityController = TextEditingController();

  String? _selectedCompanyId;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 1, hours: 4));
  bool _isLoadingComp = true;
  List<CompanyModel> _companies = [];

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    final res = await ref.read(adminControllerProvider).fetchAllCompanies();
    res.when(
      success: (list) {
        if (mounted)
          setState(() {
            _companies = list;
            _isLoadingComp = false;
          });
      },
      error: (e) {
        if (mounted)
          setState(() {
            _isLoadingComp = false;
          });
        // Handle error
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Event'),
      content: SingleChildScrollView(
        child: Container(
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoadingComp)
                  const LinearProgressIndicator()
                else
                  DropdownButtonFormField<String>(
                    value: _selectedCompanyId,
                    decoration: const InputDecoration(labelText: 'Company *'),
                    items: _companies
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCompanyId = val),
                    validator: (v) =>
                        v == null ? 'Please select a company' : null,
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Event Title *'),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                // Date Pickers simplified
                ListTile(
                  title: Text('Start: ${_startDate.toString().split('.')[0]}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setState(() => _startDate = d);
                  },
                ),
                ListTile(
                  title: Text('End: ${_endDate.toString().split('.')[0]}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _endDate,
                      firstDate: _startDate,
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setState(() => _endDate = d);
                  },
                ),
                TextFormField(
                  controller: _capacityController,
                  decoration: const InputDecoration(labelText: 'Capacity'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              await ref
                  .read(eventControllerProvider)
                  .adminCreateEvent(
                    companyId: _selectedCompanyId!,
                    title: _titleController.text,
                    description: _descController.text,
                    location: null, // Simplified for now
                    startTime: _startDate,
                    endTime: _endDate,
                    capacity: int.tryParse(_capacityController.text),
                    imagePath: null,
                  );
              if (mounted) Navigator.pop(context);
              ref.refresh(publishedEventsProvider(0));
            }
          },
          child: const Text('Create & Publish'),
        ),
      ],
    );
  }
}
