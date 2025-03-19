import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/spot_model.dart';

class SpotRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addSpot(Spot spot) async {
    await _firestore.collection('spots').add(spot.toMap());
  }

  Future<void> updateSpot(Spot spot) async {
    await _firestore.collection('spots').doc(spot.id).update(spot.toMap());
  }

  Future<void> deleteSpot(String id) async {
    await _firestore.collection('spots').doc(id).delete();
  }

  Future<List<Spot>> getNearbySpots(double latitude, double longitude) async {
    // Implémentez la logique pour récupérer les spots dans un rayon de 2 km
    final QuerySnapshot snapshot = await _firestore.collection('spots').get();
    return snapshot.docs
        .map((doc) => Spot.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }
}
