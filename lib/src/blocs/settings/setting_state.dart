part of 'settings_bloc.dart';
abstract class SettingsState extends Equatable{}

class SettingsInitial extends SettingsState {
  @override
  List<Object?> get props => [];
}

class SettingsLoading extends SettingsState {
  @override
  List<Object?> get props => [];
}

class SettingsLoaded extends SettingsState {
  final SettingsModel settings;
  SettingsLoaded(this.settings);
  
  @override
  List<Object?> get props => [];
}

class SettingsError extends SettingsState {
  final String message;
  SettingsError(this.message);
  
  @override
  List<Object?> get props => [];
}
