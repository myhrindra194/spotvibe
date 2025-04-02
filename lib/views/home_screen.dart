// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/spot_model.dart';
import 'package:flutter_application_1/viewmodels/spot_viewmodel.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  bool? _visitedFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SpotViewModel>(context, listen: false).loadSpots();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Découvrez les Spots'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showFilterDialog,
            tooltip: 'Filtrer',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
            tooltip: 'Rechercher',
          ),
        ],
      ),
      body: Consumer<SpotViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.spots.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildSpotList(viewModel.filteredSpots, context);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/addSpot'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSpotList(List<Spot> spots, BuildContext context) {
    if (spots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucun spot trouvé',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (_selectedCategory != null || _visitedFilter != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
                    _visitedFilter = null;
                  });
                  Provider.of<SpotViewModel>(context, listen: false)
                      .filterSpots();
                },
                child: const Text('Réinitialiser les filtres'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: spots.length,
      itemBuilder: (context, index) => _buildSpotCard(spots[index], context),
    );
  }

  Widget _buildSpotCard(Spot spot, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(
          context,
          '/spotDetails',
          arguments: spot,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: spot.imagePath != null
                    ? Image.file(
                        File(spot.imagePath!),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.place, size: 40),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spot.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.category, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(spot.category),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Modifier'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child:
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'edit') {
                    Navigator.pushNamed(
                      context,
                      '/editSpot',
                      arguments: spot,
                    );
                  } else if (value == 'delete') {
                    await _confirmDelete(spot, context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Spot spot, BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer "${spot.name}" définitivement ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Provider.of<SpotViewModel>(context, listen: false)
            .deleteSpot(spot.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${spot.name}" a été supprimé')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  void _showFilterDialog() {
    final viewModel = Provider.of<SpotViewModel>(context, listen: false);
    final categories = ['Tous', ...viewModel.categories];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer les spots'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory ?? 'Tous',
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value == 'Tous' ? null : value;
                });
              },
              decoration: const InputDecoration(labelText: 'Catégorie'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<bool>(
              value: _visitedFilter,
              items: const [
                DropdownMenuItem(value: null, child: Text('Tous')),
                DropdownMenuItem(value: true, child: Text('Visités')),
                DropdownMenuItem(value: false, child: Text('Non visités')),
              ],
              onChanged: (value) {
                setState(() => _visitedFilter = value);
              },
              decoration: const InputDecoration(labelText: 'Statut'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategory = null;
                _visitedFilter = null;
              });
              viewModel.filterSpots();
              Navigator.pop(context);
            },
            child: const Text('Réinitialiser'),
          ),
          TextButton(
            onPressed: () {
              viewModel.filterSpots(
                category: _selectedCategory,
                visited: _visitedFilter,
              );
              Navigator.pop(context);
            },
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechercher un spot'),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nom, catégorie, spécialité...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<SpotViewModel>(context, listen: false).filterSpots(
                searchQuery: _searchController.text,
                category: _selectedCategory,
                visited: _visitedFilter,
              );
              Navigator.pop(context);
            },
            child: const Text('Rechercher'),
          ),
        ],
      ),
    );
  }
}
