import 'package:flutter/material.dart';
import 'dart:ui';
import 'colors.dart';
import 'dark_colors.dart';
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
      color: glassColor.withValues(alpha: opacity),
      border: addBorder
          ? Border.all(color: borderColor, width: borderWidth)
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

  /// TEAL-TINTED GLASS — matches reference designs
  static BoxDecoration tealGlassDecoration({
    double opacity = 0.08,
    BorderRadius? borderRadius,
    bool addBorder = true,
  }) {
    return BoxDecoration(
      borderRadius: borderRadius ?? BorderRadius.circular(radiusLarge),
      color: DarkColors.surface,
      border: addBorder
          ? Border.all(color: DarkColors.borderColor, width: 1)
          : null,
      boxShadow: [
        BoxShadow(
          color: DarkColors.primary.withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// GRADIENT CARD — navy to darker navy
  static BoxDecoration cardGradientDecoration({
    BorderRadius? borderRadius,
    bool addBorder = true,
  }) {
    return BoxDecoration(
      borderRadius: borderRadius ?? BorderRadius.circular(radiusLarge),
      gradient: DarkColors.cardGradient,
      border: addBorder
          ? Border.all(color: DarkColors.borderColor, width: 1)
          : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// HERO GRADIENT — for prominent cards
  static BoxDecoration heroGradientDecoration({
    BorderRadius? borderRadius,
    bool addBorder = true,
  }) {
    return BoxDecoration(
      borderRadius: borderRadius ?? BorderRadius.circular(radiusLarge),
      gradient: DarkColors.heroGradient,
      border: addBorder
          ? Border.all(
              color: DarkColors.primary.withValues(alpha: 0.3),
              width: 1.5,
            )
          : null,
      boxShadow: [
        BoxShadow(
          color: DarkColors.primary.withValues(alpha: 0.15),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Glow effect for buttons or interactive elements
  static BoxDecoration glowDecoration({
    Color glowColor = const Color(0xFF0EA5E9),
    double opacity = 0.15,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      borderRadius: borderRadius ?? BorderRadius.circular(radiusLarge),
      color: glowColor.withValues(alpha: opacity),
      boxShadow: [
        BoxShadow(
          color: glowColor.withValues(alpha: 0.2),
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
  final GlassStyle style;

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
    this.style = GlassStyle.standard,
  });

  /// Teal-tinted glass (matches reference designs)
  const GlassContainer.teal({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.onTap,
  }) : opacity = 0.08,
       blur = GlassConfig.blurMedium,
       decoration = null,
       addBorder = true,
       style = GlassStyle.teal;

  /// Card with gradient background
  const GlassContainer.gradient({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.onTap,
  }) : opacity = 0,
       blur = 0,
       decoration = null,
       addBorder = true,
       style = GlassStyle.gradient;

  /// Hero card with prominent gradient
  const GlassContainer.hero({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius,
    this.onTap,
  }) : opacity = 0,
       blur = 0,
       decoration = null,
       addBorder = true,
       style = GlassStyle.hero;

  @override
  Widget build(BuildContext context) {
    final effectiveDecoration = decoration ?? _getStyleDecoration();

    if (blur > 0) {
      return ClipRRect(
        borderRadius:
            borderRadius ?? BorderRadius.circular(GlassConfig.radiusLarge),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: _buildContainer(effectiveDecoration),
        ),
      );
    }

    return _buildContainer(effectiveDecoration);
  }

  Widget _buildContainer(BoxDecoration decoration) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: decoration,
        child: child,
      ),
    );
  }

  BoxDecoration _getStyleDecoration() {
    switch (style) {
      case GlassStyle.teal:
        return GlassConfig.tealGlassDecoration(
          borderRadius: borderRadius,
          addBorder: addBorder,
        );
      case GlassStyle.gradient:
        return GlassConfig.cardGradientDecoration(
          borderRadius: borderRadius,
          addBorder: addBorder,
        );
      case GlassStyle.hero:
        return GlassConfig.heroGradientDecoration(
          borderRadius: borderRadius,
          addBorder: addBorder,
        );
      case GlassStyle.standard:
        return GlassConfig.glassDecoration(
          opacity: opacity,
          blur: blur,
          borderRadius: borderRadius,
          addBorder: addBorder,
        );
    }
  }
}

enum GlassStyle { standard, teal, gradient, hero }
