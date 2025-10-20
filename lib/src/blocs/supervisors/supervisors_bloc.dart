import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
part 'supervisors_event.dart';
part 'supervisors_state.dart';

class SupervisorsBloc extends Bloc<SupervisorsEvent, SupervisorsState> {
  final FirestoreService firestore;
  SupervisorsBloc(this.firestore) : super(SupervisorsInitial()) {
    on<LoadSupervisors>(_onLoad);
    on<SearchSupervisors>(_onSearch);
    on<CreateSupervisorWithAuth>(_onCreateWithAuth);
    on<UpdateSupervisor>(_onUpdate);
    on<DeleteSupervisor>(_onDelete);
  }

  Future<void> _onLoad(
    LoadSupervisors e,
    Emitter<SupervisorsState> emit,
  ) async {
    emit(SupervisorsLoading());
    try {
      final list = await firestore.listSupervisors(e.institutionId);
      emit(SupervisorsLoaded(list));
    } catch (err) {
      emit(SupervisorsError('فشل تحميل المشرفين: $err'));
    }
  }

  Future<void> _onSearch(
    SearchSupervisors e,
    Emitter<SupervisorsState> emit,
  ) async {
    emit(SupervisorsLoading());
    try {
      final list = await firestore.searchSupervisors(
        institutionId: e.institutionId,
        search: e.search,
        userRole: e.userRole,
        areaResponsibleFor: e.areaResponsibleFor,
        isActive: e.isActive,
      );
      emit(SupervisorsLoaded(list));
    } catch (err) {
      emit(SupervisorsError('فشل البحث: $err'));
    }
  }

  Future<void> _onCreateWithAuth(
    CreateSupervisorWithAuth e,
    Emitter<SupervisorsState> emit,
  ) async {
    try {
      final uid = await firestore.createSupervisorWithAuth(
        supervisorData: e.data,
        password: e.password,
      );
      
      if (uid == null) {
        emit(SupervisorsError('فشل إنشاء الحساب'));
        return;
      }

      // إعادة تحميل القائمة
      final instId = e.data['institutionId'] as String? ?? '';
      if (instId.isNotEmpty) add(LoadSupervisors(instId));
    } catch (err) {
      emit(SupervisorsError('فشل الإضافة: $err'));
    }
  }

  Future<void> _onUpdate(
    UpdateSupervisor e,
    Emitter<SupervisorsState> emit,
  ) async {
    try {
      await firestore.updateSupervisor(e.uid, e.data);
    } catch (err) {
      emit(SupervisorsError('فشل التحديث: $err'));
    }
  }

  Future<void> _onDelete(
    DeleteSupervisor e,
    Emitter<SupervisorsState> emit,
  ) async {
    try {
      await firestore.removeSupervisor(e.uid);
    } catch (err) {
      emit(SupervisorsError('فشل الحذف: $err'));
    }
  }
}