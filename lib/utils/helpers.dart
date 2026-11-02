import 'dart:math';

import 'package:intl/intl.dart';

/// Utility helper functions used throughout the M Call app.
class Helpers {
  Helpers._();

  // ── Duration Formatting ───────────────────────────────────────────────────

  /// Formats a duration given in minutes into a human-readable string.
  ///
  /// Examples:
  /// - `5` → "5 min"
  /// - `60` → "1 hr"
  /// - `90` → "1 hr 30 min"
  /// - `1440` → "24 hr"
  static String formatDuration(int minutes) {
    if (minutes < 1) return '0 min';

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours == 0) {
      return '$remainingMinutes min';
    } else if (remainingMinutes == 0) {
      return '$hours hr';
    } else {
      return '$hours hr $remainingMinutes min';
    }
  }

  // ── Time Formatting ───────────────────────────────────────────────────────

  /// Formats a [DateTime] to a 12-hour time string (e.g., "2:30 PM").
  static String formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  /// Formats a [DateTime] to a full time string with seconds (e.g., "2:30:45 PM").
  static String formatTimeFull(DateTime time) {
    return DateFormat('h:mm:ss a').format(time);
  }

  // ── Date Formatting ───────────────────────────────────────────────────────

  /// Formats a [DateTime] to a smart date string.
  ///
  /// Returns "Today", "Yesterday", or a formatted date like "Nov 2".
  /// For dates in a different year, includes the year (e.g., "Nov 2, 2024").
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(targetDate).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (date.year == now.year) {
      return DateFormat('MMM d').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  /// Formats a [DateTime] to a full date-time string.
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} at ${formatTime(dateTime)}';
  }

  // ── ID Generation ─────────────────────────────────────────────────────────

  /// Generates a UUID-like unique identifier string.
  ///
  /// Produces a v4-style UUID using random values:
  /// `xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx`
  static String generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    // Set version (4) and variant (10xx) bits per UUID v4 spec.
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    final hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }

  // ── Message Processing ────────────────────────────────────────────────────

  /// Processes a message template by replacing placeholders.
  ///
  /// Supported placeholders:
  /// - `{time}` → the remaining time in minutes
  /// - `{mode_name}` → the name of the active mode
  ///
  /// Example:
  /// ```dart
  /// processMessage(
  ///   "Will call you back in {time} minutes. ({mode_name})",
  ///   remainingTime: 15,
  ///   modeName: "Meeting",
  /// );
  /// // → "Will call you back in 15 minutes. (Meeting)"
  /// ```
  static String processMessage(
    String template, {
    int? remainingTime,
    String? modeName,
  }) {
    String result = template;

    if (remainingTime != null) {
      result = result.replaceAll('{time}', remainingTime.toString());
    }

    if (modeName != null) {
      result = result.replaceAll('{mode_name}', modeName);
    }

    return result;
  }

  // ── Misc Utilities ────────────────────────────────────────────────────────

  /// Returns a greeting based on the current time of day.
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) {
      return 'Good Night';
    } else if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else if (hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  /// Truncates a phone number for display, showing first 3 and last 4 digits.
  /// Returns the full number if it's 7 digits or fewer.
  static String maskPhoneNumber(String number) {
    final digits = number.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.length <= 7) return digits;
    return '${digits.substring(0, 3)}****${digits.substring(digits.length - 4)}';
  }

  /// Calculates the remaining time in minutes from now until [endTime].
  /// Returns 0 if [endTime] is in the past.
  static int remainingMinutesUntil(DateTime endTime) {
    final diff = endTime.difference(DateTime.now()).inMinutes;
    return diff > 0 ? diff : 0;
  }
}
