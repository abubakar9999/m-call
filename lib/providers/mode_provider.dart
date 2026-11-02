import 'package:flutter/foundation.dart';

import '../models/busy_mode.dart';
import '../services/auto_reply_manager.dart';
import '../services/database_service.dart';

/// Manages busy modes state — loading, activating, deactivating, and CRUD for
/// custom modes.
class ModeProvider extends ChangeNotifier {
  final AutoReplyManager autoReplyManager;
  final DatabaseService dbService;

  List<BusyMode> _modes = [];
  BusyMode? _activeMode;

  ModeProvider({
    required this.autoReplyManager,
    required this.dbService,
  });

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// All available modes (default + custom).
  List<BusyMode> get modes => List.unmodifiable(_modes);

  /// The currently active mode, or `null` if nothing is active.
  BusyMode? get activeMode => _activeMode;

  /// `true` when any mode is currently active.
  bool get isAnyModeActive => _activeMode != null;

  /// Minutes remaining for the active mode timer.
  int get remainingMinutes => autoReplyManager.remainingMinutes;

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  /// Load default modes and merge with custom modes persisted in the database.
  Future<void> loadModes() async {
    final defaults = BusyMode.defaultModes();
    final customModes = await dbService.getCustomModes();

    _modes = [...defaults, ...customModes];

    // Restore an active mode if any was flagged active in the database.
    final activeIndex = _modes.indexWhere((m) => m.isActive);
    if (activeIndex != -1) {
      _activeMode = _modes[activeIndex];
    }

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Activation / Deactivation
  // ---------------------------------------------------------------------------

  /// Activate [mode] — deactivates any currently-active mode first.
  Future<void> activateMode(BusyMode mode) async {
    // Deactivate the previous mode if one is running.
    if (_activeMode != null) {
      await _deactivateCurrent(notify: false);
    }

    final activated = mode.copyWith(
      isActive: true,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(Duration(minutes: mode.durationMinutes)),
    );

    _activeMode = activated;
    _updateModeInList(activated);

    await dbService.saveMode(activated);
    await autoReplyManager.start(activated);

    notifyListeners();
  }

  /// Deactivate the currently-active mode.
  Future<void> deactivateMode() async {
    await _deactivateCurrent(notify: true);
  }

  Future<void> _deactivateCurrent({required bool notify}) async {
    if (_activeMode == null) return;

    final deactivated = _activeMode!.copyWith(
      isActive: false,
      clearStartTime: true,
      clearEndTime: true,
    );

    _updateModeInList(deactivated);

    await dbService.saveMode(deactivated);
    await autoReplyManager.stop();

    _activeMode = null;

    if (notify) notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Custom Mode CRUD
  // ---------------------------------------------------------------------------

  /// Add a brand-new custom mode.
  Future<void> addCustomMode(BusyMode mode) async {
    final custom = mode.copyWith(type: BusyModeType.custom);
    _modes.add(custom);
    await dbService.saveMode(custom);
    notifyListeners();
  }

  /// Update an existing mode's settings.
  Future<void> updateMode(BusyMode mode) async {
    _updateModeInList(mode);

    if (_activeMode?.id == mode.id) {
      _activeMode = mode;
    }

    await dbService.saveMode(mode);
    notifyListeners();
  }

  /// Delete a custom mode by its [id]. Built-in modes cannot be deleted.
  Future<void> deleteCustomMode(String id) async {
    final target = _modes.firstWhere((m) => m.id == id);
    if (target.type != BusyModeType.custom) return;

    if (_activeMode?.id == id) {
      await deactivateMode();
    }

    _modes.removeWhere((m) => m.id == id);
    await dbService.deleteMode(id);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _updateModeInList(BusyMode updated) {
    final idx = _modes.indexWhere((m) => m.id == updated.id);
    if (idx != -1) {
      _modes[idx] = updated;
    }
  }
}
