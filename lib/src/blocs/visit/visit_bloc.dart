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
      LoadVisitsByStatus event, Emitter<VisitState> emit) async {
    emit(VisitLoading());
    try {
      final visits = await firestoreService.getVisitsByStatus(
          event.institutionId, event.status);
      emit(VisitLoaded(
          scheduledVisits: event.status == 'مجدولة' ? visits : [],
          completedVisits: event.status == 'مكتملة' ? visits : []));
    } catch (e) {
      emit(VisitError("Failed to load visits by status: $e"));
    }
  }

  Future<void> _onLoadAllVisits(LoadAllVisits event, Emitter<VisitState> emit) async {
    emit(VisitLoading());
    try {
      final scheduled = await firestoreService.getVisitsByStatus(event.institutionId, 'مجدولة');
      final completed = await firestoreService.getVisitsByStatus(event.institutionId, 'مكتملة');
      emit(VisitLoaded(scheduledVisits: scheduled, completedVisits: completed));
    } catch (e) {
      emit(VisitError("Failed to load all visits: $e"));
    }
  }

  Future<void> _onAddVisit(AddVisit event, Emitter<VisitState> emit) async {
    try {
      await firestoreService.addVisit({
        'date': event.date.toIso8601String(),
        'name': event.name,
        'location': event.location,
        'status': 'مجدولة',
        'createdAt': DateTime.now().toIso8601String(),
        'institutionId': event.institutionId,
      });

      await _sendNotificationToAll(
          "تم إضافة زيارة جديدة: ${event.name} في ${event.location}");

      add(LoadAllVisits(institutionId: event.institutionId));
    } catch (e) {
      emit(VisitError("Failed to add visit: $e"));
    }
  }

  Future<void> _onUpdateVisit(
      UpdateVisit event, Emitter<VisitState> emit) async {
    try {
      await firestoreService.updateVisit(event.id, event.updates);

      if (event.updates['status'] == 'مكتملة') {
        await _sendNotificationToAll(
            "تمت زيارة: ${event.updates['name'] ?? ''}");
      } else {
        await _sendNotificationToAll(
            "تم تعديل موعد زيارة: ${event.updates['name'] ?? ''}");
      }

      final institutionId = event.updates['institutionId'];
      if (institutionId != null) {
        add(LoadAllVisits(institutionId: institutionId));
      }
    } catch (e) {
      emit(VisitError("Failed to update visit: $e"));
    }
  }

  Future<void> _onDeleteVisit(
      DeleteVisit event, Emitter<VisitState> emit) async {
    try {
      await firestoreService.deleteVisit(event.id);
      await _sendNotificationToAll("تم حذف زيارة مجدولة.");
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
        body: jsonEncode(
          <String, dynamic>{
            'notification': <String, dynamic>{
              'title': 'إشعار الزيارات',
              'body': message,
            },
            'priority': 'high',
            'to': '/topics/all_users',
          },
        ),
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