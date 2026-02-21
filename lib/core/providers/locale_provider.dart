import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the application locale
final localeProvider = StateProvider<Locale>((ref) {
  // Default to English, but could detect system locale
  return const Locale('en');
});
