import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/models/spot_model.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

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

  Future<String?> _compressAndEncodeImage(File image) async {
    try {
      // Compress the image first
      final compressedImage = await FlutterImageCompress.compressWithFile(
        image.absolute.path,
        quality: 70,
      );

      if (compressedImage == null) return null;

      // Encode to base64
      return base64Encode(compressedImage);
    } catch (e) {
      debugPrint('Image compression error: $e');
      return null;
    }
  }

  Future<void> addSpot(Spot spot, {File? imageFile}) async {
    final docRef = _firestore.collection('spots').doc();
    String? imageBase64;

    if (imageFile != null) {
      imageBase64 = await _compressAndEncodeImage(imageFile);
    }

    await docRef
        .set(spot.copyWith(id: docRef.id, imageBase64: imageBase64).toMap());
  }

  Future<void> updateSpot(Spot spot, {File? imageFile}) async {
    String? imageBase64 = spot.imageBase64;

    if (imageFile != null) {
      imageBase64 = await _compressAndEncodeImage(imageFile);
    }

    await _firestore.collection('spots').doc(spot.id).update(
          spot.copyWith(imageBase64: imageBase64).toMap(),
        );
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
