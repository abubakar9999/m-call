import 'dart:convert';

/// The platform from which a call was received.
enum CallPlatform { phone, whatsapp, messenger }

/// Represents a single auto-replied call log entry.
class CallLogEntry {
  final String id;
  final String callerNumber;
  final String? callerName;
  final CallPlatform platform;
  final String messageSent;
  final String modeName;
  final DateTime timestamp;

  const CallLogEntry({
    required this.id,
    required this.callerNumber,
    this.callerName,
    required this.platform,
    required this.messageSent,
    required this.modeName,
    required this.timestamp,
  });

  /// Converts this entry to a database-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'callerNumber': callerNumber,
      'callerName': callerName,
      'platform': platform.index,
      'messageSent': messageSent,
      'modeName': modeName,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Creates a [CallLogEntry] from a database map.
  factory CallLogEntry.fromMap(Map<String, dynamic> map) {
    return CallLogEntry(
      id: map['id'] as String,
      callerNumber: map['callerNumber'] as String,
      callerName: map['callerName'] as String?,
      platform: CallPlatform.values[map['platform'] as int],
      messageSent: map['messageSent'] as String,
      modeName: map['modeName'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  /// Converts this entry to a JSON string.
  String toJson() => json.encode(toMap());

  /// Creates a [CallLogEntry] from a JSON string.
  factory CallLogEntry.fromJson(String source) =>
      CallLogEntry.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Returns a human-readable label for the platform.
  String get platformLabel {
    switch (platform) {
      case CallPlatform.phone:
        return 'Phone';
      case CallPlatform.whatsapp:
        return 'WhatsApp';
      case CallPlatform.messenger:
        return 'Messenger';
    }
  }

  /// Returns an icon/emoji for the platform.
  String get platformIcon {
    switch (platform) {
      case CallPlatform.phone:
        return '📞';
      case CallPlatform.whatsapp:
        return '💬';
      case CallPlatform.messenger:
        return '📱';
    }
  }

  /// Returns the display name (caller name if available, otherwise number).
  String get displayName => callerName ?? callerNumber;

  @override
  String toString() =>
      'CallLogEntry(id: $id, caller: $displayName, platform: $platformLabel, mode: $modeName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CallLogEntry && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
