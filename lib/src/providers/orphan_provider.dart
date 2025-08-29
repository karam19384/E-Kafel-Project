import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:e_kafel/src/models/orphan.dart';
/*
class OrphanProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<Orphan> _orphans = [];
  bool _isLoading = false;

  List<Orphan> get orphans => _orphans;
  bool get isLoading => _isLoading;

  // دالة لإضافة يتيم جديد مع رفع الملفات
  Future<void> addOrphan(Orphan newOrphan, File? idCardFile, File? deathCertificateFile) async {
    _setLoading(true);
    
    try {
      // رفع الملفات إذا كانت موجودة والحصول على روابطها
      String? idCardUrl;
      String? deathCertificateUrl;
      
      if (idCardFile != null) {
        idCardUrl = await _uploadFile(idCardFile, 'id_cards');
      }
      
      if (deathCertificateFile != null) {
        deathCertificateUrl = await _uploadFile(deathCertificateFile, 'death_certificates');
      }
      
      // تحديث بيانات اليتيم بروابط الملفات
      final orphanWithFiles = newOrphan.copyWith(
        idCardUrl: idCardUrl,
        deathCertificateUrl: deathCertificateUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // إضافة اليتيم إلى Firestore
      final docRef = await _firestore.collection('orphans').add(orphanWithFiles.toMap());
      
      // تحديث الـ ID المحلي للكائن
      final orphanWithId = orphanWithFiles.copyWith(id: docRef.id);
      
      // إضافة اليتيم إلى القائمة المحلية
      _orphans.add(orphanWithId);
      notifyListeners();
      
    } catch (error) {
      print('Error adding orphan: $error');
      throw 'فشل في إضافة اليتيم: $error';
    } finally {
      _setLoading(false);
    }
  }
  // دالة لجلب جميع الأيتام
  Future<void> fetchOrphans() async {
    _setLoading(true);
    
    try {
      final querySnapshot = await _firestore
          .collection('orphans')
          .orderBy('createdAt', descending: true)
          .get();
      
      _orphans = querySnapshot.docs
          .map((doc) => Orphan.fromMap(doc.data(), doc.id))
          .toList();
      
      notifyListeners();
    } catch (error) {
      print('Error fetching orphans: $error');
      throw 'فشل في جلب بيانات الأيتام: $error';
    } finally {
      _setLoading(false);
    }
  }
  // دالة للاشتراك في التحديثات الفورية
  Stream<List<Orphan>> getOrphansStream() {
    return _firestore
        .collection('orphans')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Orphan.fromMap(doc.data(), doc.id))
            .toList());
  }
  // دالة لتحديث بيانات يتيم
  Future<void> updateOrphan(String orphanId, Orphan updatedOrphan) async {
    _setLoading(true);
    
    try {
      await _firestore
          .collection('orphans')
          .doc(orphanId)
          .update(updatedOrphan.copyWith(updatedAt: DateTime.now()).toMap());
      
      // تحديث القائمة المحلية
      final index = _orphans.indexWhere((orphan) => orphan.id == orphanId);
      if (index != -1) {
        _orphans[index] = updatedOrphan.copyWith(updatedAt: DateTime.now());
        notifyListeners();
      }
    } catch (error) {
      print('Error updating orphan: $error');
      throw 'فشل في تحديث بيانات اليتيم: $error';
    } finally {
      _setLoading(false);
    }
  }
  // دالة لحذف يتيم
  Future<void> deleteOrphan(String orphanId) async {
    _setLoading(true);
    
    try {
      await _firestore.collection('orphans').doc(orphanId).delete();
      
      // إزالة اليتيم من القائمة المحلية
      _orphans.removeWhere((orphan) => orphan.id == orphanId);
      notifyListeners();
    } catch (error) {
      print('Error deleting orphan: $error');
      throw 'فشل في حذف اليتيم: $error';
    } finally {
      _setLoading(false);
    }
  }
  // دالة للبحث عن أيتام
  Future<List<Orphan>> searchOrphans(String query) async {
    try {
      final nameQuery = await _firestore
          .collection('orphans')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .get();
      
      final orphanNoQuery = await _firestore
          .collection('orphans')
          .where('orphanNo', isEqualTo: query)
          .get();
      
      final allResults = [...nameQuery.docs, ...orphanNoQuery.docs];
      
      return allResults
          .map((doc) => Orphan.fromMap(doc.data(), doc.id))
          .toList();
    } catch (error) {
      print('Error searching orphans: $error');
      throw 'فشل في البحث: $error';
    }
  }
  // دالة مساعدة لرفع الملفات إلى Firebase Storage
  Future<String> _uploadFile(File file, String folderName) async {
    try {
      // إنشاء اسم فريد للملف
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      
      // رفع الملف
      final Reference storageRef = _storage.ref().child('$folderName/$fileName');
      final UploadTask uploadTask = storageRef.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      
      // الحصول على رابط التحميل
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (error) {
      print('Error uploading file: $error');
      throw 'فشل في رفع الملف: $error';
    }
  }
  // دالة مساعدة لتحديث حالة التحميل
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  // دالة للحصول على يتيم بواسطة ID
  Orphan? getOrphanById(String id) {
    try {
      return _orphans.firstWhere((orphan) => orphan.id == id);
    } catch (e) {
      return null;
    }
  }
}
*/

class OrphanProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<Orphan> _orphans = [];
  bool _isLoading = false;

  List<Orphan> get orphans => _orphans;
  bool get isLoading => _isLoading;

  // دالة لإضافة يتيم جديد مع رفع الملفات
  Future<void> addOrphan(
    Orphan newOrphan,
    File? idCardFile,
    File? deathCertificateFile,
    File? orphanPhotoFile,
  ) async {
    _setLoading(true);

    try {
      // رفع الملفات إذا كانت موجودة والحصول على روابطها
      String? idCardUrl;
      String? deathCertificateUrl;
      String? orphanPhotoUrl;

      if (idCardFile != null) {
        idCardUrl = await _uploadFile(idCardFile, 'id_cards');
      }
      if (deathCertificateFile != null) {
        deathCertificateUrl = await _uploadFile(
          deathCertificateFile,
          'death_certificates',
        );
      }
      // رفع صورة اليتيم إذا كانت موجودة
      if (orphanPhotoFile != null) {
        orphanPhotoUrl = await _uploadFile(orphanPhotoFile, 'orphan_photos');
      }
      // تحديث بيانات اليتيم بروابط الملفات
      final orphanWithFiles = newOrphan.copyWith(
        idCardUrl: idCardUrl,
        deathCertificateUrl: deathCertificateUrl,
        orphanPhotoUrl: orphanPhotoUrl, // إضافة رابط صورة اليتيم
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      // إضافة اليتيم إلى Firestore
      final docRef = await _firestore
          .collection('orphans')
          .add(orphanWithFiles.toMap());
      // تحديث الـ ID المحلي للكائن
      final orphanWithId = orphanWithFiles.copyWith(id: docRef.id);

      // إضافة اليتيم إلى القائمة المحلية
      _orphans.add(orphanWithId);
      notifyListeners();
    } catch (error) {
      print('Error adding orphan: $error');
      throw 'فشل في إضافة اليتيم: $error';
    } finally {
      _setLoading(false);
    }
  }

  Future<String> _uploadFile(File file, String folderName) async {
    try {
      // إنشاء اسم فريد للملف
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';

      // رفع الملف
      final Reference storageRef = _storage.ref().child(
        '$folderName/$fileName',
      );
      final UploadTask uploadTask = storageRef.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;

      // الحصول على رابط التحميل
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (error) {
      print('Error uploading file: $error');
      throw 'فشل في رفع الملف: $error';
    }
  }

  // دالة لجلب جميع الأيتام
  Future<void> fetchOrphans() async {
    _setLoading(true);

    try {
      final querySnapshot = await _firestore
          .collection('orphans')
          .orderBy('createdAt', descending: true)
          .get();

      _orphans = querySnapshot.docs
          .map((doc) => Orphan.fromMap(doc.data(), doc.id))
          .toList();

      notifyListeners();
    } catch (error) {
      print('Error fetching orphans: $error');
      throw 'فشل في جلب بيانات الأيتام: $error';
    } finally {
      _setLoading(false);
    }
  }

  // دالة للاشتراك في التحديثات الفورية
  Stream<List<Orphan>> getOrphansStream() {
    return _firestore
        .collection('orphans')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Orphan.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // دالة لتحديث بيانات يتيم
  Future<void> updateOrphan(String orphanId, Orphan updatedOrphan) async {
    _setLoading(true);

    try {
      await _firestore
          .collection('orphans')
          .doc(orphanId)
          .update(updatedOrphan.copyWith(updatedAt: DateTime.now()).toMap());

      // تحديث القائمة المحلية
      final index = _orphans.indexWhere((orphan) => orphan.id == orphanId);
      if (index != -1) {
        _orphans[index] = updatedOrphan.copyWith(updatedAt: DateTime.now());
        notifyListeners();
      }
    } catch (error) {
      print('Error updating orphan: $error');
      throw 'فشل في تحديث بيانات اليتيم: $error';
    } finally {
      _setLoading(false);
    }
  }

  // دالة لحذف يتيم
  Future<void> deleteOrphan(String orphanId) async {
    _setLoading(true);

    try {
      await _firestore.collection('orphans').doc(orphanId).delete();

      // إزالة اليتيم من القائمة المحلية
      _orphans.removeWhere((orphan) => orphan.id == orphanId);
      notifyListeners();
    } catch (error) {
      print('Error deleting orphan: $error');
      throw 'فشل في حذف اليتيم: $error';
    } finally {
      _setLoading(false);
    }
  }

  // دالة للبحث عن أيتام
  Future<List<Orphan>> searchOrphans(String query) async {
    try {
      final nameQuery = await _firestore
          .collection('orphans')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .get();

      final orphanNoQuery = await _firestore
          .collection('orphans')
          .where('orphanNo', isEqualTo: query)
          .get();

      final allResults = [...nameQuery.docs, ...orphanNoQuery.docs];

      return allResults
          .map((doc) => Orphan.fromMap(doc.data(), doc.id))
          .toList();
    } catch (error) {
      print('Error searching orphans: $error');
      throw 'فشل في البحث: $error';
    }
  }

  // دالة مساعدة لتحديث حالة التحميل
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // دالة للحصول على يتيم بواسطة ID
  Orphan? getOrphanById(String id) {
    try {
      return _orphans.firstWhere((orphan) => orphan.id == id);
    } catch (e) {
      return null;
    }
  }
}
