import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
import 'shop_navigation_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final MapController _mapController = MapController();

  final TextEditingController _searchController =
      TextEditingController();

  Timer? _searchDebounce;

  // ============================================================
  // PERFORMANCE NOTIFIERS
  // ============================================================

  late final ValueNotifier<LatLng?> _currentLocationNotifier;

  late final ValueNotifier<List<Marker>> _shopMarkersNotifier;

  Widget? _mapWidget;

  // ============================================================
  // LOCATION
  // ============================================================

  StreamSubscription<Position>? _positionSubscription;

  LatLng? _currentLocation;

  double _currentHeading = 0.0;

  double _lastMovementHeading = 0.0;

  // ============================================================
  // SHOP DATA
  // ============================================================

  List<Map<String, dynamic>> _allShops =
      <Map<String, dynamic>>[];

  List<Map<String, dynamic>> _filteredShops =
      <Map<String, dynamic>>[];

  final Set<String> _offerShopIds = <String>{};

  // ============================================================
  // DIRECTION SHOPS
  // ============================================================

  List<Map<String, dynamic>> _directionShops =
      <Map<String, dynamic>>[];

  // Maximum distance to search ahead.
  static const double _directionSearchDistance = 1000;

  // Maximum side distance from travel direction.
  static const double _directionCorridorWidth = 120;

  // ============================================================
  // MARKER CACHE
  // ============================================================

  List<Marker> _cachedShopMarkers = <Marker>[];

  // ============================================================
  // FILTERS
  // ============================================================

  bool _isLoading = true;

  bool _directionFilterEnabled = false;

  String _selectedCategory = 'All';

  int _selectedIndex = 0;

  static const double _searchRadius = 5000;

  // ============================================================
  // PERFORMANCE
  // ============================================================

  LatLng? _lastShopLoadLocation;

  bool _isLoadingShops = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _currentLocationNotifier =
        ValueNotifier<LatLng?>(null);

    _shopMarkersNotifier =
        ValueNotifier<List<Marker>>(<Marker>[]);

    _searchController.addListener(_searchTextListener);

    _startLiveLocation();
  }

  // ============================================================
  // SEARCH TEXT LISTENER
  // ============================================================

  void _searchTextListener() {
    if (!mounted) return;

    setState(() {});
  }

  // ============================================================
  // DISPOSE
  // ============================================================

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

  // ============================================================
  // LIVE LOCATION
  // ============================================================

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
          'Please turn on your location.',
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
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        _showMessage(
          'Location permission is required.',
        );

        return;
      }

      await _positionSubscription?.cancel();

      late final LocationSettings locationSettings;

      if (kIsWeb) {
        locationSettings = WebSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
          maximumAge: Duration.zero,
        );
      } else {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
          intervalDuration:
              const Duration(seconds: 2),
          forceLocationManager: false,
        );
      }

      _positionSubscription =
          Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          debugPrint(
            'LIVE GPS UPDATE => '
            'lat=${position.latitude}, '
            'lng=${position.longitude}, '
            'accuracy=${position.accuracy}, '
            'heading=${position.heading}',
          );

          _updateLocation(position);
        },
        onError: (Object error) {
          debugPrint(
            'GPS STREAM ERROR => $error',
          );

          if (!mounted) return;

          setState(() {
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      debugPrint(
        'LOCATION ERROR => $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Unable to get current location.',
      );
    }
  }

  // ============================================================
  // UPDATE LOCATION
  // ============================================================

  Future<void> _updateLocation(
    Position position,
  ) async {
    if (position.accuracy > 100) {
      debugPrint(
        'IGNORING LOW QUALITY GPS => '
        'lat=${position.latitude}, '
        'lng=${position.longitude}, '
        'accuracy=${position.accuracy}',
      );
      return;
    }

    final LatLng newLocation = LatLng(
      position.latitude,
      position.longitude,
    );

    final LatLng? oldLocation =
        _currentLocation;

    final bool locationChanged =
        _currentLocation == null ||
        Geolocator.distanceBetween(
              _currentLocation!.latitude,
              _currentLocation!.longitude,
              newLocation.latitude,
              newLocation.longitude,
            ) >=
            5;

    // ==========================================================
    // MOVEMENT HEADING
    // ==========================================================

    if (oldLocation != null &&
        locationChanged) {
      final double movementDistance =
          Geolocator.distanceBetween(
        oldLocation.latitude,
        oldLocation.longitude,
        newLocation.latitude,
        newLocation.longitude,
      );

      if (movementDistance >= 5) {
        _lastMovementHeading =
            _calculateBearing(
          oldLocation.latitude,
          oldLocation.longitude,
          newLocation.latitude,
          newLocation.longitude,
        );
      }
    }

    // ==========================================================
    // GPS HEADING
    // ==========================================================

    double newHeading =
        _currentHeading;

    if (position.heading >= 0) {
      newHeading = position.heading;
    }

    // If GPS heading is unreliable while moving,
    // use actual movement direction.
    if (locationChanged &&
        oldLocation != null) {
      final double movementDistance =
          Geolocator.distanceBetween(
        oldLocation.latitude,
        oldLocation.longitude,
        newLocation.latitude,
        newLocation.longitude,
      );

      if (movementDistance >= 5) {
        newHeading =
            _lastMovementHeading;
      }
    }

    final bool headingChanged =
        (newHeading - _currentHeading).abs() >= 5;

    // ==========================================================
    // UPDATE LOCATION
    // ==========================================================

    if (locationChanged) {
      final bool firstLocation =
          _currentLocation == null;

      _currentLocation = newLocation;

      _currentLocationNotifier.value =
          newLocation;

      if (firstLocation && _mapWidget == null) {
        _mapWidget = NearbyMapWidget(
          mapController: _mapController,
          currentLocationNotifier:
              _currentLocationNotifier,
          shopMarkersNotifier:
              _shopMarkersNotifier,
          initialCenter: newLocation,
          initialZoom: 16,
        );

        if (mounted) {
          setState(() {});
        }
      }

      try {
        _mapController.move(
          newLocation,
          16,
        );
      } catch (_) {}
    }

    if (headingChanged) {
      _currentHeading = newHeading;
    }

    // ==========================================================
    // RELOAD SHOPS
    // ==========================================================

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
          movedDistance >= 100;
    }

    if (shouldReloadShops &&
        !_isLoadingShops) {
      await _loadAllShops();
    }

    // ==========================================================
    // UPDATE DIRECTION SHOPS
    // ==========================================================

    if (_directionFilterEnabled &&
        (_directionShops.isEmpty ||
            locationChanged ||
            headingChanged)) {
      _updateDirectionShops(
        _filteredShops,
      );
    }
  }

  // ============================================================
  // LOAD ALL SHOPS + ADS
  // ============================================================

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
      // --------------------------------------------------------
      // OSM / OVERPASS SHOPS
      // --------------------------------------------------------

      List<Map<String, dynamic>> nearbyShops =
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

      // --------------------------------------------------------
      // APPROVED OWNER SHOPS
      // --------------------------------------------------------

      List<Map<String, dynamic>> ownerShops =
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

      // --------------------------------------------------------
      // APPROVED ADS
      // --------------------------------------------------------

      final Set<String>
          loadedOfferShopIds = <String>{};

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

      // --------------------------------------------------------
      // COMBINE OSM + OWNER SHOPS
      // --------------------------------------------------------

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

      // --------------------------------------------------------
      // REMOVE DUPLICATES
      // --------------------------------------------------------

      final Map<String,
              Map<String, dynamic>>
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
            : '$name|$address|'
                '$latitude|$longitude';

        uniqueShops.putIfAbsent(
          key,
          () => shop,
        );
      }

      final List<Map<String, dynamic>>
          result =
          uniqueShops.values.toList();

      // --------------------------------------------------------
      // CALCULATE DISTANCE
      // --------------------------------------------------------

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

      // --------------------------------------------------------
      // UPDATE OFFER IDS
      // --------------------------------------------------------

      _offerShopIds
        ..clear()
        ..addAll(loadedOfferShopIds);

      // --------------------------------------------------------
      // UPDATE LOCATION CACHE
      // --------------------------------------------------------

      _lastShopLoadLocation =
          loadLocation;

      // --------------------------------------------------------
      // UPDATE ALL SHOPS
      // --------------------------------------------------------

      _allShops = result;

      // --------------------------------------------------------
      // APPLY FILTERS
      // --------------------------------------------------------

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

  // ============================================================
  // APPLY FILTERS
  // ============================================================

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

    // SEARCH
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

    // CATEGORY
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

    // SORT BY DISTANCE
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

    // REBUILD MARKERS
    _rebuildShopMarkers(result);

    _shopMarkersNotifier.value =
        List<Marker>.from(
      _cachedShopMarkers,
    );

    // ==========================================================
    // UPDATE DIRECTION SHOPS
    // ==========================================================

    if (_directionFilterEnabled) {
      _updateDirectionShops(result);
    } else {
      _directionShops =
          <Map<String, dynamic>>[];
    }

    if (!updateState || !mounted) {
      _filteredShops = result;
      return;
    }

    setState(() {
      _filteredShops = result;
    });
  }

  // ============================================================
  // DIRECTION SHOP DISCOVERY
  // ============================================================

  void _updateDirectionShops(
    List<Map<String, dynamic>> shops,
  ) {
    if (!_directionFilterEnabled ||
        _currentLocation == null) {
      if (mounted) {
        setState(() {
          _directionShops =
              <Map<String, dynamic>>[];
        });
      } else {
        _directionShops =
            <Map<String, dynamic>>[];
      }

      return;
    }

    final List<Map<String, dynamic>> result =
        <Map<String, dynamic>>[];

    for (final shop in shops) {
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
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        latitude,
        longitude,
      );

      // Shop must be reasonably close.
      if (distance >
          _directionSearchDistance) {
        continue;
      }

      // --------------------------------------------------------
      // FIND SHOP BEARING
      // --------------------------------------------------------

      final double shopBearing =
          _calculateBearing(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        latitude,
        longitude,
      );

      double angleDifference =
          (shopBearing - _currentHeading)
              .abs();

      if (angleDifference > 180) {
        angleDifference =
            360 - angleDifference;
      }

      // Shop must be in front of the user.
      if (angleDifference > 65) {
        continue;
      }

      // --------------------------------------------------------
      // CALCULATE SIDE DISTANCE
      // --------------------------------------------------------

      final double angleRadians =
          _degreesToRadians(
        angleDifference,
      );

      final double sideDistance =
          distance *
              math.sin(angleRadians);

      // Shop should be close to the travel corridor.
      if (sideDistance >
          _directionCorridorWidth) {
        continue;
      }

      // --------------------------------------------------------
      // FORWARD DISTANCE
      // --------------------------------------------------------

      final double forwardDistance =
          distance *
              math.cos(angleRadians);

      if (forwardDistance < 0) {
        continue;
      }

      final Map<String, dynamic> item =
          Map<String, dynamic>.from(shop);

      item['_directionDistance'] =
          forwardDistance;

      item['_sideDistance'] =
          sideDistance;

      result.add(item);
    }

    // ----------------------------------------------------------
    // SORT BY FORWARD DISTANCE
    // ----------------------------------------------------------

    result.sort((a, b) {
      final double distanceA =
          _getDouble(
                a['_directionDistance'],
              ) ??
              double.infinity;

      final double distanceB =
          _getDouble(
                b['_directionDistance'],
              ) ??
              double.infinity;

      return distanceA.compareTo(
        distanceB,
      );
    });

    // Keep the list useful and compact.
    final List<Map<String, dynamic>>
        limitedResult =
        result.take(15).toList();

    if (!mounted) {
      _directionShops =
          limitedResult;
      return;
    }

    setState(() {
      _directionShops =
          limitedResult;
    });
  }

  // ============================================================
  // MARKER CACHE
  // ============================================================

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
          width: 58,
          height: 68,
          child: GestureDetector(
            onTap: () {
              _showShopDetails(shop);
            },
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: markerColor,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    markerIcon,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.black54,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      );
    }

    _cachedShopMarkers = markers;
  }

  // ============================================================
  // DIRECTION BUTTON
  // ============================================================

  void _toggleDirectionFilter() {
    debugPrint(
      'DIRECTION BUTTON PRESSED => '
      'current=$_directionFilterEnabled',
    );

    setState(() {
      _directionFilterEnabled =
          !_directionFilterEnabled;
    });

    debugPrint(
      'DIRECTION AFTER TOGGLE => '
      '$_directionFilterEnabled',
    );

    if (_directionFilterEnabled) {
      _updateDirectionShops(
        _filteredShops,
      );

      _showMessage(
        'Direction is ON.',
      );
    } else {
      setState(() {
        _directionShops =
            <Map<String, dynamic>>[];
      });

      _showMessage(
        'Direction is OFF.',
      );
    }

    // Direction ON/OFF does NOT hide map shops.
    _applyFilters();
  }

  // ============================================================
