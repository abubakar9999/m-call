import 'package:flutter/services.dart';

import 'package:m_call/utils/constants.dart';

/// Handles all platform channel communication with native Android/iOS code
/// for background service management and call interception.
class MethodChannels {
  MethodChannels._();

  // ── Channels ──────────────────────────────────────────────────────────────

  /// Method channel for sending commands to the native platform.
  static const MethodChannel _methodChannel =
      MethodChannel(AppConstants.methodChannelName);

  /// Event channel for receiving incoming call events from the platform.
  static const EventChannel _eventChannel =
      EventChannel(AppConstants.eventChannelName);

  /// Expose channels for services
  static const MethodChannel callService = _methodChannel;
  static const MethodChannel smsService = _methodChannel;
  static const EventChannel callEvents = _eventChannel;

  // ── Method Names ──────────────────────────────────────────────────────────

  static const String _startService = 'startService';
  static const String _stopService = 'stopService';
  static const String _activateMode = 'activateMode';
  static const String _deactivateMode = 'deactivateMode';
  static const String _isServiceRunning = 'isServiceRunning';
  static const String _sendSms = 'sendSms';
  static const String _getContactName = 'getContactName';

  // ── Service Management ────────────────────────────────────────────────────

  /// Starts the background auto-reply service on the native platform.
  ///
  /// Returns `true` if the service started successfully.
  static Future<bool> startService() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(_startService);
      return result ?? false;
    } on PlatformException catch (e) {
      _logError('startService', e);
      return false;
    } on MissingPluginException {
      // Plugin not implemented on this platform (e.g., iOS simulator).
      return false;
    }
  }

  /// Stops the background auto-reply service on the native platform.
  ///
  /// Returns `true` if the service stopped successfully.
  static Future<bool> stopService() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(_stopService);
      return result ?? false;
    } on PlatformException catch (e) {
      _logError('stopService', e);
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Activates a specific busy mode on the native side.
  ///
  /// [modeId] - The unique ID of the mode to activate.
  /// [modeName] - Display name of the mode.
  /// [message] - The auto-reply message to send.
  /// [durationMinutes] - How long the mode should stay active.
  /// [replyToPhone] - Whether to reply to phone calls.
  /// [replyToWhatsApp] - Whether to reply on WhatsApp.
  /// [replyToMessenger] - Whether to reply on Messenger.
  ///
  /// Returns `true` if the mode was activated successfully.
  static Future<bool> activateMode({
    required String modeId,
    required String modeName,
    required String message,
    required int durationMinutes,
    bool replyToPhone = true,
    bool replyToWhatsApp = true,
    bool replyToMessenger = true,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        _activateMode,
        {
          'modeId': modeId,
          'modeName': modeName,
          'message': message,
          'durationMinutes': durationMinutes,
          'replyToPhone': replyToPhone,
          'replyToWhatsApp': replyToWhatsApp,
          'replyToMessenger': replyToMessenger,
        },
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _logError('activateMode', e);
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Deactivates the currently active busy mode on the native side.
  ///
  /// Returns `true` if the mode was deactivated successfully.
  static Future<bool> deactivateMode() async {
    try {
      final result =
          await _methodChannel.invokeMethod<bool>(_deactivateMode);
      return result ?? false;
    } on PlatformException catch (e) {
      _logError('deactivateMode', e);
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Checks whether the background service is currently running.
  ///
  /// Returns `true` if the service is running.
  static Future<bool> isServiceRunning() async {
    try {
      final result =
          await _methodChannel.invokeMethod<bool>(_isServiceRunning);
      return result ?? false;
    } on PlatformException catch (e) {
      _logError('isServiceRunning', e);
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Sends an SMS message to the specified phone number via the native platform.
  ///
  /// Returns `true` if the message was sent successfully.
  static Future<bool> sendSms({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        _sendSms,
        {
          'phoneNumber': phoneNumber,
          'message': message,
        },
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _logError('sendSms', e);
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Looks up a contact name from the device's address book by phone number.
  ///
  /// Returns the contact name, or `null` if not found.
  static Future<String?> getContactName(String phoneNumber) async {
    try {
      final result = await _methodChannel.invokeMethod<String>(
        _getContactName,
        {'phoneNumber': phoneNumber},
      );
      return result;
    } on PlatformException catch (e) {
      _logError('getContactName', e);
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  // ── Event Stream ──────────────────────────────────────────────────────────

  /// Returns a stream of incoming call events from the native platform.
  ///
  /// Each event is a [Map] containing:
  /// - `phoneNumber` (String) - the caller's phone number
  /// - `contactName` (String?) - the caller's name if in contacts
  /// - `platform` (String) - "phone", "whatsapp", or "messenger"
  /// - `timestamp` (String) - ISO 8601 timestamp
  static Stream<Map<String, dynamic>> get incomingCallEvents {
    return _eventChannel.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return Map<String, dynamic>.from(event);
      }
      return <String, dynamic>{};
    });
  }

  // ── Error Logging ─────────────────────────────────────────────────────────

  static void _logError(String method, PlatformException e) {
    // In production, this would integrate with a crash reporting service.
    // For now, we use debugPrint to keep the error visible during development.
    assert(() {
      // ignore: avoid_print
      print('MethodChannel error in $method: ${e.message}');
      return true;
    }());
  }
}
