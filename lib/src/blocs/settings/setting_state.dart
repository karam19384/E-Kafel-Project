part of 'settings_bloc.dart';

@immutable
abstract class SettingsState extends Equatable {
  
  const SettingsState();
  
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  final SettingsModel settings;
  const SettingsLoaded(this.settings);
  
  @override
  List<Object?> get props => [settings];
}

class SettingsUpdating extends SettingsState {
  final SettingsModel settings;
  const SettingsUpdating(this.settings);
  
  @override
  List<Object?> get props => [settings];
}

class SettingsUpdated extends SettingsState {
  final SettingsModel settings;
  const SettingsUpdated(this.settings);
  
  @override
  List<Object?> get props => [settings];
}

class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class SettingsReset extends SettingsState {
  const SettingsReset();
}