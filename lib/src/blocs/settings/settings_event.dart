part of 'settings_bloc.dart';
abstract class SettingsEvent extends Equatable{}

class LoadSettings extends SettingsEvent {
  final String userId;
  LoadSettings(this.userId);
  
  @override
  List<Object?> get props => [];
}

class UpdateSettings extends SettingsEvent {
  final SettingsModel settings;
  UpdateSettings(this.settings);
  
  @override
  List<Object?> get props => [];
}
