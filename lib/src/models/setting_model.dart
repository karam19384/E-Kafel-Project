class SettingsModel {
  final bool isDarkMode;
  final bool notificationsEnabled;
  final bool autoSyncEnabled;
  final bool biometricEnabled;
  final bool offlineMode;
  final bool dataSaver;
  final bool hideSensitiveData;
  final bool vibrationEnabled;
  final String language;
  final String syncFrequency;
  final String fontSize;
  final String themeColor;

  SettingsModel({
    required this.isDarkMode,
    required this.notificationsEnabled,
    required this.autoSyncEnabled,
    required this.biometricEnabled,
    required this.offlineMode,
    required this.dataSaver,
    required this.hideSensitiveData,
    required this.vibrationEnabled,
    required this.language,
    required this.syncFrequency,
    required this.fontSize,
    required this.themeColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'isDarkMode': isDarkMode,
      'notificationsEnabled': notificationsEnabled,
      'autoSyncEnabled': autoSyncEnabled,
      'biometricEnabled': biometricEnabled,
      'offlineMode': offlineMode,
      'dataSaver': dataSaver,
      'hideSensitiveData': hideSensitiveData,
      'vibrationEnabled': vibrationEnabled,
      'language': language,
      'syncFrequency': syncFrequency,
      'fontSize': fontSize,
      'themeColor': themeColor,
    };
  }

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      isDarkMode: map['isDarkMode'] ?? false,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      autoSyncEnabled: map['autoSyncEnabled'] ?? true,
      biometricEnabled: map['biometricEnabled'] ?? false,
      offlineMode: map['offlineMode'] ?? false,
      dataSaver: map['dataSaver'] ?? false,
      hideSensitiveData: map['hideSensitiveData'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      language: map['language'] ?? 'العربية',
      syncFrequency: map['syncFrequency'] ?? 'كل 15 دقيقة',
      fontSize: map['fontSize'] ?? 'متوسط',
      themeColor: map['themeColor'] ?? 'أخضر أساسي',
    );
  }

  SettingsModel copyWith({
    bool? isDarkMode,
    bool? notificationsEnabled,
    bool? autoSyncEnabled,
    bool? biometricEnabled,
    bool? offlineMode,
    bool? dataSaver,
    bool? hideSensitiveData,
    bool? vibrationEnabled,
    String? language,
    String? syncFrequency,
    String? fontSize,
    String? themeColor,
  }) {
    return SettingsModel(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      offlineMode: offlineMode ?? this.offlineMode,
      dataSaver: dataSaver ?? this.dataSaver,
      hideSensitiveData: hideSensitiveData ?? this.hideSensitiveData,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      language: language ?? this.language,
      syncFrequency: syncFrequency ?? this.syncFrequency,
      fontSize: fontSize ?? this.fontSize,
      themeColor: themeColor ?? this.themeColor,
    );
  }

  // إعدادات افتراضية
  static SettingsModel get defaultSettings {
    return SettingsModel(
      isDarkMode: false,
      notificationsEnabled: true,
      autoSyncEnabled: true,
      biometricEnabled: false,
      offlineMode: false,
      dataSaver: false,
      hideSensitiveData: true,
      vibrationEnabled: true,
      language: 'العربية',
      syncFrequency: 'كل 15 دقيقة',
      fontSize: 'متوسط',
      themeColor: 'أخضر أساسي',
    );
  }
}