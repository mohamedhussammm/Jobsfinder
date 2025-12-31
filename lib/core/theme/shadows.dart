import 'package:flutter/material.dart';

class AppShadows {
  // Subtle shadow (small elements)
  static const BoxShadow xs = BoxShadow(
    color: Color.fromARGB(8, 0, 0, 0),
    offset: Offset(0, 1),
    blurRadius: 2,
  );

  // Small shadow
  static const BoxShadow sm = BoxShadow(
    color: Color.fromARGB(16, 0, 0, 0),
    offset: Offset(0, 1),
    blurRadius: 3,
  );

  // Medium shadow (default cards)
  static const BoxShadow md = BoxShadow(
    color: Color.fromARGB(24, 0, 0, 0),
    offset: Offset(0, 4),
    blurRadius: 6,
  );

  // Large shadow (elevated elements)
  static const BoxShadow lg = BoxShadow(
    color: Color.fromARGB(32, 0, 0, 0),
    offset: Offset(0, 10),
    blurRadius: 15,
  );

  // Extra large shadow
  static const BoxShadow xl = BoxShadow(
    color: Color.fromARGB(40, 0, 0, 0),
    offset: Offset(0, 20),
    blurRadius: 25,
  );

  // Glow effect (light shadow)
  static const BoxShadow glow = BoxShadow(
    color: Color.fromARGB(12, 99, 102, 241),
    offset: Offset(0, 0),
    blurRadius: 10,
  );

  // List of shadows for depth
  static const List<BoxShadow> card = [md];
  static const List<BoxShadow> elevated = [lg];
  static const List<BoxShadow> floating = [xl];

  // Glass shadow (subtle inner glow)
  static const List<BoxShadow> glass = [
    BoxShadow(
      color: Color.fromARGB(8, 0, 0, 0),
      offset: Offset(0, 8),
      blurRadius: 16,
    ),
  ];
}