// SHOP DETAILS
// ============================================================

Future<bool> _isFavoriteShop(
  Map<String, dynamic> shop,
) async {
  final prefs =
      await SharedPreferences.getInstance();

  final List<String> favorites =
      prefs.getStringList('favorite_shops') ?? [];

  final String shopKey =
      (shop['id'] ??
              shop['_id'] ??
              '${shop['shop_name'] ?? shop['name']}_${shop['latitude']}_${shop['longitude']}')
          .toString();

  return favorites.any((item) {
    try {
      final Map<String, dynamic> saved =
          Map<String, dynamic>.from(
        jsonDecode(item),
      );

      final String savedKey =
          (saved['id'] ??
                  saved['_id'] ??
                  '${saved['shop_name'] ?? saved['name']}_${saved['latitude']}_${saved['longitude']}')
              .toString();

      return savedKey == shopKey;
    } catch (_) {
      return false;
    }
  });
}

Future<bool> _toggleFavoriteShop(
  Map<String, dynamic> shop,
) async {
  final prefs =
      await SharedPreferences.getInstance();

  final List<String> favorites =
      prefs.getStringList('favorite_shops') ?? [];

  final String shopKey =
      (shop['id'] ??
              shop['_id'] ??
              '${shop['shop_name'] ?? shop['name']}_${shop['latitude']}_${shop['longitude']}')
          .toString();

  int existingIndex = -1;

  for (int i = 0; i < favorites.length; i++) {
    try {
      final Map<String, dynamic> saved =
          Map<String, dynamic>.from(
        jsonDecode(favorites[i]),
      );

      final String savedKey =
          (saved['id'] ??
                  saved['_id'] ??
                  '${saved['shop_name'] ?? saved['name']}_${saved['latitude']}_${saved['longitude']}')
              .toString();

      if (savedKey == shopKey) {
        existingIndex = i;
        break;
      }
    } catch (_) {}
  }

  if (existingIndex >= 0) {
    favorites.removeAt(existingIndex);

    await prefs.setStringList(
      'favorite_shops',
      favorites,
    );

    return false;
  }

  favorites.add(
    jsonEncode(shop),
  );

  await prefs.setStringList(
    'favorite_shops',
    favorites,
  );

  return true;
}

