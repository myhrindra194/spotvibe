import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/spot_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class SpotDetailsScreen extends StatelessWidget {
  final Spot spot;

  const SpotDetailsScreen({super.key, required this.spot});

  Future<void> _openMaps() async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${spot.location.latitude},${spot.location.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(spot.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.pushNamed(
              context,
              '/editSpot',
              arguments: spot,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'spot-image-${spot.id}',
              child: spot.imageBase64 != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        base64Decode(spot.imageBase64!),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.place,
                          size: 60,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
            ),
            _buildSectionTitle('Details'),
            _buildInfoRow(Icons.category, spot.category),
            if (spot.specialty.isNotEmpty)
              _buildInfoRow(Icons.star, 'Specialty: ${spot.specialty}'),
            if (spot.isVisited) ...[
              _buildSectionTitle('Visit Details'),
              _buildInfoRow(
                Icons.calendar_today,
                spot.visitDate != null
                    ? dateFormat.format(spot.visitDate!)
                    : 'No date specified',
              ),
              if (spot.rating != null)
                _buildInfoRow(
                  Icons.star,
                  'Rating: ${spot.rating}/5',
                ),
              if (spot.comment?.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                const Text('Notes:',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                Text(spot.comment!),
              ],
            ],
            _buildSectionTitle('Location'),
            SizedBox(
              height: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(
                      spot.location.latitude,
                      spot.location.longitude,
                    ),
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            spot.location.latitude,
                            spot.location.longitude,
                          ),
                          child: Icon(
                            Icons.location_pin,
                            size: 40,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text('Open in Maps'),
                onPressed: _openMaps,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
