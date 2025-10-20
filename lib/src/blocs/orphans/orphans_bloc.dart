// lib/src/blocs/orphans/orphans_bloc.dart
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:e_kafel/src/services/firestore_service.dart';
import '../../models/orphan_model.dart';

part 'orphans_event.dart';
part 'orphans_state.dart';

class OrphansBloc extends Bloc<OrphansEvent, OrphansState> {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final FirestoreService _firestoreService;

  OrphansBloc({
    required this.firestore,
    required this.storage,
    required FirestoreService firestoreService,
  })  : _firestoreService = firestoreService,
        super(OrphansInitial()) {
    // =================== LoadOrphans ===================
    on<LoadOrphans>((event, emit) async {
      emit(OrphansLoading());
      try {
        final String institutionId = event.institutionId;
        if (institutionId.isEmpty) {
          emit(const OrphansError('InstitutionId غير متوفر'));
          return;
        }

        // نبني الاستعلام مع الفلاتر (لو موجودة)
        Query<Map<String, dynamic>> query = firestore
            .collection('orphans')
            .where('institutionId', isEqualTo: institutionId);

        final filters = event.filters ?? {};
        if ((filters['gender'] ?? '').toString().isNotEmpty) {
          query = query.where('gender', isEqualTo: filters['gender']);
        }
        if ((filters['orphanType'] ?? '').toString().isNotEmpty) {
          query = query.where('orphanType', isEqualTo: filters['orphanType']);
        }
        if (filters['isArchived'] != null) {
          query = query.where('isArchived', isEqualTo: filters['isArchived']);
        }

        if (filters['orderBy'] == 'createdAt') {
          query = query.orderBy('createdAt', descending: true);
        } else if (filters['orderBy'] == 'orphanNo') {
          query = query.orderBy('orphanNo', descending: false);
        }

        // من الكاش أولاً لتحسين تجربة المستخدم
        try {
          final cachedSnap =
              await query.get(const GetOptions(source: Source.cache));
          final cached = cachedSnap.docs
              .map((doc) => Orphan.fromMap(doc.data(), id: doc.id))
              .toList();
          if (cached.isNotEmpty) {
            emit(OrphansLoaded(cached, filters: event.filters));
          }
        } catch (_) {}

        // من الخادم
        final serverSnap =
            await query.get(const GetOptions(source: Source.server));
        final serverOrphans = serverSnap.docs
            .map((doc) => Orphan.fromMap(doc.data(), id: doc.id))
            .toList();

        emit(OrphansLoaded(serverOrphans, filters: event.filters));
      } catch (e) {
        try {
          final alt =
              await _firestoreService.getOrphansByInstitution(event.institutionId);
          emit(OrphansLoaded(alt, filters: event.filters));
        } catch (_) {
          emit(OrphansError('Failed to load orphans: $e'));
        }
      }
    });

    // =================== Archived count (fix: use _firestoreService) ===================
    on<LoadArchivedOrphansCount>((event, emit) async {
      emit(OrphansLoading());
      try {
        final count =
            await _firestoreService.getArchivedOrphansCount(event.institutionId);
        emit(ArchivedOrphansCountLoaded(count: count));
      } catch (e) {
        emit(OrphansError('Failed to load archived count: $e'));
      }
    });

    // =================== SearchOrphans ===================
    on<SearchOrphans>((event, emit) async {
      emit(OrphansLoading());
      try {
        final orphans = await _firestoreService.searchOrphans(
          institutionId: event.institutionId,
          searchTerm: event.searchTerm,
          filters: event.filters,
        );
        emit(OrphansLoaded(orphans, filters: event.filters));
      } catch (e) {
        try {
          final query = firestore
              .collection('orphans')
              .where('institutionId', isEqualTo: event.institutionId);
          final serverSnap =
              await query.get(const GetOptions(source: Source.server));
          final all = serverSnap.docs
              .map((d) => Orphan.fromMap(d.data(), id: d.id))
              .toList();

          final term = event.searchTerm.trim();
          final filtered = all.where((o) {
            final fullName = [
              o.orphanName,
              o.fatherName,
              o.grandfatherName,
              o.greatGrandfatherName,
              o.familyName
            ].where((e) => (e).isNotEmpty).join(' ');
            return fullName.contains(term) ||
                (o.orphanIdNumber.toString().contains(term)) ||
                (o.mobileNumber?.toString().contains(term) ?? false);
          }).toList();

          emit(OrphansLoaded(filtered, filters: event.filters));
        } catch (e2) {
          emit(OrphansError('Failed to search orphans: $e'));
        }
      }
    });

    // =================== AddOrphan (send notification) ===================
    on<AddOrphan>((event, emit) async {
      try {
        emit(OrphansLoading());

        final orphanId = await _firestoreService.createOrphan(event.orphan);
        if (orphanId == null) {
          emit(const OrphansError('فشل في إضافة اليتيم'));
          return;
        }

        // رفع الملفات (لو موجودة)
        final orphanPhotoUrl = await _uploadFile(
          event.orphanPhotoFile,
          'orphans/photos/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        final fatherIdPhotoUrl = await _uploadFile(
          event.fatherIdPhotoFile,
          'orphans/father_id/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        final motherIdPhotoUrl = await _uploadFile(
          event.motherIdPhotoFile,
          'orphans/mother_id/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        final deceasedPhotoUrl = await _uploadFile(
          event.deceasedPhotoFile,
          'orphans/deceased/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        final deathCertificateUrl = await _uploadFile(
          event.deathCertificateFile,
          'orphans/death_certificates/${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
        final birthCertificateUrl = await _uploadFile(
          event.birthCertificateFile,
          'orphans/birth_certificates/${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
        final breadwinnerIdPhotoUrl = await _uploadFile(
          event.breadwinnerIdPhotoFile,
          'orphans/breadwinner_id/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        // تحديث روابط الملفات
        final updatedOrphan = event.orphan.copyWith(
          id: orphanId,
          orphanPhotoUrl: orphanPhotoUrl,
          fatherIdPhotoUrl: fatherIdPhotoUrl,
          motherIdPhotoUrl: motherIdPhotoUrl,
          deceasedPhotoUrl: deceasedPhotoUrl,
          deathCertificateUrl: deathCertificateUrl,
          birthCertificateUrl: birthCertificateUrl,
          breadwinnerIdPhotoUrl: breadwinnerIdPhotoUrl,
        );

        await _firestoreService.updateOrphanData(orphanId, updatedOrphan.toMap());

        // إشعار (إضافة)
        add(
          SendOrphanNotification(
            institutionId: event.orphan.institutionId,
            title: 'تم إضافة يتيم جديد',
            message:
                'تم إضافة اليتيم ${_composeFullName(updatedOrphan)} إلى النظام',
            type: 'new_orphan',
            orphanId: orphanId,
          ),
        );

        emit(OrphanAdded(updatedOrphan));
        add(LoadOrphans(institutionId: event.orphan.institutionId));
      } catch (e) {
        emit(OrphansError('فشل في إضافة اليتيم: $e'));
      }
    });

    // =================== UpdateOrphan (send notification) ===================
    on<UpdateOrphan>((event, emit) async {
      try {
        emit(OrphansLoading());

        final success = await _firestoreService.updateOrphanData(
          event.orphanId,
          event.updatedData,
        );

        if (!success) {
          emit(const OrphansError('فشل في تحديث البيانات'));
          return;
        }

        final updated = await _firestoreService.getOrphanById(event.orphanId);
        if (updated != null) {
          // إشعار (تحديث)
          add(
            SendOrphanNotification(
              institutionId: event.institutionId,
              title: 'تحديث بيانات يتيم',
              message:
                  'تم تحديث بيانات اليتيم ${_composeFullName(updated)} بنجاح',
              type: 'orphan_updated',
              orphanId: event.orphanId,
            ),
          );

          emit(OrphanUpdated(updated));
          add(LoadOrphans(institutionId: event.institutionId));
        } else {
          emit(const OrphansError('فشل في جلب البيانات المحدثة'));
        }
      } catch (e) {
        emit(OrphansError('فشل في تحديث البيانات: $e'));
      }
    });

    // =================== ArchiveOrphan (send notification) ===================
    on<ArchiveOrphan>((event, emit) async {
      try {
        // جلب الاسم قبل الأرشفة لرسالة أوضح
        final before = await _firestoreService.getOrphanById(event.orphanId);

        final success = await _firestoreService.archiveOrphanData(
          event.orphanId,
        );
        if (!success) {
          emit(const OrphansError("فشل في أرشفة اليتيم"));
          return;
        }

        add(
          SendOrphanNotification(
            institutionId: event.institutionId,
            title: 'تم أرشفة يتيم',
            message: before == null
                ? 'تم أرشفة أحد الأيتام من النظام'
                : 'تم أرشفة اليتيم ${_composeFullName(before)} من النظام',
            type: 'orphan_archived',
            orphanId: event.orphanId,
          ),
        );

        emit(OrphanArchived(event.orphanId));
        add(LoadOrphans(institutionId: event.institutionId));
      } catch (e) {
        emit(OrphansError("فشل في أرشفة اليتيم: $e"));
      }
    });

    // =================== SendOrphanNotification ===================
    on<SendOrphanNotification>((event, emit) async {
      try {
        await _sendNotificationToInstitution(
          institutionId: event.institutionId,
          title: event.title,
          message: event.message,
          type: event.type,
          orphanId: event.orphanId,
        );
      } catch (e) {
        // لا نوقف البلوك إن فشل الإرسال
        // ignore: avoid_print
        print('Error sending notification: $e');
      }
    });
  }

  // =================== Helpers ===================
  String _composeFullName(Orphan o) {
    final parts = [
      o.orphanName,
      o.fatherName,
      o.grandfatherName,
      o.greatGrandfatherName,
      o.familyName
    ].where((e) => (e).trim().isNotEmpty).map((e) => e.trim()).toList();
    return parts.isEmpty ? (o.orphanName) : parts.join(' ');
  }

  Future<String?> _uploadFile(File? file, String path) async {
    if (file == null) return null;
    try {
      final ref = storage.ref().child(path);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      // ignore: avoid_print
      print('Error uploading file: $e');
      return null;
    }
  }

  /// يرسل إشعارات Firestore + (اختياري) FCM عبر Cloud Function sendToToken
  Future<void> _sendNotificationToInstitution({
    required String institutionId,
    required String title,
    required String message,
    required String type,
    String? orphanId,
  }) async {
    try {
      final usersSnapshot = await firestore
          .collection('users')
          .where('institutionId', isEqualTo: institutionId)
          .where('isActive', isEqualTo: true)
          .get();

      // نستخدم Cloud Function إن وُجدت (تخطي الويب إن رغبت)
      final HttpsCallable? sendToToken =
          kIsWeb ? null : FirebaseFunctions.instance.httpsCallable('sendToToken');

      // 1) أنشئ وثيقة إشعار لكل مستخدم بطريقة موحّدة عبر FirestoreService
      for (final userDoc in usersSnapshot.docs) {
        final uid = userDoc.id;
        final userData = userDoc.data();
        final String? userFcmToken = (userData['fcmToken'] as String?)?.trim();

        await _firestoreService.createNotification({
          'userId': uid,
          'title': title,
          'message': message,
          'type': type,
          'institutionId': institutionId,
          'orphanId': orphanId,
          'isRead': false,
        });

        // 2) أرسل Push Notification عبر FCM (إن توافر توكن)
        if (sendToToken != null && userFcmToken != null && userFcmToken.isNotEmpty) {
          try {
            await sendToToken.call(<String, dynamic>{
              'token': userFcmToken,
              'notification': {
                'title': title,
                'body': message,
              },
              'data': {
                'type': type,
                'institutionId': institutionId,
                if (orphanId != null) 'orphanId': orphanId,
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              },
            });
          } catch (e) {
            // ignore: avoid_print
            print('Error calling sendToToken for $uid: $e');
          }
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error in _sendNotificationToInstitution: $e');
    }
  }
}
