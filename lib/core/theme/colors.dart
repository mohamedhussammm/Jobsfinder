import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color backgroundPrimary   = Color(0xFFF7F9FF); // main bg
  static const Color backgroundSecondary = Color(0xFFE8EEFF); // cards, surfaces
  static const Color backgroundTertiary  = Color(0xFFFFFFFF); // elevated cards

  // Brand
  static const Color primary             = Color(0xFF6B4EFF); // Bond Purple
  static const Color primaryLight        = Color(0xFFF3F0FF); // soft purple
  static const Color primaryDark         = Color(0xFF563DCC); // deep purple

  // Accent (event energy / CTA highlights)
  static const Color accent              = Color(0xFFE07B14); // amber accent
  static const Color accentLight         = Color(0xFFFEF0DA); // amber badge bg
  static const Color accentDark          = Color(0xFFA05808); // amber text on light bg

  // Text
  static const Color textPrimary         = Color(0xFF1A2340); // headings
  static const Color textSecondary       = Color(0xFF6B7A99); // subtitles, captions
  static const Color textHint            = Color(0xFFAAB4CC); // placeholders

  // Status
  static const Color success             = Color(0xFF3D8A5F);
  static const Color successLight        = Color(0xFFDFF0E3);
  static const Color warning             = Color(0xFFE07B14);
  static const Color warningLight        = Color(0xFFFEF0DA);
  static const Color error               = Color(0xFFD64040);
  static const Color errorLight          = Color(0xFFFFECEC);
  static const Color info                = Color(0xFF6B4EFF);
  static const Color infoLight           = Color(0xFFF3F0FF);

  // Borders & Dividers
  static const Color border              = Color(0xFFDDE3F0);
  static const Color borderStrong        = Color(0xFFB8C4DF);
  static const Color divider             = Color(0xFFEEF1F8);

  // Glassmorphism (light version)
  static const Color glassBackground     = Color(0xCCFFFFFF); // white at 80% opacity
  static const Color glassBorder         = Color(0x4DFFFFFF);

  // Navigation
  static const Color navBackground       = Color(0xFFFFFFFF);
  static const Color navSelected         = Color(0xFF6B4EFF);
  static const Color navUnselected       = Color(0xFF9AA5BE);

  // Shimmer / Skeleton
  static const Color shimmerBase         = Color(0xFFE8EEFF);
  static const Color shimmerHighlight    = Color(0xFFF7F9FF);

  // Role-specific tints (for admin/team leader headers)
  static const Color adminTint           = Color(0xFFEDE8FF); // soft violet
  static const Color teamLeaderTint      = Color(0xFFDFF0E3); // soft green
  static const Color white               = Color(0xFFFFFFFF);
  static const Color textTertiary        = Color(0xFFAAB4CC); // Alias for hint

  // Aliases for legacy system compatibility
  static const Color surface             = Color(0xFFFFFFFF);
  static const Color borderColor         = Color(0xFFDDE3F0);
  static const Color pending             = Color(0xFFE07B14);
  static const Color secondary           = Color(0xFFE07B14); // Usually maps to accent

  // Gray scale aliases
  static const Color gray50              = Color(0xFFF9FAFB);
  static const Color gray100             = Color(0xFFF3F4F6);
  static const Color gray200             = Color(0xFFE5E7EB);
  static const Color gray300             = Color(0xFFD1D5DB);
  static const Color gray400             = Color(0xFF9CA3AF);
  static const Color gray500             = Color(0xFF6B7280);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
