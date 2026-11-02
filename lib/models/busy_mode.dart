import 'dart:convert';

/// The types of busy modes the app supports.
enum BusyModeType { namaz, meeting, sleep, classMode, driving, custom }

/// Represents a busy mode configuration that controls auto-reply behavior.
class BusyMode {
  final String id;
  final BusyModeType type;
  final String name;
  final String icon;
  final String message;
  final int durationMinutes;
  final bool isActive;
  final bool autoSchedule;
  final bool replyToPhone;
  final bool replyToWhatsApp;
  final bool replyToMessenger;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? scheduleData;

  bool get replyPhone => replyToPhone;
  bool get replyWhatsapp => replyToWhatsApp;
  bool get replyMessenger => replyToMessenger;

  const BusyMode({
    required this.id,
    required this.type,
    required this.name,
    required this.icon,
    required this.message,
    this.durationMinutes = 10,
    this.isActive = false,
    this.autoSchedule = false,
    this.replyToPhone = true,
    this.replyToWhatsApp = true,
    this.replyToMessenger = true,
    this.startTime,
    this.endTime,
    this.scheduleData,
  });

  /// Creates a copy of this [BusyMode] with the given fields replaced.
  BusyMode copyWith({
    String? id,
    BusyModeType? type,
    String? name,
    String? icon,
    String? message,
    int? durationMinutes,
    bool? isActive,
    bool? autoSchedule,
    bool? replyToPhone,
    bool? replyToWhatsApp,
    bool? replyToMessenger,
    DateTime? startTime,
    DateTime? endTime,
    String? scheduleData,
    bool clearStartTime = false,
    bool clearEndTime = false,
  }) {
    return BusyMode(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      message: message ?? this.message,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isActive: isActive ?? this.isActive,
      autoSchedule: autoSchedule ?? this.autoSchedule,
      replyToPhone: replyToPhone ?? this.replyToPhone,
      replyToWhatsApp: replyToWhatsApp ?? this.replyToWhatsApp,
      replyToMessenger: replyToMessenger ?? this.replyToMessenger,
      startTime: clearStartTime ? null : (startTime ?? this.startTime),
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
      scheduleData: scheduleData ?? this.scheduleData,
    );
  }

  /// Converts this mode to a JSON-compatible map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'name': name,
      'icon': icon,
      'message': message,
      'durationMinutes': durationMinutes,
      'isActive': isActive ? 1 : 0,
      'autoSchedule': autoSchedule ? 1 : 0,
      'replyToPhone': replyToPhone ? 1 : 0,
      'replyToWhatsApp': replyToWhatsApp ? 1 : 0,
      'replyToMessenger': replyToMessenger ? 1 : 0,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  /// Creates a [BusyMode] from a database map.
  factory BusyMode.fromMap(Map<String, dynamic> map) {
    return BusyMode(
      id: map['id'] as String,
      type: BusyModeType.values[map['type'] as int],
      name: map['name'] as String,
      icon: map['icon'] as String,
      message: map['message'] as String,
      durationMinutes: map['durationMinutes'] as int,
      isActive: (map['isActive'] as int) == 1,
      autoSchedule: (map['autoSchedule'] as int) == 1,
      replyToPhone: (map['replyToPhone'] as int) == 1,
      replyToWhatsApp: (map['replyToWhatsApp'] as int) == 1,
      replyToMessenger: (map['replyToMessenger'] as int) == 1,
      startTime: map['startTime'] != null
          ? DateTime.parse(map['startTime'] as String)
          : null,
      endTime: map['endTime'] != null
          ? DateTime.parse(map['endTime'] as String)
          : null,
    );
  }

  /// Converts this mode to a JSON string.
  String toJson() => json.encode(toMap());

  /// Creates a [BusyMode] from a JSON string.
  factory BusyMode.fromJson(String source) =>
      BusyMode.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Returns the 5 built-in busy modes with default configurations.
  static List<BusyMode> defaultModes() {
    return [
      const BusyMode(
        id: 'mode_namaz',
        type: BusyModeType.namaz,
        name: 'Namaz',
        icon: '🕌',
        message:
            'Assalamualaikum, {time} minute wait koren. Ami namaz e achi. InshaAllah namaz sheshe call korbo.',
        durationMinutes: 10,
        autoSchedule: true,
        replyToPhone: true,
        replyToWhatsApp: true,
        replyToMessenger: true,
      ),
      const BusyMode(
        id: 'mode_meeting',
        type: BusyModeType.meeting,
        name: 'Meeting',
        icon: '💼',
        message:
            "I'm in a meeting right now. Will call you back in {time} minutes.",
        durationMinutes: 30,
        replyToPhone: true,
        replyToWhatsApp: true,
        replyToMessenger: true,
      ),
      const BusyMode(
        id: 'mode_sleep',
        type: BusyModeType.sleep,
        name: 'Sleep',
        icon: '😴',
        message:
            "I'm sleeping right now. Will get back to you in the morning. 😴",
        durationMinutes: 480,
        replyToPhone: true,
        replyToWhatsApp: true,
        replyToMessenger: true,
      ),
      const BusyMode(
        id: 'mode_class',
        type: BusyModeType.classMode,
        name: 'Class',
        icon: '📚',
        message:
            "I'm in class right now. Will call you back after {time} minutes. 📚",
        durationMinutes: 45,
        replyToPhone: true,
        replyToWhatsApp: true,
        replyToMessenger: true,
      ),
      const BusyMode(
        id: 'mode_driving',
        type: BusyModeType.driving,
        name: 'Driving',
        icon: '🚗',
        message:
            "I'm driving right now. Will call you back when I stop. 🚗",
        durationMinutes: 60,
        replyToPhone: true,
        replyToWhatsApp: true,
        replyToMessenger: true,
      ),
    ];
  }

  @override
  String toString() =>
      'BusyMode(id: $id, type: $type, name: $name, isActive: $isActive)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is BusyMode && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
