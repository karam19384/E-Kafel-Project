// ملف: lib/providers/visit_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/visit.dart';

class VisitProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Visit> _visits = [];
  bool _isLoading = false;

  List<Visit> get visits => _visits;
  bool get isLoading => _isLoading;

  Future<void> fetchVisits() async {
    _setLoading(true);
    try {
      final querySnapshot = await _firestore
          .collection('visits')
          .orderBy('date', descending: false)
          .get();
      
      _visits = querySnapshot.docs
          .map((doc) => Visit.fromMap(doc.data(), doc.id))
          .toList();
      
      notifyListeners();
    } catch (error) {
      print('Error fetching visits: $error');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}