import 'package:e_kafel/src/services/firestore_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/setting_model.dart';

part 'settings_event.dart';
part 'setting_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final FirestoreService _firestoreService;

  SettingsBloc(this._firestoreService) : super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateSettings>(_onUpdateSettings);
  }

  Future<void> _onLoadSettings(
      LoadSettings event, Emitter<SettingsState> emit) async {
    emit(SettingsLoading());
    try {
      final settings = await _firestoreService.getSettings(event.userId);
      if (settings != null) {
        emit(SettingsLoaded(settings));
      } else {
        // أول مرة يتم حفظ الإعدادات
        final defaultSettings = SettingsModel(
          isDarkMode: false,
          notificationsEnabled: true,
          autoSyncEnabled: true,
          biometricEnabled: false,
          language: 'العربية',
          syncFrequency: 'كل 15 دقيقة',
        );
        await _firestoreService.saveSettings(event.userId, defaultSettings);
        emit(SettingsLoaded(defaultSettings));
      }
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onUpdateSettings(
      UpdateSettings event, Emitter<SettingsState> emit) async {
    try {
      // استرجاع userId من مكان مناسب (AuthBloc أو FirebaseAuth)
      final userId = 'event.userId'; // استبدل هذا بالقيمة الصحيحة
      await _firestoreService.saveSettings(userId, event.settings);
      emit(SettingsLoaded(event.settings));
    } catch (e) {
      emit(SettingsError("فشل تحديث الإعدادات: $e"));
    }
  }
}
