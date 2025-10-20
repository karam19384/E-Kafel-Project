part of 'supervisors_bloc.dart';


abstract class SupervisorsState extends Equatable {
  const SupervisorsState();
  @override
  List<Object?> get props => [];
}

class SupervisorsInitial extends SupervisorsState {}

class SupervisorsLoading extends SupervisorsState {}

class SupervisorsLoaded extends SupervisorsState {
  final List<UserModel> supervisors;
  const SupervisorsLoaded(this.supervisors);

  @override
  List<Object?> get props => [supervisors];
}

class SupervisorsError extends SupervisorsState {
  final String message;
  const SupervisorsError(this.message);

  @override
  List<Object?> get props => [message];
}
