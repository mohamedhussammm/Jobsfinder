import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/typography.dart';
import '../../models/user_model.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/rating_controller.dart';
import '../../models/rating_model.dart';
import '../../core/theme/dark_colors.dart';
import '../../core/utils/perf_log.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/file_upload_service.dart';
import '../../core/utils/result.dart';
import '../../core/theme/colors.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String? userId;

  const UserProfileScreen({super.key, this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  @override
  void initState() {
    super.initState();
    PerfLog.init('UserProfileScreen');
  }

  @override
  void dispose() {
    PerfLog.dispose('UserProfileScreen');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    PerfLog.build('UserProfileScreen');
    final currentSessionUser = ref.watch(currentUserProvider);
    final userAsync =
        widget.userId != null && widget.userId != currentSessionUser?.id
        ? ref.watch(fetchUserByIdProvider(widget.userId!))
        : null;

    final user = userAsync != null ? userAsync.value : currentSessionUser;
    final isMe =
        widget.userId == null || widget.userId == currentSessionUser?.id;

    if (user == null && userAsync?.isLoading == true) {
      return const Scaffold(
        backgroundColor: DarkColors.background,
        body: Center(child: CircularProgressIndicator()),
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
      body: CustomScrollView(
        slivers: [
          // Elegant Sliver App Bar
          _buildSliverAppBar(context, isMe),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Header Section
                _buildHeader(user, isMe),
                const SizedBox(height: 24),

                // Profile Completion Progress
                _buildCompletionCard(user),
                const SizedBox(height: 12),

                if (isMe && user.profileCompletion < 1.0)
                  _buildCompletionHint(user),

                const SizedBox(height: 24),

                // 1. Personal Information
                _buildSectionRow(
                  context,
                  title: 'Personal Information',
                  icon: Icons.person_outline,
                  subtitle:
                      '${user.name ?? "Not set"}, ${user.phone ?? "No phone"}',
                  onTap: () => context.push('/edit-profile'),
                ),

                // 2. Professional Details
                _buildSectionRow(
                  context,
                  title: 'Professional Details',
                  icon: Icons.work_outline,
                  subtitle:
                      'National ID: ${user.nationalIdNumber ?? "Missing"}',
                  onTap: () => context.push('/edit-profile'),
                ),

                // 3. Portfolio & Documents
                _buildSectionRow(
                  context,
                  title: 'Portfolio & Documents',
                  icon: Icons.folder_open,
                  subtitle: user.cvPath != null
                      ? 'CV Uploaded'
                      : 'Upload your CV (Required)',
                  trailing: user.cvPath != null
                      ? const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 20,
                        )
                      : null,
                  onTap: isMe ? _pickAndUploadCv : () {},
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
              ]),
            ),
          ),
        ],
      ),
    );
  }

  bool _isUploading = false;

  Future<void> _pickAndUploadAvatar() async {
    if (_isUploading) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await image.readAsBytes();
      final result = await ref
          .read(fileUploadServiceProvider)
          .uploadAvatar(fileName: image.name, bytes: bytes);

      if (result is Success<String>) {
        final currentUser = ref.read(currentUserProvider);
        if (currentUser != null) {
          final oldAvatarPath = currentUser.avatarPath;

          await ref
              .read(authControllerProvider)
              .updateProfile(userId: currentUser.id, avatarUrl: result.data);

          // Evict old image from cache so CachedNetworkImage fetches fresh
          if (oldAvatarPath != null) {
            final oldUrl = ref
                .read(fileUploadServiceProvider)
                .getPublicUrl(oldAvatarPath);
            await CachedNetworkImage.evictFromCache(oldUrl);
          }
          // Also evict using the new URL/path just in case
          final newUrl = ref
              .read(fileUploadServiceProvider)
              .getPublicUrl(result.data);
          await CachedNetworkImage.evictFromCache(newUrl);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload image'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickAndUploadCv() async {
    if (_isUploading) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _isUploading = true);

    try {
      final uploadResult = await ref
          .read(fileUploadServiceProvider)
          .uploadCV(fileName: file.name, bytes: file.bytes!);

      if (uploadResult is Success<String>) {
        final currentUser = ref.read(currentUserProvider);
        if (currentUser != null) {
          await ref
              .read(authControllerProvider)
              .updateProfile(userId: currentUser.id, cvUrl: uploadResult.data);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('CV uploaded successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload CV'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildSliverAppBar(BuildContext context, bool isMe) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: DarkColors.background,
      title: Text(
        isMe ? 'My Profile' : 'User Profile',
        style: AppTypography.titleLarge.copyWith(
          color: Colors.white,
          fontSize: 18,
        ),
      ),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () => isMe ? context.go('/') : context.pop(),
      ),
    );
  }

  Widget _buildHeader(UserModel user, bool isMe) {
    final avatarUrl = user.avatarPath != null
        ? ref.read(fileUploadServiceProvider).getPublicUrl(user.avatarPath!)
        : null;

    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: DarkColors.accent.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Hero(
                tag: 'profile_avatar',
                child: ClipOval(
                  child: Container(
                    width: 108,
                    height: 108,
                    color: DarkColors.surface,
                    child: avatarUrl != null
                        ? CachedNetworkImage(
                            imageUrl:
                                "$avatarUrl${avatarUrl.contains('?') ? '&' : '?'}v=${user.updatedAt.millisecondsSinceEpoch}",
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) =>
                                _buildAvatarPlaceholder(user),
                          )
                        : _buildAvatarPlaceholder(user),
                  ),
                ),
              ),
            ),
            if (isMe)
              Positioned(
                bottom: 4,
                right: 4,
                child: GestureDetector(
                  onTap: _pickAndUploadAvatar,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DarkColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: DarkColors.background,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
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

  Widget _buildAvatarPlaceholder(UserModel user) {
    return Center(
      child: Text(
        user.name?[0].toUpperCase() ?? 'U',
        style: AppTypography.heading1.copyWith(
          color: DarkColors.accent,
          fontSize: 40,
        ),
      ),
    );
  }

  Widget _buildCompletionCard(UserModel user) {
    final completion = user.profileCompletion;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DarkColors.surface,
            DarkColors.surface.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile Strength',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: DarkColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${(completion * 100).toInt()}%',
                  style: AppTypography.bodySmall.copyWith(
                    color: DarkColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: completion,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: const AlwaysStoppedAnimation<Color>(
                DarkColors.accent,
              ),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionHint(UserModel user) {
    String hint = "";
    if (user.name == null || user.name!.isEmpty) {
      hint = "Add your full name";
    } else if (user.phone == null || user.phone!.isEmpty)
      hint = "Add your phone number";
    else if (user.nationalIdNumber == null || user.nationalIdNumber!.isEmpty)
      hint = "Add your National ID (Required for shifts)";
    else if (user.avatarPath == null)
      hint = "Upload a profile photo";
    else if (user.cvPath == null)
      hint = "Upload your CV to apply for jobs";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: DarkColors.accent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Next step: $hint',
              style: AppTypography.labelSmall.copyWith(
                color: DarkColors.textSecondary,
              ),
            ),
          ),
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
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DarkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: DarkColors.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: DarkColors.accent, size: 22),
        ),
        title: Text(
          title,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.labelSmall.copyWith(
            color: DarkColors.textSecondary,
            fontSize: 11,
          ),
        ),
        trailing:
            trailing ??
            const Icon(
              Icons.arrow_forward_ios_rounded,
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
