import 'package:flutter/foundation.dart';

import '../models/prayer_time.dart';
import '../services/prayer_time_service.dart';
import '../services/location_service.dart';

/// Provides today's prayer times and tracks the current / next prayer.
class PrayerProvider extends ChangeNotifier {
  final PrayerTimeService prayerService;
  final LocationService locationService;

  DailyPrayerTimes? _todayPrayers;
  bool _isLoading = false;
  String? _error;

  PrayerProvider({
    required this.prayerService,
    required this.locationService,
  });

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  DailyPrayerTimes? get todayPrayers => _todayPrayers;

  /// The prayer whose busy window includes the current moment.
  PrayerTimeData? get currentPrayer => _todayPrayers?.currentPrayer;

  /// The next upcoming prayer that hasn't started yet.
  PrayerTimeData? get nextPrayer => _todayPrayers?.nextPrayer;

  bool get isLoading => _isLoading;

  String? get error => _error;

  // ---------------------------------------------------------------------------
  // Data Loading
  // ---------------------------------------------------------------------------

  /// Load prayer times for today based on the user's current location.
  Future<void> loadPrayerTimes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final position = await locationService.getCurrentLocation();
      _todayPrayers = await prayerService.calculatePrayerTimes(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      _error = 'Could not load prayer times: $e';
      // Attempt a fallback with default coordinates (Dhaka).
      try {
        final position = await locationService.getLastKnownOrDefault();
        _todayPrayers = await prayerService.calculatePrayerTimes(
          position.latitude,
          position.longitude,
        );
        _error = null;
      } catch (_) {
        // Keep the original error.
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Force-refresh prayer times from the service.
  Future<void> refreshPrayerTimes() async {
    await loadPrayerTimes();
  }
}
