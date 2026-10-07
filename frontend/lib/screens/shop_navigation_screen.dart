import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class ShopNavigationScreen extends StatefulWidget {
  final Map<String, dynamic> shop;

  const ShopNavigationScreen({
    super.key,
    required this.shop,
  });

  @override
  State<ShopNavigationScreen> createState() =>
      _ShopNavigationScreenState();
}

class _ShopNavigationScreenState
    extends State<ShopNavigationScreen> {
  final MapController _mapController = MapController();

  StreamSubscription<Position>? _positionSubscription;

  LatLng? _currentLocation;

  List<LatLng> _routePoints = <LatLng>[];

  List<Map<String, dynamic>> _routeSteps =
      <Map<String, dynamic>>[];

  double _remainingDistance = 0;
  double _remainingDuration = 0;

  double _currentHeading = 0;
  double _movementHeading = 0;

  double _routeDuration = 0;

  int _currentStepIndex = 0;

  bool _loading = true;
  bool _loadingRoute = false;
  bool _locationError = false;
  bool _rerouting = false;
  bool _destinationReached = false;
  bool _routeError = false;

  DateTime? _lastRouteRequest;

  List<Map<String, dynamic>> _availableRoutes =
      <Map<String, dynamic>>[];

  int _selectedRouteIndex = 0;

  bool _routeSelectionVisible = false;

  bool _routeSelectionRequired = false;

  // Keeps navigation progress from moving backward because
  // of normal GPS noise.
  double _progressDistanceFromStart = 0;

  // Walking speed used for ETA.
  // 5 km/h = normal walking speed.
  static const double _walkingSpeedMetersPerSecond =
      5000 / 3600;

  double? get _shopLatitude {
    return _getDouble(widget.shop['latitude']);
  }

  double? get _shopLongitude {
    return _getDouble(widget.shop['longitude']);
  }

  String get _shopName {
    return (
      widget.shop['shop_name'] ??
          widget.shop['name'] ??
          'Shop'
    ).toString();
  }

  @override
  void initState() {
    super.initState();
    _startNavigation();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startNavigation() async {
    if (_shopLatitude == null ||
        _shopLongitude == null) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _locationError = true;
      });

      return;
    }

    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        setState(() {
          _loading = false;
          _locationError = true;
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
          permission ==
              LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          _loading = false;
          _locationError = true;
        });

        _showMessage(
          'Location permission is required.',
        );

        return;
      }

      await _positionSubscription?.cancel();

      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await _updateNavigation(position);

      _positionSubscription =
          Geolocator.getPositionStream(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 2,
        ),
      ).listen(
        _updateNavigation,
        onError: (Object error) {
          debugPrint(
            'NAVIGATION GPS ERROR => $error',
          );
        },
      );
    } catch (e) {
      debugPrint(
        'NAVIGATION ERROR => $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
        _locationError = true;
      });

      _showMessage(
        'Unable to get current location.',
      );
    }
  }

  Future<void> _updateNavigation(
    Position position,
  ) async {
    if (!mounted) return;

    if (position.accuracy > 100) {
      debugPrint(
        'IGNORING GPS ACCURACY => '
        '${position.accuracy}',
      );

      return;
    }

    final LatLng current = LatLng(
      position.latitude,
      position.longitude,
    );

    if (_currentLocation != null) {
      final double movementDistance =
          Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        current.latitude,
        current.longitude,
      );

      if (movementDistance >= 3) {
        _movementHeading = _calculateBearing(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          current.latitude,
          current.longitude,
        );
      }
    }

    double heading = _currentHeading;

    if (position.heading >= 0 &&
        position.heading.isFinite) {
      heading = position.heading;
    }

    if (_currentLocation != null) {
      final double movementDistance =
          Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        current.latitude,
        current.longitude,
      );

      if (movementDistance >= 3) {
        heading = _movementHeading;
      }
    }

    if (mounted) {
      setState(() {
        _currentLocation = current;
        _currentHeading = heading;
        _loading = false;
        _locationError = false;
      });
    }

    final double destinationDistance =
        _distanceToDestination(current);

    if (destinationDistance <= 20) {
      if (!_destinationReached) {
        if (mounted) {
          setState(() {
            _remainingDistance = 0;
            _remainingDuration = 0;
            _destinationReached = true;
            _progressDistanceFromStart =
                _routeTotalDistance(_routePoints);
          });
        }

        _showMessage(
          'You have reached $_shopName.',
        );
      }

      try {
        _mapController.move(
          current,
          18,
        );
      } catch (_) {}

      return;
    }

    if (_routePoints.isEmpty &&
        !_loadingRoute) {
      if (_routeSelectionRequired) {
        try {
          _mapController.move(
            current,
            17,
          );
        } catch (_) {}

        return;
      }

      await _loadRoute(
        current.latitude,
        current.longitude,
      );

      return;
    }

    if (_routePoints.isNotEmpty &&
        !_routeSelectionRequired) {
      final double routeDistance =
          _distanceToRoute(
        current,
        _routePoints,
      );

      debugPrint(
        'DISTANCE FROM ROUTE => '
        '${routeDistance.toStringAsFixed(1)} m',
      );

      if (routeDistance > 60 &&
          !_loadingRoute &&
          !_rerouting) {
        await _reroute(current);
        return;
      }
    }

    if (!_routeSelectionRequired &&
        _routePoints.isNotEmpty) {
      _updateRouteProgress(current);
    }

    try {
      _mapController.move(
        current,
        17,
      );
    } catch (_) {}
  }

  // ============================================================
  // LOAD ROUTES
  // ============================================================

  Future<void> _loadRoute(
    double latitude,
    double longitude,
  ) async {
    if (_shopLatitude == null ||
        _shopLongitude == null) {
      return;
    }

    if (_loadingRoute) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _loadingRoute = true;
      _routeError = false;
      _routeSelectionVisible = false;
      _routeSelectionRequired = false;
      _selectedRouteIndex = 0;
      _progressDistanceFromStart = 0;
    });

    try {
      final String url =
          'https://router.project-osrm.org'
          '/route/v1/driving/'
          '$longitude,$latitude;'
          '${_shopLongitude!},'
          '${_shopLatitude!}'
          '?overview=full'
          '&geometries=geojson'
          '&steps=true'
          '&alternatives=true';

      debugPrint(
        'ROUTE REQUEST => $url',
      );

      final http.Response response =
          await http
              .get(
        Uri.parse(url),
        headers: const {
          'User-Agent':
              'NearbyAds/1.0',
        },
      )
              .timeout(
        const Duration(
          seconds: 20,
        ),
      );

      debugPrint(
        'ROUTE STATUS => '
        '${response.statusCode}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Routing HTTP ${response.statusCode}',
        );
      }

      final Map<String, dynamic> data =
          jsonDecode(
        response.body,
      ) as Map<String, dynamic>;

      debugPrint(
        'ROUTE CODE => '
        '${data['code']}',
      );

      if (data['code'] != 'Ok') {
        throw Exception(
          'Route unavailable',
        );
      }

      final List<dynamic> routes =
          data['routes'] is List
              ? data['routes'] as List<dynamic>
              : <dynamic>[];

      debugPrint(
        'RAW ROUTE COUNT => '
        '${routes.length}',
      );

      if (routes.isEmpty) {
        throw Exception(
          'No route found',
        );
      }

      final List<Map<String, dynamic>>
          parsedRoutes =
          <Map<String, dynamic>>[];

      for (final dynamic rawRoute
          in routes) {
        if (rawRoute is! Map) {
          continue;
        }

        final Map<String, dynamic>
            route =
            Map<String, dynamic>.from(
          rawRoute,
        );

        final Map<String, dynamic>
            geometry =
            route['geometry'] is Map
                ? Map<String, dynamic>.from(
                    route['geometry'] as Map,
                  )
                : <String, dynamic>{};

        final List<dynamic>
            coordinates =
            geometry['coordinates'] is List
                ? geometry['coordinates']
                    as List<dynamic>
                : <dynamic>[];

        final List<LatLng> points =
            <LatLng>[];

        for (final dynamic coordinate
            in coordinates) {
          if (coordinate is! List ||
              coordinate.length < 2) {
            continue;
          }

          final dynamic rawLongitude =
              coordinate[0];

          final dynamic rawLatitude =
              coordinate[1];

          if (rawLongitude is! num ||
              rawLatitude is! num) {
            continue;
          }

          points.add(
            LatLng(
              rawLatitude.toDouble(),
              rawLongitude.toDouble(),
            ),
          );
        }

        if (points.length < 2) {
          continue;
        }

        final List<Map<String, dynamic>>
            steps =
            <Map<String, dynamic>>[];

        final List<dynamic> legs =
            route['legs'] is List
                ? route['legs'] as List<dynamic>
                : <dynamic>[];

        if (legs.isNotEmpty &&
            legs.first is Map) {
          final Map<String, dynamic>
              leg =
              Map<String, dynamic>.from(
            legs.first as Map,
          );

          final List<dynamic>
              rawSteps =
              leg['steps'] is List
                  ? leg['steps']
                      as List<dynamic>
                  : <dynamic>[];

          for (final dynamic rawStep
              in rawSteps) {
            if (rawStep is Map) {
              steps.add(
                Map<String, dynamic>.from(
                  rawStep,
                ),
              );
            }
          }
        }

        final double osrmDuration =
            (route['duration'] as num?)
                    ?.toDouble() ??
                0;

        final double distance =
            (route['distance'] as num?)
                    ?.toDouble() ??
                _routeTotalDistance(
                  points,
                );

        // Always use walking time for display.
        final double walkingDuration =
            _walkingDurationForDistance(
          distance,
        );

        parsedRoutes.add(
          <String, dynamic>{
            'points': points,
            'steps': steps,

            // Keep OSRM duration internally if needed.
            'osrmDuration':
                osrmDuration,

            // Display duration = walking duration.
            'duration':
                walkingDuration,

            'distance': distance,
          },
        );
      }

      if (parsedRoutes.isEmpty) {
        throw Exception(
          'Route geometry is empty',
        );
      }

      if (parsedRoutes.length > 3) {
        parsedRoutes.removeRange(
          3,
          parsedRoutes.length,
        );
      }

      if (!mounted) return;

      // IMPORTANT:
      // If OSRM gives multiple routes, do NOT automatically
      // select one. User must choose.
      if (parsedRoutes.length > 1) {
        setState(() {
          _availableRoutes =
              parsedRoutes;

          _loadingRoute = false;
          _routeError = false;
          _rerouting = false;
          _destinationReached = false;

          _selectedRouteIndex = -1;

          _routeSelectionRequired = true;
          _routeSelectionVisible = true;

          _routePoints = <LatLng>[];
          _routeSteps =
              <Map<String, dynamic>>[];

          _routeDuration = 0;
          _remainingDuration = 0;
          _currentStepIndex = 0;
          _remainingDistance = 0;

          _progressDistanceFromStart = 0;
        });

        _lastRouteRequest =
            DateTime.now();

        _fitAllRoutesOnMap();

        debugPrint(
          'MULTIPLE ROUTES FOUND => '
          '${parsedRoutes.length}',
        );

        for (int i = 0;
            i < parsedRoutes.length;
            i++) {
          debugPrint(
            'ROUTE ${i + 1} => '
            '${_formatDistance(
              (parsedRoutes[i]['distance']
                      as num)
                  .toDouble(),
            )} / WALK '
            '${_formatDuration(
              (parsedRoutes[i]['duration']
                      as num)
                  .toDouble(),
            )}',
          );
        }

        return;
      }

      // Only one real route was returned by OSRM.
      // We cannot create fake alternative routes.
      setState(() {
        _availableRoutes =
            parsedRoutes;

        _loadingRoute = false;
        _routeError = false;
        _rerouting = false;
        _destinationReached = false;

        _selectedRouteIndex = 0;

        _routeSelectionRequired = false;
        _routeSelectionVisible = false;

        _progressDistanceFromStart = 0;
      });

      _applySelectedRoute(
        0,
        rebuild: true,
      );

      _lastRouteRequest =
          DateTime.now();

      if (_currentLocation != null) {
        _updateRouteProgress(
          _currentLocation!,
        );
      }

      _fitSelectedRouteOnMap();

      debugPrint(
        'ONLY ONE REAL ROUTE FOUND => '
        'OSRM did not return alternatives.',
      );
    } catch (e) {
      debugPrint(
        'ROUTE ERROR => $e',
      );

      if (!mounted) return;

      setState(() {
        _loadingRoute = false;
        _rerouting = false;
        _routeError = true;
        _routeSelectionRequired = false;
        _routeSelectionVisible = false;
      });

      _showMessage(
        'Unable to load route.',
      );
    }
  }

  // ============================================================
  // WALKING DURATION
  // ============================================================

  double _walkingDurationForDistance(
    double meters,
  ) {
    if (meters <= 0 ||
        !meters.isFinite) {
      return 0;
    }

    return meters /
        _walkingSpeedMetersPerSecond;
  }

  // ============================================================
  // APPLY SELECTED ROUTE
  // ============================================================

  void _applySelectedRoute(
    int index, {
    bool rebuild = true,
  }) {
    if (_availableRoutes.isEmpty) {
      return;
    }

    if (index < 0 ||
        index >= _availableRoutes.length) {
      return;
    }

    final Map<String, dynamic>
        selected =
        _availableRoutes[index];

    final List<LatLng> points =
        selected['points'] is List<LatLng>
            ? List<LatLng>.from(
                selected['points']
                    as List<LatLng>,
              )
            : <LatLng>[];

    final List<Map<String, dynamic>>
        steps =
        <Map<String, dynamic>>[];

    final dynamic rawSteps =
        selected['steps'];

    if (rawSteps is List) {
      for (final dynamic item
          in rawSteps) {
        if (item is Map) {
          steps.add(
            Map<String, dynamic>.from(
              item,
            ),
          );
        }
      }
    }

    final double distance =
        (selected['distance'] as num?)
                ?.toDouble() ??
            _routeTotalDistance(
              points,
            );

    final double walkingDuration =
        _walkingDurationForDistance(
      distance,
    );

    _selectedRouteIndex = index;

    _progressDistanceFromStart = 0;

    if (rebuild && mounted) {
      setState(() {
        _routePoints = points;
        _routeSteps = steps;

        _routeDuration =
            walkingDuration;

        _remainingDuration =
            walkingDuration;

        _currentStepIndex =
            _findFirstNavigationStep(
          steps,
        );

        _routeSelectionRequired = false;
        _routeSelectionVisible = false;

        _progressDistanceFromStart = 0;
      });
    } else {
      _routePoints = points;
      _routeSteps = steps;

      _routeDuration =
          walkingDuration;

      _remainingDuration =
          walkingDuration;

      _currentStepIndex =
          _findFirstNavigationStep(
        steps,
      );

      _routeSelectionRequired = false;
      _routeSelectionVisible = false;

      _progressDistanceFromStart = 0;
    }

    if (_currentLocation != null) {
      _updateRouteProgress(
        _currentLocation!,
      );
    }
  }

  void _selectRoute(
    int index,
  ) {
    if (index < 0 ||
        index >= _availableRoutes.length) {
      return;
    }

    _applySelectedRoute(
      index,
      rebuild: true,
    );

    if (!mounted) return;

    setState(() {
      _selectedRouteIndex = index;
      _routeSelectionRequired = false;
      _routeSelectionVisible = false;
      _routeError = false;
      _destinationReached = false;
    });

    _showMessage(
      'Route ${index + 1} selected.',
    );

    _fitSelectedRouteOnMap();

    if (_currentLocation != null) {
      _updateRouteProgress(
        _currentLocation!,
      );
    }
  }

  void _fitSelectedRouteOnMap() {
    if (_routePoints.isEmpty) {
      return;
    }

    _fitRouteOnMap(
      _routePoints,
    );
  }

  void _fitAllRoutesOnMap() {
    final List<LatLng> allPoints =
        <LatLng>[];

    for (final Map<String, dynamic>
        route in _availableRoutes) {
      final dynamic points =
          route['points'];

      if (points is List<LatLng>) {
        allPoints.addAll(points);
      }
    }

    if (allPoints.isEmpty) {
      return;
    }

    try {
      final LatLngBounds bounds =
          LatLngBounds.fromPoints(
        allPoints,
      );

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding:
              const EdgeInsets.only(
            top: 260,
            bottom: 220,
            left: 40,
            right: 40,
          ),
          maxZoom: 17,
        ),
      );
    } catch (e) {
      debugPrint(
        'FIT ALL ROUTES ERROR => $e',
      );
    }
  }

  void _fitRouteOnMap(
    List<LatLng> points,
  ) {
    if (points.isEmpty) {
      return;
    }

    try {
      final LatLngBounds bounds =
          LatLngBounds.fromPoints(
        points,
      );

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding:
              const EdgeInsets.only(
            top: 170,
            bottom: 100,
            left: 40,
            right: 40,
          ),
          maxZoom: 17,
        ),
      );
    } catch (e) {
      debugPrint(
        'FIT ROUTE ERROR => $e',
      );
    }
  }

  // ============================================================
  // REROUTE
  // ============================================================

  Future<void> _reroute(
    LatLng current,
  ) async {
    if (_loadingRoute ||
        _rerouting) {
      return;
    }

    final DateTime now =
        DateTime.now();

    if (_lastRouteRequest != null) {
      final Duration difference =
          now.difference(
        _lastRouteRequest!,
      );

      if (difference.inSeconds < 5) {
        return;
      }
    }

    if (!mounted) return;

    setState(() {
      _rerouting = true;
      _progressDistanceFromStart = 0;
    });

    _showMessage(
      'You are off route. Finding a new route...',
    );

    await _loadRoute(
      current.latitude,
      current.longitude,
    );
  }

  // ============================================================
  // ROUTE PROGRESS + WALKING TIME
  // ============================================================

  void _updateRouteProgress(
    LatLng current,
  ) {
    if (_destinationReached ||
        _routeSelectionRequired ||
        _routePoints.length < 2) {
      return;
    }

    final _RouteProjection projection =
        _findBestRouteProjection(
      current,
      _routePoints,
    );

    final double totalRouteDistance =
        projection.totalDistance;

    if (totalRouteDistance <= 0) {
      return;
    }

    double progressDistance =
        projection.distanceFromStart;

    if (progressDistance <
        _progressDistanceFromStart) {
      progressDistance =
          _progressDistanceFromStart;
    }

    progressDistance =
        progressDistance.clamp(
      0.0,
      totalRouteDistance,
    );

    _progressDistanceFromStart =
        progressDistance;

    final double remainingDistance =
        totalRouteDistance -
            progressDistance;

    if (remainingDistance <= 20) {
      if (!_destinationReached) {
        if (mounted) {
          setState(() {
            _remainingDistance = 0;
            _remainingDuration = 0;
            _destinationReached = true;
          });
        }

        _showMessage(
          'You have reached $_shopName.',
        );
      }

      return;
    }

    // Walking ETA based directly on actual
    // remaining route distance.
    final double remainingDuration =
        _walkingDurationForDistance(
      remainingDistance,
    );

    if (mounted) {
      setState(() {
        _remainingDistance =
            remainingDistance;

        _remainingDuration =
            remainingDuration;

        _destinationReached = false;
      });
    }

    _updateCurrentStep(current);
  }

  // ============================================================
  // ACTUAL REMAINING ROAD DISTANCE
  // ============================================================

  _RouteProjection _findBestRouteProjection(
    LatLng current,
    List<LatLng> route,
  ) {
    if (route.length < 2) {
      return const _RouteProjection(
        distanceFromStart: 0,
        distanceToPoint: double.infinity,
        totalDistance: 0,
      );
    }

    double totalDistance = 0;

    for (int i = 0;
        i < route.length - 1;
        i++) {
      totalDistance +=
          Geolocator.distanceBetween(
        route[i].latitude,
        route[i].longitude,
        route[i + 1].latitude,
        route[i + 1].longitude,
      );
    }

    double bestDistance =
        double.infinity;

    double bestDistanceFromStart =
        _progressDistanceFromStart;

    double distanceFromStart = 0;

    for (int i = 0;
        i < route.length - 1;
        i++) {
      final LatLng start = route[i];
      final LatLng end = route[i + 1];

      final double segmentDistance =
          Geolocator.distanceBetween(
        start.latitude,
        start.longitude,
        end.latitude,
        end.longitude,
      );

      if (segmentDistance <= 0) {
        continue;
      }

      final double ratio =
          _projectionRatio(
        current,
        start,
        end,
      );

      final double projectedLat =
          start.latitude +
              (end.latitude -
                      start.latitude) *
                  ratio;

      final double projectedLng =
          start.longitude +
              (end.longitude -
                      start.longitude) *
                  ratio;

      final double distanceToProjection =
          Geolocator.distanceBetween(
        current.latitude,
        current.longitude,
        projectedLat,
        projectedLng,
      );

      final double candidateDistance =
          distanceFromStart +
              segmentDistance * ratio;

      final bool acceptableProgress =
          candidateDistance >=
              (_progressDistanceFromStart -
                  30);

      if (acceptableProgress &&
          distanceToProjection <
              bestDistance) {
        bestDistance =
            distanceToProjection;

        bestDistanceFromStart =
            candidateDistance;
      }

      distanceFromStart +=
          segmentDistance;
    }

    if (!bestDistance.isFinite) {
      bestDistanceFromStart =
          _progressDistanceFromStart;
    }

    return _RouteProjection(
      distanceFromStart:
          bestDistanceFromStart.clamp(
        0.0,
        totalDistance,
      ),
      distanceToPoint:
          bestDistance,
      totalDistance:
          totalDistance,
    );
  }

  double _remainingRouteDistance(
    LatLng current,
    List<LatLng> route,
  ) {
    final _RouteProjection projection =
        _findBestRouteProjection(
      current,
      route,
    );

    final double remaining =
        projection.totalDistance -
            projection.distanceFromStart;

    return remaining.clamp(
      0.0,
      projection.totalDistance,
    );
  }

  double _projectionRatio(
    LatLng point,
    LatLng start,
    LatLng end,
  ) {
    const double earthRadius =
        6371000;

    final double referenceLat =
        _degreesToRadians(
      (start.latitude +
              end.latitude +
              point.latitude) /
          3,
    );

    final double cosLat =
        math.cos(referenceLat);

    final double startX =
        _degreesToRadians(
              start.longitude,
            ) *
            earthRadius *
            cosLat;

    final double startY =
        _degreesToRadians(
              start.latitude,
            ) *
            earthRadius;

    final double endX =
        _degreesToRadians(
              end.longitude,
            ) *
            earthRadius *
            cosLat;

    final double endY =
        _degreesToRadians(
              end.latitude,
            ) *
            earthRadius;

    final double pointX =
        _degreesToRadians(
              point.longitude,
            ) *
            earthRadius *
            cosLat;

    final double pointY =
        _degreesToRadians(
              point.latitude,
            ) *
            earthRadius;

    final double dx =
        endX - startX;

    final double dy =
        endY - startY;

    final double lengthSquared =
        dx * dx + dy * dy;

    if (lengthSquared <= 0) {
      return 0;
    }

    double ratio =
        ((pointX - startX) * dx +
                (pointY - startY) * dy) /
            lengthSquared;

    return ratio.clamp(
      0.0,
      1.0,
    );
  }

  // ============================================================
  // REMAINING WALKING TIME
  // ============================================================

  double _estimateRemainingDuration(
    double remainingMeters,
    double totalRouteDistance,
  ) {
    if (remainingMeters <= 0) {
      return 0;
    }

    return _walkingDurationForDistance(
      remainingMeters,
    );
  }

  // ============================================================
  // CURRENT NAVIGATION STEP
  // ============================================================

  void _updateCurrentStep(
    LatLng current,
  ) {
    if (_routeSteps.isEmpty) {
      return;
    }

    int stepIndex =
        _currentStepIndex;

    if (stepIndex < 0) {
      stepIndex = 0;
    }

    if (stepIndex >=
        _routeSteps.length) {
      stepIndex =
          _routeSteps.length - 1;
    }

    while (stepIndex <
            _routeSteps.length - 1 &&
        _isStepReached(
          current,
          _routeSteps[stepIndex],
        )) {
      stepIndex++;
    }

    if (mounted &&
        stepIndex !=
            _currentStepIndex) {
      setState(() {
        _currentStepIndex =
            stepIndex;
      });
    }
  }

  bool _isStepReached(
    LatLng current,
    Map<String, dynamic> step,
  ) {
    final Map<String, dynamic>
        maneuver =
        step['maneuver'] is Map
            ? Map<String, dynamic>.from(
                step['maneuver'] as Map,
              )
            : <String, dynamic>{};

    final List<dynamic>? location =
        maneuver['location'] is List
            ? maneuver['location']
                as List<dynamic>
            : null;

    if (location == null ||
        location.length < 2 ||
        location[0] is! num ||
        location[1] is! num) {
      return false;
    }

    final double longitude =
        (location[0] as num)
            .toDouble();

    final double latitude =
        (location[1] as num)
            .toDouble();

    final double distance =
        Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      latitude,
      longitude,
    );

    return distance <= 35;
  }

  int _findFirstNavigationStep(
    List<Map<String, dynamic>> steps,
  ) {
    for (int i = 0;
        i < steps.length;
        i++) {
      final Map<String, dynamic>
          maneuver =
          steps[i]['maneuver'] is Map
              ? Map<String, dynamic>.from(
                  steps[i]['maneuver'] as Map,
                )
              : <String, dynamic>{};

      final String type =
          (maneuver['type'] ?? '')
              .toString();

      if (type != 'depart') {
        return i;
      }
    }

    return 0;
  }

  String _getCurrentInstruction() {
    if (_routeSelectionRequired) {
      return 'Please select a route to start navigation.';
    }

    if (_destinationReached) {
      return 'Destination reached';
    }

    if (_loadingRoute) {
      return 'Finding route...';
    }

    if (_routeError) {
      return 'Route unavailable';
    }

    if (_routeSteps.isEmpty) {
      return 'Continue to $_shopName';
    }

    int index =
        _currentStepIndex;

    if (index < 0) {
      index = 0;
    }

    if (index >=
        _routeSteps.length) {
      index =
          _routeSteps.length - 1;
    }

    final Map<String, dynamic>
        step =
        _routeSteps[index];

    final Map<String, dynamic>
        maneuver =
        step['maneuver'] is Map
            ? Map<String, dynamic>.from(
                step['maneuver'] as Map,
              )
            : <String, dynamic>{};

    final String type =
        (maneuver['type'] ?? '')
            .toString();

    final String modifier =
        (maneuver['modifier'] ?? '')
            .toString();

    final String name =
        (step['name'] ?? '')
            .toString()
            .trim();

    String instruction =
        _maneuverText(
      type,
      modifier,
    );

    if (name.isNotEmpty &&
        type != 'arrive') {
      instruction =
          '$instruction on $name';
    }

    return instruction;
  }

  String _maneuverText(
    String type,
    String modifier,
  ) {
    switch (type) {
      case 'depart':
        return 'Start';

      case 'arrive':
        return 'You have arrived';

      case 'turn':
        if (modifier == 'left') {
          return 'Turn left';
        }

        if (modifier == 'right') {
          return 'Turn right';
        }

        if (modifier ==
            'slight left') {
          return 'Slight left';
        }

        if (modifier ==
            'slight right') {
          return 'Slight right';
        }

        if (modifier ==
            'sharp left') {
          return 'Sharp left';
        }

        if (modifier ==
            'sharp right') {
          return 'Sharp right';
        }

        return 'Go straight';

      case 'new name':
        return 'Continue';

      case 'continue':
        if (modifier == 'left') {
          return 'Continue left';
        }

        if (modifier == 'right') {
          return 'Continue right';
        }

        return 'Continue straight';

      case 'merge':
        return 'Merge';

      case 'fork':
        if (modifier == 'left') {
          return 'Keep left';
        }

        if (modifier == 'right') {
          return 'Keep right';
        }

        return 'Keep straight';

      case 'on ramp':
        return 'Take the ramp';

      case 'off ramp':
        return 'Take the exit ramp';

      case 'roundabout':
      case 'rotary':
        return 'Enter roundabout';

      case 'roundabout turn':
      case 'exit roundabout':
        return 'Exit roundabout';

      case 'uturn':
        return 'Make a U-turn';

      case 'end of road':
        if (modifier == 'left') {
          return 'Turn left at the end of the road';
        }

        if (modifier == 'right') {
          return 'Turn right at the end of the road';
        }

        return 'Continue at the end of the road';

      default:
        return 'Continue';
    }
  }

  double _distanceToDestination(
    LatLng current,
  ) {
    if (_shopLatitude == null ||
        _shopLongitude == null) {
      return 0;
    }

    return Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      _shopLatitude!,
      _shopLongitude!,
    );
  }

  double _distanceToRoute(
    LatLng point,
    List<LatLng> route,
  ) {
    if (route.isEmpty) {
      return double.infinity;
    }

    if (route.length == 1) {
      return Geolocator.distanceBetween(
        point.latitude,
        point.longitude,
        route.first.latitude,
        route.first.longitude,
      );
    }

    double minimum =
        double.infinity;

    for (int i = 0;
        i < route.length - 1;
        i++) {
      final LatLng start =
          route[i];

      final LatLng end =
          route[i + 1];

      final double distance =
          _distanceToSegment(
        point,
        start,
        end,
      );

      if (distance < minimum) {
        minimum = distance;
      }
    }

    return minimum;
  }

  double _distanceToSegment(
    LatLng point,
    LatLng start,
    LatLng end,
  ) {
    const double earthRadius =
        6371000;

    final double referenceLat =
        _degreesToRadians(
      (start.latitude +
              end.latitude +
              point.latitude) /
          3,
    );

    final double cosLat =
        math.cos(referenceLat);

    final double startX =
        _degreesToRadians(
              start.longitude,
            ) *
            earthRadius *
            cosLat;

    final double startY =
        _degreesToRadians(
              start.latitude,
            ) *
            earthRadius;

    final double endX =
        _degreesToRadians(
              end.longitude,
            ) *
            earthRadius *
            cosLat;

    final double endY =
        _degreesToRadians(
              end.latitude,
            ) *
            earthRadius;

    final double pointX =
        _degreesToRadians(
              point.longitude,
            ) *
            earthRadius *
            cosLat;

    final double pointY =
        _degreesToRadians(
              point.latitude,
            ) *
            earthRadius;

    final double dx =
        endX - startX;

    final double dy =
        endY - startY;

    final double lengthSquared =
        dx * dx + dy * dy;

    if (lengthSquared <= 0) {
      return Geolocator.distanceBetween(
        point.latitude,
        point.longitude,
        start.latitude,
        start.longitude,
      );
    }

    double t =
        ((pointX - startX) * dx +
                (pointY - startY) * dy) /
            lengthSquared;

    t = t.clamp(
      0.0,
      1.0,
    );

    final double projectionX =
        startX + t * dx;

    final double projectionY =
        startY + t * dy;

    final double distance =
        math.sqrt(
      math.pow(
            pointX - projectionX,
            2,
          ) +
          math.pow(
            pointY - projectionY,
            2,
          ),
    );

    return distance;
  }

  double _routeTotalDistance(
    List<LatLng> points,
  ) {
    if (points.length < 2) {
      return 0;
    }

    double total = 0;

    for (int i = 0;
        i < points.length - 1;
        i++) {
      total +=
          Geolocator.distanceBetween(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }

    return total;
  }

  String _formatDistance(
    double meters,
  ) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatDuration(
    double seconds,
  ) {
    if (seconds <= 0 ||
        !seconds.isFinite) {
      return '< 1 min';
    }

    final int minutes =
        (seconds / 60).round();

    if (minutes < 1) {
      return '< 1 min';
    }

    if (minutes < 60) {
      return '$minutes min';
    }

    final int hours =
        minutes ~/ 60;

    final int remainingMinutes =
        minutes % 60;

    if (remainingMinutes == 0) {
      return '$hours hr';
    }

    return '$hours hr '
        '$remainingMinutes min';
  }

  String _routeTitle(
    int index,
  ) {
    if (index < 0 ||
        index >=
            _availableRoutes.length) {
      return 'Route';
    }

    if (index == 0) {
      return 'Best Route';
    }

    if (_availableRoutes.length >
        1) {
      final Map<String, dynamic>
          route =
          _availableRoutes[index];

      final double duration =
          (route['distance'] as num?)
                  ?.toDouble() ??
              0;

      final double bestDuration =
          (_availableRoutes.first[
                      'distance']
                  as num?)
              ?.toDouble() ??
          0;

      if (duration <
          bestDuration) {
        return 'Shorter Route';
      }
    }

    return 'Alternative Route';
  }

  Future<void> _retryRoute() async {
    if (_currentLocation == null) {
      await _startNavigation();
      return;
    }

    await _loadRoute(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
    );
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
    return degrees *
        math.pi /
        180;
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        duration:
            const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildRouteCard(
    int index,
  ) {
    final Map<String, dynamic>
        route =
        _availableRoutes[index];

    final double distance =
        (route['distance'] as num?)
                ?.toDouble() ??
            0;

    final double walkingDuration =
        _walkingDurationForDistance(
      distance,
    );

    final bool selected =
        index == _selectedRouteIndex;

    return GestureDetector(
      onTap: () {
        _selectRoute(index);
      },
      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 8,
        ),
        padding:
            const EdgeInsets.all(
          12,
        ),
        decoration:
            BoxDecoration(
          color: selected
              ? const Color(
                  0xFFE3F2FD,
                )
              : Colors.white,
          borderRadius:
              BorderRadius.circular(
            12,
          ),
          border: Border.all(
            color: selected
                ? const Color(
                    0xFF1976D2,
                  )
                : Colors.black12,
            width:
                selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration:
                  BoxDecoration(
                color: selected
                    ? const Color(
                        0xFF1976D2,
                      )
                    : Colors.grey.shade200,
                shape:
                    BoxShape.circle,
              ),
              child: Icon(
                selected
                    ? Icons.check
                    : Icons.alt_route,
                color: selected
                    ? Colors.white
                    : Colors.black54,
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    _routeTitle(index),
                    style:
                        const TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    '${_formatDistance(distance)} • '
                    'Walk ${_formatDuration(walkingDuration)}',
                    style:
                        const TextStyle(
                      fontSize: 13,
                      color:
                          Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.radio_button_checked,
                color:
                    Color(0xFF1976D2),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteSelectionPanel() {
    if (!_routeSelectionVisible ||
        _availableRoutes.length <= 1) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: Container(
        padding:
            const EdgeInsets.fromLTRB(
          14,
          12,
          14,
          10,
        ),
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Choose a route',
                    style:
                        TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                      _routeSelectionRequired
                          ? null
                          : () {
                              setState(() {
                                _routeSelectionVisible =
                                    false;
                              });
                            },
                  icon:
                      const Icon(
                    Icons.close,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 4,
            ),
            const Text(
              'Select the route you want to use for navigation.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            ...List.generate(
              _availableRoutes.length,
              (int index) {
                return _buildRouteCard(
                  index,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final double? shopLat =
        _shopLatitude;

    final double? shopLng =
        _shopLongitude;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Navigation',
        ),
        centerTitle: true,
        actions: [
          if (_availableRoutes.length > 1)
            IconButton(
              onPressed:
                  _routeSelectionRequired
                      ? null
                      : () {
                          setState(() {
                            _routeSelectionVisible =
                                !_routeSelectionVisible;
                          });

                          if (_routeSelectionVisible) {
                            _fitAllRoutesOnMap();
                          }
                        },
              icon: const Icon(
                Icons.alt_route,
              ),
              tooltip:
                  'Choose route',
            ),
        ],
      ),
      body: shopLat == null ||
              shopLng == null
          ? const Center(
              child: Text(
                'Shop location unavailable.',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController:
                      _mapController,
                  options:
                      MapOptions(
                    initialCenter:
                        LatLng(
                      shopLat,
                      shopLng,
                    ),
                    initialZoom: 16,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'com.nearbyads.app',
                    ),

                    if (_availableRoutes
                        .isNotEmpty)
                      PolylineLayer(
                        polylines:
                            List.generate(
                          _availableRoutes
                              .length,
                          (int index) {
                            final dynamic
                                rawPoints =
                                _availableRoutes[
                                        index]
                                    ['points'];

                            final List<LatLng>
                                points =
                                rawPoints
                                        is List<
                                            LatLng>
                                    ? rawPoints
                                    : <LatLng>[];

                            final bool selected =
                                index ==
                                    _selectedRouteIndex;

                            return Polyline(
                              points: points,
                              strokeWidth:
                                  selected
                                      ? 7
                                      : 4,
                              color: selected
                                  ? const Color(
                                      0xFF1976D2,
                                    )
                                  : Colors.grey
                                      .withValues(
                                      alpha: 0.65,
                                    ),
                            );
                          },
                        ),
                      ),

                    MarkerLayer(
                      markers: [
                        Marker(
                          point:
                              LatLng(
                            shopLat,
                            shopLng,
                          ),
                          width: 55,
                          height: 65,
                          child: Column(
                            children: [
                              Container(
                                width: 45,
                                height: 45,
                                decoration:
                                    const BoxDecoration(
                                  color:
                                      Color(
                                    0xFF7B1FA2,
                                  ),
                                  shape:
                                      BoxShape.circle,
                                ),
                                child:
                                    const Icon(
                                  Icons.store,
                                  color:
                                      Colors.white,
                                  size: 24,
                                ),
                              ),
                              const Icon(
                                Icons
                                    .arrow_drop_down,
                                color:
                                    Colors.black54,
                              ),
                            ],
                          ),
                        ),

                        if (_currentLocation !=
                            null)
                          Marker(
                            point:
                                _currentLocation!,
                            width: 55,
                            height: 55,
                            child:
                                Transform.rotate(
                              angle:
                                  _currentHeading *
                                      math.pi /
                                      180,
                              child:
                                  Container(
                                decoration:
                                    BoxDecoration(
                                  color:
                                      const Color(
                                    0xFF1976D2,
                                  ),
                                  shape:
                                      BoxShape.circle,
                                  border:
                                      Border.all(
                                    color:
                                        Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child:
                                    const Icon(
                                  Icons.navigation,
                                  color:
                                      Colors.white,
                                  size: 25,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // ==================================================
                // TOP INFORMATION
                // ==================================================

                Positioned(
                  top: 15,
                  left: 15,
                  right: 15,
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(
                      maxHeight:
                          MediaQuery.sizeOf(
                                context,
                              ).height *
                              0.43,
                    ),
                    child: Container(
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                        boxShadow:
                            const [
                          BoxShadow(
                            color:
                                Colors.black26,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child:
                          SingleChildScrollView(
                        physics:
                            const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min,
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              _shopName,
                              style:
                                  const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height: 10,
                            ),

                            Row(
                              children: [
                                const Icon(
                                  Icons
                                      .location_on,
                                  color:
                                      Color(
                                    0xFF1976D2,
                                  ),
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  _routeSelectionRequired
                                      ? '--'
                                      : _formatDistance(
                                          _remainingDistance,
                                        ),
                                  style:
                                      const TextStyle(
                                    fontSize: 22,
                                    fontWeight:
                                        FontWeight.bold,
                                    color:
                                        Color(
                                      0xFF1976D2,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (!_destinationReached &&
                                !_routeSelectionRequired &&
                                _remainingDuration >
                                    0) ...[
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                'Walk ${_formatDuration(
                                  _remainingDuration,
                                )} remaining',
                                style:
                                    const TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight.w600,
                                  color:
                                      Color(
                                    0xFF1976D2,
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(
                              height: 5,
                            ),

                            Text(
                              _getCurrentInstruction(),
                              style:
                                  TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    _routeSelectionRequired
                                        ? Colors.orange
                                        : _destinationReached
                                            ? Colors.green
                                            : _routeError
                                                ? Colors.red
                                                : Colors.black87,
                              ),
                            ),

                            if (_availableRoutes
                                        .length >
                                    1 &&
                                !_routeSelectionVisible &&
                                !_routeSelectionRequired) ...[
                              const SizedBox(
                                height: 10,
                              ),
                              SizedBox(
                                width:
                                    double.infinity,
                                child:
                                    OutlinedButton.icon(
                                  onPressed:
                                      () {
                                    setState(() {
                                      _routeSelectionVisible =
                                          true;
                                    });

                                    _fitAllRoutesOnMap();
                                  },
                                  icon:
                                      const Icon(
                                    Icons.alt_route,
                                  ),
                                  label:
                                      Text(
                                    'Choose Another Route '
                                    '(${_availableRoutes.length})',
                                  ),
                                ),
                              ),
                            ],

                            if (_loadingRoute) ...[
                              const SizedBox(
                                height: 10,
                              ),
                              const LinearProgressIndicator(
                                color:
                                    Color(
                                  0xFF1976D2,
                                ),
                              ),
                            ],

                            if (_rerouting) ...[
                              const SizedBox(
                                height: 8,
                              ),
                              const Text(
                                'Recalculating route...',
                                style:
                                    TextStyle(
                                  fontSize: 13,
                                  color:
                                      Colors.orange,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ],

                            if (_routeError) ...[
                              const SizedBox(
                                height: 10,
                              ),
                              SizedBox(
                                width:
                                    double.infinity,
                                child:
                                    ElevatedButton.icon(
                                  onPressed:
                                      _retryRoute,
                                  icon:
                                      const Icon(
                                    Icons.refresh,
                                  ),
                                  label:
                                      const Text(
                                    'Retry Route',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                _buildRouteSelectionPanel(),

                if (_loading)
                  const Center(
                    child:
                        CircularProgressIndicator(
                      color:
                          Color(0xFF1976D2),
                    ),
                  ),

                if (_locationError)
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 25,
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          _startNavigation,
                      icon: const Icon(
                        Icons.my_location,
                      ),
                      label: const Text(
                        'Retry Location',
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _RouteProjection {
  final double distanceFromStart;
  final double distanceToPoint;
  final double totalDistance;

  const _RouteProjection({
    required this.distanceFromStart,
    required this.distanceToPoint,
    required this.totalDistance,
  });
}