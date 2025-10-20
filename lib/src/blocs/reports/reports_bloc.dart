import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/reports_model.dart';
import '../../models/filter_model.dart';
import '../../services/reports_service.dart';

part 'reports_event.dart';
part 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final ReportsService reportsService;

  ReportsBloc(this.reportsService) : super(ReportsInitial()) {
    on<CreateReportEvent>((event, emit) async {
      emit(ReportsLoading());
      try {
        final reportId = await reportsService.createReport(event.report);
        final newReport = event.report.copyWith(reportId: reportId);
        emit(ReportCreated(newReport));
        add(GetReportsEvent(event.report.kafalaHeadId));
      } catch (e) {
        emit(ReportsError('فشل إنشاء التقرير: $e'));
      }
    });

    on<GetReportsEvent>((event, emit) async {
      emit(ReportsLoading());
      try {
        final reports = await reportsService.getReportsByKafalaHead(event.kafalaHead);
        emit(ReportsLoaded(reports));
      } catch (e) {
        emit(ReportsError('فشل جلب التقارير: $e'));
      }
    });

    on<FilterDataEvent>((event, emit) async {
      emit(ReportsLoading());
      try {
        final data = await reportsService.getFilteredData(event.filter);
        emit(ReportsDataLoaded(data, event.filter));
      } catch (e) {
        emit(ReportsError('فشل في تصفية البيانات: $e'));
      }
    });

    on<LoadFilterOptionsEvent>((event, emit) async {
      try {
        final options = await reportsService.getFilterOptions();
        emit(FilterOptionsLoaded(options));
      } catch (e) {
        emit(ReportsError('فشل في تحميل خيارات الفلاتر: $e'));
      }
    });

    on<DeleteReportEvent>((event, emit) async {
      emit(ReportsLoading());
      try {
        await reportsService.deleteReport(event.reportId);
        emit(ReportDeleted(event.reportId));
        final state = this.state;
        if (state is ReportsLoaded) {
          final updatedReports = state.reports.where((r) => r.reportId != event.reportId).toList();
          emit(ReportsLoaded(updatedReports));
        }
      } catch (e) {
        emit(ReportsError('فشل حذف التقرير: $e'));
      }
    });
  }
}