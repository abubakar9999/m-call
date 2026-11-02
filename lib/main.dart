import 'package:flutter/material.dart';

import 'app.dart';
import 'services/auto_reply_manager.dart';
import 'services/call_service.dart';
import 'services/database_service.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/prayer_time_service.dart';
import 'services/sms_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Core Services
  final dbService = DatabaseService();
  await dbService.init();

  final notificationService = NotificationService();
  await notificationService.init();

  final locationService = LocationService();
  final prayerService = PrayerTimeService();
  final callService = CallService();
  final smsService = SmsService();

  final autoReplyManager = AutoReplyManager(
    db: dbService,
    notifications: notificationService,
    callService: callService,
    smsService: smsService,
  );

  runApp(
    MCallApp(
      dbService: dbService,
      autoReplyManager: autoReplyManager,
      prayerService: prayerService,
      locationService: locationService,
    ),
  );
}
