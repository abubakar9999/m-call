import 'package:flutter_test/flutter_test.dart';
import 'package:m_call/models/busy_mode.dart';
import 'package:m_call/models/prayer_time.dart';
import 'package:m_call/utils/helpers.dart';

void main() {
  group('BusyMode Unit Tests', () {
    test('defaultModes contains 5 built-in modes', () {
      final modes = BusyMode.defaultModes();
      expect(modes.length, 5);
      expect(modes.any((m) => m.type == BusyModeType.namaz), isTrue);
      expect(modes.any((m) => m.type == BusyModeType.meeting), isTrue);
      expect(modes.any((m) => m.type == BusyModeType.sleep), isTrue);
      expect(modes.any((m) => m.type == BusyModeType.classMode), isTrue);
      expect(modes.any((m) => m.type == BusyModeType.driving), isTrue);
    });

    test('replaces placeholders in auto-reply message', () {
      const template = 'Ami {mode_name} e achi, {time} min wait koren.';
      final processed = Helpers.processMessage(
        template,
        remainingTime: 10,
        modeName: 'Namaz',
      );
      expect(processed, 'Ami Namaz e achi, 10 min wait koren.');
    });

    test('formats duration correctly', () {
      expect(Helpers.formatDuration(5), '5 min');
      expect(Helpers.formatDuration(60), '1 hr');
      expect(Helpers.formatDuration(90), '1 hr 30 min');
      expect(Helpers.formatDuration(480), '8 hr');
    });

    test('PrayerTimeData initializes properly', () {
      final now = DateTime.now();
      final prayer = PrayerTimeData(
        name: 'Dhuhr',
        time: now,
        durationMinutes: 15,
      );
      expect(prayer.name, 'Dhuhr');
      expect(prayer.durationMinutes, 15);
      expect(prayer.enabled, isTrue);
    });
  });
}
