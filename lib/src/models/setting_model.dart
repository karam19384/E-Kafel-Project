
class SettingsModel {
  final bool isDarkMode;
  final bool notificationsEnabled;
  final bool autoSyncEnabled;
  final bool biometricEnabled;
  final String language;
  final String syncFrequency;

  SettingsModel({
    required this.isDarkMode,
    required this.notificationsEnabled,
    required this.autoSyncEnabled,
    required this.biometricEnabled,
    required this.language,
    required this.syncFrequency,
  });

  Map<String, dynamic> toMap() {
    return {
      'isDarkMode': isDarkMode,
      'notificationsEnabled': notificationsEnabled,
      'autoSyncEnabled': autoSyncEnabled,
      'biometricEnabled': biometricEnabled,
      'language': language,
      'syncFrequency': syncFrequency,
    };
  }

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      isDarkMode: map['isDarkMode'] ?? false,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      autoSyncEnabled: map['autoSyncEnabled'] ?? true,
      biometricEnabled: map['biometricEnabled'] ?? false,
      language: map['language'] ?? 'العربية',
      syncFrequency: map['syncFrequency'] ?? 'كل 15 دقيقة',
    );
  }

  SettingsModel copyWith({
    bool? isDarkMode,
    bool? notificationsEnabled,
    bool? autoSyncEnabled,
    bool? biometricEnabled,
    String? language,
    String? syncFrequency,
  }) {
    return SettingsModel(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      language: language ?? this.language,
      syncFrequency: syncFrequency ?? this.syncFrequency,
    );
  }
}
