import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';
import '../widgets/nearby_map_widget.dart';
import '../widgets/main_bottom_navigation.dart';
import 'offers_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController =
      TextEditingController();

  Timer? _searchDebounce;

  late final ValueNotifier<LatLng?> _currentLocationNotifier;
  late final ValueNotifier<List<Marker>> _shopMarkersNotifier;
  late final Widget _mapWidget;

  StreamSubscription<Position>? _positionSubscription;

  LatLng? _currentLocation;
  double _currentHeading = 0.0;

  List<Map<String, dynamic>> _allShops =
      <Map<String, dynamic>>[];

  List<Map<String, dynamic>> _filteredShops =
      <Map<String, dynamic>>[];

  final Set<String> _offerShopIds = <String>{};

  List<Marker> _cachedShopMarkers = <Marker>[];

  bool _isLoading = true;
  bool _directionFilterEnabled = false;

  String _selectedCategory = 'All';

  int _selectedIndex = 0;

  static const double _searchRadius = 5000.0;

  LatLng? _lastShopLoadLocation;
  bool _isLoadingShops = false;

  @override
  void initState() {
    super.initState();

    _currentLocationNotifier =
        ValueNotifier<LatLng?>(null);

    _shopMarkersNotifier =
        ValueNotifier<List<Marker>>(<Marker>[]);

    _mapWidget = NearbyMapWidget(
      mapController: _mapController,
      currentLocationNotifier:
          _currentLocationNotifier,
      shopMarkersNotifier:
          _shopMarkersNotifier,
      initialCenter:
          const LatLng(8.764165, 78.134835),
      initialZoom: 14,
    );

    _searchController.addListener(_searchTextListener);

    _startLiveLocation();
  }

  void _searchTextListener() {
    if (!mounted) return;

    setState(() {});
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _searchDebounce?.cancel();

    _searchController.removeListener(
      _searchTextListener,
    );

    _searchController.dispose();
    _currentLocationNotifier.dispose();
    _shopMarkersNotifier.dispose();

    super.dispose();
  }

  Future<void> _startLiveLocation() async {
    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        _showMessage(
          'Please enable location service.',
        );

        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        _showMessage(
          'Location permission is required.',
        );

        return;
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await _updateLocation(position);

      if (!mounted) return;

      const LocationSettings locationSettings =
          LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
      );

      _positionSubscription =
          Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        _updateLocation(position);
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Unable to get current location.',
      );
    }
  }

  Future<void> _updateLocation(
    Position position,
  ) async {
    final LatLng newLocation = LatLng(
      position.latitude,
      position.longitude,
    );

    final bool firstLocation =
        _currentLocation == null;

    final double newHeading =
        position.heading >= 0
            ? position.heading
            : _currentHeading;

    final bool locationChanged =
        _currentLocation == null ||
            Geolocator.distanceBetween(
                  _currentLocation!.latitude,
                  _currentLocation!.longitude,
                  newLocation.latitude,
                  newLocation.longitude,
                ) >=
                5.0;

    final double headingDifference =
        (newHeading - _currentHeading).abs();

    final bool headingChanged =
        headingDifference >= 5.0;

    if (locationChanged) {
      _currentLocation = newLocation;
      _currentLocationNotifier.value =
          newLocation;
    }

    if (headingChanged) {
      _currentHeading = newHeading;
    }

    bool shouldReloadShops =
        _lastShopLoadLocation == null;

    if (!shouldReloadShops &&
        _lastShopLoadLocation != null) {
      final double movedDistance =
          Geolocator.distanceBetween(
        _lastShopLoadLocation!.latitude,
        _lastShopLoadLocation!.longitude,
        newLocation.latitude,
        newLocation.longitude,
      );

      shouldReloadShops =
          movedDistance >= 100.0;
    }

    if (shouldReloadShops &&
        !_isLoadingShops) {
      await _loadAllShops();
    }

    if (firstLocation) {
      try {
        _mapController.move(
          newLocation,
          15.0,
        );
      } catch (_) {}
    }

    if (_directionFilterEnabled &&
        (locationChanged || headingChanged)) {
      _applyFilters(updateState: true);
    }
  }

  Future<void> _loadAllShops() async {
    if (_currentLocation == null) {
      return;
    }

    if (_isLoadingShops) {
      return;
    }

    _isLoadingShops = true;

    final LatLng loadLocation =
        _currentLocation!;

    try {
      List<Map<String, dynamic>>
          nearbyShops =
          <Map<String, dynamic>>[];

      try {
        final Map<String, dynamic> nearbyData =
            await ApiService.getNearbyShops(
          latitude: loadLocation.latitude,
          longitude: loadLocation.longitude,
          radius: _searchRadius,
        );

        final List<dynamic> nearbyList =
            nearbyData['shops'] is List
                ? nearbyData['shops'] as List
                : <dynamic>[];

        nearbyShops = nearbyList
            .whereType<Map>()
            .map(
              (shop) =>
                  Map<String, dynamic>.from(shop),
            )
            .toList();
      } catch (_) {
        nearbyShops =
            <Map<String, dynamic>>[];
      }

      List<Map<String, dynamic>>
          ownerShops =
          <Map<String, dynamic>>[];

      try {
        final Map<String, dynamic> ownerData =
            await ApiService.getApprovedShops();

        final List<dynamic> ownerList =
            ownerData['shops'] is List
                ? ownerData['shops'] as List
                : <dynamic>[];

        ownerShops = ownerList
            .whereType<Map>()
            .map(
              (shop) =>
                  Map<String, dynamic>.from(shop),
            )
            .toList();
      } catch (_) {
        ownerShops =
            <Map<String, dynamic>>[];
      }

      final Set<String>
          loadedOfferShopIds =
          <String>{};

      try {
        final Map<String, dynamic> adsData =
            await ApiService.getApprovedAds();

        final List<dynamic> ads =
            adsData['ads'] is List
                ? adsData['ads'] as List
                : <dynamic>[];

        for (final dynamic ad in ads) {
          if (ad is! Map) {
            continue;
          }

          final String shopId =
              (ad['shop_id'] ??
                      ad['shopId'] ??
                      '')
                  .toString();

          if (shopId.isNotEmpty) {
            loadedOfferShopIds.add(shopId);
          }
        }
      } catch (_) {}

      final List<Map<String, dynamic>>
          combined =
          <Map<String, dynamic>>[];

      for (final shop in nearbyShops) {
        final Map<String, dynamic> item =
            Map<String, dynamic>.from(shop);

        item['source'] = 'osm';

        combined.add(item);
      }

      for (final shop in ownerShops) {
        final double? latitude =
            _getDouble(shop['latitude']);

        final double? longitude =
            _getDouble(shop['longitude']);

        if (latitude == null ||
            longitude == null) {
          continue;
        }

        final double distance =
            Geolocator.distanceBetween(
          loadLocation.latitude,
          loadLocation.longitude,
          latitude,
          longitude,
        );

        if (distance <= _searchRadius) {
          final Map<String, dynamic> item =
              Map<String, dynamic>.from(shop);

          item['source'] = 'owner';
          item['_distance'] = distance;

          combined.add(item);
        }
      }

      final Map<String, Map<String, dynamic>>
          uniqueShops =
          <String, Map<String, dynamic>>{};

      for (final shop in combined) {
        final String id =
            (shop['id'] ??
                    shop['_id'] ??
                    '')
                .toString();

        final String name =
            (shop['shop_name'] ??
                    shop['name'] ??
                    '')
                .toString()
                .trim()
                .toLowerCase();

        final String address =
            (shop['address'] ?? '')
                .toString()
                .trim()
                .toLowerCase();

        final String latitude =
            (shop['latitude'] ?? '')
                .toString();

        final String longitude =
            (shop['longitude'] ?? '')
                .toString();

        final String key = id.isNotEmpty
            ? id
            : '$name|$address|$latitude|$longitude';

        uniqueShops.putIfAbsent(
          key,
          () => shop,
        );
      }

      final List<Map<String, dynamic>>
          result =
          uniqueShops.values.toList();

      for (final shop in result) {
        final double? latitude =
            _getDouble(shop['latitude']);

        final double? longitude =
            _getDouble(shop['longitude']);

        if (latitude != null &&
            longitude != null) {
          shop['_distance'] =
              Geolocator.distanceBetween(
            loadLocation.latitude,
            loadLocation.longitude,
            latitude,
            longitude,
          );
        }
      }

      if (!mounted) {
        return;
      }

      _offerShopIds
        ..clear()
        ..addAll(
          loadedOfferShopIds,
        );

      _lastShopLoadLocation =
          loadLocation;

      _allShops = result;

      _applyFilters(
        updateState: true,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    } finally {
      _isLoadingShops = false;
    }
  }

  void _applyFilters({
    bool updateState = true,
  }) {
    final String query =
        _searchController.text
            .trim()
            .toLowerCase();

    List<Map<String, dynamic>> result =
        List<Map<String, dynamic>>.from(
      _allShops,
    );

    if (query.isNotEmpty) {
      result = result.where((shop) {
        final String name =
            (shop['shop_name'] ??
                    shop['name'] ??
                    '')
                .toString()
                .toLowerCase();

        final String category =
            (shop['category'] ?? '')
                .toString()
                .toLowerCase();

        final String address =
            (shop['address'] ?? '')
                .toString()
                .toLowerCase();

        final String locality =
            (shop['locality'] ?? '')
                .toString()
                .toLowerCase();

        return name.contains(query) ||
            category.contains(query) ||
            address.contains(query) ||
            locality.contains(query);
      }).toList();
    }

    if (_selectedCategory != 'All') {
      final String selected =
          _selectedCategory.toLowerCase();

      result = result.where((shop) {
        final String category =
            (shop['category'] ?? '')
                .toString()
                .toLowerCase();

        return category == selected;
      }).toList();
    }

    if (_directionFilterEnabled &&
        _currentLocation != null) {
      result = result
          .where(
            _isShopInCurrentDirection,
          )
          .toList();
    }

    result.sort((a, b) {
      final double distanceA =
          _getDouble(a['_distance']) ??
              double.infinity;

      final double distanceB =
          _getDouble(b['_distance']) ??
              double.infinity;

      return distanceA.compareTo(
        distanceB,
      );
    });

    _rebuildShopMarkers(result);

    _shopMarkersNotifier.value =
        List<Marker>.from(
      _cachedShopMarkers,
    );

    if (!updateState || !mounted) {
      _filteredShops = result;
      return;
    }

    setState(() {
      _filteredShops = result;
    });
  }

  void _rebuildShopMarkers(
    List<Map<String, dynamic>> shops,
  ) {
    final List<Marker> markers =
        <Marker>[];

    for (final shop in shops) {
      final double? latitude =
          _getDouble(shop['latitude']);

      final double? longitude =
          _getDouble(shop['longitude']);

      if (latitude == null ||
          longitude == null) {
        continue;
      }

      final bool isOwner =
          shop['source'] == 'owner';

      final String shopId =
          (shop['id'] ??
                  shop['_id'] ??
                  '')
              .toString();

      final bool hasOffer =
          _offerShopIds.contains(shopId);

      final Color markerColor;

      if (hasOffer) {
        markerColor =
            const Color(0xFF7B1FA2);
      } else if (isOwner) {
        markerColor =
            const Color(0xFF1976D2);
      } else {
        markerColor =
            _getCategoryColor(
          shop['category'],
        );
      }

      final IconData markerIcon =
          hasOffer
              ? Icons.local_offer
              : _getCategoryIcon(
                  shop['category'],
                );

      markers.add(
        Marker(
          point: LatLng(
            latitude,
            longitude,
          ),
          width: 58.0,
          height: 68.0,
          child: GestureDetector(
            onTap: () {
              _showShopDetails(shop);
            },
            child: Column(
              children: [
                Container(
                  width: 44.0,
                  height: 44.0,
                  decoration:
                      BoxDecoration(
                    color: markerColor,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5.0,
                        offset: Offset(
                          0,
                          2,
                        ),
                      ),
                    ],
                  ),
                  child: Icon(
                    markerIcon,
                    color: Colors.white,
                    size: 22.0,
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.black54,
                  size: 18.0,
                ),
              ],
            ),
          ),
        ),
      );
    }

    _cachedShopMarkers = markers;
  }

  bool _isShopInCurrentDirection(
    Map<String, dynamic> shop,
  ) {
    if (_currentLocation == null) {
      return true;
    }

    final double? latitude =
        _getDouble(shop['latitude']);

    final double? longitude =
        _getDouble(shop['longitude']);

    if (latitude == null ||
        longitude == null) {
      return false;
    }

    final double bearing =
        _calculateBearing(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      latitude,
      longitude,
    );

    double difference =
        (bearing - _currentHeading).abs();

    if (difference > 180.0) {
      difference = 360.0 - difference;
    }

    return difference <= 60.0;
  }

  double _calculateBearing(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final double lat1 =
        _degreesToRadians(startLat);

    final double lat2 =
        _degreesToRadians(endLat);

    final double differenceLng =
        _degreesToRadians(
      endLng - startLng,
    );

    final double y =
        math.sin(differenceLng) *
            math.cos(lat2);

    final double x =
        math.cos(lat1) *
                math.sin(lat2) -
            math.sin(lat1) *
                math.cos(lat2) *
                math.cos(
                  differenceLng,
                );

    final double bearing =
        math.atan2(y, x) *
            180.0 /
            math.pi;

    return (bearing + 360.0) % 360.0;
  }

  double _degreesToRadians(
    double degrees,
  ) {
    return degrees * math.pi / 180.0;
  }

  void _onSearchChanged(
    String value,
  ) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(
      const Duration(
        milliseconds: 350,
      ),
      () {
        if (!mounted) return;

        _applyFilters();
      },
    );
  }

  void _clearSearch() {
    _searchDebounce?.cancel();

    _searchController.clear();

    _applyFilters();
  }

  void _selectCategory(
    String category,
  ) {
    if (_selectedCategory == category) {
      return;
    }

    setState(() {
      _selectedCategory = category;
    });

    _applyFilters();
  }

  List<String> _availableCategories() {
    final Set<String> categories =
        <String>{'All'};

    for (final shop in _allShops) {
      final String category =
          (shop['category'] ?? '')
              .toString()
              .trim();

      if (category.isNotEmpty) {
        categories.add(category);
      }
    }

    return categories.toList();
  }

  void _toggleDirectionFilter() {
    setState(() {
      _directionFilterEnabled =
          !_directionFilterEnabled;
    });

    _applyFilters();

    _showMessage(
      _directionFilterEnabled
          ? 'Showing shops in your current direction.'
          : 'Direction filter disabled.',
    );
  }

  void _showShopDetails(
    Map<String, dynamic> shop,
  ) {
    final String name =
        (shop['shop_name'] ??
                shop['name'] ??
                'Unknown Shop')
            .toString();

    final String category =
        (shop['category'] ?? 'Shop')
            .toString();

    final String address =
        (shop['address'] ??
                'Address unavailable')
            .toString();

    final String description =
        (shop['description'] ??
                'No description available.')
            .toString();

    final bool isOwner =
        shop['source'] == 'owner';

    final String shopId =
        (shop['id'] ??
                shop['_id'] ??
                '')
            .toString();

    final bool hasOffer =
        _offerShopIds.contains(shopId);

    final double distance =
        _getDouble(
              shop['_distance'],
            ) ??
            0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(25.0),
        ),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(22.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 45.0,
                      height: 5.0,
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.grey.shade300,
                        borderRadius:
                            BorderRadius.circular(
                          10.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20.0,
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28.0,
                        backgroundColor:
                            hasOffer
                                ? const Color(
                                    0xFF7B1FA2,
                                  )
                                : isOwner
                                    ? const Color(
                                        0xFF1976D2,
                                      )
                                    : _getCategoryColor(
                                        category,
                                      ),
                        child: Icon(
                          hasOffer
                              ? Icons.local_offer
                              : _getCategoryIcon(
                                  category,
                                ),
                          color:
                              Colors.white,
                          size: 28.0,
                        ),
                      ),
                      const SizedBox(
                        width: 15.0,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              name,
                              style:
                                  const TextStyle(
                                fontSize: 21.0,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(
                              height: 5.0,
                            ),
                            Text(
                              category
                                  .toUpperCase(),
                              style:
                                  const TextStyle(
                                color: Color(
                                  0xFF1976D2,
                                ),
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 15.0,
                  ),
                  if (distance > 0.0)
                    _detailRow(
                      Icons.near_me,
                      _formatDistance(
                        distance,
                      ),
                    ),
                  if (hasOffer)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 10.0,
                      ),
                      child: Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets.all(
                          12.0,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFEDE7F6,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            12.0,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.local_offer,
                              color: Color(
                                0xFF7B1FA2,
                              ),
                            ),
                            SizedBox(
                              width: 8.0,
                            ),
                            Expanded(
                              child: Text(
                                'Offers available at this shop',
                                style:
                                    TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                  color: Color(
                                    0xFF7B1FA2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (isOwner)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 10.0,
                      ),
                      child: Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 12.0,
                          vertical: 7.0,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.green
                              .withValues(
                            alpha: 0.1,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            20.0,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 17.0,
                              color: Colors.green,
                            ),
                            SizedBox(
                              width: 5.0,
                            ),
                            Text(
                              'Owner Verified Shop',
                              style:
                                  TextStyle(
                                color:
                                    Colors.green,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(
                    height: 15.0,
                  ),
                  _detailRow(
                    Icons.location_on,
                    address,
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  _detailRow(
                    Icons.info_outline,
                    description,
                  ),
                  if (shop['phone'] != null &&
                      shop['phone']
                          .toString()
                          .isNotEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 10.0,
                      ),
                      child: _detailRow(
                        Icons.phone,
                        shop['phone']
                            .toString(),
                      ),
                    ),
                  const SizedBox(
                    height: 22.0,
                  ),
                  SizedBox(
                    width:
                        double.infinity,
                    height: 52.0,
                    child:
                        ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(
                          sheetContext,
                        );

                        _openDirections(
                          shop,
                        );
                      },
                      icon: const Icon(
                        Icons.directions,
                      ),
                      label: const Text(
                        'Get Directions',
                        style:
                            TextStyle(
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(
    IconData icon,
    String text,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 0.0),
        Icon(
          icon,
          size: 21.0,
          color: Color(0xFF1976D2),
        ),
        const SizedBox(width: 10.0),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15.0,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDistance(
    double meters,
  ) {
    if (meters < 1000.0) {
      return '${meters.round()} m away';
    }

    return '${(meters / 1000.0).toStringAsFixed(1)} km away';
  }

  void _openDirections(
    Map<String, dynamic> shop,
  ) {
    final double? latitude =
        _getDouble(shop['latitude']);

    final double? longitude =
        _getDouble(shop['longitude']);

    if (latitude == null ||
        longitude == null) {
      _showMessage(
        'Shop location unavailable.',
      );
      return;
    }

    if (_currentLocation == null) {
      _showMessage(
        'Current location unavailable.',
      );
      return;
    }

    final LatLng shopLocation =
        LatLng(
      latitude,
      longitude,
    );

    try {
      _mapController.move(
        shopLocation,
        17.0,
      );
    } catch (_) {}

    final double distance =
        Geolocator.distanceBetween(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      latitude,
      longitude,
    );

    _showMessage(
      'Shop is ${_formatDistance(distance)} away.',
    );
  }

  Future<void> _goToCurrentLocation() async {
    if (_currentLocation == null) {
      await _startLiveLocation();

      if (!mounted ||
          _currentLocation == null) {
        return;
      }
    }

    final LatLng location =
        _currentLocation!;

    try {
      _mapController.move(
        location,
        16.0,
      );
    } catch (_) {}

    _showMessage(
      'Moved to your current location.',
    );
  }

  void _onNavigationChanged(
    int index,
  ) {
    if (!mounted) return;

    if (index == 0) {
      if (_selectedIndex != 0) {
        setState(() {
          _selectedIndex = 0;
        });
      }

      return;
    }

    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const OffersScreen(),
        ),
      ).then((_) {
        if (!mounted) return;

        setState(() {
          _selectedIndex = 0;
        });
      });

      return;
    }

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const FavoritesScreen(),
        ),
      ).then((_) {
        if (!mounted) return;

        setState(() {
          _selectedIndex = 0;
        });
      });

      return;
    }

    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const ProfileScreen(),
        ),
      ).then((_) {
        if (!mounted) return;

        setState(() {
          _selectedIndex = 0;
        });
      });
    }
  }

  double? _getDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  Color _getCategoryColor(
    dynamic category,
  ) {
    final String value =
        category.toString().toLowerCase();

    switch (value) {
      case 'restaurant':
      case 'resturant':
        return const Color(0xFFD32F2F);

      case 'bakery':
        return const Color(0xFF795548);

      case 'pharmacy':
        return const Color(0xFF2E7D32);

      case 'hospital':
        return const Color(0xFFC62828);

      case 'clinic':
        return const Color(0xFF00897B);

      case 'supermarket':
        return const Color(0xFF7B1FA2);

      case 'clothing':
        return const Color(0xFF8E24AA);

      case 'electronics':
        return const Color(0xFF3949AB);

      case 'hardware':
        return const Color(0xFF455A64);

      case 'hotel':
        return const Color(0xFF1976D2);

      case 'mall':
        return const Color(0xFF7B1FA2);

      case 'guest_house':
        return const Color(0xFF00838F);

      default:
        return const Color(0xFF1976D2);
    }
  }

  IconData _getCategoryIcon(
    dynamic category,
  ) {
    final String value =
        category.toString().toLowerCase();

    switch (value) {
      case 'restaurant':
      case 'resturant':
        return Icons.restaurant;

      case 'bakery':
        return Icons.bakery_dining;

      case 'pharmacy':
        return Icons.local_pharmacy;

      case 'hospital':
        return Icons.local_hospital;

      case 'clinic':
        return Icons.medical_services;

      case 'supermarket':
        return Icons.local_grocery_store;

      case 'clothing':
        return Icons.checkroom;

      case 'electronics':
        return Icons.devices;

      case 'hardware':
        return Icons.hardware;

      case 'hotel':
        return Icons.hotel;

      case 'mall':
        return Icons.shopping_bag;

      case 'guest_house':
        return Icons.house;

      default:
        return Icons.store;
    }
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> categories =
        _availableCategories();

    final bool hasSearchText =
        _searchController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _mapWidget,
            ),

            Positioned(
              top: 15.0,
              left: 15.0,
              right: 15.0,
              child: Material(
                elevation: 5.0,
                borderRadius:
                    BorderRadius.circular(
                  15.0,
                ),
                child: Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 15.0,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      15.0,
                    ),
                  ),
                  child: TextField(
                    controller:
                        _searchController,
                    onChanged:
                        _onSearchChanged,
                    decoration:
                        InputDecoration(
                      border:
                          InputBorder.none,
                      hintText:
                          'Search shops...',
                      icon: const Icon(
                        Icons.search,
                        color: Color(
                          0xFF1976D2,
                        ),
                      ),
                      suffixIcon:
                          hasSearchText
                              ? IconButton(
                                  onPressed:
                                      _clearSearch,
                                  icon:
                                      const Icon(
                                    Icons.clear,
                                  ),
                                )
                              : null,
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              top: 75.0,
              left: 15.0,
              right: 15.0,
              child: SizedBox(
                height: 42.0,
                child: ListView.separated(
                  scrollDirection:
                      Axis.horizontal,
                  itemCount:
                      categories.length,
                  separatorBuilder:
                      (_, index) =>
                          const SizedBox(
                    width: 8.0,
                  ),
                  itemBuilder:
                      (context, index) {
                    final String category =
                        categories[index];

                    final bool selected =
                        _selectedCategory ==
                            category;

                    return FilterChip(
                      selected:
                          selected,
                      label:
                          Text(category),
                      onSelected: (_) {
                        _selectCategory(
                          category,
                        );
                      },
                      backgroundColor:
                          Colors.white,
                      selectedColor:
                          const Color(
                        0xFFE3F2FD,
                      ),
                    );
                  },
                ),
              ),
            ),

            Positioned(
              top: 125.0,
              left: 18.0,
              right: 18.0,
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 12.0,
                      vertical: 7.0,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        20.0,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5.0,
                        ),
                      ],
                    ),
                    child: Text(
                      '${_filteredShops.length} nearby shops',
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap:
                        _toggleDirectionFilter,
                    child: Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 12.0,
                        vertical: 7.0,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            _directionFilterEnabled
                                ? const Color(
                                    0xFF1976D2,
                                  )
                                : Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          20.0,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color:
                                Colors.black26,
                            blurRadius: 5.0,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.explore,
                            size: 18.0,
                            color:
                                _directionFilterEnabled
                                    ? Colors.white
                                    : const Color(
                                        0xFF1976D2,
                                      ),
                          ),
                          const SizedBox(
                            width: 5.0,
                          ),
                          Text(
                            _directionFilterEnabled
                                ? 'Direction ON'
                                : 'Direction',
                            style: TextStyle(
                              color:
                                  _directionFilterEnabled
                                      ? Colors.white
                                      : Colors.black87,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              left: 15.0,
              bottom: 95.0,
              child: Container(
                padding:
                    const EdgeInsets.all(
                  10.0,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    12.0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5.0,
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 12.0,
                          color: Color(
                            0xFF1976D2,
                          ),
                        ),
                        SizedBox(width: 5.0),
                        Text(
                          'Owner Shop',
                        ),
                      ],
                    ),
                    SizedBox(height: 5.0),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 12.0,
                          color: Color(
                            0xFF7B1FA2,
                          ),
                        ),
                        SizedBox(width: 5.0),
                        Text(
                          'Offer Available',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              right: 15.0,
              bottom: 95.0,
              child: FloatingActionButton(
                heroTag:
                    'currentLocationButton',
                backgroundColor:
                    Colors.white,
                foregroundColor:
                    const Color(
                  0xFF1976D2,
                ),
                onPressed:
                    _goToCurrentLocation,
                child: const Icon(
                  Icons.my_location,
                ),
              ),
            ),

            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.white
                      .withValues(
                    alpha: 0.55,
                  ),
                  child:
                      const Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar:
          MainBottomNavigation(
        currentIndex:
            _selectedIndex,
        onTap:
            _onNavigationChanged,
      ),
    );
  }
}