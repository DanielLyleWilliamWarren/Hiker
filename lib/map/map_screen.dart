import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' hide TileLayer;
import 'package:vector_map_tiles_mbtiles/vector_map_tiles_mbtiles.dart';
import 'package:mbtiles/mbtiles.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Trail data model
class HikingTrail {
  final String name;
  final String difficulty;
  final double distance; // in km
  final List<LatLng> route;
  final String description;
  final Color color;

  HikingTrail({
    required this.name,
    required this.difficulty,
    required this.distance,
    required this.route,
    required this.description,
    required this.color,
  });
}

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController mapController = MapController();

  // Initial location (Lake District, UK - popular hiking area)
  final LatLng initialCenter = LatLng(54.4609, -3.0886);
  final double initialZoom = 10.0;

  // Selected trail
  HikingTrail? selectedTrail;

  // UK Hiking Trails
  late List<HikingTrail> trails;

  // Vector tile provider
  Style? vectorStyle;
  bool isLoadingTiles = true;
  MbTiles? mbtiles;

  @override
  void initState() {
    super.initState();
    _initializeTrails();
    _loadVectorTiles();
  }

  Future<void> _loadVectorTiles() async {
    // Check if running on web
    if (kIsWeb) {
      print('Running on web - Using online vector tiles');
      await _loadOnlineVectorTiles();
      return;
    }

    try {
      print('Starting vector tiles load process...');

      // Copy MBTiles from assets to a writable location
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/terr50_gb.mbtiles';
      final file = File(filePath);

      print('Target file path: $filePath');

      // Check if file already exists, if not copy from assets
      if (!await file.exists()) {
        print('File does not exist. Copying vector tiles file from assets...');
        try {
          final byteData = await rootBundle.load(
            'assets/terr50_mbtiles_gb/Data/terr50_gb.mbtiles',
          );
          print(
            'Asset loaded. Size: ${byteData.lengthInBytes} bytes (${(byteData.lengthInBytes / 1024 / 1024).toStringAsFixed(2)} MB)',
          );

          final buffer = byteData.buffer;
          await file.writeAsBytes(
            buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
          );
          print('Vector tiles file copied successfully');
        } catch (e) {
          print('ERROR copying asset: $e');
          await _loadOnlineVectorTiles();
          return;
        }
      } else {
        print('Vector tiles file already exists at target location');
        final fileSize = await file.length();
        print(
          'Existing file size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB',
        );
      }

      // Initialize MBTiles
      mbtiles = MbTiles(mbtilesPath: filePath);

      await _initializeVectorStyle();

      print('Vector tiles loaded successfully from: $filePath');
    } catch (e, stackTrace) {
      print('ERROR loading vector tiles: $e');
      print('Stack trace: $stackTrace');
      await _loadOnlineVectorTiles();
    }
  }

  Future<void> _loadOnlineVectorTiles() async {
    print('Loading online vector tiles fallback');
    setState(() {
      isLoadingTiles = false;
      mbtiles = null;
    });
  }

  Future<void> _initializeVectorStyle() async {
    try {
      print(
        '=== VERSION 33: Initializing vector style with custom OS Terrain theme ===',
      );

      // Get metadata from MBTiles to see what layers are available
      try {
        final metadata = mbtiles!.getMetadata();
        print('MBTiles Format: ${metadata.format}');
        print('Min Zoom: ${metadata.minZoom}');
        print('Max Zoom: ${metadata.maxZoom}');
        print('Layers: contour_line, land_water_boundary, spot_height');
      } catch (e) {
        print('Could not read metadata: $e');
      }

      // Create a custom theme for OS Terrain 50 layers
      print('Creating custom theme for OS Terrain layers...');
      final theme = ThemeReader().read({
        "version": 8,
        "sources": {
          "openmaptiles": {
            "type": "vector",
            "tiles": ["http://localhost/{z}/{x}/{y}.pbf"],
          },
        },
        "layers": [
          // Contour lines - brown elevation lines
          {
            "id": "contour_line",
            "type": "line",
            "source": "openmaptiles",
            "source-layer": "contour_line",
            "minzoom": 9,
            "maxzoom": 14,
            "paint": {
              "line-color": "#8B7355",
              "line-width": 1.0,
              "line-opacity": 0.7,
            },
          },
          // Land-water boundary - blue coastlines/rivers
          {
            "id": "land_water_boundary",
            "type": "line",
            "source": "openmaptiles",
            "source-layer": "land_water_boundary",
            "minzoom": 9,
            "maxzoom": 14,
            "paint": {
              "line-color": "#4A90E2",
              "line-width": 2.0,
              "line-opacity": 0.8,
            },
          },
          // Spot heights - elevation numbers
          {
            "id": "spot_height",
            "type": "symbol",
            "source": "openmaptiles",
            "source-layer": "spot_height",
            "minzoom": 9,
            "maxzoom": 14,
            "layout": {
              "text-field": ["get", "property_value"],
              "text-size": 10,
              "text-font": ["Open Sans Regular"],
            },
            "paint": {
              "text-color": "#000000",
              "text-halo-color": "#FFFFFF",
              "text-halo-width": 1,
            },
          },
        ],
      });

      print('Custom theme created successfully');
      vectorStyle = Style(
        theme: theme,
        providers: TileProviders({
          'openmaptiles': MbTilesVectorTileProvider(mbtiles: mbtiles!),
        }),
      );

      final metadata = mbtiles!.getMetadata();
      print('MBTiles metadata: $metadata');

      setState(() {
        isLoadingTiles = false;
      });
    } catch (e) {
      print('Error initializing vector style: $e');
      await _loadOnlineVectorTiles();
    }
  }

  void _initializeTrails() {
    trails = [
      // Scafell Pike (Lake District)
      HikingTrail(
        name: 'Scafell Pike',
        difficulty: 'Hard',
        distance: 9.6,
        description:
            'England\'s highest mountain. Challenging climb with stunning views.',
        color: Color(0xFFEB5757), // Secondary Red
        route: [
          LatLng(54.4542, -3.2118),
          LatLng(54.4565, -3.2095),
          LatLng(54.4590, -3.2070),
          LatLng(54.4615, -3.2055),
          LatLng(54.4640, -3.2040),
          LatLng(54.4643, -3.2115), // Summit
        ],
      ),

      // Helvellyn via Striding Edge
      HikingTrail(
        name: 'Helvellyn via Striding Edge',
        difficulty: 'Hard',
        distance: 14.5,
        description:
            'Iconic ridge walk with dramatic drops. Not for the faint-hearted!',
        color: Color(0xFF7391BF), // Secondary Sky
        route: [
          LatLng(54.5269, -2.9979),
          LatLng(54.5295, -3.0025),
          LatLng(54.5320, -3.0055),
          LatLng(54.5345, -3.0075),
          LatLng(54.5370, -3.0085),
          LatLng(54.5395, -3.0095),
          LatLng(54.5410, -3.0105), // Striding Edge
          LatLng(54.5425, -3.0165), // Summit
        ],
      ),

      // Snowdon - Llanberis Path (Wales)
      HikingTrail(
        name: 'Snowdon - Llanberis Path',
        difficulty: 'Moderate',
        distance: 14.5,
        description:
            'Most popular route up Wales\' highest peak. Steady climb.',
        color: Color(0xFF8CB052), // Secondary Grass
        route: [
          LatLng(53.1181, -4.1327),
          LatLng(53.1200, -4.1290),
          LatLng(53.1220, -4.1250),
          LatLng(53.1240, -4.1210),
          LatLng(53.1260, -4.1170),
          LatLng(53.1280, -4.1130),
          LatLng(53.0685, -4.0761), // Summit
        ],
      ),

      // Ben Nevis (Scotland)
      HikingTrail(
        name: 'Ben Nevis - Mountain Track',
        difficulty: 'Hard',
        distance: 17.0,
        description: 'Britain\'s highest mountain. Long, challenging ascent.',
        color: Color(0xFF528791), // Secondary Sea
        route: [
          LatLng(56.8167, -5.0533),
          LatLng(56.8180, -5.0500),
          LatLng(56.8200, -5.0470),
          LatLng(56.8220, -5.0450),
          LatLng(56.8240, -5.0430),
          LatLng(56.8260, -5.0410),
          LatLng(56.7969, -5.0037), // Summit
        ],
      ),

      // Catbells (Lake District)
      HikingTrail(
        name: 'Catbells',
        difficulty: 'Easy',
        distance: 5.5,
        description:
            'Family-friendly fell with spectacular views of Derwentwater.',
        color: Color(0xFFF0A845), // Secondary Amber
        route: [
          LatLng(54.5537, -3.1514),
          LatLng(54.5555, -3.1490),
          LatLng(54.5575, -3.1470),
          LatLng(54.5595, -3.1455),
          LatLng(54.5615, -3.1445), // Summit
        ],
      ),
    ];
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    for (var trail in trails) {
      // Start point marker
      markers.add(
        Marker(
          point: trail.route.first,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedTrail = trail;
              });
              mapController.move(trail.route.first, 13.0);
            },
            child: Icon(Icons.hiking, color: trail.color, size: 40),
          ),
        ),
      );

      // Summit marker
      markers.add(
        Marker(
          point: trail.route.last,
          width: 30,
          height: 30,
          child: Icon(Icons.flag, color: trail.color, size: 30),
        ),
      );
    }

    return markers;
  }

  List<Polyline> _buildPolylines() {
    return trails.map((trail) {
      return Polyline(
        points: trail.route,
        strokeWidth: selectedTrail == trail ? 5.0 : 3.0,
        color: selectedTrail == trail
            ? trail.color
            : trail.color.withOpacity(0.6),
      );
    }).toList();
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

  void _resetView() {
    setState(() {
      selectedTrail = null;
    });
    mapController.move(initialCenter, initialZoom);
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Color(0xFF8CB052); // Secondary Grass
      case 'moderate':
        return Color(0xFFF0A845); // Secondary Amber
      case 'hard':
        return Color(0xFFEB5757); // Secondary Red
      default:
        return Color(0xFF505050); // Alternate
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isLoadingTiles
              ? 'Loading Map...'
              : mbtiles != null
              ? 'UK Hiking Trails (Offline)'
              : 'UK Hiking Trails (Online)',
        ),
        backgroundColor: Color(0xFF002E40), // AppColors.primaryEarth
        foregroundColor: Color(0xFFFFFFFF), // AppColors.primaryWhite
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () {
              _showTrailsList(context);
            },
          ),
        ],
      ),
      body: isLoadingTiles
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF002E40)),
                  SizedBox(height: 16),
                  Text('Loading vector tiles...'),
                ],
              ),
            )
          : Stack(
              children: [
                // Map widget
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: initialZoom,
                    minZoom: 5.0,
                    maxZoom: 17.0,
                  ),
                  children: [
                    // Vector tile layer or fallback raster tiles
                    if (mbtiles != null && vectorStyle != null)
                      VectorTileLayer(
                        tileProviders: TileProviders({
                          'openmaptiles': MbTilesVectorTileProvider(
                            mbtiles: mbtiles!,
                          ),
                        }),
                        theme: vectorStyle!.theme,
                      )
                    else
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.example.app',
                        maxZoom: 17,
                      ),

                    // Trail routes
                    PolylineLayer(polylines: _buildPolylines()),

                    // Trail markers
                    MarkerLayer(markers: _buildMarkers()),

                    // Attribution
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          mbtiles != null && vectorStyle != null
                              ? 'OS Terrain 50'
                              : 'OpenStreetMap contributors',
                        ),
                      ],
                    ),
                  ],
                ),

                // Trail info card
                if (selectedTrail != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedTrail!.name,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF002E40),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      selectedTrail = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getDifficultyColor(
                                      selectedTrail!.difficulty,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    selectedTrail!.difficulty,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Icon(
                                  Icons.straighten,
                                  size: 16,
                                  color: Color(0xFF505050),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${selectedTrail!.distance} km',
                                  style: TextStyle(color: Color(0xFF505050)),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              selectedTrail!.description,
                              style: TextStyle(
                                color: Color(0xFF505050),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Zoom controls
                Positioned(
                  right: 16,
                  bottom: 100,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'zoom_in',
                        onPressed: _zoomIn,
                        backgroundColor: Color(
                          0xFFAD9C70,
                        ), // AppColors.primaryStone
                        child: Icon(Icons.add, color: Color(0xFFFFFFFF)),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'zoom_out',
                        onPressed: _zoomOut,
                        backgroundColor: Color(
                          0xFFAD9C70,
                        ), // AppColors.primaryStone
                        child: Icon(Icons.remove, color: Color(0xFFFFFFFF)),
                      ),
                    ],
                  ),
                ),

                // Reset view button
                Positioned(
                  right: 16,
                  bottom: 30,
                  child: FloatingActionButton(
                    heroTag: 'reset',
                    onPressed: _resetView,
                    backgroundColor: Color(
                      0xFF7391BF,
                    ), // AppColors.secondarySky
                    child: Icon(Icons.explore, color: Color(0xFFFFFFFF)),
                  ),
                ),
              ],
            ),
    );
  }

  void _showTrailsList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hiking Trails',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF002E40),
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: trails.length,
                  itemBuilder: (context, index) {
                    final trail = trails[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          Icons.hiking,
                          color: trail.color,
                          size: 32,
                        ),
                        title: Text(
                          trail.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF002E40),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getDifficultyColor(
                                      trail.difficulty,
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    trail.difficulty,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('${trail.distance} km'),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            selectedTrail = trail;
                          });
                          mapController.move(trail.route.first, 13.0);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}
