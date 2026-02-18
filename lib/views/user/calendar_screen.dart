import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/application_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/application_model.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    final applicationsAsync = ref.watch(
      userApplicationsProvider(currentUser.id),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar'), centerTitle: true),
      body: applicationsAsync.when(
        data: (apps) {
          // Filter accepted applications (upcoming events)
          final accepted = apps.where((a) => a.status == 'accepted').toList();

          return _CalendarBody(acceptedApps: accepted);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _CalendarBody extends StatefulWidget {
  final List<ApplicationModel> acceptedApps;

  const _CalendarBody({required this.acceptedApps});

  @override
  State<_CalendarBody> createState() => _CalendarBodyState();
}

class _CalendarBodyState extends State<_CalendarBody> {
  late DateTime _selectedMonth;
  int? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Month navigation
        Padding(
          padding: ResponsiveHelper.screenPadding(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month - 1,
                    );
                    _selectedDay = null;
                  });
                },
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
                style: TextStyle(
                  fontSize: ResponsiveHelper.sp(context, 18),
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + 1,
                    );
                    _selectedDay = null;
                  });
                },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),

        // Day of week headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map(
                  (d) => SizedBox(
                    width: 36,
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.sp(context, 12),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Calendar grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildCalendarGrid(context),
        ),
        const SizedBox(height: 16),

        // Events for selected day
        Expanded(child: _buildSelectedDayEvents(context)),
      ],
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;
    final startWeekday = firstDay.weekday; // 1 = Monday

    final cells = <Widget>[];

    // Empty cells before first day
    for (int i = 1; i < startWeekday; i++) {
      cells.add(const SizedBox(width: 36, height: 36));
    }

    // Day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final isToday = _isToday(date);
      final isSelected = day == _selectedDay;
      final hasEvent = _hasEventOnDate(date);

      cells.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDay = day),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : isToday
                  ? AppColors.primaryLight
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.sp(context, 14),
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected
                        ? Colors.white
                        : isToday
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                if (hasEvent)
                  Positioned(
                    bottom: 2,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: (MediaQuery.of(context).size.width - 32 - 7 * 36) / 6,
      runSpacing: 4,
      children: cells,
    );
  }

  Widget _buildSelectedDayEvents(BuildContext context) {
    if (_selectedDay == null) {
      return Center(
        child: Text(
          'Select a day to see your schedule',
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: ResponsiveHelper.sp(context, 14),
          ),
        ),
      );
    }

    // For now, show accepted apps (in a real app, we'd filter by event dates)
    return ListView.builder(
      padding: ResponsiveHelper.screenPadding(context),
      itemCount: widget.acceptedApps.length,
      itemBuilder: (context, index) {
        final app = widget.acceptedApps[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.borderColor),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.event_available,
                color: AppColors.success,
              ),
            ),
            title: Text(
              'Accepted Application',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.sp(context, 14),
              ),
            ),
            subtitle: Text(
              'Applied ${app.appliedAt.day}/${app.appliedAt.month}/${app.appliedAt.year}',
              style: TextStyle(
                fontSize: ResponsiveHelper.sp(context, 12),
                color: AppColors.textTertiary,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.gray400),
          ),
        );
      },
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _hasEventOnDate(DateTime date) {
    // In a real implementation, this would check event start/end dates
    // For now, show dots on apps' applied dates
    return widget.acceptedApps.any(
      (a) =>
          a.appliedAt.day == date.day &&
          a.appliedAt.month == date.month &&
          a.appliedAt.year == date.year,
    );
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
