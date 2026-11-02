import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/busy_mode.dart';
import '../models/call_log_entry.dart';

/// Service for managing the local SQLite database.
///
/// Provides CRUD operations for call logs and custom busy modes.
/// Call [init] once before using any other method.
class DatabaseService {
  static const String _dbName = 'mcall.db';
  static const int _dbVersion = 1;

  Database? _database;

  /// Returns the active database instance.
  /// Throws if [init] has not been called.
  Database get _db {
    if (_database == null) {
      throw StateError(
        'DatabaseService has not been initialized. Call init() first.',
      );
    }
    return _database!;
  }

  /// Initialises the database, creating tables if they don't exist.
  ///
  /// Must be called once during app startup before any reads or writes.
  Future<void> init() async {
    if (_database != null) return;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    _database = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE call_logs (
        id TEXT PRIMARY KEY,
        caller_number TEXT NOT NULL,
        caller_name TEXT,
        platform TEXT NOT NULL,
        message_sent TEXT NOT NULL,
        mode_name TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_modes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        message TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        reply_phone INTEGER NOT NULL DEFAULT 1,
        reply_whatsapp INTEGER NOT NULL DEFAULT 0,
        reply_messenger INTEGER NOT NULL DEFAULT 0,
        auto_schedule INTEGER NOT NULL DEFAULT 0,
        schedule_data TEXT
      )
    ''');
  }

  // ---------------------------------------------------------------------------
  // Call Logs
  // ---------------------------------------------------------------------------

  /// Inserts a new call log entry into the database.
  Future<void> insertCallLog(CallLogEntry entry) async {
    await _db.insert(
      'call_logs',
      {
        'id': entry.id,
        'caller_number': entry.callerNumber,
        'caller_name': entry.callerName,
        'platform': entry.platform.name,
        'message_sent': entry.messageSent,
        'mode_name': entry.modeName,
        'timestamp': entry.timestamp.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Alias for [getCallLogs] without parameters.
  Future<List<CallLogEntry>> getCallHistory() => getCallLogs();

  /// Retrieves call log entries, optionally filtered by date range and
  /// limited to [limit] results.
  ///
  /// Results are returned in reverse chronological order (newest first).
  Future<List<CallLogEntry>> getCallLogs({
    int? limit,
    DateTime? from,
    DateTime? to,
  }) async {
    final where = <String>[];
    final whereArgs = <String>[];

    if (from != null) {
      where.add('timestamp >= ?');
      whereArgs.add(from.toIso8601String());
    }
    if (to != null) {
      where.add('timestamp <= ?');
      whereArgs.add(to.toIso8601String());
    }

    final rows = await _db.query(
      'call_logs',
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return rows.map(_callLogFromRow).toList();
  }

  /// Returns the total number of call log entries, optionally restricted to
  /// entries on or after [from].
  Future<int> getCallLogCount({DateTime? from}) async {
    final where = from != null ? 'timestamp >= ?' : null;
    final whereArgs = from != null ? [from.toIso8601String()] : null;

    final result = Sqflite.firstIntValue(
      await _db.rawQuery(
        'SELECT COUNT(*) FROM call_logs'
        '${where != null ? ' WHERE $where' : ''}',
        whereArgs,
      ),
    );
    return result ?? 0;
  }

  /// Deletes call log entries before a given date.
  Future<void> deleteCallLogsBefore(DateTime cutoff) async {
    await _db.delete(
      'call_logs',
      where: 'timestamp < ?',
      whereArgs: [cutoff.toIso8601String()],
    );
  }

  /// Deletes call log entries older than [daysOld] days.
  Future<void> deleteOldLogs(int daysOld) async {
    final cutoff =
        DateTime.now().subtract(Duration(days: daysOld)).toIso8601String();
    await _db.delete(
      'call_logs',
      where: 'timestamp < ?',
      whereArgs: [cutoff],
    );
  }

  // ---------------------------------------------------------------------------
  // Custom Modes
  // ---------------------------------------------------------------------------

  /// Saves or updates a mode. If custom, persists to the database.
  Future<void> saveMode(BusyMode mode) async {
    if (mode.type == BusyModeType.custom) {
      await insertCustomMode(mode);
    }
  }

  /// Deletes a custom mode by its ID.
  Future<void> deleteMode(String id) async {
    await deleteCustomMode(id);
  }

  /// Persists a new custom busy mode.
  Future<void> insertCustomMode(BusyMode mode) async {
    await _db.insert(
      'custom_modes',
      _modeToRow(mode),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns all stored custom busy modes.
  Future<List<BusyMode>> getCustomModes() async {
    final rows = await _db.query('custom_modes');
    return rows.map(_modeFromRow).toList();
  }

  /// Updates an existing custom busy mode.
  Future<void> updateCustomMode(BusyMode mode) async {
    await _db.update(
      'custom_modes',
      _modeToRow(mode),
      where: 'id = ?',
      whereArgs: [mode.id],
    );
  }

  /// Deletes a custom busy mode by its [id].
  Future<void> deleteCustomMode(String id) async {
    await _db.delete(
      'custom_modes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------------------------------------------------------------------
  // Row ↔ Model mapping helpers
  // ---------------------------------------------------------------------------

  CallLogEntry _callLogFromRow(Map<String, dynamic> row) {
    return CallLogEntry(
      id: row['id'] as String,
      callerNumber: row['caller_number'] as String,
      callerName: row['caller_name'] as String?,
      platform: CallPlatform.values.firstWhere(
        (e) => e.name == row['platform'],
        orElse: () => CallPlatform.phone,
      ),
      messageSent: row['message_sent'] as String,
      modeName: row['mode_name'] as String,
      timestamp: DateTime.parse(row['timestamp'] as String),
    );
  }

  Map<String, dynamic> _modeToRow(BusyMode mode) {
    return {
      'id': mode.id,
      'name': mode.name,
      'icon': mode.icon,
      'message': mode.message,
      'duration_minutes': mode.durationMinutes,
      'reply_phone': mode.replyPhone ? 1 : 0,
      'reply_whatsapp': mode.replyWhatsapp ? 1 : 0,
      'reply_messenger': mode.replyMessenger ? 1 : 0,
      'auto_schedule': mode.autoSchedule ? 1 : 0,
      'schedule_data': mode.scheduleData,
    };
  }

  BusyMode _modeFromRow(Map<String, dynamic> row) {
    return BusyMode(
      id: row['id'] as String,
      name: row['name'] as String,
      type: BusyModeType.custom,
      icon: row['icon'] as String,
      message: row['message'] as String,
      durationMinutes: row['duration_minutes'] as int,
      replyToPhone: (row['reply_phone'] as int) == 1,
      replyToWhatsApp: (row['reply_whatsapp'] as int) == 1,
      replyToMessenger: (row['reply_messenger'] as int) == 1,
      autoSchedule: (row['auto_schedule'] as int) == 1,
      scheduleData: row['schedule_data'] as String?,
    );
  }
}
