import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/glass.dart';
import '../../core/theme/shadows.dart';
import '../../core/theme/typography.dart';
import '../../models/event_model.dart';
import '../../core/utils/extensions.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;

  const EventCard({
    Key? key,
    required this.event,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: GlassContainer(
          blur: GlassConfig.blurMedium,
          opacity: 0.2,
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(GlassConfig.radiusLarge),
          addBorder: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event image placeholder
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(GlassConfig.radiusLarge),
                    topRight: Radius.circular(GlassConfig.radiusLarge),
                  ),
                  color: AppColors.gray200,
                ),
                child: event.imagePath != null
                    ? Image.network(
                        event.imagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.image_not_supported,
                            color: AppColors.gray400,
                            size: 48,
                          );
                        },
                      )
                    : Icon(
                        Icons.event,
                        color: AppColors.gray400,
                        size: 48,
                      ),
              ),
              // Event details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      event.title,
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.gray900,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Status badge
                    _buildStatusBadge(event.status),
                    const SizedBox(height: 12),
                    // Description
                    if (event.description != null)
                      Text(
                        event.description!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.gray600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 12),
                    // Event info row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Date & Time
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.gray500,
                              ),
                            ),
                            Text(
                              event.startTime.toDisplayDate(),
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.gray900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        // Capacity
                        if (event.capacity != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Capacity',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.gray500,
                                ),
                              ),
                              Text(
                                '${event.capacity} spots',
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.gray900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Location
                    if (event.location?.address != null)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event.location!.address!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.gray600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    // Apply button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onTap,
                        child: const Text('View Details'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'published':
        bgColor = AppColors.successGradient.colors[0].withOpacity(0.15);
        textColor = AppColors.success;
        icon = Icons.check_circle;
        break;
      case 'pending':
        bgColor = AppColors.warning.withOpacity(0.15);
        textColor = AppColors.warning;
        icon = Icons.schedule;
        break;
      case 'completed':
        bgColor = AppColors.info.withOpacity(0.15);
        textColor = AppColors.info;
        icon = Icons.task_alt;
        break;
      default:
        bgColor = AppColors.gray200;
        textColor = AppColors.gray600;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            status.replaceFirst(status[0], status[0].toUpperCase()),
            style: AppTypography.labelSmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
