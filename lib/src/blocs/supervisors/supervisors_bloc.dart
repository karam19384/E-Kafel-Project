import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/fcm_service.dart';
import '../../models/user_model.dart';

part 'supervisors_event.dart';
part 'supervisors_state.dart';

class SupervisorsBloc extends Bloc<SupervisorsEvent, SupervisorsState> {
  final FirestoreService firestoreService;
  final AuthService authService;
  final FCMService fcm;

  SupervisorsBloc(this.firestoreService,
      {AuthService? auth, FCMService? fcmService})
      : authService = auth ?? AuthService(),
        fcm = fcmService ?? FCMService(),
        super(SupervisorsInitial()) {
    on<LoadSupervisors>(_onLoad);
    on<LoadSupervisorsByHead>(_onLoadByHead);
    on<SearchSupervisors>(_onSearch);
    on<CreateSupervisorWithAuth>(_onCreateWithAuth);
    on<UpdateSupervisor>(_onUpdate);
    // أزلنا DeleteSupervisor
    on<ToggleSupervisorActive>(_onToggleActive);
  }

  Future<void> _onLoad(
      LoadSupervisors e, Emitter<SupervisorsState> emit) async {
    emit(SupervisorsLoading());
    try {
      final list = await firestoreService.listSupervisors(e.institutionId);
      emit(SupervisorsLoaded(list));
    } catch (err) {
      emit(SupervisorsError('فشل تحميل المشرفين: $err'));
    }
  }

  Future<void> _onLoadByHead(
      LoadSupervisorsByHead e, Emitter<SupervisorsState> emit) async {
    emit(SupervisorsLoading());
    try {
      final list = await firestoreService.listSupervisorsByHead(
        institutionId: e.institutionId,
        kafalaHeadId: e.kafalaHeadId,
      );
      emit(SupervisorsLoaded(list.map((m) => UserModel.fromMap(m)).toList()));
    } catch (err) {
      emit(SupervisorsError('فشل تحميل المشرفين: $err'));
    }
  }

  Future<void> _onSearch(
      SearchSupervisors e, Emitter<SupervisorsState> emit) async {
    emit(SupervisorsLoading());
    try {
      final list = await firestoreService.searchSupervisors(
        institutionId: e.institutionId,
        search: e.search,
        userRole: e.userRole,
        areaResponsibleFor: e.areaResponsibleFor,
      );
      emit(SupervisorsLoaded(list));
    } catch (err) {
      emit(SupervisorsError('فشل البحث: $err'));
    }
  }

  Future<void> _onCreateWithAuth(
      CreateSupervisorWithAuth e, Emitter<SupervisorsState> emit) async {
    try {
      final uid = await authService.createSupervisorAccount(
        supervisorData: e.data,
        password: e.password,
      );
      if (uid.isEmpty) {
        emit(SupervisorsError('فشل إنشاء الحساب'));
        return;
      }

      // إشعار للمشرف الجديد
      await firestoreService.notifyUser(
        userId: uid,
        title: 'تم إنشاء حسابك',
        message: 'مرحباً ${e.data['fullName']}, تم إعداد حسابك كمشرف.',
        type: 'supervisor_created',
      );
      await fcm.sendToUser(
        userId: uid,
        title: 'حسابك جاهز',
        body: 'يمكنك تسجيل الدخول الآن.',
        data: {'type': 'supervisor_created'},
      );

      final instId = e.data['institutionId'] as String? ?? '';
      final headId = e.data['kafalaHeadId'] as String? ?? '';
      if (instId.isNotEmpty && headId.isNotEmpty) {
        add(LoadSupervisorsByHead(institutionId: instId, kafalaHeadId: headId , isActive: true));
      } else if (instId.isNotEmpty) {
        add(LoadSupervisors(instId));
      }
    } catch (err) {
      emit(SupervisorsError('فشل الإضافة: $err'));
    }
  }

  Future<void> _onUpdate(
      UpdateSupervisor e, Emitter<SupervisorsState> emit) async {
    try {
      await firestoreService.updateSupervisor(e.uid, e.data);

      // إشعار للمشرف المعدّل
      await firestoreService.notifyUser(
        userId: e.uid,
        title: 'تحديث بيانات',
        message: 'تم تعديل بيانات حسابك من قبل رئيس القسم.',
        type: 'supervisor_updated',
      );
      await fcm.sendToUser(
        userId: e.uid,
        title: 'تم تعديل بياناتك',
        body: 'راجِع صفحتك الشخصية للاطلاع على التغييرات.',
        data: {'type': 'supervisor_updated'},
      );
    } catch (err) {
      emit(SupervisorsError('فشل التحديث: $err'));
    }
  }

  Future<void> _onToggleActive(
      ToggleSupervisorActive e, Emitter<SupervisorsState> emit) async {
    try {
      await firestoreService.toggleSupervisorActive(e.uid, e.isActive);
      await firestoreService.notifyUser(
        userId: e.uid,
        title: e.isActive ? 'تفعيل الحساب' : 'إلغاء التفعيل',
        message: e.isActive
            ? 'تم تفعيل حسابك ويمكنك استخدام النظام.'
            : 'تم إلغاء تفعيل حسابك. لن يمكنك تسجيل الدخول.',
        type: 'supervisor_active_toggle',
        extra: {'isActive': e.isActive},
      );
      await fcm.sendToUser(
        userId: e.uid,
        title: e.isActive ? 'تم تفعيل الحساب' : 'تم إلغاء التفعيل',
        body: e.isActive
            ? 'يمكنك استخدام النظام الآن.'
            : 'لن تتمكن من تسجيل الدخول حتى إشعار آخر.',
        data: {'type': 'supervisor_active_toggle'},
      );
    } catch (err) {
      emit(SupervisorsError('فشل تعديل الحالة: $err'));
    }
  }
}
