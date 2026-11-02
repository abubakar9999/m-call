import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_call/models/busy_mode.dart';
import 'package:m_call/models/call_log_entry.dart';
import 'package:m_call/models/prayer_time.dart';
import 'package:m_call/widgets/call_log_tile.dart';
import 'package:m_call/widgets/mode_card.dart';
import 'package:m_call/widgets/prayer_time_card.dart';

void main() {
  group('Widget UI Tests', () {
    testWidgets('ModeCard renders mode name, duration, and icon', (tester) async {
      final mode = BusyMode.defaultModes().first; // Namaz
      bool toggled = false;
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModeCard(
              mode: mode,
              onToggle: (_) => toggled = true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Namaz'), findsOneWidget);
      expect(find.text('🕌'), findsOneWidget);
      expect(find.text('10m'), findsOneWidget);

      await tester.tap(find.byType(GestureDetector).first);
      expect(tapped, isTrue);

      await tester.tap(find.byType(Switch).first);
      expect(toggled, isTrue);
    });

    testWidgets('PrayerTimeCard renders prayer name and formatted time', (tester) async {
      final now = DateTime(2026, 11, 2, 13, 15);
      final prayer = PrayerTimeData(
        name: 'Dhuhr',
        time: now,
        durationMinutes: 15,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrayerTimeCard(
              prayer: prayer,
              onToggle: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Dhuhr'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('CallLogTile renders caller information and platform icon', (tester) async {
      final entry = CallLogEntry(
        id: '1',
        callerNumber: '+8801700000000',
        callerName: 'Rahim Ahmed',
        platform: CallPlatform.phone,
        messageSent: 'Ami namaz e achi',
        modeName: 'Namaz',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CallLogTile(entry: entry),
          ),
        ),
      );

      expect(find.text('Rahim Ahmed'), findsOneWidget);
      expect(find.text('Namaz'), findsOneWidget);
      expect(find.text('Ami namaz e achi'), findsOneWidget);
      expect(find.byIcon(Icons.phone), findsOneWidget);
    });
  });
}

