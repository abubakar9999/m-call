import 'package:m_call/models/busy_mode.dart';

/// Application-wide constants for M Call.
class AppConstants {
  AppConstants._();

  // ── App Info ──────────────────────────────────────────────────────────────
  static const String appName = 'M Call';
  static const String appTagline = "Smart Auto-Reply When You're Busy";
  static const String appVersion = '1.0.0';

  // ── Prayer Defaults ───────────────────────────────────────────────────────
  static const int defaultPrayerDurationMinutes = 10;

  // ── Platform Channel ──────────────────────────────────────────────────────
  static const String methodChannelName = 'com.mcall.app/services';
  static const String eventChannelName = 'com.mcall.app/events';

  // ── Database ──────────────────────────────────────────────────────────────
  static const String databaseName = 'mcall.db';
  static const int databaseVersion = 1;
  static const String tableBusyModes = 'busy_modes';
  static const String tableCallLogs = 'call_logs';

  // ── SharedPreferences Keys ────────────────────────────────────────────────
  static const String prefSettings = 'app_settings';
  static const String prefActiveModeId = 'active_mode_id';
  static const String prefLastLatitude = 'last_latitude';
  static const String prefLastLongitude = 'last_longitude';
  static const String prefPrayerTimes = 'prayer_times';
  static const String prefFirstLaunch = 'first_launch';
  static const String prefServiceRunning = 'service_running';
  static const String prefLanguage = 'language';
  static const String prefDarkMode = 'dark_mode';
  static const String prefCalculationMethod = 'calculation_method';

  // ── Notification Channels ─────────────────────────────────────────────────
  static const String notificationChannelId = 'mcall_auto_reply';
  static const String notificationChannelName = 'Auto Reply Notifications';
  static const String notificationChannelDesc =
      'Notifications for auto-reply actions';
  static const String serviceNotificationChannelId = 'mcall_service';
  static const String serviceNotificationChannelName = 'Background Service';
  static const String serviceNotificationChannelDesc =
      'Foreground service notification';

  // ── Default Messages ──────────────────────────────────────────────────────
  static const Map<BusyModeType, String> defaultMessages = {
    BusyModeType.namaz:
        'Assalamualaikum, {time} minute wait koren. Ami namaz e achi. InshaAllah namaz sheshe call korbo.',
    BusyModeType.meeting:
        "I'm in a meeting right now. Will call you back in {time} minutes.",
    BusyModeType.sleep:
        "I'm sleeping right now. Will get back to you in the morning. 😴",
    BusyModeType.classMode:
        "I'm in class right now. Will call you back after {time} minutes. 📚",
    BusyModeType.driving:
        "I'm driving right now. Will call you back when I stop. 🚗",
    BusyModeType.custom:
        "I'm busy right now. Will get back to you in {time} minutes.",
  };

  // ── Mode Icons ────────────────────────────────────────────────────────────
  static const Map<BusyModeType, String> modeIcons = {
    BusyModeType.namaz: '🕌',
    BusyModeType.meeting: '💼',
    BusyModeType.sleep: '😴',
    BusyModeType.classMode: '📚',
    BusyModeType.driving: '🚗',
    BusyModeType.custom: '⚙️',
  };

  // ── Mode Names ────────────────────────────────────────────────────────────
  static const Map<BusyModeType, String> modeNames = {
    BusyModeType.namaz: 'Namaz',
    BusyModeType.meeting: 'Meeting',
    BusyModeType.sleep: 'Sleep',
    BusyModeType.classMode: 'Class',
    BusyModeType.driving: 'Driving',
    BusyModeType.custom: 'Custom',
  };

  // ── Prayer Calculation Methods ────────────────────────────────────────────
  static const Map<String, String> calculationMethods = {
    'karachi': 'University of Islamic Sciences, Karachi',
    'isna': 'Islamic Society of North America (ISNA)',
    'mwl': 'Muslim World League',
    'egyptian': 'Egyptian General Authority of Survey',
    'umm_al_qura': 'Umm al-Qura University, Makkah',
  };

  // ── Prayer Names ──────────────────────────────────────────────────────────
  static const List<String> prayerNames = [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];
}
