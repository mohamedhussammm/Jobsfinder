import 'package:flutter/material.dart';
import 'dart:ui';
import 'colors.dart';
import 'shadows.dart';

/// Glassmorphic widget styling utilities
class GlassConfig {
  // Blur amounts
  static const double blurSmall = 4;
  static const double blurMedium = 8;
  static const double blurLarge = 12;
  static const double blurXL = 16;

  // Border radius
  static const double radiusSmall = 12;
  static const double radiusMedium = 16;
  static const double radiusLarge = 20;
  static const double radiusXL = 28;

  // Opacity levels
  static const double opacityLow = 0.1;
  static const double opacityMedium = 0.2;
  static const double opacityHigh = 0.3;
  static const double opacityVeryHigh = 0.4;

  /// Create a glassmorphic container decoration
  static BoxDecoration glassDecoration({
    Color glassColor = const Color.fromARGB(255, 255, 255, 255),
    double opacity = 0.15,
    double blur = blurMedium,
    BorderRadius? borderRadius,
    bool addBorder = true,
    Color borderColor = const Color.fromARGB(50, 255, 255, 255),
    double borderWidth = 1.5,
  }) {
    return BoxDecoration(
      borderRadius: borderRadius ?? BorderRadius.circular(radiusLarge),
      color: glassColor.withOpacity(opacity),
      border: addBorder
          ? Border.all(
              color: borderColor,
              width: borderWidth,
            )
          : null,
      boxShadow: AppShadows.glass,
    );
  }

  /// Create a dark glassmorphic decoration (for dark backgrounds)
  static BoxDecoration darkGlassDecoration({
    double opacity = 0.1,
    double blur = blurMedium,
    BorderRadius? borderRadius,
    bool addBorder = true,
  }) {
    return glassDecoration(
      glassColor: AppColors.white,
      opacity: opacity,
      blur: blur,
      borderRadius: borderRadius,
      addBorder: addBorder,
    );
  }

  /// Glow effect for buttons or interactive elements
  static BoxDecoration glowDecoration({
    Color glowColor = const Color(0xFF6366F1),
    double opacity = 0.15,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      borderRadius: borderRadius ?? BorderRadius.circular(radiusLarge),
      color: glowColor.withOpacity(opacity),
      boxShadow: [
        BoxShadow(
          color: glowColor.withOpacity(0.2),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

/// Glassmorphic widget helper
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  final double opacity;
  final double blur;
  final VoidCallback? onTap;
  final BoxDecoration? decoration;
  final bool addBorder;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.opacity = 0.15,
    this.blur = GlassConfig.blurMedium,
    this.onTap,
    this.decoration,
    this.addBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(GlassConfig.radiusLarge),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: width,
            height: height,
            padding: padding,
            decoration: decoration ??
                GlassConfig.glassDecoration(
                  opacity: opacity,
                  blur: blur,
                  borderRadius: borderRadius,
                  addBorder: addBorder,
                ),
            child: child,
          ),
        ),
      ),
    );
  }
}
