import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/rating_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/dark_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/glass.dart';
import '../../core/utils/responsive.dart';
import '../../models/rating_model.dart';

class UserRatingsScreen extends ConsumerWidget {
  final String? userId;

  const UserRatingsScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSessionUser = ref.watch(currentUserProvider);
    final targetUserId = userId ?? currentSessionUser?.id;

    if (targetUserId == null) {
      return const Scaffold(
        backgroundColor: DarkColors.background,
        body: Center(
          child: Text('User not found', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final ratingsAsync = ref.watch(userRatingsProvider(targetUserId));

    return Scaffold(
      backgroundColor: DarkColors.background,
      appBar: AppBar(
        title: Text(
          'My Ratings',
          style: AppTypography.titleLarge.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ratingsAsync.when(
        data: (ratings) {
          if (ratings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_border,
                    size: ResponsiveHelper.sp(context, 64),
                    color: DarkColors.textTertiary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No ratings yet',
                    style: AppTypography.titleMedium.copyWith(
                      color: DarkColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete events to receive ratings',
                    style: AppTypography.bodySmall.copyWith(
                      color: DarkColors.textTertiary,
                    ),
                  ),
                ],
              ),
            );
          }

          // Calculate average
          final avg =
              ratings.fold<double>(0, (sum, r) => sum + r.score) /
              ratings.length;

          return CustomScrollView(
            slivers: [
              // Summary card
              SliverToBoxAdapter(
                child: Padding(
                  padding: ResponsiveHelper.screenPadding(context),
                  child: GlassContainer(
                    padding: ResponsiveHelper.cardPadding(context),
                    child: Row(
                      children: [
                        // Big average
                        Column(
                          children: [
                            Text(
                              avg.toStringAsFixed(1),
                              style: AppTypography.heading1.copyWith(
                                fontSize: ResponsiveHelper.sp(context, 40),
                                color: Colors.white,
                              ),
                            ),
                            Row(
                              children: List.generate(5, (i) {
                                return Icon(
                                  i < avg.round()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: DarkColors.accent,
                                  size: ResponsiveHelper.sp(context, 18),
                                );
                              }),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${ratings.length} rating${ratings.length != 1 ? 's' : ''}',
                              style: AppTypography.labelSmall.copyWith(
                                color: DarkColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        // Distribution bars
                        Expanded(
                          child: Column(
                            children: List.generate(5, (i) {
                              final star = 5 - i;
                              final count = ratings
                                  .where((r) => r.score == star)
                                  .length;
                              final pct = ratings.isNotEmpty
                                  ? count / ratings.length
                                  : 0.0;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '$star',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: DarkColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.star,
                                      size: 12,
                                      color: DarkColors.accent,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: pct,
                                          backgroundColor: DarkColors.gray100,
                                          color: DarkColors.accent,
                                          minHeight: 6,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Ratings list
              SliverPadding(
                padding: ResponsiveHelper.screenPadding(context),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final rating = ratings[index];
                    return _buildRatingCard(context, rating);
                  }, childCount: ratings.length),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildRatingCard(BuildContext context, RatingModel rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DarkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DarkColors.borderColor),
      ),
      child: Padding(
        padding: ResponsiveHelper.cardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Stars
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < rating.score ? Icons.star : Icons.star_border,
                      color: DarkColors.accent,
                      size: ResponsiveHelper.sp(context, 16),
                    );
                  }),
                ),
                const Spacer(),
                Text(
                  _formatDate(rating.createdAt),
                  style: AppTypography.labelSmall.copyWith(
                    color: DarkColors.textTertiary,
                  ),
                ),
              ],
            ),
            if (rating.textReview != null && rating.textReview!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                rating.textReview!,
                style: AppTypography.bodySmall.copyWith(
                  color: DarkColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
