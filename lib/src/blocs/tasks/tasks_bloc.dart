// lib/src/blocs/tasks/tasks_bloc.dart

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/tasks_model.dart';
import '../../services/firestore_service.dart';

part 'tasks_event.dart';
part 'tasks_state.dart';

class TasksBloc extends Bloc<TasksEvent, TasksState> {
  final FirestoreService firestoreService;

  TasksBloc(this.firestoreService) : super(TasksLoading()) {
   on<LoadTasksEvent>((event, emit) async {
  emit(TasksLoading());
  try {
    final tasks = await firestoreService.fetchTasks(event.institutionId);
    emit(TasksLoaded(tasks));
  } catch (e) {
    emit(TasksError('حدث خطأ أثناء جلب المهام'));
  }
});

    on<AddTaskEvent>((event, emit) async {
      try {
        await firestoreService.addTasks(event.task.toMap());
        add(LoadTasksEvent(event.institutionId)); // إعادة تحميل المهام بعد الإضافة
      } catch (e) {
        emit(TasksError("فشل إضافة المهمة: $e"));
      }
    });

   on<UpdateTaskEvent>((event, emit) async {
  try {
    await firestoreService.updateTask(event.task); // 🔹 تحديث كامل وليس status فقط
    add(LoadTasksEvent(event.institutionId));
  } catch (e) {
    emit(TasksError("فشل تحديث المهمة: $e"));
  }
});

    on<DeleteTaskEvent>((event, emit) async {
      try {
        await firestoreService.deleteTask(event.taskId);
        add(LoadTasksEvent(event.institutionId));
      } catch (e) {
        emit(TasksError("فشل حذف المهمة: $e"));
      }
    });
  }
}


