import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/rating_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/rating_model.dart';

class UserRatingsScreen extends ConsumerWidget {
  const UserRatingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    final ratingsAsync = ref.watch(userRatingsProvider(currentUser.id));

    return Scaffold(
      appBar: AppBar(title: const Text('My Ratings'), centerTitle: true),
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
                    color: AppColors.gray300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No ratings yet',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.sp(context, 18),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete events to receive ratings',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.sp(context, 14),
                      color: AppColors.textTertiary,
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
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: ResponsiveHelper.cardPadding(context),
                      child: Row(
                        children: [
                          // Big average
                          Column(
                            children: [
                              Text(
                                avg.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.sp(context, 40),
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < avg.round()
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: AppColors.accent,
                                    size: ResponsiveHelper.sp(context, 18),
                                  );
                                }),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${ratings.length} rating${ratings.length != 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.sp(context, 12),
                                  color: AppColors.textTertiary,
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
                                        style: TextStyle(
                                          fontSize: ResponsiveHelper.sp(
                                            context,
                                            12,
                                          ),
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.star,
                                        size: 12,
                                        color: AppColors.accent,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: pct,
                                            backgroundColor: AppColors.gray100,
                                            color: AppColors.accent,
                                            minHeight: 6,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 24,
                                        child: Text(
                                          '$count',
                                          style: TextStyle(
                                            fontSize: ResponsiveHelper.sp(
                                              context,
                                              11,
                                            ),
                                            color: AppColors.textTertiary,
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
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderColor),
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
                      color: AppColors.accent,
                      size: ResponsiveHelper.sp(context, 18),
                    );
                  }),
                ),
                const Spacer(),
                Text(
                  _formatDate(rating.createdAt),
                  style: TextStyle(
                    fontSize: ResponsiveHelper.sp(context, 11),
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            if (rating.textReview != null && rating.textReview!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                rating.textReview!,
                style: TextStyle(
                  fontSize: ResponsiveHelper.sp(context, 14),
                  color: AppColors.textSecondary,
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
