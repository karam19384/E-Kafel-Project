import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/sponsorship_model.dart';
import '../../services/firestore_service.dart';
part 'sponsorship_event.dart';

part 'sponsorship_state.dart';

class SponsorshipBloc extends Bloc<SponsorshipEvent, SponsorshipState> {
  final FirestoreService firestore;

  SponsorshipBloc({required this.firestore}) : super(SponsorshipInitial()) {
    // تأكد من تسجيل جميع المعالجات بشكل صحيح
    on<LoadSponsorshipProjects>(_onLoad);
    on<CreateSponsorshipProjectEvent>(_onCreate);
    on<UpdateSponsorshipProjectEvent>(_onUpdate);
    on<ChangeProjectStatusEvent>(_onChangeStatus);
    on<AddProjectEventItemEvent>(_onAddEvent);
  }

  Future<void> _onLoad(
      LoadSponsorshipProjects event, Emitter<SponsorshipState> emit) async {
    try {
      emit(SponsorshipLoading());
      final list = await firestore.listSponsorshipProjects(
        institutionId: event.institutionId,
        status: event.status,
        type: event.type,
        search: event.search,
      );

      // احسب الإحصائيات
      final total = list.length;
      final active = list.where((p) => p.status == 'active').length;
      final completed = list.where((p) => p.status == 'completed').length;
      final pending = list.where((p) => p.status == 'pending').length;
      final budget = list.fold<double>(0, (s, p) => s + p.budget);
      final spent = list.fold<double>(0, (s, p) => s + p.spent);
      final double available = (budget - spent).clamp(0, double.infinity);

      emit(SponsorshipLoaded(
        projects: list,
        totalProjects: total,
        activeCount: active,
        completedCount: completed,
        pendingCount: pending,
        totalBudget: budget,
        totalSpent: spent,
        totalAvailable: available,
      ));
    } catch (e) {
      emit(SponsorshipError('فشل تحميل المشاريع: $e'));
    }
  }

  Future<void> _onCreate(
    CreateSponsorshipProjectEvent event,
    Emitter<SponsorshipState> emit,
  ) async {
    try {
      // أولاً أنشئ المشروع
      await firestore.createSponsorshipProject(event.project);
      
      // ثم أعد تحميل القائمة للحصول على أحدث البيانات
      final list = await firestore.listSponsorshipProjects(
        institutionId: event.project.institutionId,
      );

      // احسب الإحصائيات الجديدة
      final total = list.length;
      final active = list.where((p) => p.status == 'active').length;
      final completed = list.where((p) => p.status == 'completed').length;
      final pending = list.where((p) => p.status == 'pending').length;
      final budget = list.fold<double>(0, (s, p) => s + p.budget);
      final spent = list.fold<double>(0, (s, p) => s + p.spent);
      final double available = (budget - spent).clamp(0, double.infinity);

      // أصدر الحالة المحدثة
      emit(SponsorshipLoaded(
        projects: list,
        totalProjects: total,
        activeCount: active,
        completedCount: completed,
        pendingCount: pending,
        totalBudget: budget,
        totalSpent: spent,
        totalAvailable: available,
      ));
    } catch (e) {
      emit(SponsorshipError('فشل إنشاء المشروع: $e'));
    }
  }

  Future<void> _onUpdate(
    UpdateSponsorshipProjectEvent event,
    Emitter<SponsorshipState> emit,
  ) async {
    try {
      // أولاً حدث المشروع
      await firestore.updateSponsorshipProject(event.project);
      
      // ثم أعد تحميل القائمة
      final list = await firestore.listSponsorshipProjects(
        institutionId: event.project.institutionId,
      );

      // احسب الإحصائيات الجديدة
      final total = list.length;
      final active = list.where((p) => p.status == 'active').length;
      final completed = list.where((p) => p.status == 'completed').length;
      final pending = list.where((p) => p.status == 'pending').length;
      final budget = list.fold<double>(0, (s, p) => s + p.budget);
      final spent = list.fold<double>(0, (s, p) => s + p.spent);
      final double available = (budget - spent).clamp(0, double.infinity);

      // أصدر الحالة المحدثة
      emit(SponsorshipLoaded(
        projects: list,
        totalProjects: total,
        activeCount: active,
        completedCount: completed,
        pendingCount: pending,
        totalBudget: budget,
        totalSpent: spent,
        totalAvailable: available,
      ));
    } catch (e) {
      emit(SponsorshipError('فشل تحديث المشروع: $e'));
    }
  }

  Future<void> _onChangeStatus(
    ChangeProjectStatusEvent event,
    Emitter<SponsorshipState> emit,
  ) async {
    try {
      // أولاً غير الحالة
      await firestore.setSponsorshipProjectStatus(event.projectId, event.status);
      
      // إذا كانت الحالة الحالية تحتوي على بيانات، أعد تحميلها
      if (state is SponsorshipLoaded) {
        final currentState = state as SponsorshipLoaded;
        final institutionId = currentState.projects.isNotEmpty 
            ? currentState.projects.first.institutionId 
            : '';
        
        if (institutionId.isNotEmpty) {
          final list = await firestore.listSponsorshipProjects(
            institutionId: institutionId,
          );

          // احسب الإحصائيات الجديدة
          final total = list.length;
          final active = list.where((p) => p.status == 'active').length;
          final completed = list.where((p) => p.status == 'completed').length;
          final pending = list.where((p) => p.status == 'pending').length;
          final budget = list.fold<double>(0, (s, p) => s + p.budget);
          final spent = list.fold<double>(0, (s, p) => s + p.spent);
          final double available = (budget - spent).clamp(0, double.infinity);

          emit(SponsorshipLoaded(
            projects: list,
            totalProjects: total,
            activeCount: active,
            completedCount: completed,
            pendingCount: pending,
            totalBudget: budget,
            totalSpent: spent,
            totalAvailable: available,
          ));
        }
      }
    } catch (e) {
      emit(SponsorshipError('فشل تغيير حالة المشروع: $e'));
    }
  }

  Future<void> _onAddEvent(
    AddProjectEventItemEvent event,
    Emitter<SponsorshipState> emit,
  ) async {
    try {
      await firestore.addSponsorshipEvent(
        projectId: event.projectId,
        event: event.event,
      );
      
      // إصدار حالة نجاح بدون تغيير البيانات الحالية
      // يمكنك هنا إصدار حالة خاصة أو البقاء في الحالة الحالية
      if (state is SponsorshipLoaded) {
        // ابق في الحالة الحالية مع إمكانية إظهار رسالة نجاح
        // أو أعد تحميل البيانات إذا كانت الأحداث تؤثر على الإحصائيات
      }
    } catch (e) {
      emit(SponsorshipError('فشل إضافة الحدث: $e'));
    }
  }
}