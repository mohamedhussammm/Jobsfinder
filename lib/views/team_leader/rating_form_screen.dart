import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/dark_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/glass.dart';
import '../../controllers/rating_controller.dart';
import '../../controllers/auth_controller.dart';

class RatingFormScreen extends ConsumerStatefulWidget {
  final String applicantId;
  final String applicantName;
  final String eventTitle;
  final String eventId;

  const RatingFormScreen({
    super.key,
    required this.applicantId,
    required this.applicantName,
    required this.eventTitle,
    required this.eventId,
  });

  @override
  ConsumerState<RatingFormScreen> createState() => _RatingFormScreenState();
}

class _RatingFormScreenState extends ConsumerState<RatingFormScreen> {
  int _rating = 0;
  late TextEditingController _reviewController;
  bool _isSubmitting = false;
  bool _alreadyRated = false;
  bool _checkingExisting = true;

  @override
  void initState() {
    super.initState();
    _reviewController = TextEditingController();
    _checkIfAlreadyRated();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _checkIfAlreadyRated() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      setState(() => _checkingExisting = false);
      return;
    }
    final result = await ref
        .read(ratingControllerProvider)
        .hasRatedApplicant(
          raterUserId: currentUser.id,
          ratedUserId: widget.applicantId,
          eventId: widget.eventId,
        );
    if (mounted) {
      setState(() {
        _alreadyRated = result;
        _checkingExisting = false;
      });
    }
  }

  void _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a rating'),
          backgroundColor: DarkColors.error,
        ),
      );
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You must be logged in to rate'),
          backgroundColor: DarkColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await ref
        .read(ratingControllerProvider)
        .rateApplicant(
          raterUserId: currentUser.id,
          ratedUserId: widget.applicantId,
          eventId: widget.eventId,
          score: _rating,
          textReview: _reviewController.text.trim().isEmpty
              ? null
              : _reviewController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rating submitted successfully! ⭐'),
            backgroundColor: DarkColors.success,
          ),
        );
        context.pop();
      },
      error: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: DarkColors.error),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkColors.background,
      appBar: AppBar(
        title: Text(
          'Rate Applicant',
          style: AppTypography.headlineMedium.copyWith(color: Colors.white),
        ),
        centerTitle: false,
      ),
      body: _checkingExisting
          ? const Center(child: CircularProgressIndicator())
          : _alreadyRated
          ? _buildAlreadyRatedState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Applicant Info Card
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rating Details',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(
                          label: 'Applicant',
                          value: widget.applicantName,
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(label: 'Event', value: widget.eventTitle),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Rating Stars
                  Text(
                    'Your Rating',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            5,
                            (index) => GestureDetector(
                              onTap: () => setState(() => _rating = index + 1),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Icon(
                                  _rating > index
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 48,
                                  color: _rating > index
                                      ? DarkColors.accent
                                      : DarkColors.textTertiary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_rating > 0)
                          Text(
                            _getRatingLabel(_rating),
                            style: AppTypography.titleMedium.copyWith(
                              color: _getRatingColor(_rating),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Review Text
                  Text(
                    'Review (Optional)',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: DarkColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: DarkColors.accent.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _reviewController,
                      maxLines: 5,
                      style: AppTypography.body2,
                      decoration: InputDecoration(
                        hintText: 'Share your feedback about the applicant...',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: DarkColors.textTertiary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Rating Criteria
                  Text(
                    'Rating Criteria',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _RatingCriterion(
                    label: 'Excellent',
                    rating: 5,
                    description: 'Exceptional performance and skills',
                    isSelected: _rating == 5,
                    onTap: () => setState(() => _rating = 5),
                  ),
                  const SizedBox(height: 8),
                  _RatingCriterion(
                    label: 'Good',
                    rating: 4,
                    description: 'Strong performance and abilities',
                    isSelected: _rating == 4,
                    onTap: () => setState(() => _rating = 4),
                  ),
                  const SizedBox(height: 8),
                  _RatingCriterion(
                    label: 'Average',
                    rating: 3,
                    description: 'Meets basic requirements',
                    isSelected: _rating == 3,
                    onTap: () => setState(() => _rating = 3),
                  ),
                  const SizedBox(height: 8),
                  _RatingCriterion(
                    label: 'Below Average',
                    rating: 2,
                    description: 'Needs improvement',
                    isSelected: _rating == 2,
                    onTap: () => setState(() => _rating = 2),
                  ),
                  const SizedBox(height: 8),
                  _RatingCriterion(
                    label: 'Poor',
                    rating: 1,
                    description: 'Does not meet requirements',
                    isSelected: _rating == 1,
                    onTap: () => setState(() => _rating = 1),
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isSubmitting ? null : () => context.pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTypography.bodyLarge.copyWith(
                              color: _isSubmitting
                                  ? DarkColors.textTertiary
                                  : DarkColors.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitRating,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DarkColors.accent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: DarkColors.accent
                                .withValues(alpha: 0.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Submit Rating',
                                  style: AppTypography.button,
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAlreadyRatedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 80, color: DarkColors.success),
            const SizedBox(height: 24),
            Text(
              'Already Rated',
              style: AppTypography.headlineMedium.copyWith(
                color: DarkColors.success,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You have already submitted a rating for ${widget.applicantName} for this event.',
              style: AppTypography.bodyLarge.copyWith(
                color: DarkColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: DarkColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 5:
        return 'Excellent';
      case 4:
        return 'Good';
      case 3:
        return 'Average';
      case 2:
        return 'Below Average';
      case 1:
        return 'Poor';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5:
        return DarkColors.success;
      case 4:
        return DarkColors.accent;
      case 3:
        return DarkColors.pending;
      case 2:
      case 1:
        return DarkColors.error;
      default:
        return DarkColors.textSecondary;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: DarkColors.textTertiary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: AppTypography.bodyLarge.copyWith(color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _RatingCriterion extends StatelessWidget {
  final String label;
  final int rating;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _RatingCriterion({
    required this.label,
    required this.rating,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? DarkColors.accent.withValues(alpha: 0.1)
              : DarkColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? DarkColors.accent : DarkColors.borderColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? DarkColors.accent
                      : DarkColors.textTertiary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: DarkColors.accent)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodyLarge.copyWith(
                      color: isSelected ? DarkColors.accent : Colors.white,
                    ),
                  ),
                  Text(
                    description,
                    style: AppTypography.labelSmall.copyWith(
                      color: DarkColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  size: 12,
                  color: index < rating
                      ? DarkColors.accent
                      : DarkColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
