import 'package:intl/intl.dart';

/// Date & Time utilities
extension DateTimeX on DateTime {
  /// Format datetime to readable format
  String toDisplayDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisDay = DateTime(year, month, day);

    if (thisDay == today) {
      return 'Today ${DateFormat('HH:mm').format(this)}';
    } else if (thisDay == yesterday) {
      return 'Yesterday ${DateFormat('HH:mm').format(this)}';
    } else if (thisDay.year == today.year) {
      return DateFormat('MMM dd, HH:mm').format(this);
    } else {
      return DateFormat('MMM dd, yyyy').format(this);
    }
  }

  /// Format to time only
  String toTimeString() => DateFormat('HH:mm').format(this);

  /// Format to date only
  String toDateString() => DateFormat('MMM dd, yyyy').format(this);

  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is in the past
  bool get isPast => isBefore(DateTime.now());

  /// Check if date is in the future
  bool get isFuture => isAfter(DateTime.now());

  /// Days until this date
  int get daysUntil {
    final now = DateTime.now();
    final difference = DateTime(year, month, day).difference(DateTime(now.year, now.month, now.day));
    return difference.inDays;
  }

  /// Hours until this date
  int get hoursUntil => difference(DateTime.now()).inHours;

  /// Minutes until this date
  int get minutesUntil => difference(DateTime.now()).inMinutes;
}

/// String utilities
extension StringX on String {
  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Check if email is valid
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Check if phone is valid (basic)
  bool get isValidPhone {
    final phoneRegex = RegExp(r'^\+?[\d\s\-()]{8,}$');
    return phoneRegex.hasMatch(this);
  }

  /// Truncate string
  String truncate(int length) {
    if (this.length <= length) return this;
    return '${substring(0, length)}...';
  }

  /// Remove extra whitespace
  String removeExtraSpaces() => trim().replaceAll(RegExp(r'\s+'), ' ');
}

/// Num utilities
extension NumX on num {
  /// Format as currency
  String toCurrency({String symbol = '\$', int decimals = 2}) {
    return '$symbol${toStringAsFixed(decimals)}';
  }

  /// Format as percentage
  String toPercentage({int decimals = 1}) {
    return '${toStringAsFixed(decimals)}%';
  }

  /// Format large numbers (1000 -> 1K, 1000000 -> 1M)
  String toCompactNumber() {
    if (this >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(1)}M';
    } else if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)}K';
    }
    return toString();
  }
}

/// List utilities
extension ListX<T> on List<T> {
  /// Group items by a key
  Map<K, List<T>> groupBy<K>(K Function(T) keyOf) {
    final map = <K, List<T>>{};
    for (final item in this) {
      final key = keyOf(item);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  /// Get unique items
  List<T> unique([bool Function(T, T)? compare]) {
    if (compare == null) {
      return toSet().toList();
    }
    final result = <T>[];
    for (final item in this) {
      final isDuplicate = result.any((element) => compare(element, item));
      if (!isDuplicate) {
        result.add(item);
      }
    }
    return result;
  }

  /// Chunk list into smaller lists
  List<List<T>> chunk(int size) {
    if (size <= 0) throw ArgumentError('Chunk size must be positive');
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, (i + size).clamp(0, length)));
    }
    return chunks;
  }

  /// Flatten nested lists
  List<T> flatten() {
    final result = <T>[];
    for (final item in this) {
      if (item is List) {
        result.addAll(item.flatten() as List<T>);
      } else {
        result.add(item);
      }
    }
    return result;
  }
}
