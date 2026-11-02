import 'package:flutter/services.dart';

import '../platform/method_channels.dart';

/// Service for sending SMS messages via the native Android platform.
///
/// Uses a [MethodChannel] to invoke native code that dispatches SMS using
/// the device's SIM card.
class SmsService {
  /// Sends an SMS [message] to the given [phoneNumber].
  ///
  /// Returns `true` if the SMS was dispatched successfully, `false` otherwise.
  /// Does **not** guarantee delivery — only that the message was handed off to
  /// the telephony framework.
  Future<bool> sendSms(String phoneNumber, String message) async {
    try {
      final result = await MethodChannels.smsService.invokeMethod<bool>(
        'sendSms',
        <String, String>{
          'phoneNumber': phoneNumber,
          'message': message,
        },
      );
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Checks whether the device is able to send SMS.
  ///
  /// Returns `true` if `SEND_SMS` permission is granted **and** a SIM card
  /// is available.
  Future<bool> canSendSms() async {
    try {
      final result = await MethodChannels.smsService.invokeMethod<bool>(
        'canSendSms',
      );
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }
}
