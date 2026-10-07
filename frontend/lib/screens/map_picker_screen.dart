import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const MapPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const LatLng defaultLocation =
      LatLng(8.8057, 78.1450);

  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color purple = Color(0xFF7B1FA2);

  LatLng? selectedLocation;

  @override
  void initState() {
    super.initState();

    if (widget.initialLatitude != null &&
        widget.initialLongitude != null) {
      selectedLocation = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
    } else {
      selectedLocation = defaultLocation;
    }
  }

  void onMapTap(
    TapPosition tapPosition,
    LatLng location,
  ) {
    setState(() {
      selectedLocation = location;
    });
  }

  void confirmLocation() {
    if (selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a location on the map.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      selectedLocation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final location =
        selectedLocation ?? defaultLocation;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      appBar: AppBar(
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Pick Shop Location',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: location,
              initialZoom: 15,
              onTap: onMapTap,
            ),

            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.nearbyads.app',
              ),

              if (selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selectedLocation!,
                      width: 55,
                      height: 55,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              primaryBlue,
                              purple,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue
                                  .withValues(alpha: 0.35),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          size: 38,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ----------------------------------------------------
          // TOP INFORMATION CARD
          // ----------------------------------------------------
          Positioned(
            top: 15,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(14),
                border: Border.all(
                  color: lightBlue,
                ),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 10,
                    offset: Offset(0, 3),
                    color: Colors.black12,
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    color: primaryBlue,
                    size: 28,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tap anywhere on the map to select the shop location.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ----------------------------------------------------
          // SELECTED LOCATION CARD
          // ----------------------------------------------------
          if (selectedLocation != null)
            Positioned(
              left: 15,
              right: 15,
              bottom: 90,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                    color: lightBlue,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 12,
                      offset: Offset(0, 4),
                      color: Colors.black12,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: primaryBlue,
                          size: 22,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Selected Location',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: darkBlue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Latitude: '
                      '${selectedLocation!.latitude.toStringAsFixed(6)}\n'
                      'Longitude: '
                      '${selectedLocation!.longitude.toStringAsFixed(6)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ----------------------------------------------------
          // CONFIRM BUTTON
          // ----------------------------------------------------
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: SizedBox(
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      primaryBlue,
                      purple,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue
                          .withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: confirmLocation,
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Use This Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}