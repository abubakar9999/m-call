import 'dart:async';

import '../models/busy_mode.dart';
import '../models/call_log_entry.dart';
import 'call_service.dart';
import 'database_service.dart';
import 'notification_service.dart';
import 'sms_service.dart';

/// The main orchestrator for the M Call auto-reply system.
///
/// [AutoReplyManager] ties together call detection, SMS sending, database
/// logging, and notifications. When a busy mode is activated it starts
/// listening for incoming calls, auto-replies with the configured message,
/// logs every interaction, and shows a persistent notification until the
/// mode expires.
class AutoReplyManager {
  /// Database service for persisting call logs.
  final DatabaseService db;

  /// Notification service for showing / updating status notifications.
  final NotificationService notifications;

  /// Native call-detection bridge.
  final CallService callService;

  /// Native SMS bridge.
  final SmsService smsService;

  /// The currently active busy mode, or `null` if no mode is active.
  BusyMode? _activeMode;

  /// Timer that fires when the active mode's duration expires.
  Timer? _modeTimer;

  /// Subscription to the native incoming-call event stream.
  StreamSubscription<Map<String, dynamic>>? _callSubscription;

  /// Tracks the moment the current mode was activated — used to compute
  /// [remainingMinutes].
  DateTime? _modeStartTime;

  /// Running tally of calls handled during the current mode session.
  int _callsHandled = 0;

  /// Timer that periodically refreshes the persistent notification.
  Timer? _notificationRefreshTimer;

  /// Creates an [AutoReplyManager].
  ///
  /// All dependencies must already be initialised (e.g. [DatabaseService.init]
  /// should have been called).
  AutoReplyManager({
    required this.db,
    required this.notifications,
    required this.callService,
    required this.smsService,
  });

  /// The busy mode that is currently active, or `null`.
  BusyMode? get activeMode => _activeMode;

  /// Whether any busy mode is currently active.
  bool get isActive => _activeMode != null;

  /// Approximate number of minutes remaining for the active mode.
  ///
  /// Returns `0` if no mode is active.
  int get remainingMinutes {
    if (_activeMode == null || _modeStartTime == null) return 0;
    final elapsed = DateTime.now().difference(_modeStartTime!).inMinutes;
    final remaining = _activeMode!.durationMinutes - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  /// Alias for [activateMode] for convenience.
  Future<void> start(BusyMode mode) => activateMode(mode);

  /// Alias for [deactivateMode] for convenience.
  Future<void> stop() => deactivateMode();

  /// Activates [mode], starting call detection and scheduling automatic
  /// deactivation after the mode's configured duration.
  ///
  /// If another mode is already active it will be deactivated first.
  Future<void> activateMode(BusyMode mode) async {
    // Deactivate any currently running mode.
    if (isActive) {
      await deactivateMode();
    }

    _activeMode = mode;
    _modeStartTime = DateTime.now();
    _callsHandled = 0;

    // Start the native call-detection service and pass active mode configuration.
    try {
      await callService.activateMode(mode);
      await callService.startCallDetectionService();
    } catch (_) {
      // If the native service fails to start we still activate the mode
      // so the user sees the UI state, but call interception won't work.
    }

    // Subscribe to incoming call events.
    _callSubscription = callService.incomingCallStream.listen(
      _handleIncomingCall,
      onError: (_) {},
    );

    // Show persistent notification.
    await notifications.showModeActiveNotification(
      mode.name,
      mode.durationMinutes,
    );

    // Refresh the notification every minute so the remaining time stays
    // up-to-date.
    _notificationRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        if (_activeMode != null) {
          notifications.showModeActiveNotification(
            _activeMode!.name,
            remainingMinutes,
          );
        }
      },
    );

    // Schedule automatic deactivation.
    _modeTimer = Timer(
      Duration(minutes: mode.durationMinutes),
      () async {
        await deactivateMode();
      },
    );
  }

  /// Deactivates the current busy mode, stopping call detection,
  /// cancelling timers, and showing a summary notification.
  ///
  /// Safe to call even when no mode is active — it simply returns.
  Future<void> deactivateMode() async {
    final mode = _activeMode;
    final callsHandled = _callsHandled;

    // Cancel timers and subscriptions.
    _modeTimer?.cancel();
    _modeTimer = null;
    _notificationRefreshTimer?.cancel();
    _notificationRefreshTimer = null;
    await _callSubscription?.cancel();
    _callSubscription = null;

    _activeMode = null;
    _modeStartTime = null;
    _callsHandled = 0;

    // Stop the native call-detection service and deactivate mode in storage.
    try {
      await callService.deactivateMode();
      await callService.stopCallDetectionService();
    } catch (_) {
      // Best-effort — the service may already be stopped.
    }

    // Replace the persistent notification with a summary.
    await notifications.cancelAllNotifications();
    if (mode != null) {
      await notifications.showModeEndedNotification(
        mode.name,
        callsHandled,
      );
    }
  }

  /// Handles an incoming call event from the native side.
  ///
  /// Rejects the call, sends an auto-reply SMS if the mode is configured to
  /// reply via phone, and logs the interaction in the database.
  Future<void> _handleIncomingCall(Map<String, dynamic> callData) async {
    final mode = _activeMode;
    if (mode == null) return;

    final phoneNumber = callData['phoneNumber'] as String? ?? '';
    final callerName = callData['callerName'] as String?;
    final platformStr = callData['platform'] as String? ?? 'phone';

    final platform = CallPlatform.values.firstWhere(
      (e) => e.name == platformStr,
      orElse: () => CallPlatform.phone,
    );

    // Reject the incoming call.
    try {
      await callService.rejectCall();
    } catch (_) {
      // Best-effort rejection.
    }

    // Compose the reply message.
    final message = _processMessage(mode.message, mode);

    // Send the auto-reply if the mode supports the detected platform.
    bool messageSent = false;
    if (platform == CallPlatform.phone && mode.replyPhone) {
      messageSent = await smsService.sendSms(phoneNumber, message);
    }

    _callsHandled++;

    // Persist the call log entry.
    final logEntry = CallLogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      callerNumber: phoneNumber,
      callerName: callerName,
      platform: platform,
      messageSent: messageSent ? message : '',
      modeName: mode.name,
      timestamp: DateTime.now(),
    );

    try {
      await db.insertCallLog(logEntry);
    } catch (_) {
      // Database write failure should not crash the auto-reply flow.
    }
  }

  /// Processes a message template by substituting placeholders with
  /// runtime values.
  ///
  /// Supported placeholders:
  /// - `{time}` — replaced with the number of remaining minutes.
  /// - `{mode_name}` — replaced with the busy mode's display name.
  String _processMessage(String template, BusyMode mode) {
    return template
        .replaceAll('{time}', remainingMinutes.toString())
        .replaceAll('{mode_name}', mode.name);
  }

  /// Releases all resources held by this manager.
  ///
  /// After calling [dispose] this instance must not be used.
  void dispose() {
    _modeTimer?.cancel();
    _modeTimer = null;
    _notificationRefreshTimer?.cancel();
    _notificationRefreshTimer = null;
    _callSubscription?.cancel();
    _callSubscription = null;
    _activeMode = null;
    _modeStartTime = null;
  }
}
