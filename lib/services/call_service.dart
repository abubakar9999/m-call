import 'package:flutter/services.dart';

import '../models/busy_mode.dart';
import '../platform/method_channels.dart';

/// Service for communicating with the native Android call-detection
/// foreground service via platform channels.
///
/// Provides methods to start / stop the native service, check its status,
/// reject the current incoming call, and stream incoming call events.
class CallService {
  /// Cached broadcast stream so multiple listeners share one EventChannel.
  Stream<Map<String, dynamic>>? _callStream;

  /// Informs the native platform that a busy mode has been activated with its parameters.
  Future<void> activateMode(BusyMode mode) async {
    try {
      await MethodChannels.activateMode(
        modeId: mode.id,
        modeName: mode.name,
        message: mode.message,
        durationMinutes: mode.durationMinutes,
        replyToPhone: mode.replyToPhone,
        replyToWhatsApp: mode.replyToWhatsApp,
        replyToMessenger: mode.replyToMessenger,
      );
    } catch (_) {}
  }

  /// Informs the native platform that the busy mode has been deactivated.
  Future<void> deactivateMode() async {
    try {
      await MethodChannels.deactivateMode();
    } catch (_) {}
  }

  /// Opens the system notification listener settings so the user can enable WhatsApp/Messenger auto-reply.
  Future<void> openNotificationSettings() async {
    try {
      await MethodChannels.callService.invokeMethod('openNotificationSettings');
    } catch (_) {}
  }

  /// Tells the native Android side to start the foreground call-detection
  /// service.
  ///
  /// The service listens for incoming phone calls and forwards events to
  /// Flutter through the [incomingCallStream].
  Future<void> startCallDetectionService() async {
    try {
      await MethodChannels.callService.invokeMethod('startService');
    } on PlatformException catch (e) {
      throw CallServiceException(
        'Failed to start call detection service: ${e.message}',
      );
    }
  }

  /// Tells the native Android side to stop the foreground call-detection
  /// service.
  Future<void> stopCallDetectionService() async {
    try {
      await MethodChannels.callService.invokeMethod('stopService');
    } on PlatformException catch (e) {
      throw CallServiceException(
        'Failed to stop call detection service: ${e.message}',
      );
    }
  }

  /// Returns `true` if the native call-detection service is currently running.
  Future<bool> isServiceRunning() async {
    try {
      final result = await MethodChannels.callService
          .invokeMethod<bool>('isServiceRunning');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// A broadcast stream of incoming call events.
  ///
  /// Each event is a `Map<String, dynamic>` with keys such as:
  /// - `"phoneNumber"` — the caller's phone number (String)
  /// - `"callerName"` — contact display name, if resolved (String?)
  /// - `"platform"` — the originating platform (String, e.g. "phone")
  Stream<Map<String, dynamic>> get incomingCallStream {
    _callStream ??= MethodChannels.callEvents
        .receiveBroadcastStream()
        .map<Map<String, dynamic>>((dynamic event) {
      if (event is Map) {
        return Map<String, dynamic>.from(event);
      }
      return <String, dynamic>{};
    }).handleError((dynamic error) {
      // Log or swallow — the stream stays alive so we don't lose future events.
    });
    return _callStream!;
  }

  /// Programmatically rejects (ends) the current incoming call.
  ///
  /// This invokes a native API that requires `ANSWER_PHONE_CALLS` permission
  /// on Android 9+.
  Future<void> rejectCall() async {
    try {
      await MethodChannels.callService.invokeMethod('rejectCall');
    } on PlatformException catch (e) {
      throw CallServiceException(
        'Failed to reject call: ${e.message}',
      );
    }
  }
}

/// Exception thrown when a platform call related to call detection fails.
class CallServiceException implements Exception {
  /// Human-readable description of the error.
  final String message;

  /// Creates a [CallServiceException] with the given [message].
  const CallServiceException(this.message);

  @override
  String toString() => 'CallServiceException: $message';
}
