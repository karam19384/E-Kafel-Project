import 'package:e_kafel/src/services/firestore_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../models/setting_model.dart';

part 'settings_event.dart';
part 'setting_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final FirestoreService _firestoreService;

  SettingsBloc(this._firestoreService) : super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateSettings>(_onUpdateSettings);
    on<UpdateSingleSetting>(_onUpdateSingleSetting);
    on<ResetSettings>(_onResetSettings);
    on<ToggleDarkMode>(_onToggleDarkMode);
    on<ToggleNotification>(_onToggleNotification);
    on<ChangeLanguage>(_onChangeLanguage);
    on<ChangeSyncFrequency>(_onChangeSyncFrequency);
  }

  Future<void> _onLoadSettings(
      LoadSettings event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    try {
      final settings = await _firestoreService.getSettings(event.userId);
      if (settings != null) {
        emit(SettingsLoaded(settings));
      } else {
        // أول مرة يتم حفظ الإعدادات
        final defaultSettings = SettingsModel.defaultSettings;
        await _firestoreService.saveSettings(event.userId, defaultSettings);
        emit(SettingsLoaded(defaultSettings));
      }
    } catch (e) {
      emit(SettingsError('فشل تحميل الإعدادات: $e'));
    }
  }

  Future<void> _onUpdateSettings(
      UpdateSettings event, Emitter<SettingsState> emit) async {
    try {
      emit(SettingsUpdating(event.settings));
      await _firestoreService.saveSettings(event.userId, event.settings);
      emit(SettingsUpdated(event.settings));
    } catch (e) {
      emit(SettingsError("فشل تحديث الإعدادات: $e"));
    }
  }

  Future<void> _onUpdateSingleSetting(
      UpdateSingleSetting event, Emitter<SettingsState> emit) async {
    try {
      final currentState = state;
      SettingsModel currentSettings;
      
      // الحصول على الإعدادات الحالية من أي حالة
      if (currentState is SettingsLoaded) {
        currentSettings = currentState.settings;
      } else if (currentState is SettingsUpdated) {
        currentSettings = currentState.settings;
      } else if (currentState is SettingsUpdating) {
        currentSettings = currentState.settings;
      } else {
        // إذا لم تكن هناك إعدادات محملة، نستخدم الإعدادات الافتراضية
        currentSettings = SettingsModel.defaultSettings;
      }

      final updatedSettings = _updateSetting(
        currentSettings,
        event.settingKey,
        event.value,
      );
      
      // إصدار حالة التحديث فوراً
      emit(SettingsUpdating(updatedSettings));
      await _firestoreService.saveSettings(event.userId, updatedSettings);
      // إصدار الحالة النهائية
      emit(SettingsUpdated(updatedSettings));
    } catch (e) {
      // في حالة الخطأ، نرجع للحالة السابقة
      final currentState = state;
      if (currentState is SettingsLoaded) {
        emit(SettingsError("فشل تحديث الإعداد: $e"));
        // إعادة تحميل الإعدادات الأصلية بعد الخطأ
        await Future.delayed(const Duration(seconds: 2));
        add(LoadSettings(event.userId));
      } else {
        emit(SettingsError("فشل تحديث الإعداد: $e"));
      }
    }
  }

  Future<void> _onResetSettings(
      ResetSettings event, Emitter<SettingsState> emit) async {
    try {
      emit(const SettingsLoading());
      final defaultSettings = SettingsModel.defaultSettings;
      await _firestoreService.saveSettings(event.userId, defaultSettings);
      emit(SettingsLoaded(defaultSettings));
    } catch (e) {
      emit(SettingsError("فشل إعادة تعيين الإعدادات: $e"));
    }
  }

  Future<void> _onToggleDarkMode(
      ToggleDarkMode event, Emitter<SettingsState> emit) async {
    try {
      final currentState = state;
      SettingsModel currentSettings;
      
      if (currentState is SettingsLoaded) {
        currentSettings = currentState.settings;
      } else if (currentState is SettingsUpdated) {
        currentSettings = currentState.settings;
      } else if (currentState is SettingsUpdating) {
        currentSettings = currentState.settings;
      } else {
        currentSettings = SettingsModel.defaultSettings;
      }

      final updatedSettings = currentSettings.copyWith(
        isDarkMode: event.isDarkMode,
      );
      emit(SettingsUpdating(updatedSettings));
      await _firestoreService.saveSettings(event.userId, updatedSettings);
      emit(SettingsUpdated(updatedSettings));
    } catch (e) {
      emit(SettingsError("فشل تغيير وضع الثيم: $e"));
    }
  }

  Future<void> _onToggleNotification(
      ToggleNotification event, Emitter<SettingsState> emit) async {
    try {
      final currentState = state;
      SettingsModel currentSettings;
      
      if (currentState is SettingsLoaded) {
        currentSettings = currentState.settings;
      } else if (currentState is SettingsUpdated) {
        currentSettings = currentState.settings;
      } else if (currentState is SettingsUpdating) {
        currentSettings = currentState.settings;
      } else {
        currentSettings = SettingsModel.defaultSettings;
      }

      final updatedSettings = currentSettings.copyWith(
        notificationsEnabled: event.enabled,
      );
      emit(SettingsUpdating(updatedSettings));
      await _firestoreService.saveSettings(event.userId, updatedSettings);
      emit(SettingsUpdated(updatedSettings));
    } catch (e) {
      emit(SettingsError("فشل تغيير إعداد الإشعارات: $e"));
    }
  }

  Future<void> _onChangeLanguage(
      ChangeLanguage event, Emitter<SettingsState> emit) async {
    try {
      final currentState = state;
      SettingsModel currentSettings;
      
      if (currentState is SettingsLoaded) {
        currentSettings = currentState.settings;
      } else if (currentState is SettingsUpdated) {
        currentSettings = currentState.settings;
      } else if (currentState is SettingsUpdating) {
        currentSettings = currentState.settings;
      } else {
        currentSettings = SettingsModel.defaultSettings;
      }

      final updatedSettings = currentSettings.copyWith(
        language: event.language,
      );
      emit(SettingsUpdating(updatedSettings));
      await _firestoreService.saveSettings(event.userId, updatedSettings);
      emit(SettingsUpdated(updatedSettings));
    } catch (e) {
      emit(SettingsError("فشل تغيير اللغة: $e"));
    }
  }

  Future<void> _onChangeSyncFrequency(
      ChangeSyncFrequency event, Emitter<SettingsState> emit) async {
    try {
      final currentState = state;
      SettingsModel currentSettings;
      
      if (currentState is SettingsLoaded) {
        currentSettings = currentState.settings;
      } else if (currentState is SettingsUpdated) {
        currentSettings = currentState.settings;
      } else if (currentState is SettingsUpdating) {
        currentSettings = currentState.settings;
      } else {
        currentSettings = SettingsModel.defaultSettings;
      }

      final updatedSettings = currentSettings.copyWith(
        syncFrequency: event.frequency,
      );
      emit(SettingsUpdating(updatedSettings));
      await _firestoreService.saveSettings(event.userId, updatedSettings);
      emit(SettingsUpdated(updatedSettings));
    } catch (e) {
      emit(SettingsError("فشل تغيير تكرار المزامنة: $e"));
    }
  }

  SettingsModel _updateSetting(
    SettingsModel settings,
    String key,
    dynamic value,
  ) {
    switch (key) {
      case 'isDarkMode':
        return settings.copyWith(isDarkMode: value as bool);
      case 'notificationsEnabled':
        return settings.copyWith(notificationsEnabled: value as bool);
      case 'autoSyncEnabled':
        return settings.copyWith(autoSyncEnabled: value as bool);
      case 'biometricEnabled':
        return settings.copyWith(biometricEnabled: value as bool);
      case 'offlineMode':
        return settings.copyWith(offlineMode: value as bool);
      case 'dataSaver':
        return settings.copyWith(dataSaver: value as bool);
      case 'hideSensitiveData':
        return settings.copyWith(hideSensitiveData: value as bool);
      case 'vibrationEnabled':
        return settings.copyWith(vibrationEnabled: value as bool);
      case 'language':
        return settings.copyWith(language: value as String);
      case 'syncFrequency':
        return settings.copyWith(syncFrequency: value as String);
      case 'fontSize':
        return settings.copyWith(fontSize: value as String);
      case 'themeColor':
        return settings.copyWith(themeColor: value as String);
      default:
        return settings;
    }
  }
}