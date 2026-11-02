import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/history_provider.dart';
import 'providers/mode_provider.dart';
import 'providers/prayer_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/auto_reply_manager.dart';
import 'services/database_service.dart';
import 'services/location_service.dart';
import 'services/prayer_time_service.dart';
import 'utils/constants.dart';
import 'utils/theme.dart';

/// The root application widget for M Call.
class MCallApp extends StatelessWidget {
  const MCallApp({
    super.key,
    required this.dbService,
    required this.autoReplyManager,
    required this.prayerService,
    required this.locationService,
  });

  final DatabaseService dbService;
  final AutoReplyManager autoReplyManager;
  final PrayerTimeService prayerService;
  final LocationService locationService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..loadSettings(),
        ),
        ChangeNotifierProvider(
          create: (_) => ModeProvider(
            autoReplyManager: autoReplyManager,
            dbService: dbService,
          )..loadModes(),
        ),
        ChangeNotifierProvider(
          create: (_) => PrayerProvider(
            prayerService: prayerService,
            locationService: locationService,
          )..loadPrayerTimes(),
        ),
        ChangeNotifierProvider(
          create: (_) => HistoryProvider(
            dbService: dbService,
          )..loadHistory(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsProvider.settings.darkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            home: settingsProvider.onboardingComplete
                ? const MainShell()
                : OnboardingScreen(
                    onFinished: () {
                      // Trigger a rebuild when onboarding is complete
                    },
                  ),
          );
        },
      ),
    );
  }
}

