import 'package:flutter_test/flutter_test.dart';
import 'package:m_call/utils/helpers.dart';

void main() {
  group('Helpers Tests', () {
    test('formatDuration handles minute and hour formatting', () {
      expect(Helpers.formatDuration(0), '0 min');
      expect(Helpers.formatDuration(1), '1 min');
      expect(Helpers.formatDuration(45), '45 min');
      expect(Helpers.formatDuration(60), '1 hr');
      expect(Helpers.formatDuration(90), '1 hr 30 min');
      expect(Helpers.formatDuration(120), '2 hr');
      expect(Helpers.formatDuration(150), '2 hr 30 min');
    });

    test('processMessage handles placeholder substitution', () {
      const template = 'Assalamualaikum, {mode_name} e achi, {time} min wait koren.';
      final result = Helpers.processMessage(
        template,
        remainingTime: 15,
        modeName: 'Namaz',
      );
      expect(result, 'Assalamualaikum, Namaz e achi, 15 min wait koren.');
    });

    test('generateId produces non-empty unique string', () {
      final id1 = Helpers.generateId();
      final id2 = Helpers.generateId();
      expect(id1.isNotEmpty, isTrue);
      expect(id2.isNotEmpty, isTrue);
      expect(id1, isNot(id2));
    });
  });
}

