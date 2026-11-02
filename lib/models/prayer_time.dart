import 'dart:convert';

/// Represents the prayer time data for a single prayer.
class PrayerTimeData {
  final String name;
  final DateTime time;
  final int durationMinutes;
  final bool enabled;

  const PrayerTimeData({
    required this.name,
    required this.time,
    this.durationMinutes = 10,
    this.enabled = true,
  });

  /// Returns `true` if the current time falls within [time, time + duration].
  bool get isActive {
    final now = DateTime.now();
    final end = time.add(Duration(minutes: durationMinutes));
    return now.isAfter(time) && now.isBefore(end);
  }

  /// Returns the remaining minutes until this prayer's busy window ends.
  /// Returns 0 if the prayer is not currently active.
  int get remainingMinutes {
    if (!isActive) return 0;
    final now = DateTime.now();
    final end = time.add(Duration(minutes: durationMinutes));
    return end.difference(now).inMinutes;
  }

  /// Returns `true` if this prayer hasn't occurred yet today.
  bool get isUpcoming {
    final now = DateTime.now();
    return time.isAfter(now);
  }

  /// Creates a copy of this [PrayerTimeData] with the given fields replaced.
  PrayerTimeData copyWith({
    String? name,
    DateTime? time,
    int? durationMinutes,
    bool? enabled,
  }) {
    return PrayerTimeData(
      name: name ?? this.name,
      time: time ?? this.time,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      enabled: enabled ?? this.enabled,
    );
  }

  /// Converts this prayer time to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'time': time.toIso8601String(),
      'durationMinutes': durationMinutes,
      'enabled': enabled,
    };
  }

  /// Creates a [PrayerTimeData] from a JSON map.
  factory PrayerTimeData.fromJson(Map<String, dynamic> json) {
    return PrayerTimeData(
      name: json['name'] as String,
      time: DateTime.parse(json['time'] as String),
      durationMinutes: json['durationMinutes'] as int? ?? 10,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  @override
  String toString() =>
      'PrayerTimeData(name: $name, time: $time, active: $isActive)';
}

/// Holds all five daily prayer times for a single date.
class DailyPrayerTimes {
  final DateTime date;
  final PrayerTimeData fajr;
  final PrayerTimeData dhuhr;
  final PrayerTimeData asr;
  final PrayerTimeData maghrib;
  final PrayerTimeData isha;
  final String calculationMethod;

  const DailyPrayerTimes({
    required this.date,
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.calculationMethod = 'karachi',
  });

  /// Returns all five prayer times as a list.
  List<PrayerTimeData> get all => [fajr, dhuhr, asr, maghrib, isha];

  /// Returns the currently active prayer, or `null` if no prayer is active.
  PrayerTimeData? get currentPrayer {
    for (final prayer in all) {
      if (prayer.enabled && prayer.isActive) {
        return prayer;
      }
    }
    return null;
  }

  /// Returns the next upcoming prayer, or `null` if all prayers have passed.
  PrayerTimeData? get nextPrayer {
    final now = DateTime.now();
    for (final prayer in all) {
      if (prayer.enabled && prayer.time.isAfter(now)) {
        return prayer;
      }
    }
    return null;
  }

  /// Converts this object to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'fajr': fajr.toJson(),
      'dhuhr': dhuhr.toJson(),
      'asr': asr.toJson(),
      'maghrib': maghrib.toJson(),
      'isha': isha.toJson(),
    };
  }

  /// Creates a [DailyPrayerTimes] from a JSON map.
  factory DailyPrayerTimes.fromJson(Map<String, dynamic> json) {
    return DailyPrayerTimes(
      date: DateTime.parse(json['date'] as String),
      fajr: PrayerTimeData.fromJson(json['fajr'] as Map<String, dynamic>),
      dhuhr: PrayerTimeData.fromJson(json['dhuhr'] as Map<String, dynamic>),
      asr: PrayerTimeData.fromJson(json['asr'] as Map<String, dynamic>),
      maghrib:
          PrayerTimeData.fromJson(json['maghrib'] as Map<String, dynamic>),
      isha: PrayerTimeData.fromJson(json['isha'] as Map<String, dynamic>),
    );
  }

  /// Serializes to a JSON string.
  String encode() => json.encode(toJson());

  /// Deserializes from a JSON string.
  factory DailyPrayerTimes.decode(String source) =>
      DailyPrayerTimes.fromJson(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'DailyPrayerTimes(date: $date, current: ${currentPrayer?.name}, next: ${nextPrayer?.name})';
}
