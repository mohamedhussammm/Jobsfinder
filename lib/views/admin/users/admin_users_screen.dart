import 'package:flutter/material.dart';
import '../../../core/utils/perf_log.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../controllers/admin_controller.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../models/user_model.dart';
import '../../../core/theme/dark_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../common/skeleton_loader.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _roleFilter = 'all'; // 'all', 'normal', 'company', 'team_leader'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    PerfLog.init('AdminUsersScreen');
  }

  @override
  void dispose() {
    PerfLog.dispose('AdminUsersScreen');
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    PerfLog.build('AdminUsersScreen');
    final usersAsync = ref.watch(allUsersProvider(0)); // Start with page 0

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Filters
          Row(
            children: [
              Expanded(
                child: Text(
                  'User Management',
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontSize: ResponsiveHelper.sp(context, 20),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Role Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: DarkColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: DarkColors.borderColor.withValues(alpha: 0.5),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _roleFilter,
                    dropdownColor: DarkColors.surface,
                    style: AppTypography.body2.copyWith(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Roles')),
                      DropdownMenuItem(value: 'normal', child: Text('Users')),
                      DropdownMenuItem(
                        value: 'company',
                        child: Text('Companies'),
                      ),
                      DropdownMenuItem(
                        value: 'team_leader',
                        child: Text('Team Leaders'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _roleFilter = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search Bar
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              prefixIcon: const Icon(
                Icons.search,
                color: DarkColors.textSecondary,
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: DarkColors.borderColor.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: DarkColors.borderColor.withValues(alpha: 0.3),
                ),
              ),
            ),
            onChanged: (val) {
              setState(() => _searchQuery = val);
            },
          ),
          const SizedBox(height: 16),
          // Users Table Replacement (ListView.builder for lazy loading)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DarkColors.borderColor.withValues(alpha: 0.5),
                ),
              ),
              child: usersAsync.when(
                data: (users) {
                  var filteredUsers = users;
                  if (_roleFilter != 'all') {
                    filteredUsers = filteredUsers
                        .where((u) => u.role == _roleFilter)
                        .toList();
                  }
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    filteredUsers = filteredUsers
                        .where(
                          (u) =>
                              (u.name?.toLowerCase().contains(q) ?? false) ||
                              u.email.toLowerCase().contains(q),
                        )
                        .toList();
                  }

                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Text(
                        'No users found',
                        style: AppTypography.body1.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // Table Header
                      _buildTableHeader(),
                      const Divider(height: 1, color: DarkColors.borderColor),
                      // Lazy List
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            return _buildUserRow(filteredUsers[index]);
                          },
                        ),
                      ),
                    ],
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
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DarkColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'User',
              style: AppTypography.labelSmall.copyWith(
                color: DarkColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Role',
              style: AppTypography.labelSmall.copyWith(
                color: DarkColors.textSecondary,
              ),
            ),
          ),
          if (!ResponsiveHelper.isPhone(context))
            Expanded(
              flex: 2,
              child: Text(
                'Status',
                style: AppTypography.labelSmall.copyWith(
                  color: DarkColors.textSecondary,
                ),
              ),
            ),
          const SizedBox(width: 48), // Action space
        ],
      ),
    );
  }

  Widget _buildUserRow(UserModel user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: DarkColors.borderColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: DarkColors.accent.withValues(alpha: 0.2),
                  backgroundImage: user.avatarPath != null
                      ? CachedNetworkImageProvider(
                          user.avatarPath!,
                          maxHeight: 64, // Optimize memory for thumbnails
                          maxWidth: 64,
                        )
                      : null,
                  child: user.avatarPath == null
                      ? Text(
                          (user.name ?? user.email)[0].toUpperCase(),
                          style: const TextStyle(
                            color: DarkColors.accent,
                            fontSize: 12,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name ?? 'No Name',
                        style: AppTypography.body1.copyWith(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user.email,
                        style: AppTypography.caption.copyWith(
                          color: DarkColors.textTertiary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRoleColor(user.role).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  user.role.toUpperCase(),
                  style: TextStyle(
                    color: _getRoleColor(user.role),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          if (!ResponsiveHelper.isPhone(context))
            Expanded(
              flex: 2,
              child: Text(
                'Active',
                style: TextStyle(color: DarkColors.success, fontSize: 13),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
            onPressed: () => _showEditUserDialog(context, user),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return DarkColors.error;
      case 'company':
        return DarkColors.accent;
      case 'team_leader':
        return DarkColors.warning;
      default:
        return DarkColors.success;
    }
  }

  void _showEditUserDialog(BuildContext context, UserModel user) {
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: DarkColors.surface,
          title: const Text('Edit User', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change role for ${user.email}',
                style: const TextStyle(color: DarkColors.textSecondary),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                dropdownColor: DarkColors.surface,
                items: ['normal', 'team_leader', 'company', 'admin']
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(
                          r.toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedRole = val);
                },
                decoration: InputDecoration(
                  labelText: 'Role',
                  labelStyle: const TextStyle(color: DarkColors.textTertiary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: DarkColors.borderColor),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final controller = ref.read(adminControllerProvider);
                final nav = Navigator.of(context);
                await controller.updateUserRole(user.id, selectedRole);
                nav.pop();
                // ignore: unused_result
                ref.refresh(allUsersProvider(0));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
