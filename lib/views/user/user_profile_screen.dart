import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/typography.dart';
import '../../models/user_model.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/rating_controller.dart';
import '../../models/rating_model.dart';
import '../../core/theme/dark_colors.dart';

class UserProfileScreen extends ConsumerWidget {
  final String? userId;

  const UserProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSessionUser = ref.watch(currentUserProvider);
    final userAsync = userId != null && userId != currentSessionUser?.id
        ? ref.watch(fetchUserByIdProvider(userId!))
        : null;

    final user = userAsync != null ? userAsync.value : currentSessionUser;

    final isMe = userId == null || userId == currentSessionUser?.id;

    if (user == null && userAsync?.isLoading == true) {
      return Scaffold(
        backgroundColor: DarkColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: DarkColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(
            userAsync?.error?.toString() ?? 'User not found',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: DarkColors.background,
      appBar: AppBar(
        title: Text(
          isMe ? 'My Profile' : 'User Profile',
          style: AppTypography.titleLarge.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => isMe ? context.go('/') : context.pop(),
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

            if (isMe) ...[
              // 4. Privacy Settings
              _buildSectionRow(
                context,
                title: 'Privacy Settings',
                icon: Icons.lock_outline,
                subtitle: 'Visibility, Data usage',
                onTap: () {},
              ),
              const SizedBox(height: 24),
            ],

            _buildRecentReviewsSection(context, ref, user.id),

            if (isMe) ...[
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () {
                  ref.read(authControllerProvider).logout();
                  context.go('/auth');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: DarkColors.error,
                  side: const BorderSide(color: DarkColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Center(child: Text('Logout')),
              ),
            ],
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
                border: Border.all(color: DarkColors.accent, width: 2),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: DarkColors.surface,
                backgroundImage: user.avatarPath != null
                    ? NetworkImage(user.avatarPath!)
                    : null,
                child: user.avatarPath == null
                    ? Text(
                        user.name?[0].toUpperCase() ?? 'U',
                        style: AppTypography.heading1.copyWith(
                          color: DarkColors.accent,
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
                  color: DarkColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
        Text(
          user.name ?? 'User',
          style: AppTypography.titleLarge.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: DarkColors.accent, size: 20),
            const SizedBox(width: 4),
            Text(
              '${user.ratingAvg.toStringAsFixed(1)} (${user.ratingCount} reviews)',
              style: AppTypography.bodySmall.copyWith(
                color: DarkColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletionCard(UserModel user) {
    final completion = user.profileComplete ? 1.0 : 0.4; // Placeholder logic

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DarkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DarkColors.borderColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
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
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${(completion * 100).toInt()}%',
                style: AppTypography.bodyLarge.copyWith(
                  color: DarkColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: completion,
            backgroundColor: DarkColors.gray100,
            valueColor: const AlwaysStoppedAnimation<Color>(DarkColors.accent),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          if (completion < 1.0) ...[
            const SizedBox(height: 12),
            Text(
              'Complete your profile to apply for shifts faster!',
              style: AppTypography.labelSmall.copyWith(
                color: DarkColors.textSecondary,
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
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DarkColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DarkColors.borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: DarkColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: DarkColors.accent, size: 24),
        ),
        title: Text(
          title,
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.labelSmall.copyWith(
            color: DarkColors.textSecondary,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: DarkColors.textTertiary,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildRecentReviewsSection(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    final ratingsAsync = ref.watch(userRatingsProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Reviews',
              style: AppTypography.titleMedium.copyWith(color: Colors.white),
            ),
            TextButton(
              onPressed: () {
                context.push('/ratings/$userId');
              },
              child: Text(
                'View All',
                style: AppTypography.labelSmall.copyWith(
                  color: DarkColors.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ratingsAsync.when(
          data: (ratings) {
            if (ratings.isEmpty) {
              return Text(
                'No reviews yet',
                style: AppTypography.bodySmall.copyWith(
                  color: DarkColors.textTertiary,
                ),
              );
            }
            // Show only first 2
            final recent = ratings.take(2).toList();
            return Column(
              children: recent
                  .map((r) => _buildMiniReviewCard(context, r))
                  .toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Text('Error loading reviews'),
        ),
      ],
    );
  }

  Widget _buildMiniReviewCard(BuildContext context, RatingModel rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DarkColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DarkColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < rating.score ? Icons.star : Icons.star_border,
                    color: DarkColors.accent,
                    size: 14,
                  );
                }),
              ),
              const Spacer(),
              _formatRelativeDate(rating.createdAt),
            ],
          ),
          if (rating.textReview != null && rating.textReview!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              rating.textReview!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: DarkColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    String text = '';

    if (difference.inDays > 7) {
      text = '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays >= 1) {
      text = '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      text = '${difference.inHours}h ago';
    } else {
      text = 'Just now';
    }

    return Text(
      text,
      style: AppTypography.labelSmall.copyWith(
        color: DarkColors.textTertiary,
        fontSize: 10,
      ),
    );
  }
}
