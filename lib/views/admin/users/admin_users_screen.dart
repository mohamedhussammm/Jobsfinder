import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../controllers/admin_controller.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../models/user_model.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _roleFilter = 'all'; // 'all', 'normal', 'company', 'team_leader'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider(0)); // Start with page 0

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Filters
          Row(
            children: [
              Text(
                'User Management',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              // Role Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _roleFilter,
                    dropdownColor: AppColors.surface,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textPrimary,
                    ),
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
                      // In a real app, we'd trigger a refetch here with the filter
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
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              hintStyle: const TextStyle(color: AppColors.textTertiary),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) {
              setState(() => _searchQuery = val);
            },
          ),
          const SizedBox(height: 16),
          // Users Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: usersAsync.when(
                data: (users) {
                  // Client-side filtering for demo (controllers usually handle this)
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

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                          AppColors.background,
                        ),
                        columns: const [
                          DataColumn(
                            label: Text(
                              'User',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Role',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Status',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Actions',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                        rows: filteredUsers.map((user) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppColors.primary
                                          .withOpacity(0.2),
                                      child: Text(
                                        (user.name ?? user.email)[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          user.name ?? 'No Name',
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          user.email,
                                          style: const TextStyle(
                                            color: AppColors.textTertiary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(
                                      user.role,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    user.role.toUpperCase(),
                                    style: TextStyle(
                                      color: _getRoleColor(user.role),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  'Active',
                                  style: TextStyle(color: AppColors.success),
                                ),
                              ), // Placeholder for active/blocked status
                              DataCell(
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      _showEditUserDialog(context, user),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
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

  Color _getRoleColor(Stringrole) {
    switch (Stringrole) {
      case 'admin':
        return AppColors.error;
      case 'company':
        return AppColors.accent;
      case 'team_leader':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  void _showEditUserDialog(BuildContext context, UserModel user) {
    // Normalize 'user' to 'normal' and handle any invalid roles
    const validRoles = ['normal', 'team_leader', 'company', 'admin'];
    String selectedRole = user.role == 'user' ? 'normal' : user.role;

    if (!validRoles.contains(selectedRole)) {
      selectedRole = 'normal';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Edit User',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change role for ${user.email}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                dropdownColor: AppColors.surface,
                items: ['normal', 'team_leader', 'company', 'admin']
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(
                          r.toUpperCase(),
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedRole = val);
                },
                decoration: InputDecoration(
                  labelText: 'Role',
                  labelStyle: const TextStyle(color: AppColors.textTertiary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
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
                await controller.updateUserRole(user.id, selectedRole);
                Navigator.pop(context);
                ref.refresh(allUsersProvider(0)); // Refresh list
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
