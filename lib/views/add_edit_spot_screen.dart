import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/spot_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/spot_viewmodel.dart';

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
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.spot != null
        ? LatLng(
            widget.spot!.location.latitude,
            widget.spot!.location.longitude,
          )
        : const LatLng(-18.8792, 47.5079);

    if (widget.spot != null) {
      _initializeForm(widget.spot!);
    }
  }

  void _initializeForm(Spot spot) {
    _nameController.text = spot.name;
    _categoryController.text = spot.category;
    _specialtyController.text = spot.specialty;
    _isVisited = spot.isVisited;
    _visitDate = spot.visitDate;
    _rating = spot.rating ?? 3;
    _commentController.text = spot.comment ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePlaceName();
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
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
        SnackBar(
          content: Text('Location not found: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
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
        setState(() => _placeName = 'Unknown location');
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userUid =
          Provider.of<AuthViewModel>(context, listen: false).user?.id;
      if (userUid == null) throw Exception('User not authenticated');

      final spot = Spot(
        id: widget.spot?.id,
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        location: GeoPoint(
          _selectedLocation!.latitude,
          _selectedLocation!.longitude,
        ),
        specialty: _specialtyController.text.trim(),
        imageBase64: widget.spot?.imageBase64,
        createdAt: widget.spot?.createdAt ?? DateTime.now(),
        isVisited: _isVisited,
        visitDate: _isVisited ? _visitDate : null,
        rating: _isVisited ? _rating : null,
        comment: _isVisited ? _commentController.text.trim() : null,
        userUid: userUid,
      );

      final viewModel = Provider.of<SpotViewModel>(context, listen: false);
      if (widget.spot == null) {
        await viewModel.addSpot(spot, imageFile: _imageFile);
      } else {
        await viewModel.updateSpot(spot, imageFile: _imageFile);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
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
        title: const Text('Confirm Deletion'),
        content: Text('Delete "${_nameController.text}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        await Provider.of<SpotViewModel>(context, listen: false)
            .deleteSpot(widget.spot!);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildImagePreview() {
    if (_imageFile != null) {
      return Image.file(
        _imageFile!,
        fit: BoxFit.cover,
      );
    } else if (widget.spot?.imageBase64 != null) {
      return Image.memory(
        base64Decode(widget.spot!.imageBase64!),
        fit: BoxFit.cover,
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, size: 50, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text('Add photo', style: TextStyle(color: Colors.grey.shade600)),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<SpotViewModel>(context);
    final categories = viewModel.getCategoriesSync();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.spot == null ? 'New Spot' : 'Edit Spot'),
        actions: [
          if (widget.spot != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageSection(),
                    const SizedBox(height: 24),
                    _buildBasicInfoSection(categories),
                    const SizedBox(height: 24),
                    _buildLocationSection(),
                    const SizedBox(height: 24),
                    _buildVisitInfoSection(),
                    const SizedBox(height: 32),
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
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildImagePreview(),
            ),
          ),
        ),
        if (_imageFile != null || widget.spot?.imageBase64 != null)
          TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.edit),
            label: const Text('Change photo'),
          ),
      ],
    );
  }

  Widget _buildBasicInfoSection(List<String> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Basic Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Spot name*',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.place),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'This field is required' : null,
        ),
        const SizedBox(height: 16),
        if (!_showCategoryTextField)
          DropdownButtonFormField<String>(
            value: _categoryController.text.isEmpty
                ? null
                : _categoryController.text,
            decoration: const InputDecoration(
              labelText: 'Category*',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
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
                    Text('Add new category'),
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
                setState(() => _categoryController.text = value);
              }
            },
            validator: (value) =>
                value == null ? 'This field is required' : null,
          ),
        if (_showCategoryTextField)
          TextFormField(
            controller: _categoryController,
            decoration: InputDecoration(
              labelText: 'New category*',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.category),
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
                value?.isEmpty ?? true ? 'This field is required' : null,
          ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _specialtyController,
          decoration: const InputDecoration(
            labelText: 'Specialty',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.star),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _locationSearchController,
                decoration: const InputDecoration(
                  labelText: 'Search location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isSearchingLocation ? null : _searchLocation,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(14),
              ),
              child: _isSearchingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Tap on the map to select location:'),
        const SizedBox(height: 8),
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
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
                ),
                MarkerLayer(
                  markers: [
                    Marker(
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
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selected Location',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700)),
                const SizedBox(height: 8),
                Text(_placeName ?? 'Not specified'),
                const SizedBox(height: 4),
                Text(
                  '${_selectedLocation?.latitude.toStringAsFixed(5)}, '
                  '${_selectedLocation?.longitude.toStringAsFixed(5)}',
                  style: TextStyle(color: Colors.grey.shade500),
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
        Text('Visit Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Already visited?'),
          value: _isVisited,
          onChanged: (value) => setState(() => _isVisited = value),
        ),
        if (_isVisited) ...[
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Visit date'),
            subtitle: Text(_visitDate != null
                ? '${_visitDate!.day}/${_visitDate!.month}/${_visitDate!.year}'
                : 'Not specified'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDate(context),
          ),
          const SizedBox(height: 16),
          const Text('Rating:'),
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
              labelText: 'Comments',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.comment),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          widget.spot == null ? 'Add Spot' : 'Update Spot',
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
