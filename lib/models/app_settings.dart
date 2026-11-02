import 'dart:convert';

/// Application-wide settings for M Call.
class AppSettings {
  final String language;
  final bool phoneAutoReply;
  final bool whatsappAutoReply;
  final bool messengerAutoReply;
  final String calculationMethod;
  final bool darkMode;
  final bool showNotifications;

  const AppSettings({
    this.language = 'en',
    this.phoneAutoReply = true,
    this.whatsappAutoReply = true,
    this.messengerAutoReply = true,
    this.calculationMethod = 'karachi',
    this.darkMode = false,
    this.showNotifications = true,
  });

  /// Creates a copy of this [AppSettings] with the given fields replaced.
  AppSettings copyWith({
    String? language,
    bool? phoneAutoReply,
    bool? whatsappAutoReply,
    bool? messengerAutoReply,
    String? calculationMethod,
    bool? darkMode,
    bool? showNotifications,
  }) {
    return AppSettings(
      language: language ?? this.language,
      phoneAutoReply: phoneAutoReply ?? this.phoneAutoReply,
      whatsappAutoReply: whatsappAutoReply ?? this.whatsappAutoReply,
      messengerAutoReply: messengerAutoReply ?? this.messengerAutoReply,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      darkMode: darkMode ?? this.darkMode,
      showNotifications: showNotifications ?? this.showNotifications,
    );
  }

  /// Converts this settings object to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'phoneAutoReply': phoneAutoReply,
      'whatsappAutoReply': whatsappAutoReply,
      'messengerAutoReply': messengerAutoReply,
      'calculationMethod': calculationMethod,
      'darkMode': darkMode,
      'showNotifications': showNotifications,
    };
  }

  /// Creates an [AppSettings] from a JSON map.
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      language: json['language'] as String? ?? 'en',
      phoneAutoReply: json['phoneAutoReply'] as bool? ?? true,
      whatsappAutoReply: json['whatsappAutoReply'] as bool? ?? true,
      messengerAutoReply: json['messengerAutoReply'] as bool? ?? true,
      calculationMethod: json['calculationMethod'] as String? ?? 'karachi',
      darkMode: json['darkMode'] as bool? ?? false,
      showNotifications: json['showNotifications'] as bool? ?? true,
    );
  }

  /// Serializes to a JSON string.
  String encode() => json.encode(toJson());

  /// Deserializes from a JSON string.
  factory AppSettings.decode(String source) =>
      AppSettings.fromJson(json.decode(source) as Map<String, dynamic>);

  /// Returns the default settings instance.
  static const AppSettings defaults = AppSettings();

  @override
  String toString() =>
      'AppSettings(language: $language, darkMode: $darkMode, method: $calculationMethod)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettings &&
          other.language == language &&
          other.phoneAutoReply == phoneAutoReply &&
          other.whatsappAutoReply == whatsappAutoReply &&
          other.messengerAutoReply == messengerAutoReply &&
          other.calculationMethod == calculationMethod &&
          other.darkMode == darkMode &&
          other.showNotifications == showNotifications);

  @override
  int get hashCode => Object.hash(
        language,
        phoneAutoReply,
        whatsappAutoReply,
        messengerAutoReply,
        calculationMethod,
        darkMode,
        showNotifications,
      );
}
