// lib/src/blocs/tasks/tasks_event.dart

part of 'tasks_bloc.dart';

abstract class TasksEvent extends Equatable {
  
}

// tasks_event.dart
class LoadTasksEvent extends TasksEvent {
  final String institutionId;
  LoadTasksEvent(this.institutionId);
  
  @override
  List<Object?> get props => [];
}


class AddTaskEvent extends TasksEvent {
  final TaskModel task;
    final String institutionId;

  AddTaskEvent(this.task, this.institutionId);
  
  @override
  List<Object?> get props => [];
}

class UpdateTaskEvent extends TasksEvent {
  final TaskModel task;
    final String institutionId;

  UpdateTaskEvent(this.task, this.institutionId);
  
  @override
  List<Object?> get props => [];
}

class DeleteTaskEvent extends TasksEvent {
  final String taskId;
    final String institutionId;

  DeleteTaskEvent(this.taskId,this.institutionId);
  
  @override
  List<Object?> get props => [];
}
