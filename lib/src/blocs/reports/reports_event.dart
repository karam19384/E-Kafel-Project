part of 'reports_bloc.dart';

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

class CreateReportEvent extends ReportsEvent {
  final ReportModel report;
  const CreateReportEvent(this.report);
  @override
  List<Object?> get props => [report];
}

class GetReportsEvent extends ReportsEvent {
  final String kafalaHead;
  const GetReportsEvent(this.kafalaHead);
  @override
  List<Object?> get props => [kafalaHead];
}

class FilterDataEvent extends ReportsEvent {
  final ReportFilter filter;
  const FilterDataEvent(this.filter);
  @override
  List<Object?> get props => [filter];
}

class LoadFilterOptionsEvent extends ReportsEvent {}

class DeleteReportEvent extends ReportsEvent {
  final String reportId;
  const DeleteReportEvent(this.reportId);
  @override
  List<Object?> get props => [reportId];
}

/// فلترة التقارير
class FilterReportsEvent extends ReportsEvent {
  final ReportFilter filter;

  const FilterReportsEvent(this.filter);

  @override
  List<Object?> get props => [filter];
}

