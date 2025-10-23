part of 'supervisors_bloc.dart';

abstract class SupervisorsEvent extends Equatable {
  const SupervisorsEvent();
  @override
  List<Object?> get props => [];
}

class LoadSupervisors extends SupervisorsEvent {
  final String institutionId;
  const LoadSupervisors(this.institutionId);

  @override
  List<Object?> get props => [institutionId];
}
// في supervisors_event.dart
class CreateSupervisorWithAuth extends SupervisorsEvent {
  final Map<String, dynamic> data;
  final String password;
  const CreateSupervisorWithAuth({
    required this.data,
    required this.password,
  });

  @override
  List<Object?> get props => [data, password];
}


class UpdateSupervisor extends SupervisorsEvent {
  final String uid;
  final Map<String, dynamic> data;
  const UpdateSupervisor({required this.uid, required this.data});

  @override
  List<Object?> get props => [uid, data];
}

class DeleteSupervisor extends SupervisorsEvent {
  final String uid;
  const DeleteSupervisor(this.uid);

  @override
  List<Object?> get props => [uid];
}

class SearchSupervisors extends SupervisorsEvent {
  final String institutionId;
  final String? search;
  final String? userRole;
  final String? areaResponsibleFor;
  final bool? isActive;

  const SearchSupervisors({
    required this.institutionId,
    this.search,
    this.userRole,
    this.areaResponsibleFor,
    this.isActive,
  });

  @override
  List<Object?> get props => [
    institutionId,
    search,
    userRole,
    areaResponsibleFor,
    isActive,
  ];
}

class ToggleSupervisorActive extends SupervisorsEvent {
  final String uid;
  final bool isActive;
  const ToggleSupervisorActive({required this.uid, required this.isActive});
}

class LoadSupervisorsByHead extends SupervisorsEvent {
  final String institutionId;
  final String kafalaHeadId; // رئيس القسم الحالي
  final bool isActive;
  const LoadSupervisorsByHead({required this.institutionId, required this.kafalaHeadId, required this.isActive});
}