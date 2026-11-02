import 'package:flutter_test/flutter_test.dart';
import 'package:m_call/services/prayer_time_service.dart';

void main() {
  group('PrayerTimeService Tests', () {
    test('calculatePrayerTimes produces valid prayer times for Dhaka', () async {
      final service = PrayerTimeService();
      // Dhaka coordinates
      final times = await service.calculatePrayerTimes(23.8103, 90.4125);

      expect(times.fajr.name, 'Fajr');
      expect(times.dhuhr.name, 'Dhuhr');
      expect(times.asr.name, 'Asr');
      expect(times.maghrib.name, 'Maghrib');
      expect(times.isha.name, 'Isha');

      // Verify chronological order
      expect(times.fajr.time.isBefore(times.dhuhr.time), isTrue);
      expect(times.dhuhr.time.isBefore(times.asr.time), isTrue);
      expect(times.asr.time.isBefore(times.maghrib.time), isTrue);
      expect(times.maghrib.time.isBefore(times.isha.time), isTrue);
    });

    test('supports different calculation methods', () async {
      final service = PrayerTimeService();
      final timesKarachi = await service.calculatePrayerTimes(
        23.8103,
        90.4125,
        method: 'karachi',
      );
      final timesMwl = await service.calculatePrayerTimes(
        23.8103,
        90.4125,
        method: 'muslimWorldLeague',
      );

      expect(timesKarachi.fajr.name, 'Fajr');
      expect(timesMwl.fajr.name, 'Fajr');
    });
  });
}

