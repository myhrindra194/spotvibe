import 'dart:io';

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
    final url = 'https://www.google.com/maps/search/?api=1&query='
        '${spot.location.latitude},${spot.location.longitude}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

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
            if (spot.imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(spot.imagePath!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 200,
                color: Colors.grey.shade200,
                child: const Center(child: Icon(Icons.place, size: 50)),
              ),
            const SizedBox(height: 16),
            Text(spot.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.category, size: 16),
                const SizedBox(width: 8),
                Text(spot.category),
              ],
            ),
            const SizedBox(height: 16),
            if (spot.specialty.isNotEmpty) ...[
              Text('Spécialité: ${spot.specialty}'),
              const SizedBox(height: 16),
            ],
            if (spot.isVisited) ...[
              const Text('Visité le:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(spot.visitDate != null
                  ? dateFormat.format(spot.visitDate!)
                  : 'Date inconnue'),
              if (spot.rating != null) ...[
                const SizedBox(height: 8),
                const Text('Note:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: List.generate(
                    5,
                    (index) {
                      return Icon(
                        index < spot.rating! ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      );
                    },
                  ),
                ),
              ],
              if (spot.comment?.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                const Text('Commentaire:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(spot.comment!),
              ],
              const SizedBox(height: 16),
            ],
            const Text('Localisation',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
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
            ElevatedButton(
              onPressed: _openMaps,
              child: const Text('Ouvrir dans Google Maps'),
            ),
          ],
        ),
      ),
    );
  }
}
