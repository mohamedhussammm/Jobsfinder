import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/colors.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          )
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(
            duration: 1500.ms,
            color: AppColors.shimmerHighlight,
          ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SkeletonLoader(width: 76, height: 76, borderRadius: 10),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(width: 60, height: 12),
                const SizedBox(height: 8),
                const SkeletonLoader(width: double.infinity, height: 18),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Flexible(child: SkeletonLoader(width: 40, height: 10)),
                    SizedBox(width: 8),
                    Flexible(child: SkeletonLoader(width: 80, height: 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonHeroCard extends StatelessWidget {
  const SkeletonHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.85;
    return RepaintBoundary(
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: const SkeletonLoader(
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonLoader(width: 80, height: 12),
                  SizedBox(height: 8),
                  SkeletonLoader(width: double.infinity, height: 20),
                  SizedBox(height: 8),
                  SkeletonLoader(width: 120, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
