import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../controllers/admin_controller.dart';
import '../../../models/application_model.dart';
import '../../../core/theme/typography.dart';
import '../../../core/theme/dark_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../common/skeleton_loader.dart';
import 'package:intl/intl.dart';

class AdminApplicationsScreen extends ConsumerStatefulWidget {
  const AdminApplicationsScreen({super.key});

  @override
  ConsumerState<AdminApplicationsScreen> createState() =>
      _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState
    extends ConsumerState<AdminApplicationsScreen> {
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final applicationsAsync = ref.watch(allApplicationsAdminProvider(0));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Application Management',
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontSize: ResponsiveHelper.sp(context, 20),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                _buildFilterChip('Applied', 'applied'),
                const SizedBox(width: 8),
                _buildFilterChip('Accepted', 'accepted'),
                const SizedBox(width: 8),
                _buildFilterChip('Rejected', 'rejected'),
                const SizedBox(width: 8),
                _buildFilterChip('Invited', 'invited'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DarkColors.borderColor.withValues(alpha: 0.5),
                ),
              ),
              child: applicationsAsync.when(
                data: (apps) {
                  if (apps.isEmpty) {
                    return const Center(
                      child: Text(
                        'No applications found',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: apps.length,
                    separatorBuilder: (_, i) => Divider(
                      color: DarkColors.borderColor.withValues(alpha: 0.2),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: DarkColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: Icon(
                            Icons.description,
                            color: DarkColors.primary,
                          ),
                        ),
                        title: Text(
                          'Application #${app.id.substring(0, 8)}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'User ID: ${app.userId.substring(0, 8)}... • ${DateFormat('MMM dd, yyyy').format(app.appliedAt)}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                        trailing: _buildStatusBadge(app.status),
                        onTap: () {
                          // View application details
                        },
                      );
                    },
                  );
                },
                loading: () => ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: 8,
                  separatorBuilder: (_, i) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => const SkeletonCard(),
                ),
                error: (e, s) => Center(
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(color: DarkColors.error),
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
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected
            ? DarkColors.primary
            : DarkColors.borderColor.withValues(alpha: 0.3),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'accepted':
        color = DarkColors.success;
        break;
      case 'rejected':
      case 'declined':
        color = DarkColors.error;
        break;
      case 'shortlisted':
      case 'invited':
        color = DarkColors.warning;
        break;
      default:
        color = DarkColors.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
