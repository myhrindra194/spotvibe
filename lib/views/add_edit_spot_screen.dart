// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/spot_model.dart';
import 'package:flutter_application_1/viewmodels/spot_viewmodel.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class AddEditSpotScreen extends StatefulWidget {
  final Spot? spot;

  const AddEditSpotScreen({super.key, this.spot});

  @override
  State<AddEditSpotScreen> createState() => _AddEditSpotScreenState();
}

class _AddEditSpotScreenState extends State<AddEditSpotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _commentController = TextEditingController();
  final _locationSearchController = TextEditingController();
  final _mapController = MapController();

  File? _imageFile;
  LatLng? _selectedLocation;
  bool _isVisited = false;
  DateTime? _visitDate = DateTime.now();
  int _rating = 3;
  bool _isLoading = false;
  bool _isSearchingLocation = false;
  String? _placeName;
  bool _showCategoryTextField = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.spot != null
        ? LatLng(
            widget.spot!.location.latitude, widget.spot!.location.longitude)
        : const LatLng(-18.8792, 47.5079);

    if (widget.spot != null) {
      _initializeForm(widget.spot!);
    }
  }

  void _initializeForm(Spot spot) {
    _nameController.text = spot.name;
    _categoryController.text = spot.category;
    _specialtyController.text = spot.specialty;
    _selectedLocation = LatLng(spot.location.latitude, spot.location.longitude);
    _isVisited = spot.isVisited;
    _visitDate = spot.visitDate;
    _rating = spot.rating ?? 3;
    _commentController.text = spot.comment ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePlaceName();
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _searchLocation() async {
    if (_locationSearchController.text.isEmpty) return;

    setState(() => _isSearchingLocation = true);
    try {
      final locations =
          await locationFromAddress(_locationSearchController.text);
      if (locations.isNotEmpty) {
        final newLocation =
            LatLng(locations.first.latitude, locations.first.longitude);
        setState(() {
          _selectedLocation = newLocation;
          _isSearchingLocation = false;
        });
        _mapController.move(newLocation, 15.0);
        _updatePlaceName();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lieu non trouvé: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSearchingLocation = false);
      }
    }
  }

  Future<void> _updatePlaceName() async {
    if (_selectedLocation == null) return;

    try {
      final placemarks = await placemarkFromCoordinates(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final newPlaceName = [
          if (place.name != null && place.name!.isNotEmpty) place.name,
          if (place.street != null && place.street!.isNotEmpty) place.street,
          if (place.locality != null && place.locality!.isNotEmpty)
            place.locality,
        ].join(', ');

        if (mounted) {
          setState(() => _placeName = newPlaceName);
        }
      }
    } catch (e) {
      debugPrint('Error getting place name: $e');
      if (mounted) {
        setState(() => _placeName = 'Lieu inconnu');
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez remplir tous les champs obligatoires')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final spot = Spot(
        id: widget.spot?.id,
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        location: GeoPoint(
          _selectedLocation!.latitude,
          _selectedLocation!.longitude,
        ),
        specialty: _specialtyController.text.trim(),
        imagePath: _imageFile?.path ?? widget.spot?.imagePath,
        createdAt: widget.spot?.createdAt ?? DateTime.now(),
        isVisited: _isVisited,
        visitDate: _isVisited ? _visitDate : null,
        rating: _isVisited ? _rating : null,
        comment: _isVisited ? _commentController.text.trim() : null,
      );

      final viewModel = Provider.of<SpotViewModel>(context, listen: false);
      if (widget.spot == null) {
        await viewModel.addSpot(spot, imagePath: _imageFile?.path);
      } else {
        await viewModel.updateSpot(spot, imagePath: _imageFile?.path);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _visitDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _visitDate && mounted) {
      setState(() => _visitDate = picked);
    }
  }

  Future<void> _confirmDelete() async {
    if (widget.spot == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer "${_nameController.text}" définitivement ?'),
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

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        await Provider.of<SpotViewModel>(context, listen: false)
            .deleteSpot(widget.spot!.id!);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<SpotViewModel>(context);
    final categories = viewModel.categories;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.spot == null ? 'Nouveau Spot' : 'Modifier Spot'),
        actions: [
          if (widget.spot != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageSection(),
                    const SizedBox(height: 20),
                    _buildBasicInfoSection(categories),
                    const SizedBox(height: 20),
                    _buildLocationSection(),
                    const SizedBox(height: 20),
                    _buildVisitInfoSection(),
                    const SizedBox(height: 30),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: _imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_imageFile!, fit: BoxFit.cover),
                  )
                : widget.spot?.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(widget.spot!.imagePath!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 50),
                            SizedBox(height: 8),
                            Text('Ajouter une photo'),
                          ],
                        ),
                      ),
          ),
        ),
        if (_imageFile != null || widget.spot?.imagePath != null)
          TextButton(
            onPressed: _pickImage,
            child: const Text('Changer la photo'),
          ),
      ],
    );
  }

  Widget _buildBasicInfoSection(List<String> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Informations de base',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nom du spot*',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Ce champ est requis' : null,
        ),
        const SizedBox(height: 16),
        if (!_showCategoryTextField)
          DropdownButtonFormField<String>(
            value: _categoryController.text.isEmpty
                ? null
                : _categoryController.text,
            decoration: const InputDecoration(
              labelText: 'Catégorie*',
              border: OutlineInputBorder(),
            ),
            items: [
              ...categories.map((category) => DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  )),
              const DropdownMenuItem(
                value: '__add_new__',
                child: Row(
                  children: [
                    Icon(Icons.add, size: 20),
                    SizedBox(width: 8),
                    Text('Ajouter une nouvelle catégorie'),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              if (value == '__add_new__') {
                setState(() {
                  _showCategoryTextField = true;
                  _categoryController.clear();
                });
              } else if (value != null) {
                setState(() {
                  _categoryController.text = value;
                });
              }
            },
            validator: (value) => value == null ? 'Ce champ est requis' : null,
            isExpanded: true,
          ),
        if (_showCategoryTextField)
          TextFormField(
            controller: _categoryController,
            decoration: InputDecoration(
              labelText: 'Nouvelle catégorie*',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _showCategoryTextField = false;
                    _categoryController.clear();
                  });
                },
              ),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Ce champ est requis' : null,
          ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _specialtyController,
          decoration: const InputDecoration(
            labelText: 'Spécialité',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Localisation',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _locationSearchController,
                decoration: const InputDecoration(
                  labelText: 'Rechercher un lieu',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isSearchingLocation ? null : _searchLocation,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: _isSearchingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Chercher'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Sélectionnez sur la carte :'),
        const SizedBox(height: 8),
        SizedBox(
          height: 300,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation!,
              initialZoom: 13.0,
              onTap: (_, latLng) {
                setState(() => _selectedLocation = latLng);
                _updatePlaceName();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40.0,
                    height: 40.0,
                    point: _selectedLocation!,
                    child: const Icon(
                      Icons.location_pin,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Text('Lieu sélectionné :',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  _placeName ?? 'Non spécifié',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_selectedLocation?.latitude.toStringAsFixed(5)}, '
                  '${_selectedLocation?.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisitInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Informations de visite',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Déjà visité ?'),
          value: _isVisited,
          onChanged: (value) => setState(() => _isVisited = value),
        ),
        if (_isVisited) ...[
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Date de visite'),
            subtitle: Text(_visitDate != null
                ? '${_visitDate!.day}/${_visitDate!.month}/${_visitDate!.year}'
                : 'Non spécifiée'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDate(context),
          ),
          const SizedBox(height: 16),
          const Text('Note :'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  size: 30,
                ),
                color: Colors.amber,
                onPressed: () => setState(() => _rating = index + 1),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              labelText: 'Commentaire',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          widget.spot == null ? 'Ajouter le spot' : 'Mettre à jour',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _specialtyController.dispose();
    _commentController.dispose();
    _locationSearchController.dispose();
    super.dispose();
  }
}
