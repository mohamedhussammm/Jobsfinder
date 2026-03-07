import 'package:flutter/foundation.dart';

/// A utility for standardized performance and memory logging
class PerfLog {
  /// Log a widget build event
  static void build(String widgetName) {
    if (kDebugMode) {
      print('🔨 [BUILD] $widgetName - ${DateTime.now().millisecond}ms');
    }
  }

  /// Log a widget initialization event
  static void init(String widgetName) {
    if (kDebugMode) {
      print('🚀 [INIT] $widgetName');
    }
  }

  /// Log a widget disposal event
  static void dispose(String widgetName) {
    if (kDebugMode) {
      print('♻️ [DISPOSE] $widgetName');
    }
  }

  /// Log a specific performance checkpoint
  static void trace(String message) {
    if (kDebugMode) {
      print('📍 [TRACE] $message');
    }
  }
}
