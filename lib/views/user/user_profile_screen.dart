import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/typography.dart';
import '../../models/user_model.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/rating_controller.dart';
import '../../models/rating_model.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/perf_log.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/file_upload_service.dart';
import '../../core/utils/result.dart';

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
        backgroundColor: AppColors.backgroundPrimary,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(
            userAsync?.error?.toString() ?? 'User not found',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          // Elegant Sliver App Bar
          _buildSliverAppBar(context, isMe),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final widgets = [
                    // Header Section
                    RepaintBoundary(child: _buildHeader(user, isMe)),
                    const SizedBox(height: 24),

                    // Profile Completion Progress
                    RepaintBoundary(child: _buildCompletionCard(user)),
                    const SizedBox(height: 12),

                    if (isMe && user.profileCompletion < 1.0)
                      RepaintBoundary(child: _buildCompletionHint(user)),

                    const SizedBox(height: 24),

                    // 1. Personal Information
                    _buildSectionRow(
                      context,
                      title: 'Personal Information',
                      icon: Icons.person_outline,
                      subtitle:
                          '${user.name ?? "Not set"}, ${user.age != null ? "${user.age} yrs" : "Age missing"}',
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

                    // 2.5 National ID Verification (NEW)
                    if (isMe) ...[
                      const SizedBox(height: 8),
                      RepaintBoundary(child: _buildIdVerificationSection(user)),
                    ],

                    // 3. Portfolio & Documents
                    _buildSectionRow(
                      context,
                      title: 'Portfolio & Documents',
                      icon: Icons.folder_open,
                      subtitle: user.cvPath != null
                          ? 'CV Uploaded'
                          : 'Upload your CV (Optional)',
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

                    RepaintBoundary(
                      child: _buildRecentReviewsSection(context, ref, user.id),
                    ),

                    if (isMe) ...[
                      const SizedBox(height: 32),
                      OutlinedButton(
                        onPressed: () {
                          ref.read(authControllerProvider).logout();
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
                        child: const Center(child: Text('Logout')),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ];

                  if (index >= widgets.length) return null;
                  return widgets[index];
                },
                childCount: 15, // Approximate max count including spacers
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: false,
              ),
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

  Future<void> _pickAndUploadIdCard(bool isFront) async {
    if (_isUploading) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await image.readAsBytes();
      final result = isFront
          ? await ref
                .read(fileUploadServiceProvider)
                .uploadIdFront(fileName: image.name, bytes: bytes)
          : await ref
                .read(fileUploadServiceProvider)
                .uploadIdBack(fileName: image.name, bytes: bytes);

      if (result is Success<String>) {
        final currentUser = ref.read(currentUserProvider);
        if (currentUser != null) {
          // Update profile on backend is handled by the upload route itself for ID paths
          // But we need to refresh the local user state
          await ref.read(authControllerProvider).syncUser();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${isFront ? "Front" : "Back"} of ID uploaded!'),
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

  Widget _buildIdVerificationSection(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'National ID Verification',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildIdCardItem(
                title: 'Front Side',
                path: user.nationalIdFrontPath,
                onTap: () => _pickAndUploadIdCard(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildIdCardItem(
                title: 'Back Side',
                path: user.nationalIdBackPath,
                onTap: () => _pickAndUploadIdCard(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIdCardItem({
    required String title,
    String? path,
    required VoidCallback onTap,
  }) {
    final uploadService = ref.read(fileUploadServiceProvider);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: path != null
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Stack(
          children: [
            if (path != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: uploadService.getPublicUrl(path),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  memCacheHeight: 300,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      path != null ? Icons.check_circle : Icons.add_a_photo,
                      color: path != null ? AppColors.success : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isMe) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.backgroundPrimary,
      title: Text(
        isMe ? 'My Profile' : 'User Profile',
        style: AppTypography.titleLarge.copyWith(
          color: AppColors.textPrimary,
          fontSize: 18,
        ),
      ),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
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
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Hero(
                tag: 'profile_avatar',
                child: ClipOval(
                  child: Container(
                    width: 108,
                    height: 108,
                    color: AppColors.backgroundTertiary,
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
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.backgroundPrimary,
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
                              color: AppColors.textPrimary,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            color: AppColors.textPrimary,
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
          style: AppTypography.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        if (user.ratingCount > 0) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 20),
              const SizedBox(width: 4),
              Text(
                '${user.ratingAvg.toStringAsFixed(1)} (${user.ratingCount} reviews)',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAvatarPlaceholder(UserModel user) {
    return Center(
      child: Text(
        user.name?[0].toUpperCase() ?? 'U',
        style: AppTypography.heading1.copyWith(
          color: AppColors.primary,
          fontSize: 40,
        ),
      ),
    );
  }

  Widget _buildCompletionCard(UserModel user) {
    final completion = user.profileCompletion;
    final missing = _getMissingFields(user);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile Strength',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${(completion * 100).toInt()}%',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: completion,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Complete these to reach 100%:',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: missing.map((field) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                ),
                child: Text(
                  field,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontSize: 10,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _getMissingFields(UserModel user) {
    final List<String> missing = [];
    if (user.name == null || user.name!.isEmpty) missing.add('Full Name');
    if (user.phone == null || user.phone!.isEmpty) missing.add('Phone');
    if (user.nationalIdNumber == null || user.nationalIdNumber!.isEmpty) {
      missing.add('National ID');
    }
    if (user.age == null || user.age == 0) missing.add('Age');
    if (user.avatarPath == null) missing.add('Photo');
    if (user.cvPath == null) missing.add('CV');
    if (user.nationalIdFrontPath == null) missing.add('ID Front');
    if (user.nationalIdBackPath == null) missing.add('ID Back');
    return missing;
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
    else if (user.age == null)
      hint = "Add your age in profile settings";
    else if (user.nationalIdFrontPath == null ||
        user.nationalIdBackPath == null)
      hint = "Upload both sides of your National ID";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Next step: $hint',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
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
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(
          title,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        trailing:
            trailing ??
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textHint,
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
              style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
            ),
            TextButton(
              onPressed: () {
                context.push('/ratings/$userId');
              },
              child: Text(
                'View All',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
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
                  color: AppColors.textHint,
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
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
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
                    color: AppColors.primary,
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
                color: AppColors.textSecondary,
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
        color: AppColors.textHint,
        fontSize: 10,
      ),
    );
  }
}
