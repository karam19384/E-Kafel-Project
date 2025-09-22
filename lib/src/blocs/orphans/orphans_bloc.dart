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
   
        // 📌 Add Orphan
    on<AddOrphan>((event, emit) async {
      try {
        final storage = FirebaseStorage.instance;

        String? idCardUrl;
        String? deathCertificateUrl;
        String? orphanPhotoUrl;

        Future<String?> uploadFile({File? file, Uint8List? bytes, required String path}) async {
          if (kIsWeb && bytes != null) {
            final ref = storage.ref().child(path);
            await ref.putData(bytes);
            return await ref.getDownloadURL();
          } else if (!kIsWeb && file != null) {
            final ref = storage.ref().child(path);
            await ref.putFile(file);
            return await ref.getDownloadURL();
          }
          return null;
        }

        idCardUrl = await uploadFile(
          file: event.idCardFile,
          bytes: event.idCardBytes,
          path: 'orphans/id_cards/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        deathCertificateUrl = await uploadFile(
          file: event.deathCertificateFile,
          bytes: event.deathCertificateBytes,
          path: 'orphans/death_certificates/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        orphanPhotoUrl = await uploadFile(
          file: event.orphanPhotoFile,
          bytes: event.orphanPhotoBytes,
          path: 'orphans/photos/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        // 📌 Get new orphanNo from counter
        final counterRef = firestore.collection('counters').doc('orphanCounter');
        final counterSnap = await counterRef.get();

        int newOrphanNo;
        if (counterSnap.exists) {
          int lastOrphanNo = counterSnap['lastOrphanNo'] as int;
          newOrphanNo = lastOrphanNo + 1;
          await counterRef.update({'lastOrphanNo': newOrphanNo});
        } else {
          newOrphanNo = 10000;
          await counterRef.set({'lastOrphanNo': newOrphanNo});
        }

        // 📌 Prepare Orphan data
        final orphanData = event.orphan.copyWith(
          idCardUrl: idCardUrl,
          deathCertificateUrl: deathCertificateUrl,
          orphanPhotoUrl: orphanPhotoUrl,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          orphanNo: newOrphanNo,
        );

        await firestore.collection('orphans').add(orphanData.toMap());

        emit(OrphanAdded());
        add(LoadOrphans(institutionId: event.orphan.institutionId));
      } catch (e) {
        if (kDebugMode) print('Failed to add orphan: $e');
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
        add(LoadOrphans(institutionId: event.institutionId)); // إعادة تحميل الأيتام بعد التحديث
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
        add(LoadOrphans(institutionId: event.institutionId)); // إعادة تحميل الأيتام بعد الأرشفة
      } catch (e) {
        emit(OrphansError("Failed to archive orphan: $e"));
      }
    });
  }
}
 /*
    await firestore.updateInstitutionOrphansCount(event.institutionId);
     await _sendNotificationToAll(
        "تم أرشفة يتيم بنجاح.", event.institutionId); 
    add(LoadOrphans(institutionId: event.institutionId)); 


    */