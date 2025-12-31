import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/glass.dart';
import '../../models/user_model.dart';
import '../../controllers/rating_controller.dart';

class RatingFormScreen extends ConsumerStatefulWidget {
  final String applicantId;
  final String applicantName;
  final String eventTitle;

  const RatingFormScreen({
    Key? key,
    required this.applicantId,
    required this.applicantName,
    required this.eventTitle,
  }) : super(key: key);

  @override
  ConsumerState<RatingFormScreen> createState() => _RatingFormScreenState();
}

class _RatingFormScreenState extends ConsumerState<RatingFormScreen> {
  int _rating = 0;
  late TextEditingController _reviewController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _reviewController = TextEditingController();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a rating'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Here you would call the rating controller to save the rating
      // await ref.read(ratingControllerProvider.notifier).submitRating(
      //   applicantId: widget.applicantId,
      //   rating: _rating,
      //   review: _reviewController.text,
      // );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rating submitted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: Text('Rate Applicant', style: AppTypography.heading2),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
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
                  Text('Rating Details', style: AppTypography.heading3),
                  const SizedBox(height: 16),
                  _InfoRow(label: 'Applicant', value: widget.applicantName),
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Event', value: widget.eventTitle),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Rating Stars
            Text('Your Rating', style: AppTypography.heading3),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            _rating > index ? Icons.star : Icons.star_border,
                            size: 48,
                            color: _rating > index
                                ? AppColors.warning
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_rating > 0)
                    Text(
                      _getRatingLabel(_rating),
                      style: AppTypography.heading3.copyWith(
                        color: _getRatingColor(_rating),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Review Text
            Text('Review (Optional)', style: AppTypography.heading3),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.glassSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accent.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _reviewController,
                maxLines: 5,
                style: AppTypography.body2,
                decoration: InputDecoration(
                  hintText: 'Share your feedback about the applicant...',
                  hintStyle: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Rating Criteria
            Text('Rating Criteria', style: AppTypography.heading3),
            const SizedBox(height: 12),
            _RatingCriterion(
              label: 'Excellent',
              rating: 5,
              description: 'Exceptional performance and skills',
              isSelected: _rating == 5,
            ),
            const SizedBox(height: 8),
            _RatingCriterion(
              label: 'Good',
              rating: 4,
              description: 'Strong performance and abilities',
              isSelected: _rating == 4,
            ),
            const SizedBox(height: 8),
            _RatingCriterion(
              label: 'Average',
              rating: 3,
              description: 'Meets basic requirements',
              isSelected: _rating == 3,
            ),
            const SizedBox(height: 8),
            _RatingCriterion(
              label: 'Below Average',
              rating: 2,
              description: 'Needs improvement',
              isSelected: _rating == 2,
            ),
            const SizedBox(height: 8),
            _RatingCriterion(
              label: 'Poor',
              rating: 1,
              description: 'Does not meet requirements',
              isSelected: _rating == 1,
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
                      style: AppTypography.body1.copyWith(
                        color: _isSubmitting
                            ? AppColors.textSecondary
                            : AppColors.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRating,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.accent.withOpacity(
                        0.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text('Submit', style: AppTypography.button),
                  ),
                ),
              ],
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
        return AppColors.success;
      case 4:
        return AppColors.accent;
      case 3:
        return AppColors.warning;
      case 2:
      case 1:
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({Key? key, required this.label, required this.value})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: AppTypography.body1,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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

  const _RatingCriterion({
    Key? key,
    required this.label,
    required this.rating,
    required this.description,
    required this.isSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.accent.withOpacity(0.1)
            : AppColors.glassSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.accent : Colors.transparent,
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
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
                width: 2,
              ),
            ),
            child: isSelected
                ? Icon(Icons.check, size: 16, color: AppColors.accent)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.body1.copyWith(
                    color: isSelected ? AppColors.accent : AppColors.text,
                  ),
                ),
                Text(
                  description,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
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
                    ? AppColors.warning
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
