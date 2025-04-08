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

  Future<List<Spot>> getNearbySpots(LatLng userLocation,
      {required double radiusKm}) async {
    try {
      final spots = await _firestore.collection('spots').get();

      return spots.docs
          .map((doc) {
            final spot = Spot.fromFirestore(doc);
            final spotLocation =
                LatLng(spot.location.latitude, spot.location.longitude);
            final distance =
                LocationService.calculateDistance(userLocation, spotLocation);

            return spot.copyWith(distanceFromUser: distance);
          })
          .where((spot) =>
              spot.distanceFromUser != null &&
              spot.distanceFromUser! <= radiusKm)
          .toList()
        ..sort((a, b) =>
            (a.distanceFromUser ?? 0).compareTo(b.distanceFromUser ?? 0));
    } catch (e) {
      debugPrint('Error getting nearby spots: $e');
      rethrow;
    }
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
