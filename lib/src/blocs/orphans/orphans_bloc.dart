// ignore_for_file: unused_local_variable

import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../models/orphan_model.dart';
part 'orphans_event.dart';
part 'orphans_state.dart';

class OrphansBloc extends Bloc<OrphansEvent, OrphansState> {
  final FirebaseFirestore firestore;

  OrphansBloc({required this.firestore}) : super(OrphansInitial()) {
    // جلب الأيتام
    on<LoadOrphans>((event, emit) async {
      emit(OrphansLoading());
      try {
        final snapshot = await firestore
            .collection('orphans')
            .where('isArchived', isEqualTo: false) // نعرض فقط غير المؤرشفين
            .get();

        final orphans = snapshot.docs
            .map((doc) => {"id": doc.id, ...doc.data()})
            .toList();

        emit(OrphansLoaded(orphans));
      } catch (e) {
        emit(OrphansError(e.toString()));
      }
    });
    // إضافة يتيم جديد
    on<AddOrphan>((event, emit) async {
      try {
        final storage = FirebaseStorage.instance;
        final firestore = FirebaseFirestore.instance;

        String? idCardUrl;
        String? deathCertificateUrl;
        String? orphanPhotoUrl;
        String? institutionId;

        // رفع بطاقة الهوية
        if (kIsWeb) {
          if (event.idCardBytes != null) {
            final ref = storage.ref().child(
              'orphans/id_cards/${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
            await ref.putData(event.idCardBytes!);
            idCardUrl = await ref.getDownloadURL();
          }
        } else {
          if (event.idCardFile != null) {
            final ref = storage.ref().child(
              'orphans/id_cards/${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
            await ref.putFile(event.idCardFile!);
            idCardUrl = await ref.getDownloadURL();
          }
        }

        // رفع شهادة الوفاة
        if (kIsWeb) {
          if (event.deathCertificateBytes != null) {
            final ref = storage.ref().child(
              'orphans/death_certificates/${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
            await ref.putData(event.deathCertificateBytes!);
            deathCertificateUrl = await ref.getDownloadURL();
          }
        } else {
          if (event.deathCertificateFile != null) {
            final ref = storage.ref().child(
              'orphans/death_certificates/${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
            await ref.putFile(event.deathCertificateFile!);
            deathCertificateUrl = await ref.getDownloadURL();
          }
        }

        // رفع صورة اليتيم
        if (kIsWeb) {
          if (event.orphanPhotoBytes != null) {
            final ref = storage.ref().child(
              'orphans/photos/${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
            await ref.putData(event.orphanPhotoBytes!);
            orphanPhotoUrl = await ref.getDownloadURL();
          }
        } else {
          if (event.orphanPhotoFile != null) {
            final ref = storage.ref().child(
              'orphans/photos/${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
            await ref.putFile(event.orphanPhotoFile!);
            orphanPhotoUrl = await ref.getDownloadURL();
          }
        }
        //  توليد رقم يتيم فريد تلقائياً
        final orphanNo = firestore.collection('orphans').doc().id;

        // تجهيز بيانات اليتيم كـ Map باستخدام وظيفة toMap()
        final orphanData = event.orphan
            .copyWith(
              institutionId: institutionId,
              idCardUrl: idCardUrl,
              deathCertificateUrl: deathCertificateUrl,
              orphanPhotoUrl: orphanPhotoUrl,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              orphanNo: orphanNo,
            )
            .toMap();

        // حفظ البيانات في Firestore
        await firestore.collection('orphans').add(orphanData);

        emit(OrphanAdded());
        add(LoadOrphans());
      } catch (e) {
        if (kDebugMode) {
          print('Failed to add orphan: $e');
        }
        emit(OrphansError(e.toString()));
      }
    });
    // تحديث بيانات يتيم
    on<UpdateOrphan>((event, emit) async {
      try {
        await firestore
            .collection('orphans')
            .doc(event.orphanId)
            .update(event.updatedData);
        add(LoadOrphans());
      } catch (e) {
        emit(OrphansError(e.toString()));
      }
    });
    // أرشفة يتيم
    on<ArchiveOrphan>((event, emit) async {
      try {
        await firestore.collection('orphans').doc(event.orphanId).update({
          "isArchived": true,
          "archivedAt": FieldValue.serverTimestamp(),
        });
        add(LoadOrphans()); // إعادة تحميل الأيتام بعد الأرشفة
      } catch (e) {
        emit(OrphansError("Failed to archive orphan: $e"));
      }
    });
  }
}
