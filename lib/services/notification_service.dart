import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for managing local notifications in M Call.
///
/// Supports persistent "mode active" notifications, mode-ended summaries,
/// and prayer-time reminders. Call [init] once during app startup.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Notification IDs — kept constant so we can update / cancel them by ID.
  static const int _modeActiveId = 1001;
  static const int _modeEndedId = 1002;
  static const int _prayerReminderId = 1003;

  /// Android notification channel identifier.
  static const String _channelId = 'mcall_channel';

  /// Human-readable channel name shown in device settings.
  static const String _channelName = 'M Call Notifications';

  /// Channel description shown in device settings.
  static const String _channelDescription =
      'Notifications for active busy modes, missed calls, and prayer reminders.';

  /// Initialises the notification plugin with Android-specific settings.
  ///
  /// Must be called once before any notification is shown.
  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Shows a persistent (ongoing) notification indicating that a busy mode is
  /// currently active.
  ///
  /// [modeName] is the display name of the mode (e.g. "Namaz", "Meeting").
  /// [remainingMinutes] is the approximate number of minutes left.
  Future<void> showModeActiveNotification(
    String modeName,
    int remainingMinutes,
  ) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      icon: '@mipmap/ic_launcher',
      showWhen: true,
    );

    await _plugin.show(
      _modeActiveId,
      '$modeName Mode Active',
      'Auto-replying to incoming calls • ${remainingMinutes}m remaining',
      NotificationDetails(android: androidDetails),
    );
  }

  /// Shows a notification summarising a completed busy-mode session.
  ///
  /// [modeName] is the mode that just ended.
  /// [missedCalls] is the number of calls that were auto-replied to.
  Future<void> showModeEndedNotification(
    String modeName,
    int missedCalls,
  ) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ongoing: false,
      autoCancel: true,
      icon: '@mipmap/ic_launcher',
    );

    final body = missedCalls > 0
        ? 'You had $missedCalls missed call${missedCalls == 1 ? '' : 's'} '
            'while in $modeName mode.'
        : 'No calls were received during $modeName mode.';

    await _plugin.show(
      _modeEndedId,
      '$modeName Mode Ended',
      body,
      NotificationDetails(android: androidDetails),
    );
  }

  /// Shows a reminder notification for an upcoming prayer.
  ///
  /// [prayerName] is the name of the prayer (e.g. "Dhuhr").
  /// [prayerTime] is the exact time the prayer begins.
  Future<void> showPrayerReminderNotification(
    String prayerName,
    DateTime prayerTime,
  ) async {
    final formattedTime =
        '${prayerTime.hour.toString().padLeft(2, '0')}:'
        '${prayerTime.minute.toString().padLeft(2, '0')}';

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ongoing: false,
      autoCancel: true,
      icon: '@mipmap/ic_launcher',
    );

    await _plugin.show(
      _prayerReminderId,
      '$prayerName Prayer Time',
      '$prayerName prayer starts at $formattedTime. '
          'Would you like to activate Namaz mode?',
      NotificationDetails(android: androidDetails),
    );
  }

  /// Cancels all active notifications managed by this service.
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  /// Cancels a specific notification by its [id].
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// Callback fired when the user taps on a notification.
  void _onNotificationTapped(NotificationResponse response) {
    // Intentionally left as a no-op — the app simply opens.
    // Deep-link navigation can be added here in the future.
  }
}
