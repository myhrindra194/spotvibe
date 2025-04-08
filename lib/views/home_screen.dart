import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/spot_model.dart';
import 'package:flutter_application_1/viewmodels/auth_viewmodel.dart';
import 'package:flutter_application_1/viewmodels/spot_viewmodel.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  int _currentFilterIndex = 0; // 0:All, 1:Visited, 2:Not Visited, 3:Nearby
  double _radius = 5.0;
  bool _showSearchBar = false;
  bool _isLoadingLocation = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialSpots());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialSpots() async {
    final spotVM = Provider.of<SpotViewModel>(context, listen: false);
    if (spotVM.spots.isEmpty) {
      await spotVM.loadSpots();
    }
    _applyFilter(_currentFilterIndex);
  }

  Future<void> _refreshSpots() async {
    final viewModel = Provider.of<SpotViewModel>(context, listen: false);
    if (_currentFilterIndex == 3) {
      await _loadNearbySpots(viewModel);
    } else {
      await viewModel.loadSpots();
      _applyFilter(_currentFilterIndex);
    }
  }

  Future<void> _loadNearbySpots(SpotViewModel viewModel) async {
    setState(() => _isLoadingLocation = true);
    try {
      await viewModel.loadNearbySpots(radiusKm: _radius);
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            const Text('Confirm Logout', style: TextStyle(color: Colors.black)),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Provider.of<AuthViewModel>(context, listen: false).signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  void _applyFilter(int index) {
    setState(() => _currentFilterIndex = index);
    final viewModel = Provider.of<SpotViewModel>(context, listen: false);

    if (index == 3) {
      // Nearby - charge les spots à proximité
      _loadNearbySpots(viewModel);
    } else {
      // Applique le filtre localement
      viewModel.filterSpots(
        category: _selectedCategory,
        visited: index == 1
            ? true
            : index == 2
                ? false
                : null,
        searchQuery:
            _searchController.text.isNotEmpty ? _searchController.text : null,
      );
    }
  }

  void _handleSearchChanged(String query) {
    // Annule le timer précédent s'il existe
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();

    // Démarre un nouveau timer
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (_currentFilterIndex == 3) {
        // Pour les spots à proximité, on recharge avec le nouveau filtre
        _loadNearbySpots(Provider.of<SpotViewModel>(context, listen: false));
      } else {
        // Pour les autres filtres, on applique localement
        Provider.of<SpotViewModel>(context, listen: false).filterSpots(
          category: _selectedCategory,
          visited: _currentFilterIndex == 1
              ? true
              : _currentFilterIndex == 2
                  ? false
                  : null,
          searchQuery: query.isNotEmpty ? query : null,
        );
      }
    });
  }

  void _showCategoryFilter(BuildContext context) {
    final categories = Provider.of<SpotViewModel>(context, listen: false)
        .getCategoriesSync()
        .toList();

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Filter by Category',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: categories.length + 1,
                itemBuilder: (ctx, index) {
                  if (index == 0) {
                    return ListTile(
                      title:
                          Text('All Categories', style: GoogleFonts.poppins()),
                      leading: const Icon(Icons.clear_all),
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _selectedCategory = null);
                        _applyFilter(_currentFilterIndex);
                      },
                    );
                  }
                  final category = categories[index - 1];
                  return ListTile(
                    title: Text(category, style: GoogleFonts.poppins()),
                    leading: const Icon(Icons.category),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _selectedCategory = category);
                      _applyFilter(_currentFilterIndex);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImageFromBase64(String? base64String) {
    if (base64String == null) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(
            Icons.place,
            size: 50,
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    return Image.memory(
      base64Decode(base64String),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.broken_image, size: 40)),
      ),
    );
  }

  Widget _buildSpotCard(Spot spot) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(
          context,
          '/spotDetails',
          arguments: spot,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Hero(
                tag: 'spot-image-${spot.id}',
                child: _buildImageFromBase64(spot.imageBase64),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spot.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.category, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          spot.category,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (_currentFilterIndex == 3 &&
                      spot.distanceFromUser != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.near_me, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${spot.distanceFromUser!.toStringAsFixed(1)} km',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: FutureBuilder<List<Placemark>>(
                            future: placemarkFromCoordinates(
                              spot.location.latitude,
                              spot.location.longitude,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Text(
                                  "Loading...",
                                  style: TextStyle(fontSize: 12),
                                );
                              }
                              if (snapshot.hasError ||
                                  !snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return const Text(
                                  "Unknown location",
                                  style: TextStyle(fontSize: 12),
                                );
                              }
                              final place = snapshot.data!.first;
                              final locationName = [
                                if (place.subLocality != null)
                                  place.subLocality,
                                if (place.street != null) place.street
                              ].where((part) => part != null).join(', ');

                              return Text(
                                locationName,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (spot.isVisited && spot.rating != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < spot.rating!
                                ? Icons.star
                                : Icons.star_border,
                            size: 16,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _currentFilterIndex == 3 ? Icons.location_off : Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _currentFilterIndex == 3
                ? 'No spots within $_radius km'
                : 'No spots found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          if (_currentFilterIndex == 3) ...[
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _applyFilter(3),
              child: Text(
                'Refresh',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
          if (_selectedCategory != null || _currentFilterIndex > 0) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                  _currentFilterIndex = 0;
                  _searchController.clear();
                });
                _applyFilter(0);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6200EE),
              ),
              child: Text(
                'Reset filters',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpotGrid(List<Spot> spots) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: spots.length,
      itemBuilder: (context, index) => _buildSpotCard(spots[index]),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search spots...',
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              setState(() => _showSearchBar = false);
              _searchController.clear();
              _handleSearchChanged('');
            },
          ),
          filled: true,
          fillColor: const Color(0xFF6200EE),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Colors.white70),
        ),
        style: const TextStyle(color: Colors.white),
        onChanged: _handleSearchChanged,
      ),
    );
  }

  Widget _buildRadiusSlider() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Search Radius: ${_radius.toStringAsFixed(1)} km',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
            Slider(
              value: _radius,
              min: 1,
              max: 20,
              divisions: 19,
              label: '${_radius.toStringAsFixed(1)} km',
              activeColor: const Color(0xFF6200EE),
              onChanged: (value) {
                setState(() => _radius = value);
              },
              onChangeEnd: (value) {
                if (_currentFilterIndex == 3) {
                  _applyFilter(3);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileDropdown(AuthViewModel authVM) {
    return PopupMenuButton<String>(
      icon: CircleAvatar(
        backgroundColor: Colors.white,
        child: Icon(Icons.person, color: Color(0xFF6200EE)),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person, color: Color(0xFF6200EE)),
              SizedBox(width: 8),
              Text(authVM.user?.email ?? 'User', style: GoogleFonts.poppins()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 8),
              Text('Logout', style: GoogleFonts.poppins()),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'logout') {
          _logout(context);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<SpotViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: _showSearchBar
            ? null
            : Text('My Spots', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: const Color(0xFF6200EE),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_showSearchBar)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => setState(() => _showSearchBar = true),
            ),
          IconButton(
            icon: const Icon(Icons.category, color: Colors.white),
            onPressed: () => _showCategoryFilter(context),
            tooltip: 'Filter by category',
          ),
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            onSelected: _applyFilter,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 0,
                child: Row(
                  children: [
                    Icon(
                      Icons.all_inclusive,
                      color: _currentFilterIndex == 0
                          ? const Color(0xFF6200EE)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('All Spots'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 1,
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: _currentFilterIndex == 1
                          ? const Color(0xFF6200EE)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Visited'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 2,
                child: Row(
                  children: [
                    Icon(
                      Icons.cancel,
                      color: _currentFilterIndex == 2
                          ? const Color(0xFF6200EE)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Not Visited'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 3,
                child: Row(
                  children: [
                    Icon(
                      Icons.near_me,
                      color: _currentFilterIndex == 3
                          ? const Color(0xFF6200EE)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Nearby Spots'),
                  ],
                ),
              ),
            ],
          ),
          _buildUserProfileDropdown(authVM),
        ],
      ),
      body: Column(
        children: [
          if (_showSearchBar) _buildSearchBar(),
          if (_currentFilterIndex == 3) _buildRadiusSlider(),
          Expanded(
            child: _isLoadingLocation
                ? const Center(child: CircularProgressIndicator())
                : viewModel.isLoading && viewModel.spots.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _refreshSpots,
                        child: viewModel.filteredSpots.isEmpty
                            ? _buildEmptyState()
                            : _buildSpotGrid(viewModel.filteredSpots),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/addSpot'),
        backgroundColor: const Color(0xFF6200EE),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
