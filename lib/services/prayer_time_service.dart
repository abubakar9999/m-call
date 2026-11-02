import 'package:adhan_dart/adhan_dart.dart';

import '../models/prayer_time.dart';

/// Service for calculating Islamic prayer times using the Adhan library.
///
/// Supports multiple calculation methods (Karachi, Muslim World League,
/// North America, Egyptian) and provides helpers to determine the
/// current and next prayer based on the current time.
class PrayerTimeService {
  /// Calculates the five daily prayer times for the given coordinates.
  ///
  /// [lat] and [lng] are the GPS coordinates.
  /// [method] selects the calculation method — one of `'karachi'`,
  /// `'muslimWorldLeague'`, `'northAmerica'`, or `'egyptian'`.
  /// Defaults to `'karachi'`.
  ///
  /// Returns a [DailyPrayerTimes] model populated from the Adhan results.
  Future<DailyPrayerTimes> calculatePrayerTimes(
    double lat,
    double lng, {
    String method = 'karachi',
  }) async {
    try {
      final coordinates = Coordinates(lat, lng);
      final params = _getCalculationParameters(method);
      final now = DateTime.now();
      final prayerTimes = PrayerTimes(
        coordinates: coordinates,
        date: now,
        calculationParameters: params,
      );

      return DailyPrayerTimes(
        fajr: PrayerTimeData(
          name: 'Fajr',
          time: prayerTimes.fajr,
        ),
        dhuhr: PrayerTimeData(
          name: 'Dhuhr',
          time: prayerTimes.dhuhr,
        ),
        asr: PrayerTimeData(
          name: 'Asr',
          time: prayerTimes.asr,
        ),
        maghrib: PrayerTimeData(
          name: 'Maghrib',
          time: prayerTimes.maghrib,
        ),
        isha: PrayerTimeData(
          name: 'Isha',
          time: prayerTimes.isha,
        ),
        date: now,
        calculationMethod: method,
      );
    } catch (e) {
      // Return a fallback with zeroed times so the caller can still function.
      final now = DateTime.now();
      return DailyPrayerTimes(
        fajr: PrayerTimeData(name: 'Fajr', time: now),
        dhuhr: PrayerTimeData(name: 'Dhuhr', time: now),
        asr: PrayerTimeData(name: 'Asr', time: now),
        maghrib: PrayerTimeData(name: 'Maghrib', time: now),
        isha: PrayerTimeData(name: 'Isha', time: now),
        date: now,
        calculationMethod: method,
      );
    }
  }

  /// Returns the [PrayerTimeData] for the prayer that is currently active
  /// (i.e. the most recent prayer whose time has already passed).
  ///
  /// Returns `null` if all prayer times are in the future (edge case near
  /// midnight before Fajr).
  PrayerTimeData? getCurrentPrayer(DailyPrayerTimes times) {
    final now = DateTime.now();
    final prayers = [
      times.fajr,
      times.dhuhr,
      times.asr,
      times.maghrib,
      times.isha,
    ];

    PrayerTimeData? current;
    for (final prayer in prayers) {
      if (prayer.time.isBefore(now) || prayer.time.isAtSameMomentAs(now)) {
        current = prayer;
      }
    }
    return current;
  }

  /// Returns the [PrayerTimeData] for the next upcoming prayer.
  ///
  /// Returns `null` if all prayer times have passed for the day
  /// (i.e. after Isha).
  PrayerTimeData? getNextPrayer(DailyPrayerTimes times) {
    final now = DateTime.now();
    final prayers = [
      times.fajr,
      times.dhuhr,
      times.asr,
      times.maghrib,
      times.isha,
    ];

    for (final prayer in prayers) {
      if (prayer.time.isAfter(now)) {
        return prayer;
      }
    }
    return null;
  }

  /// Maps a string method name to the corresponding Adhan
  /// [CalculationParameters].
  CalculationParameters _getCalculationParameters(String method) {
    switch (method.toLowerCase()) {
      case 'muslimworldleague':
        return CalculationMethodParameters.muslimWorldLeague();
      case 'northamerica':
        return CalculationMethodParameters.northAmerica();
      case 'egyptian':
        return CalculationMethodParameters.egyptian();
      case 'karachi':
      default:
        return CalculationMethodParameters.karachi();
    }
  }
}
