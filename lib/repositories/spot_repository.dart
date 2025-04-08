import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/models/spot_model.dart';
import 'package:flutter_application_1/services/location_service.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:latlong2/latlong.dart';

class SpotRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Spot>> getSpotsByUser(String userUid) {
    return _firestore
        .collection('spots')
        .where('userUid', isEqualTo: userUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Spot.fromFirestore).toList());
  }

  Future<List<Spot>> getNearbySpots(LatLng center,
      {double radiusKm = 5.0, String? category}) async {
    final querySnapshot = category != null
        ? await _firestore
            .collection('spots')
            .where('category', isEqualTo: category)
            .get()
        : await _firestore.collection('spots').get();

    return querySnapshot.docs
        .map((doc) => Spot.fromFirestore(doc))
        .where((spot) {
      final distance = LocationService.calculateDistance(
        center,
        LatLng(spot.location.latitude, spot.location.longitude),
      );
      return distance <= radiusKm;
    }).toList();
  }

  Future<String?> compressAndEncodeImage(File image) async {
    try {
      final compressedImage = await FlutterImageCompress.compressWithFile(
        image.absolute.path,
        quality: 70,
      );

      if (compressedImage == null) return null;
      return base64Encode(compressedImage);
    } catch (e) {
      debugPrint('Image compression error: $e');
      return null;
    }
  }

  Future<void> addSpot(Spot spot) async {
    final docRef = _firestore.collection('spots').doc();
    await docRef.set(spot.copyWith(id: docRef.id).toMap());
  }

  Future<void> updateSpot(Spot spot) async {
    await _firestore.collection('spots').doc(spot.id).update(spot.toMap());
  }

  Future<void> deleteSpot(String id) async {
    await _firestore.collection('spots').doc(id).delete();
  }

  Future<List<String>> getCategories(String userUid) async {
    final snapshot = await _firestore
        .collection('spots')
        .where('userUid', isEqualTo: userUid)
        .get();
    return snapshot.docs
        .map((doc) => doc.data()['category'] as String)
        .toSet()
        .toList();
  }
}
