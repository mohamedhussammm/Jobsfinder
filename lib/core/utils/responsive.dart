import 'package:flutter/material.dart';

/// Responsive design utility for adapting UI to all screen sizes
class ResponsiveHelper {
  // Base design dimensions (iPhone 13/14 = 375x812)
  static const double _baseWidth = 375.0;
  static const double _baseHeight = 812.0;

  /// Check if device is a small phone (< 360dp)
  static bool isSmallPhone(BuildContext context) =>
      MediaQuery.of(context).size.width < 360;

  /// Check if device is a regular phone (< 600dp)
  static bool isPhone(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  /// Check if device is a tablet (>= 600dp)
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600;

  /// Check if device is a large tablet or desktop (>= 900dp)
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;

  /// Get screen width
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  /// Get screen height
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// Scale factor based on screen width (clamped between 0.8 and 1.3)
  static double scaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return (width / _baseWidth).clamp(0.8, 1.3);
  }

  /// Scaled font size
  static double sp(BuildContext context, double size) {
    return size * scaleFactor(context);
  }

  /// Scaled width dimension
  static double wp(BuildContext context, double size) {
    return size * (MediaQuery.of(context).size.width / _baseWidth);
  }

  /// Scaled height dimension
  static double hp(BuildContext context, double size) {
    return size * (MediaQuery.of(context).size.height / _baseHeight);
  }

  /// Responsive padding based on screen size
  static EdgeInsets screenPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    }
    if (width < 600) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    }
    if (width < 900) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
    return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
  }

  /// Responsive card padding
  static EdgeInsets cardPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return const EdgeInsets.all(12);
    if (width < 600) return const EdgeInsets.all(16);
    return const EdgeInsets.all(20);
  }

  /// Responsive grid column count
  static int gridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 1;
    if (width < 600) return 2;
    if (width < 900) return 3;
    return 4;
  }

  /// Responsive bottom nav icon size
  static double iconSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 20;
    if (width < 600) return 24;
    return 28;
  }

  /// Responsive button height
  static double buttonHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 44;
    if (width < 600) return 48;
    return 52;
  }

  /// Responsive avatar radius
  static double avatarRadius(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 28;
    if (width < 600) return 36;
    return 44;
  }

  /// Responsive dialog width factor
  static double dialogWidthFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 0.9;
    if (width < 900) return 0.7;
    return 0.5;
  }

  /// Get the number of KPI cards per row
  static int kpiCardsPerRow(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 1;
    if (width < 600) return 2;
    return 4;
  }
}

/// Responsive extension on BuildContext for convenience
extension ResponsiveContext on BuildContext {
  bool get isSmallPhone => ResponsiveHelper.isSmallPhone(this);
  bool get isPhone => ResponsiveHelper.isPhone(this);
  bool get isTablet => ResponsiveHelper.isTablet(this);
  double get screenW => ResponsiveHelper.screenWidth(this);
  double get screenH => ResponsiveHelper.screenHeight(this);
  EdgeInsets get responsivePadding => ResponsiveHelper.screenPadding(this);
  EdgeInsets get responsiveCardPadding => ResponsiveHelper.cardPadding(this);
}
