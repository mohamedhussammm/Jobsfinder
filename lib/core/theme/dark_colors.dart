import 'package:flutter/material.dart';

/// Dark theme color palette — matches reference designs with navy + cyan/teal
class DarkColors {
  // Primary Colors — CYAN/TEAL (brighter for dark backgrounds)
  static const Color primary = Color(0xFF0EA5E9);
  static const Color primaryLight = Color(0xFF1E3A5F);
  static const Color primaryDark = Color(0xFF0284C7);

  // Secondary Colors
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryLight = Color(0xFF0D3326);
  static const Color secondaryDark = Color(0xFF059669);

  // Accent Colors
  static const Color accent = Color(0xFFFBBF24);
  static const Color accentLight = Color(0xFF3D3216);
  static const Color accentDark = Color(0xFFF59E0B);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);
  static const Color info = Color(0xFF0EA5E9);

  // Neutral Colors — DEEP NAVY PALETTE
  static const Color gray50 = Color(0xFF0A0E1A); // Deep navy background
  static const Color gray100 = Color(0xFF131B2E); // Card surface
  static const Color gray200 = Color(0xFF1E2D3D); // Borders (teal-tinted)
  static const Color gray300 = Color(0xFF2A3F54);
  static const Color gray400 = Color(0xFF64748B);
  static const Color gray500 = Color(0xFF94A3B8);
  static const Color gray600 = Color(0xFFCBD5E1);
  static const Color gray700 = Color(0xFFE2E8F0);
  static const Color gray800 = Color(0xFFF1F5F9);
  static const Color gray900 = Color(0xFFF8FAFC);

  // Semantic Colors — NAVY-FIRST
  static const Color background = Color(0xFF0A0E1A); // Deep navy
  static const Color surface = Color(0xFF131B2E); // Teal-tinted navy
  static const Color borderColor = Color(0xFF1E2D3D); // Subtle teal border

  // Text Colors
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);

  // Status-specific (same as light for consistency)
  static const Color pending = Color(0xFFFBBF24);
  static const Color published = Color(0xFF10B981);
  static const Color completed = Color(0xFF0EA5E9);
  static const Color cancelled = Color(0xFFF87171);

  // Gradients — TEAL-TINTED
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF131B2E), // surface
      Color(0xFF0F1621), // slightly darker
    ],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E3A5F), // primaryLight
      Color(0xFF0A0E1A), // background
    ],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.fromARGB(40, 14, 165, 233), // primary with alpha
      Color.fromARGB(10, 14, 165, 233),
    ],
  );
}
