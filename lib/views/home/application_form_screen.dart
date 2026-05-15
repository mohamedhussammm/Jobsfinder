import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../controllers/application_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../services/file_upload_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';

class ApplicationFormScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventTitle;

  const ApplicationFormScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  ConsumerState<ApplicationFormScreen> createState() =>
      _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends ConsumerState<ApplicationFormScreen> {
  late final TextEditingController _coverLetterController;
  late final TextEditingController _experienceController;

  bool _isAvailable = false;
  bool _openToOtherOptions = false;
  bool _agreedToTerms = false;
  bool _isSubmitting = false;

  // CV Upload state
  String? _cvFileName;
  Uint8List? _cvBytes;

  @override
  void initState() {
    super.initState();
    _coverLetterController = TextEditingController();
    _experienceController = TextEditingController();
  }

  @override
  void dispose() {
    _coverLetterController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _pickCV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _cvFileName = result.files.single.name;
          _cvBytes = result.files.single.bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.backgroundPrimary,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Apply for Event',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Info Context
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event_available_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You are applying for',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.eventTitle,
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
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
            const SizedBox(height: 32),

            // Experience Section
            _buildSectionTitle(
              'Relevant Experience',
              'Tell us about your background for this role',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _experienceController,
              hint: 'Describe your previous experience in similar events...',
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // Cover Letter Section
            _buildSectionTitle(
              'Cover Letter (Optional)',
              'Tell us why you\'re a great fit',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _coverLetterController,
              hint: 'Add any additional details or message to the organizer...',
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // CV Upload Section
            _buildSectionTitle(
              'Resume / CV (Optional)',
              'Upload your CV to stand out',
            ),
            const SizedBox(height: 12),
            _buildCVUploadButton(),
            const SizedBox(height: 32),

            // Confirmations Section
            _buildSectionTitle('Confirmations', 'Please verify the following'),
            const SizedBox(height: 12),
            _buildConfirmationItem(
              title: 'Availability Confirmation',
              subtitle:
                  'I confirm that I am available for the full duration of this event.',
              value: _isAvailable,
              onChanged: (v) => setState(() => _isAvailable = v!),
            ),
            const SizedBox(height: 12),
            _buildConfirmationItem(
              title: 'Alternative Opportunities',
              subtitle:
                  'I am open to being considered for other similar roles or future events.',
              value: _openToOtherOptions,
              onChanged: (v) => setState(() => _openToOtherOptions = v!),
            ),
            const SizedBox(height: 12),
            _buildConfirmationItem(
              title: 'Terms & Accuracy',
              subtitle:
                  'I agree to the Terms & Conditions and confirm my data is accurate.',
              value: _agreedToTerms,
              onChanged: (v) => setState(() => _agreedToTerms = v!),
            ),

            const SizedBox(height: 40),

            // Submit Buttons
            _buildSubmitButton(),
            const SizedBox(height: 100), // Spacing for bottom
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.backgroundTertiary,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCVUploadButton() {
    return InkWell(
      onTap: _pickCV,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _cvFileName != null
                ? AppColors.primary
                : AppColors.border,
            width: _cvFileName != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _cvFileName != null
                  ? Icons.description_rounded
                  : Icons.upload_file_rounded,
              color: _cvFileName != null ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _cvFileName ?? 'Tap to select PDF/DOC file',
                style: TextStyle(
                  color: _cvFileName != null ? Colors.white : AppColors.textSecondary,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_cvFileName != null)
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () => setState(() {
                  _cvFileName = null;
                  _cvBytes = null;
                }),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.scale(
            scale: 0.9,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: const BorderSide(color: AppColors.textHint),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final bool canSubmit = _agreedToTerms && !_isSubmitting;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canSubmit ? _submitApplication : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.textPrimary,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Submit Application',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _submitApplication() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    String? cvUrl;
    if (_cvBytes != null && _cvFileName != null) {
      final uploadResult = await ref
          .read(fileUploadServiceProvider)
          .uploadCV(fileName: _cvFileName!, bytes: _cvBytes!);

      uploadResult.when(
        success: (url) => cvUrl = url,
        error: (e) {
          // Continue anyway or show error? Let's show warning
          debugPrint('CV Upload failed: ${e.message}');
        },
      );
    }

    final controller = ref.read(applicationControllerProvider);
    final result = await controller.applyToEvent(
      userId: currentUser.id,
      eventId: widget.eventId,
      experience: _experienceController.text.trim(),
      coverLetter: _coverLetterController.text.trim(),
      cvPath: cvUrl,
      isAvailable: _isAvailable,
      openToOtherOptions: _openToOtherOptions,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (application) {
        ref.invalidate(userApplicationsProvider(currentUser.id));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/applications');
      },
      error: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}