Future<void> _showShopDetails(
  Map<String, dynamic> shop,
) async {
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
      _getDouble(shop['_distance']) ??
          0;

  final bool initialFavorite =
      await _isFavoriteShop(shop);

  if (!mounted) return;

  bool isFavorite = initialFavorite;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape:
        const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(
        top: Radius.circular(25),
      ),
    ),
    builder: (BuildContext sheetContext) {
      return StatefulBuilder(
        builder: (
          BuildContext innerContext,
          StateSetter setSheetState,
        ) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 45,
                        height: 5,
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.grey.shade300,
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              hasOffer
                                  ? const Color(
                                      0xFF7B1FA2,
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
                            color: Colors.white,
                            size: 28,
                          ),
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style:
                                    const TextStyle(
                                  fontSize: 21,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(
                                height: 5,
                              ),

                              Text(
                                category
                                    .toUpperCase(),
                                style:
                                    const TextStyle(
                                  color:
                                      Color(0xFF1976D2),
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    if (distance > 0)
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
                          top: 10,
                        ),
                        child: Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(
                            12,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFF7B1FA2,
                            ).withValues(
                              alpha: 0.10,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.local_offer,
                                color:
                                    Color(0xFF7B1FA2),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Offers available at this shop',
                                  style: TextStyle(
                                    fontWeight:
                                        FontWeight.w600,
                                    color:
                                        Color(0xFF7B1FA2),
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
                          top: 10,
                        ),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFF1976D2,
                            ).withValues(
                              alpha: 0.10,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                size: 17,
                                color:
                                    Color(0xFF1976D2),
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Owner Verified Shop',
                                style: TextStyle(
                                  color:
                                      Color(0xFF1976D2),
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 15),

                    _detailRow(
                      Icons.location_on,
                      address,
                    ),

                    const SizedBox(height: 10),

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
                          top: 10,
                        ),
                        child: _detailRow(
                          Icons.phone,
                          shop['phone']
                              .toString(),
                        ),
                      ),

                    const SizedBox(height: 22),

                    // ====================================================
                    // FAVORITES BUTTON
                    // ====================================================

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child:
                          OutlinedButton.icon(
                        onPressed: () async {
                          final bool added =
                              await _toggleFavoriteShop(
                            shop,
                          );

                          if (!mounted) return;

                          setSheetState(() {
                            isFavorite = added;
                          });

                          _showMessage(
                            added
                                ? 'Added to favorites.'
                                : 'Removed from favorites.',
                          );
                        },
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              const Color(0xFF7B1FA2),
                        ),
                        label: Text(
                          isFavorite
                              ? 'Remove from Favorites'
                              : 'Add to Favorites',
                          style:
                              const TextStyle(
                            fontSize: 16,
                            color:
                                Color(0xFF7B1FA2),
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ====================================================
                    // GET DIRECTIONS
                    // ====================================================

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child:
                          ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(
                            sheetContext,
                          );

                          _openDirections(shop);
                        },
                        icon: const Icon(
                          Icons.directions,
                        ),
                        label: const Text(
                          'Get Directions',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(
    IconData icon,
    String text,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 0),

        Icon(
          icon,
          size: 21,
          color: Color(0xFF1976D2),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DISTANCE
  // ============================================================

  String _formatDistance(
    double meters,
  ) {
    if (meters < 1000) {
      return '${meters.round()} m away';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }

  // ============================================================
  // DIRECTION SHOP DISTANCE
  // ============================================================

  String _formatDirectionDistance(
    Map<String, dynamic> shop,
  ) {
    final double distance =
        _getDouble(
              shop['_directionDistance'],
            ) ??
            _getDouble(
              shop['_distance'],
            ) ??
            0;

    if (distance < 1000) {
      return '${distance.round()} m';
    }

    return '${(distance / 1000).toStringAsFixed(1)} km';
  }

  // ============================================================
  // DIRECTIONS
  // ============================================================

  void _openDirections(
    Map<String, dynamic> shop,
  ) {
    if (!_directionFilterEnabled) {
      _showMessage(
        'Please turn ON Direction first.',
      );
      return;
    }

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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopNavigationScreen(
          shop: shop,
        ),
      ),
    );
  }

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

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
        16,
      );
    } catch (_) {}

    _showMessage(
      'Moved to your current location.',
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

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

  // ============================================================
  // DOUBLE VALUE
  // ============================================================

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

  // ============================================================
  // CATEGORY COLOR
  // ============================================================

  Color _getCategoryColor(
    dynamic category,
  ) {
    final String value =
        category.toString().trim().toLowerCase();

    switch (value) {
      case 'restaurant':
      case 'resturant':
        return Colors.red;

      case 'bakery':
        return Colors.brown;

      case 'pharmacy':
        return Colors.green;

      case 'hospital':
        return Colors.redAccent;

      case 'clinic':
        return Colors.teal;

      case 'supermarket':
        return Colors.deepPurple;

      case 'grocery':
      case 'grocery store':
      case 'grocery_shop':
        return Colors.orange;

      case 'mobile':
      case 'mobile shop':
      case 'mobile_shop':
        return Colors.blue;

      case 'clothing':
      case 'clothes':
      case 'dress':
      case 'dresses':
        return Colors.pink;

      case 'electronics':
        return Colors.indigo;

      case 'hardware':
        return Colors.blueGrey;

      case 'hotel':
        return Colors.amber.shade800;

      case 'mall':
        return Colors.purple;

      case 'guest_house':
      case 'guest house':
        return Colors.cyan;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // CATEGORY ICON
  // ============================================================

  IconData _getCategoryIcon(
    dynamic category,
  ) {
    final String value =
        category.toString().trim().toLowerCase();

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

      case 'grocery':
      case 'grocery store':
      case 'grocery_shop':
        return Icons.shopping_cart;

      case 'mobile':
      case 'mobile shop':
      case 'mobile_shop':
        return Icons.phone_android;

      case 'clothing':
      case 'clothes':
      case 'dress':
      case 'dresses':
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
      case 'guest house':
        return Icons.house;

      default:
        return Icons.store;
    }
  }

  // ============================================================
  // BEARING
  // ============================================================

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
            math.cos(differenceLng);

    final double bearing =
        math.atan2(y, x) *
            180 /
            math.pi;

    return (bearing + 360) % 360;
  }

  double _degreesToRadians(
    double degrees,
  ) {
    return degrees * math.pi / 180;
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _onSearchChanged(
    String value,
  ) {
    _searchDebounce?.cancel();

    _searchDebounce =
        Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;

      _applyFilters();
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();

    _searchController.clear();

    _applyFilters();
  }

  // ============================================================
  // CATEGORY
  // ============================================================

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

  // ============================================================
  // SNACKBAR
  // ============================================================

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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final List<String> categories =
        _availableCategories();

    final bool hasSearchText =
        _searchController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: Stack(
          children: [
            // ==================================================
            // MAP
            // ==================================================

            Positioned.fill(
              child: _mapWidget ??
                  const ColoredBox(
                color: Colors.white,
              ),
            ),

            // ==================================================
            // SEARCH BAR
            // ==================================================

            Positioned(
              top: 15,
              left: 15,
              right: 15,
              child: Material(
                elevation: 5,
                borderRadius:
                    BorderRadius.circular(15),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 15,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(15),
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
                        color:
                            Color(0xFF1976D2),
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

            // ==================================================
            // CATEGORY FILTER
            // ==================================================

            Positioned(
              top: 75,
              left: 15,
              right: 15,
              child: SizedBox(
                height: 42,
                child:
                    ListView.separated(
                  scrollDirection:
                      Axis.horizontal,
                  itemCount:
                      categories.length,
                  separatorBuilder:
                      (_, index) =>
                          const SizedBox(
                    width: 8,
                  ),
                  itemBuilder:
                      (context, index) {
                    final String
                        category =
                        categories[index];

                    final bool selected =
                        _selectedCategory ==
                            category;

                    return FilterChip(
                      selected:
                          selected,
                      label:
                          Text(category),
                      onSelected:
                          (_) {
                        _selectCategory(
                          category,
                        );
                      },
                      backgroundColor:
                          Colors.white,
                      selectedColor:
                          const Color(
                        0xFF1976D2,
                      ).withValues(
                        alpha: 0.18,
                      ),
                      checkmarkColor:
                          const Color(
                        0xFF1976D2,
                      ),
                    );
                  },
                ),
              ),
            ),

            // ==================================================
            // SHOP COUNT + DIRECTION
            // ==================================================

            Positioned(
              top: 125,
              left: 18,
              right: 18,
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                      boxShadow:
                          const [
                        BoxShadow(
                          color:
                              Colors.black26,
                          blurRadius: 5,
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
                    behavior:
                        HitTestBehavior.translucent,
                    onTap: () {
                      debugPrint(
                        'DIRECTION TAP TEST',
                      );

                      _toggleDirectionFilter();
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
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
                          20,
                        ),
                        boxShadow:
                            const [
                          BoxShadow(
                            color:
                                Colors.black26,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.explore,
                            size: 18,
                            color:
                                _directionFilterEnabled
                                    ? Colors.white
                                    : const Color(
                                        0xFF1976D2,
                                      ),
                          ),

                          const SizedBox(
                            width: 5,
                          ),

                          Text(
                            _directionFilterEnabled
                                ? 'Direction ON'
                                : 'Direction',
                            style:
                                TextStyle(
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

            // ==================================================
            // DIRECTION SHOP LIST
            // ==================================================

            if (_directionFilterEnabled)
              Positioned(
                top: 175,
                left: 15,
                right: 15,
                child: _buildDirectionShopList(),
              ),

            // ==================================================
            // MAP LEGEND
            // ==================================================

            Positioned(
              left: 15,
              bottom: 95,
              child: Container(
                padding:
                    const EdgeInsets.all(
                  10,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                  boxShadow:
                      const [
                    BoxShadow(
                      color:
                          Colors.black26,
                      blurRadius: 5,
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
                          size: 12,
                          color:
                              Color(0xFF1976D2),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Owner Shop',
                        ),
                      ],
                    ),

                    SizedBox(height: 5),

                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 12,
                          color:
                              Color(0xFF7B1FA2),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Offer Available',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ==================================================
            // CURRENT LOCATION
            // ==================================================

            Positioned(
              right: 15,
              bottom: 95,
              child: FloatingActionButton(
                heroTag:
                    'currentLocationButton',
                backgroundColor:
                    Colors.white,
                foregroundColor:
                    const Color(0xFF1976D2),
                onPressed:
                    _goToCurrentLocation,
                child: const Icon(
                  Icons.my_location,
                ),
              ),
            ),

            // ==================================================
            // LOADING
            // ==================================================

            if (_isLoading)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: Container(
                    color: Colors.white
                        .withValues(
                      alpha: 0.55,
                    ),
                    child: const Center(
                      child:
                          CircularProgressIndicator(
                        color:
                            Color(0xFF1976D2),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),

      // ========================================================
      // COMMON BOTTOM NAVIGATION
      // ========================================================

      bottomNavigationBar:
          MainBottomNavigation(
        currentIndex:
            _selectedIndex,
        onTap:
            _onNavigationChanged,
      ),
    );
  }

  // ============================================================
  // DIRECTION SHOP LIST UI
  // ============================================================

  Widget _buildDirectionShopList() {
    return Material(
      elevation: 7,
      borderRadius:
          BorderRadius.circular(16),
      color: Colors.white,
      child: Container(
        constraints:
            const BoxConstraints(
          maxHeight: 245,
        ),
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: _directionShops.isEmpty
            ? Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.explore,
                      color:
                          Color(0xFF1976D2),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Text(
                        'No shops found ahead in your current direction.',
                        style:
                            TextStyle(
                          color:
                              Colors.grey.shade700,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      14,
                      12,
                      14,
                      8,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.navigation,
                          size: 20,
                          color:
                              Color(0xFF1976D2),
                        ),
                        const SizedBox(
                          width: 7,
                        ),
                        const Expanded(
                          child: Text(
                            'Shops ahead',
                            style:
                                TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${_directionShops.length}',
                          style:
                              const TextStyle(
                            color:
                                Color(0xFF1976D2),
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding:
                          const EdgeInsets.only(
                        bottom: 8,
                      ),
                      itemCount:
                          _directionShops.length,
                      separatorBuilder:
                          (_, index) =>
                              Divider(
                        height: 1,
                        color:
                            Colors.grey.shade200,
                      ),
                      itemBuilder:
                          (context, index) {
                        final Map<String, dynamic>
                            shop =
                            _directionShops[index];

                        final String name =
                            (shop['shop_name'] ??
                                    shop['name'] ??
                                    'Unknown Shop')
                                .toString();

                        final String category =
                            (shop['category'] ??
                                    'Shop')
                                .toString();

                        final String shopId =
                            (shop['id'] ??
                                    shop['_id'] ??
                                    '')
                                .toString();

                        final bool hasOffer =
                            _offerShopIds.contains(
                          shopId,
                        );

                        return InkWell(
                          onTap: () {
                            _showShopDetails(
                              shop,
                            );
                          },
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor:
                                      hasOffer
                                          ? const Color(
                                              0xFF7B1FA2,
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
                                    size: 20,
                                  ),
                                ),

                                const SizedBox(
                                  width: 11,
                                ),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight.w700,
                                          fontSize:
                                              14,
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 3,
                                      ),

                                      Text(
                                        category,
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style:
                                            TextStyle(
                                          fontSize:
                                              12,
                                          color:
                                              Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(
                                  width: 8,
                                ),

                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _formatDirectionDistance(
                                        shop,
                                      ),
                                      style:
                                          const TextStyle(
                                        color:
                                            Color(0xFF1976D2),
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize:
                                            14,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 2,
                                    ),

                                    const Icon(
                                      Icons.chevron_right,
                                      size: 20,
                                      color:
                                          Colors.grey,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}