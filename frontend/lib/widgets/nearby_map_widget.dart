import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class NearbyMapWidget extends StatefulWidget {
  final MapController mapController;
  final ValueNotifier<LatLng?> currentLocationNotifier;
  final ValueNotifier<List<Marker>> shopMarkersNotifier;
  final LatLng initialCenter;
  final double initialZoom;

  const NearbyMapWidget({
    super.key,
    required this.mapController,
    required this.currentLocationNotifier,
    required this.shopMarkersNotifier,
    required this.initialCenter,
    this.initialZoom = 14,
  });

  @override
  State<NearbyMapWidget> createState() =>
      _NearbyMapWidgetState();
}

class _NearbyMapWidgetState
    extends State<NearbyMapWidget> {
  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: widget.mapController,
      options: MapOptions(
        initialCenter: widget.initialCenter,
        initialZoom: widget.initialZoom,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName:
              'com.nearbyads.app',
        ),

        ValueListenableBuilder<List<Marker>>(
          valueListenable:
              widget.shopMarkersNotifier,
          builder: (
            BuildContext context,
            List<Marker> shopMarkers,
            Widget? child,
          ) {
            return ValueListenableBuilder<
                LatLng?>(
              valueListenable:
                  widget.currentLocationNotifier,
              builder: (
                BuildContext context,
                LatLng? currentLocation,
                Widget? child,
              ) {
                final List<Marker> markers =
                    <Marker>[];

                // Current user location
                if (currentLocation != null) {
                  markers.add(
                    Marker(
                      point: currentLocation,
                      width: 55,
                      height: 55,
                      child: Container(
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.blue
                                  .withValues(
                            alpha: 0.18,
                          ),
                          shape:
                              BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.my_location,
                            color: Colors.blue,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // Shop markers
                markers.addAll(
                  shopMarkers,
                );

                return MarkerLayer(
                  markers: markers,
                );
              },
            );
          },
        ),
      ],
    );
  }
}