import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_model.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/glass.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Profile', style: AppTypography.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header Section
            _buildHeader(user),
            const SizedBox(height: 24),

            // Profile Completion Progress
            _buildCompletionCard(user),
            const SizedBox(height: 24),

            // 1. Personal Information
            _buildSectionRow(
              context,
              title: 'Personal Information',
              icon: Icons.person_outline,
              subtitle: 'Username, Phone Number',
              onTap: () {
                // Navigate to Personal Info Edit
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit Personal Info')),
                );
              },
            ),

            // 2. Professional Details
            _buildSectionRow(
              context,
              title: 'Professional Details',
              icon: Icons.work_outline,
              subtitle: 'Experience, Skills, Certificates',
              onTap: () {
                // Navigate to Professional Details
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit Professional Details')),
                );
              },
            ),

            // 3. Portfolio & Documents
            _buildSectionRow(
              context,
              title: 'Portfolio & Documents',
              icon: Icons.folder_open,
              subtitle: 'Upload CV, Portfolio',
              onTap: () {
                // Navigate to Documents
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Manage Documents')),
                );
              },
            ),

            // 4. Privacy Settings
            _buildSectionRow(
              context,
              title: 'Privacy Settings',
              icon: Icons.lock_outline,
              subtitle: 'Visibility, Data usage',
              onTap: () {},
            ),

            // 5. Notification Settings
            _buildSectionRow(
              context,
              title: 'Notification Settings',
              icon: Icons.notifications_outlined,
              subtitle: 'Push, Email, SMS',
              onTap: () {},
            ),

            // 6. Account Settings
            _buildSectionRow(
              context,
              title: 'Account Settings',
              icon: Icons.settings_outlined,
              subtitle: 'Password, Language, Logout',
              isLast: true,
              onTap: () {},
            ),

            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () {
                context.go('/auth');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Center(child: Text('Log Out')),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel user) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent, width: 2),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: user.avatarPath != null
                    ? NetworkImage(user.avatarPath!)
                    : null,
                child: user.avatarPath == null
                    ? Text(
                        user.name?[0].toUpperCase() ?? 'U',
                        style: AppTypography.heading1.copyWith(
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(user.name ?? 'User', style: AppTypography.heading2),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: AppColors.accent, size: 20),
            const SizedBox(width: 4),
            Text(
              '${user.ratingAvg?.toStringAsFixed(1) ?? "0.0"} (${user.ratingCount ?? 0} reviews)',
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletionCard(UserModel user) {
    final completion = user.profileComplete == true
        ? 1.0
        : 0.4; // Placeholder logic

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile Completion',
                style: AppTypography.body1.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(completion * 100).toInt()}%',
                style: AppTypography.body1.copyWith(color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: completion,
            backgroundColor: AppColors.gray200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          if (completion < 1.0) ...[
            const SizedBox(height: 12),
            Text(
              'Complete your profile to apply for shifts faster!',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionRow(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String subtitle,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        title: Text(
          title,
          style: AppTypography.body1.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle, style: AppTypography.caption),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.gray400,
        ),
        onTap: onTap,
      ),
    );
  }
}
