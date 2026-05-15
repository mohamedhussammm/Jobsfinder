import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  // Font families (for reference)
  static String get fontFamily => GoogleFonts.poppins().fontFamily!;
  static String get fontFamilyMono => GoogleFonts.jetBrainsMono().fontFamily!;

  // Display styles (large headlines)
  static final TextStyle displayLarge = GoogleFonts.poppins(
    fontSize: 56,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static final TextStyle displayMedium = GoogleFonts.poppins(
    fontSize: 45,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static final TextStyle displaySmall = GoogleFonts.poppins(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    letterSpacing: 0,
  );

  // Headline styles
  static final TextStyle headlineLarge = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: 0,
  );

  static final TextStyle headlineMedium = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static final TextStyle headlineSmall = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  // Title styles
  static final TextStyle titleLarge = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static final TextStyle titleMedium = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static final TextStyle titleSmall = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  // Body styles
  static final TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );

  static final TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  );

  static final TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );

  // Label styles
  static final TextStyle labelLarge = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static final TextStyle labelMedium = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static final TextStyle labelSmall = GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // Caption styles
  static final TextStyle caption = GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );

  // Monospace (for code/technical text)
  static final TextStyle mono = GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  // Backward compatibility aliases
  static TextStyle get heading1 => displayLarge;
  static TextStyle get heading2 => headlineMedium;
  static TextStyle get heading3 => headlineSmall;
  static TextStyle get body1 => bodyLarge;
  static TextStyle get body2 => bodyMedium;
  static TextStyle get button => labelLarge;
}
