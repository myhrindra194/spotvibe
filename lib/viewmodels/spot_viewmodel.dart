import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/models/spot_model.dart';
import 'package:flutter_application_1/repositories/spot_repository.dart';
import 'package:flutter_application_1/viewmodels/auth_viewmodel.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class SpotViewModel with ChangeNotifier {
  final SpotRepository _repository;
  final AuthViewModel _authViewModel;

  List<Spot> _spots = [];
  bool _isLoading = false;
  String? _searchQuery;
  String? _selectedCategory;
  bool? _visitedFilter;

  SpotViewModel(this._repository, this._authViewModel);

  List<Spot> get spots => _spots;
  bool get isLoading => _isLoading;

  List<Spot> get filteredSpots {
    return _spots.where((spot) {
      final matchesSearch = _searchQuery == null ||
          _searchQuery!.isEmpty ||
          spot.name.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
          spot.category.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
          spot.specialty.toLowerCase().contains(_searchQuery!.toLowerCase());

      final matchesCategory = _selectedCategory == null ||
          _selectedCategory!.isEmpty ||
          spot.category == _selectedCategory;

      final matchesVisited =
          _visitedFilter == null || spot.isVisited == _visitedFilter;

      return matchesSearch && matchesCategory && matchesVisited;
    }).toList();
  }

  Future<void> loadSpots() async {
    final userUid = _authViewModel.user?.id;
    if (userUid == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _spots = await _repository.getSpotsByUser(userUid).first;
    } catch (e) {
      debugPrint('Error loading spots: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> _compressAndEncodeImage(File imageFile) async {
    try {
      final compressedImage = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        quality: 70,
        minWidth: 800,
        minHeight: 800,
      );

      if (compressedImage == null) return null;
      return base64Encode(compressedImage);
    } catch (e) {
      debugPrint('Image compression error: $e');
      return null;
    }
  }

  Future<void> addSpot(Spot spot, {File? imageFile}) async {
    try {
      String? imageBase64;
      if (imageFile != null) {
        imageBase64 = await _compressAndEncodeImage(imageFile);
      }
      await _repository.addSpot(spot.copyWith(imageBase64: imageBase64));
      await loadSpots();
    } catch (e) {
      debugPrint('Error adding spot: $e');
      rethrow;
    }
  }

  Future<void> updateSpot(Spot spot, {File? imageFile}) async {
    try {
      String? imageBase64 = spot.imageBase64;
      if (imageFile != null) {
        imageBase64 = await _compressAndEncodeImage(imageFile);
      }
      await _repository.updateSpot(spot.copyWith(imageBase64: imageBase64));
      await loadSpots();
    } catch (e) {
      debugPrint('Error updating spot: $e');
      rethrow;
    }
  }

  Future<void> deleteSpot(Spot spot) async {
    try {
      await _repository.deleteSpot(spot.id!);
      _spots.removeWhere((s) => s.id == spot.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting spot: $e');
      rethrow;
    }
  }

  Future<List<String>> getCategories() async {
    final userUid = _authViewModel.user?.id;
    if (userUid == null) return [];
    return await _repository.getCategories(userUid);
  }

  void filterSpots({
    String? searchQuery,
    String? category,
    bool? visited,
  }) {
    _searchQuery = searchQuery;
    _selectedCategory = category;
    _visitedFilter = visited;
    notifyListeners();
  }

  List<String> getCategoriesSync() {
    return _spots.map((spot) => spot.category).toSet().toList();
  }
}
