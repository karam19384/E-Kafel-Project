part of 'reports_bloc.dart';

abstract class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

class ReportsLoaded extends ReportsState {
  final List<ReportModel> reports;

  const ReportsLoaded(this.reports);

  @override
  List<Object?> get props => [reports];
}

class ReportsDataLoaded extends ReportsState {
  final List<Map<String, dynamic>> data;
  final ReportFilter filter;

  const ReportsDataLoaded(this.data, this.filter);

  @override
  List<Object?> get props => [data, filter];
}

class FilterOptionsLoaded extends ReportsState {
  final Map<String, List<String>> filterOptions;

  const FilterOptionsLoaded(this.filterOptions);

  @override
  List<Object?> get props => [filterOptions];
}

class ReportsError extends ReportsState {
  final String message;

  const ReportsError(this.message);

  @override
  List<Object?> get props => [message];
}

class ReportCreated extends ReportsState {
  final ReportModel report;

  const ReportCreated(this.report);

  @override
  List<Object?> get props => [report];
}

class ReportDeleted extends ReportsState {
  final String reportId;

  const ReportDeleted(this.reportId);

  @override
  List<Object?> get props => [reportId];
}

