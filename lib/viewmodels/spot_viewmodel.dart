import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/models/spot_model.dart';
import 'package:flutter_application_1/repositories/spot_repository.dart';
import 'package:flutter_application_1/services/location_service.dart';
import 'package:flutter_application_1/viewmodels/auth_viewmodel.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:latlong2/latlong.dart';

class SpotViewModel with ChangeNotifier {
  final SpotRepository _repository;
  final AuthViewModel _authViewModel;

  List<Spot> _spots = [];
  List<Spot> _filteredSpots = [];
  bool _isLoading = false;
  String? _searchQuery;
  String? _selectedCategory;
  bool? _visitedFilter;
  LatLng? _userLocation;
  double _searchRadius = 5.0;
  int _currentFilterIndex = 0; // 0:All, 1:Visited, 2:Not Visited, 3:Nearby

  SpotViewModel(this._repository, this._authViewModel);

  List<Spot> get spots => _spots;
  List<Spot> get filteredSpots => _filteredSpots;
  bool get isLoading => _isLoading;
  double get searchRadius => _searchRadius;
  int get currentFilterIndex => _currentFilterIndex;
  LatLng? get userLocation => _userLocation;

  Future<void> loadSpots() async {
    final userUid = _authViewModel.user?.id;
    if (userUid == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _spots = await _repository.getSpotsByUser(userUid).first;
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading spots: $e');
      _resetSpotLists();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNearbySpots(
      {required double radiusKm, String? category}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final position = await LocationService.getCurrentPosition();
      _userLocation = LatLng(position.latitude, position.longitude);
      _searchRadius = radiusKm;

      final nearbySpots = await _repository.getNearbySpots(
        _userLocation!,
        radiusKm: radiusKm,
        category: category,
      );

      _spots = nearbySpots.map((spot) {
        final distance = spot.distanceFromUser ??
            LocationService.calculateDistance(
              _userLocation!,
              LatLng(spot.location.latitude, spot.location.longitude),
            );
        return spot.copyWith(distanceFromUser: distance);
      }).toList()
        ..sort((a, b) =>
            (a.distanceFromUser ?? 0).compareTo(b.distanceFromUser ?? 0));

      _applyFilters();
    } catch (e) {
      debugPrint('Error loading nearby spots: $e');
      _resetSpotLists();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFilters() {
    _filteredSpots = _spots.where((spot) {
      final matchesSearch = _searchQuery == null ||
          _searchQuery!.isEmpty ||
          spot.name.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
          spot.category.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
          (spot.specialty.toLowerCase().contains(_searchQuery!.toLowerCase()));

      final matchesCategory = _selectedCategory == null ||
          _selectedCategory!.isEmpty ||
          spot.category == _selectedCategory;

      final matchesVisited = _currentFilterIndex != 3
          ? (_visitedFilter == null || spot.isVisited == _visitedFilter)
          : true;

      return matchesSearch && matchesCategory && matchesVisited;
    }).toList();

    notifyListeners();
  }

  Future<String?> _compressAndEncodeImage(File imageFile) async {
    try {
      final compressedImage = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        quality: 70,
        minWidth: 800,
        minHeight: 800,
      );
      return compressedImage != null ? base64Encode(compressedImage) : null;
    } catch (e) {
      debugPrint('Image compression error: $e');
      return null;
    }
  }

  Future<void> addSpot(Spot spot, {File? imageFile}) async {
    try {
      final imageBase64 =
          imageFile != null ? await _compressAndEncodeImage(imageFile) : null;
      await _repository.addSpot(spot.copyWith(imageBase64: imageBase64));
      await loadSpots();
    } catch (e) {
      debugPrint('Error adding spot: $e');
      rethrow;
    }
  }

  Future<void> updateSpot(Spot spot, {File? imageFile}) async {
    try {
      final imageBase64 = imageFile != null
          ? await _compressAndEncodeImage(imageFile)
          : spot.imageBase64;
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
      _applyFilters();
    } catch (e) {
      debugPrint('Error deleting spot: $e');
      rethrow;
    }
  }

  Future<List<String>> getCategories() async {
    final userUid = _authViewModel.user?.id;
    return userUid != null ? await _repository.getCategories(userUid) : [];
  }

  List<String> getCategoriesSync() {
    return _spots.map((spot) => spot.category).toSet().toList();
  }

  void filterSpots({
    String? searchQuery,
    String? category,
    bool? visited,
    int? filterIndex,
    double? radius,
  }) {
    _searchQuery = searchQuery;
    _selectedCategory = category;
    _visitedFilter = visited;

    if (filterIndex != null) {
      _currentFilterIndex = filterIndex;
    }

    if (radius != null) {
      _searchRadius = radius;
    }

    _applyFilters();
  }

  void setSearchRadius(double radius) {
    _searchRadius = radius;
    if (_currentFilterIndex == 3) {
      loadNearbySpots(radiusKm: radius, category: _selectedCategory);
    } else {
      _applyFilters();
    }
  }

  void resetFilters() {
    _searchQuery = null;
    _selectedCategory = null;
    _visitedFilter = null;
    _currentFilterIndex = 0;
    _applyFilters();
  }

  void _resetSpotLists() {
    _spots = [];
    _filteredSpots = [];
  }
}
