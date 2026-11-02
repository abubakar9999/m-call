import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/call_log_entry.dart';
import '../services/database_service.dart';

/// Provides call-log history — entries, grouping, and statistics.
class HistoryProvider extends ChangeNotifier {
  final DatabaseService dbService;

  List<CallLogEntry> _entries = [];
  int _todayCount = 0;

  HistoryProvider({required this.dbService});

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// All call-log entries ordered newest-first.
  List<CallLogEntry> get entries => List.unmodifiable(_entries);

  /// Number of auto-replies sent today.
  int get todayCount => _todayCount;

  /// Entries grouped by human-readable date: "Today", "Yesterday", or a date.
  Map<String, List<CallLogEntry>> get groupedByDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateFormat = DateFormat('MMM d, yyyy');

    final Map<String, List<CallLogEntry>> grouped = {};

    for (final entry in _entries) {
      final entryDate = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );

      String label;
      if (entryDate == today) {
        label = 'Today';
      } else if (entryDate == yesterday) {
        label = 'Yesterday';
      } else {
        label = dateFormat.format(entryDate);
      }

      grouped.putIfAbsent(label, () => []).add(entry);
    }

    return grouped;
  }

  // ---------------------------------------------------------------------------
  // Data Loading
  // ---------------------------------------------------------------------------

  /// Load the full history from the database.
  Future<void> loadHistory() async {
    _entries = await dbService.getCallHistory();
    _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _computeTodayCount();
    notifyListeners();
  }

  /// Record a new call-log entry and persist it.
  Future<void> addEntry(CallLogEntry entry) async {
    await dbService.insertCallLog(entry);
    _entries.insert(0, entry);
    _computeTodayCount();
    notifyListeners();
  }

  /// Remove entries older than 30 days.
  Future<void> clearOldEntries() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    await dbService.deleteCallLogsBefore(cutoff);
    _entries.removeWhere((e) => e.timestamp.isBefore(cutoff));
    _computeTodayCount();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _computeTodayCount() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    _todayCount = _entries
        .where((e) => e.timestamp.isAfter(startOfDay))
        .length;
  }
}
