import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/models/spot_model.dart';

class SpotRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Spot>> getSpots() {
    return _firestore
        .collection('spots')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Spot.fromFirestore).toList());
  }

  Future<void> addSpot(Spot spot) async {
    await _firestore.collection('spots').add(spot.toMap());
  }

  Future<void> updateSpot(Spot spot) async {
    await _firestore.collection('spots').doc(spot.id).update(spot.toMap());
  }

  Future<void> deleteSpot(String id) async {
    await _firestore.collection('spots').doc(id).delete();
  }

  Future<List<String>> getCategories() async {
    final snapshot = await _firestore.collection('spots').get();
    final categories = snapshot.docs
        .map((doc) => (doc.data())['category'] as String)
        .toSet()
        .toList();
    return categories;
  }
}
