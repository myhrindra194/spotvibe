import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/spot_model.dart';
import 'package:flutter_application_1/repositories/spot_repository.dart';

class SpotViewModel with ChangeNotifier {
  final SpotRepository _repository = SpotRepository();

  List<Spot> _spots = [];
  List<String> _categories = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedCategory;
  bool? _visitedFilter;

  List<Spot> get spots => _spots;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;

  List<Spot> get filteredSpots {
    return _spots.where((spot) {
      final matchesSearch = _searchQuery.isEmpty ||
          spot.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          spot.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          spot.specialty.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == null ||
          _selectedCategory!.isEmpty ||
          spot.category == _selectedCategory;

      final matchesVisited =
          _visitedFilter == null || spot.isVisited == _visitedFilter;

      return matchesSearch && matchesCategory && matchesVisited;
    }).toList();
  }

  Future<void> loadSpots() async {
    _isLoading = true;
    notifyListeners();

    try {
      _spots = await _repository.getSpots().first;
      _categories = await _repository.getCategories();
      _categories = _categories.toSet().toList(); // Ensure unique categories
    } catch (e) {
      debugPrint('Error loading spots: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSpot(Spot spot, {String? imagePath}) async {
    try {
      await _repository.addSpot(spot.copyWith(imagePath: imagePath));
      await loadSpots();
    } catch (e) {
      debugPrint('Error adding spot: $e');
      rethrow;
    }
  }

  Future<void> updateSpot(Spot spot, {String? imagePath}) async {
    try {
      await _repository.updateSpot(spot.copyWith(imagePath: imagePath));
      await loadSpots();
    } catch (e) {
      debugPrint('Error updating spot: $e');
      rethrow;
    }
  }

  Future<void> deleteSpot(String id) async {
    try {
      await _repository.deleteSpot(id);
      // Don't call loadSpots here to avoid widget tree issues
      _spots.removeWhere((spot) => spot.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting spot: $e');
      rethrow;
    }
  }

  void filterSpots({
    String? searchQuery,
    String? category,
    bool? visited,
  }) {
    _searchQuery = searchQuery ?? '';
    _selectedCategory = category;
    _visitedFilter = visited;
    notifyListeners();
  }
}
