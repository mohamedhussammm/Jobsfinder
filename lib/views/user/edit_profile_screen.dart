import 'package:flutter/material.dart';
import '../../core/utils/perf_log.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/responsive.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/file_upload_service.dart';
import '../../core/utils/result.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/dark_colors.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _nationalIdController = TextEditingController();
  bool _isLoading = false;
  bool _isUploading = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    PerfLog.init('EditProfileScreen');
  }

  @override
  void dispose() {
    PerfLog.dispose('EditProfileScreen');
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  void _initFields() {
    if (_initialized) return;
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      _nameController.text = currentUser.name ?? '';
      _phoneController.text = currentUser.phone ?? '';
      _emailController.text = currentUser.email;
      _nationalIdController.text = currentUser.nationalIdNumber ?? '';
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    PerfLog.build('EditProfileScreen');
    _initFields();
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile'), centerTitle: true),
      body: SingleChildScrollView(
        padding: ResponsiveHelper.screenPadding(context),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar section
              Center(
                child: Stack(
                  children: [
                    ClipOval(
                      child: Container(
                        width: ResponsiveHelper.sp(context, 100),
                        height: ResponsiveHelper.sp(context, 100),
                        color: DarkColors.surface,
                        child: currentUser?.avatarPath != null
                            ? CachedNetworkImage(
                                imageUrl:
                                    "${ref.watch(fileUploadServiceProvider).getPublicUrl(currentUser!.avatarPath!)}${currentUser.avatarPath!.contains('?') ? '&' : '?'}v=${currentUser.updatedAt.millisecondsSinceEpoch}",
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    _buildAvatarPlaceholder(currentUser),
                              )
                            : (currentUser != null)
                            ? _buildAvatarPlaceholder(currentUser)
                            : Icon(
                                Icons.person,
                                size: ResponsiveHelper.sp(context, 48),
                                color: DarkColors.accent,
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: DarkColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: DarkColors.background,
                            width: 2,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: _isUploading ? null : _pickAndUploadAvatar,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveHelper.sp(context, 24)),

              // Name
              _buildLabel('Full Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Your name', Icons.person_outline),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // Email (read-only)
              _buildLabel('Email'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration('Email', Icons.email_outlined),
                enabled: false,
              ),
              const SizedBox(height: 16),

              // Phone
              _buildLabel('Phone Number'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                decoration: _inputDecoration('Phone', Icons.phone_outlined),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // National ID
              _buildLabel('National ID'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nationalIdController,
                decoration: _inputDecoration('ID Number', Icons.badge_outlined),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'National ID is required' : null,
              ),
              const SizedBox(height: 16),

              // Role (read-only)
              _buildLabel('Role'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      (currentUser?.role ?? 'User').toUpperCase(),
                      style: TextStyle(
                        fontSize: ResponsiveHelper.sp(context, 14),
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveHelper.sp(context, 32)),

              // Save button
              SizedBox(
                width: double.infinity,
                height: ResponsiveHelper.buttonHeight(context),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.sp(context, 16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: ResponsiveHelper.sp(context, 14),
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      // inherits from global theme's inputDecorationTheme
    );
  }

  Widget _buildAvatarPlaceholder(UserModel user) {
    return Center(
      child: Text(
        user.name?[0].toUpperCase() ?? 'U',
        style: TextStyle(
          color: DarkColors.accent,
          fontSize: ResponsiveHelper.sp(context, 40),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    final authController = ref.read(authControllerProvider);
    final success = await authController.updateProfile(
      userId: currentUser.id,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      nationalIdNumber: _nationalIdController.text.trim().isNotEmpty
          ? _nationalIdController.text.trim()
          : null,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
