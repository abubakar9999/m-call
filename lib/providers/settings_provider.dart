import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

/// Persists and exposes application settings via [SharedPreferences].
class SettingsProvider extends ChangeNotifier {
  static const _settingsKey = 'app_settings';
  static const _onboardedKey = 'onboarding_complete';

  AppSettings _settings = const AppSettings();

  AppSettings get settings => _settings;

  /// Whether the user has completed onboarding.
  bool _onboardingComplete = false;
  bool get onboardingComplete => _onboardingComplete;

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  /// Load settings from shared preferences.
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_settingsKey);
    if (raw != null) {
      _settings = AppSettings.fromJson(
        json.decode(raw) as Map<String, dynamic>,
      );
    }

    _onboardingComplete = prefs.getBool(_onboardedKey) ?? false;

    notifyListeners();
  }

  /// Persist updated settings.
  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, json.encode(settings.toJson()));
    notifyListeners();
  }

  /// Toggle dark mode on / off.
  Future<void> toggleDarkMode() async {
    await updateSettings(_settings.copyWith(darkMode: !_settings.darkMode));
  }

  /// Set the display language.
  Future<void> setLanguage(String lang) async {
    await updateSettings(_settings.copyWith(language: lang));
  }

  /// Mark onboarding as complete.
  Future<void> completeOnboarding() async {
    _onboardingComplete = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardedKey, true);
    notifyListeners();
  }
}
