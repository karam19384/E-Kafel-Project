// lib/src/blocs/visit/visit_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:e_kafel/src/services/firestore_service.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

part 'visit_event.dart';
part 'visit_state.dart';

class VisitBloc extends Bloc<VisitEvent, VisitState> {
  final FirestoreService firestoreService;

  VisitBloc(this.firestoreService) : super(VisitInitial()) {
    on<LoadVisitsByStatus>(_onLoadVisitsByStatus);
    on<AddVisit>(_onAddVisit);
    on<UpdateVisit>(_onUpdateVisit);
    on<DeleteVisit>(_onDeleteVisit);
    on<LoadAllVisits>(_onLoadAllVisits);
  }
  Future<void> _onLoadVisitsByStatus(
    LoadVisitsByStatus event,
    Emitter<VisitState> emit,
  ) async {
    try {
      final visits = await firestoreService.getAllVisits(
        event.institutionId,
        event.status,
      );

      List<Map<String, dynamic>> scheduled = [];
      List<Map<String, dynamic>> completed = [];

      if (state is VisitLoaded) {
        scheduled = List.from((state as VisitLoaded).scheduledVisits);
        completed = List.from((state as VisitLoaded).completedVisits);
      }

      if (event.status == 'scheduled') {
        scheduled = visits;
      } else if (event.status == 'completed') {
        completed = visits;
      }

      emit(VisitLoaded(scheduledVisits: scheduled, completedVisits: completed));
    } catch (e) {
      emit(VisitError("Failed to load visits by status: $e"));
    }
  }

  Future<void> _onLoadAllVisits(
    LoadAllVisits event,
    Emitter<VisitState> emit,
  ) async {
    emit(VisitLoading());
    try {
      final scheduled = await firestoreService.getAllVisits(
        event.institutionId,
        'scheduled',
      );
      final completed = await firestoreService.getAllVisits(
        event.institutionId,
        'completed',
      );
      emit(VisitLoaded(scheduledVisits: scheduled, completedVisits: completed));
    } catch (e) {
      emit(VisitError("Failed to load all visits: $e"));
    }
  }

  Future<void> _onAddVisit(AddVisit event, Emitter<VisitState> emit) async {
    try {
      await firestoreService.addVisit({
        'date': event.date.toIso8601String(),
        'fullName': event.name,
        'location': event.location,
        'status': 'scheduled',
        'createdAt': DateTime.now().toIso8601String(),
        'institutionId': event.institutionId,
      });

      await _sendNotificationToAll(
        "تم إضافة زيارة جديدة: ${event.name} في ${event.location}",
      );

      add(LoadAllVisits(institutionId: event.institutionId));
    } catch (e) {
      emit(VisitError("Failed to add visit: $e"));
    }
  }

  Future<void> _onUpdateVisit(
    UpdateVisit event,
    Emitter<VisitState> emit,
  ) async {
    try {
      await firestoreService.updateVisit(event.id, event.updates);

      // إرسال إشعار حسب الحالة
      final newStatus = event.updates['status'];
      final visitName = event.updates['name'] ?? '';
      if (newStatus == 'completed') {
        await _sendNotificationToAll("تمت زيارة: $visitName");
      } else if (newStatus == 'scheduled') {
        await _sendNotificationToAll(
          "تم إعادة الزيارة $visitName إلى المجدولة",
        );
      } else {
        await _sendNotificationToAll("تم تعديل موعد زيارة: $visitName");
      }

      // إعادة تحميل جميع الزيارات
      final institutionId =
          event.updates['institutionId'] ?? event.institutionId;
      if (institutionId != null) {
        add(LoadAllVisits(institutionId: institutionId));
      }
    } catch (e) {
      emit(VisitError("Failed to update visit: $e"));
    }
  }

  Future<void> _onDeleteVisit(
    DeleteVisit event,
    Emitter<VisitState> emit,
  ) async {
    try {
      await firestoreService.deleteVisit(event.id);
      await _sendNotificationToAll("تم حذف زيارة scheduled.");
      add(LoadAllVisits(institutionId: event.institutionId));
    } catch (e) {
      emit(VisitError("Failed to delete visit: $e"));
    }
  }

  Future<void> _sendNotificationToAll(String message) async {
    const serverKey = "YOUR_FCM_SERVER_KEY";
    const url = "https://fcm.googleapis.com/fcm/send";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(<String, dynamic>{
          'notification': <String, dynamic>{
            'title': 'إشعار الزيارات',
            'body': message,
          },
          'priority': 'high',
          'to': '/topics/all_users',
        }),
      );
      if (response.statusCode == 200) {
        print("Notification sent successfully!");
      } else {
        print("Failed to send notification: ${response.body}");
      }
    } catch (e) {
      print("Error sending notification: $e");
    }
  }
}
