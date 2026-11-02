import 'package:flutter_test/flutter_test.dart';
import 'package:m_call/models/busy_mode.dart';

void main() {
  group('BusyMode Model Tests', () {
    test('defaultModes contains 5 modes with expected properties', () {
      final modes = BusyMode.defaultModes();
      expect(modes.length, 5);

      final namaz = modes.firstWhere((m) => m.type == BusyModeType.namaz);
      expect(namaz.name, 'Namaz');
      expect(namaz.icon, '🕌');
      expect(namaz.durationMinutes, 10);
      expect(namaz.replyToPhone, isTrue);
      expect(namaz.replyToWhatsApp, isTrue);
      expect(namaz.replyToMessenger, isTrue);

      final meeting = modes.firstWhere((m) => m.type == BusyModeType.meeting);
      expect(meeting.name, 'Meeting');
      expect(meeting.durationMinutes, 30);

      final sleep = modes.firstWhere((m) => m.type == BusyModeType.sleep);
      expect(sleep.name, 'Sleep');
      expect(sleep.durationMinutes, 480);
    });

    test('copyWith works correctly', () {
      final original = BusyMode(
        id: '1',
        type: BusyModeType.custom,
        name: 'Gym',
        icon: '🏋️',
        message: 'At gym',
        durationMinutes: 60,
      );

      final updated = original.copyWith(name: 'Workout', durationMinutes: 75);
      expect(updated.name, 'Workout');
      expect(updated.durationMinutes, 75);
      expect(updated.icon, '🏋️');
      expect(updated.id, '1');
    });

    test('serialization toMap and fromMap preserves data', () {
      final mode = BusyMode(
        id: 'test_123',
        type: BusyModeType.custom,
        name: 'Study',
        icon: '📖',
        message: 'Studying now',
        durationMinutes: 45,
        isActive: true,
        replyToPhone: true,
        replyToWhatsApp: false,
        replyToMessenger: true,
      );

      final map = mode.toMap();
      final restored = BusyMode.fromMap(map);

      expect(restored.id, mode.id);
      expect(restored.name, mode.name);
      expect(restored.icon, mode.icon);
      expect(restored.message, mode.message);
      expect(restored.durationMinutes, mode.durationMinutes);
      expect(restored.isActive, mode.isActive);
      expect(restored.replyToPhone, mode.replyToPhone);
      expect(restored.replyToWhatsApp, mode.replyToWhatsApp);
      expect(restored.replyToMessenger, mode.replyToMessenger);
    });
  });
}

