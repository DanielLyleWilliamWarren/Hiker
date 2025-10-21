import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hiker/constants/app_colors.dart';
import 'package:latlong2/latlong.dart';
// Import your color scheme
// import 'package:your_app_name/constants/app_colors.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController mapController = MapController();

  // Initial location (Auckland, NZ)
  final LatLng initialCenter = LatLng(-41.8485, 174.7633);
  final double initialZoom = 8.0;

  // Sample markers
  List<Marker> markers = [];

  @override
  void initState() {
    super.initState();
  }
  
  void _zoomIn() {
    mapController.move(
      mapController.camera.center,
      mapController.camera.zoom + 1,
    );
  }

  void _zoomOut() {
    mapController.move(
      mapController.camera.center,
      mapController.camera.zoom - 1,
    );
  }

  void _goToLocation(LatLng location) {
    mapController.move(location, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
        backgroundColor: AppColors.primaryEarth, 
        foregroundColor: AppColors.primaryWhite,
      ),
      body: Stack(
        children: [
          // Map widget
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: initialZoom,
              minZoom: 3.0,
              maxZoom: 18.0,
            ),
            children: [
              // Tile layer - displays the map tiles
              TileLayer(
                urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.app',
                maxZoom: 17,
              ),

              // Marker layer - displays location pins
              MarkerLayer(markers: markers),

              // Optional: Add attribution (required for OSM)
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () {
                      // Open OSM website if needed
                    },
                  ),
                ],
              ),
            ],
          ),

          // Zoom controls
          Positioned(
            left: 16,
            top: 50,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: _zoomIn,
                  backgroundColor: AppColors.primaryEarth,
                  child: Icon(Icons.add, color: AppColors.primaryWhite),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: _zoomOut,
                  backgroundColor: AppColors.primaryEarth,
                  child: Icon(Icons.remove, color: AppColors.primaryWhite),
                ),
              ],
            ),
          ),

          // Center location button
          Positioned(
            left: 16,
            bottom: 30,
            child: FloatingActionButton(
              heroTag: 'center',
              onPressed: () => _goToLocation(initialCenter),
              backgroundColor: AppColors.primaryEarth, 
              child: Icon(Icons.my_location, color: Color(0xFFFFFFFF)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}
