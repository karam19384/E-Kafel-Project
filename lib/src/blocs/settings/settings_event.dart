part of 'settings_bloc.dart';

@immutable
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {
  final String userId;
  const LoadSettings(this.userId);
  
  @override
  List<Object?> get props => [userId];
}

class UpdateSettings extends SettingsEvent {
  final String userId;
  final SettingsModel settings;
  const UpdateSettings(this.userId, this.settings);
  
  @override
  List<Object?> get props => [userId, settings];
}

class UpdateSingleSetting extends SettingsEvent {
  final String userId;
  final String settingKey;
  final dynamic value;
  const UpdateSingleSetting(this.userId, this.settingKey, this.value);
  
  @override
  List<Object?> get props => [userId, settingKey, value];
}

class ResetSettings extends SettingsEvent {
  final String userId;
  const ResetSettings(this.userId);
  
  @override
  List<Object?> get props => [userId];
}

class ToggleDarkMode extends SettingsEvent {
  final String userId;
  final bool isDarkMode;
  const ToggleDarkMode(this.userId, this.isDarkMode);
  
  @override
  List<Object?> get props => [userId, isDarkMode];
}

class ToggleNotification extends SettingsEvent {
  final String userId;
  final bool enabled;
  const ToggleNotification(this.userId, this.enabled);
  
  @override
  List<Object?> get props => [userId, enabled];
}

class ChangeLanguage extends SettingsEvent {
  final String userId;
  final String language;
  const ChangeLanguage(this.userId, this.language);
  
  @override
  List<Object?> get props => [userId, language];
}

class ChangeSyncFrequency extends SettingsEvent {
  final String userId;
  final String frequency;
  const ChangeSyncFrequency(this.userId, this.frequency);
  
  @override
  List<Object?> get props => [userId, frequency];
}

