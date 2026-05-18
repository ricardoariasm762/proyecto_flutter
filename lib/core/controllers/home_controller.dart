import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:osrm/osrm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/location_service.dart';
import '../../services/ride_service.dart';
import '../../services/notification_service.dart';
import '../../services/groq_service.dart';
import '../localization/app_dictionary.dart';

class HomeController extends ChangeNotifier {
  final LocationService _locationService;
  final RideService _rideService;
  final GroqService _aiService = GroqService();
  final MapController mapController = MapController();
  final Osrm _osrm = Osrm();

  LatLng? currentPosition;
  LatLng? destination;

  String originTitleKey = 'getting_location';
  String destinationTitleKey = 'select_destination';
  String? customOriginTitle;
  String? customDestinationTitle;

  String userRole = 'passenger';
  // Eliminada la variable isDriverOnline redundante

  num? routeDistance;
  num? routeDuration;

  // IA Pricing
  double? aiSuggestedPrice;
  String? aiSuggestedTime;
  String? aiRecommendation;
  bool isAiCalculatingPrice = false;

  // Search Flow (inDrive style)
  bool isSearching = false;
  bool isGatheringMembers = false;
  bool isOnTrip = false;
  bool isPaymentPending = false;
  bool isPickingUp = false;
  double? offeredPrice;
  String? currentGroupId;

  LatLng? driverPosition;
  Map<String, dynamic>? activeTripData;

  List<LatLng> routePoints = [];
  List<LatLng> pickupRoutePoints = [];
  num? pickupRouteDistance;
  num? pickupRouteDuration;
  LatLng? _lastPickupRouteStart;
  DateTime? _lastPickupRouteTime;
  List<LatLng> tripRoutePoints = [];
  num? tripRouteDistance;
  num? tripRouteDuration;
  LatLng? _lastTripRouteStart;
  DateTime? _lastTripRouteTime;
  int availableSeats = 1;

  // Historial de búsquedas recientes
  List<Map<String, dynamic>> recentSearches = [];

  StreamSubscription<Map<String, dynamic>?>? _driverLocationSub;
  String? _driverLocationDriverId;
  StreamSubscription<int>? _passengerCountSub;
  String? _passengerCountGroupId;
  int activePassengerCount = 1;

  HomeController(this._locationService, this._rideService) {
    _initRole();
    _loadRecentSearches();
    _listenToActiveTrip();
    _listenToLocation();
  }

  void _listenToLocation() {
    _locationService.getLocationStream().listen(_onLocationChanged);
  }

  void _onLocationChanged(Position position) {
    currentPosition = LatLng(position.latitude, position.longitude);

    // Actualizar ubicación en base de datos si está en un viaje o es conductor online
    if (isOnTrip ||
        isPickingUp ||
        (userRole == 'driver' && activeTripData?['is_online'] == true)) {
      _rideService.updateLocation(position.latitude, position.longitude);
    }

    if (destination != null && routePoints.isEmpty) {
      fetchRoute(currentPosition!, destination!);
    }
    if (isPickingUp) {
      _maybeUpdatePickupRoute();
    }
    if (isOnTrip) {
      _maybeUpdateTripRoute();
    }
    notifyListeners();
  }

  void _listenToActiveTrip() {
    _rideService.getActiveGroupStream().listen((trip) {
      activeTripData = trip;
      // Actualizar el estado de online basado en activeTripData si es conductor
      notifyListeners();

      if (trip == null) {
        isSearching = false;
        isGatheringMembers = false;
        isOnTrip = false;
        isPaymentPending = false;
        isPickingUp = false;
        currentGroupId = null;
        _stopPassengerCountListener();
        _stopDriverLocationListener();
        pickupRoutePoints = [];
        pickupRouteDistance = null;
        pickupRouteDuration = null;
        _lastPickupRouteStart = null;
        _lastPickupRouteTime = null;
        tripRoutePoints = [];
        tripRouteDistance = null;
        tripRouteDuration = null;
        _lastTripRouteStart = null;
        _lastTripRouteTime = null;
        activePassengerCount = 1;
      } else {
        currentGroupId = trip['id']?.toString();
        _startPassengerCountListener(currentGroupId);
        final status = trip['status']?.toString() ?? '';
        final driverId = trip['driver_id']?.toString();

        if (status == 'gathering') {
          isGatheringMembers = true;
          isSearching = false;
          isOnTrip = false;
          isPaymentPending = false;
          isPickingUp = false;
          pickupRoutePoints = [];
          tripRoutePoints = [];
          _stopDriverLocationListener();
        } else if (status == 'searching_driver') {
          isGatheringMembers = false;
          isSearching = true;
          isOnTrip = false;
          isPaymentPending = false;
          isPickingUp = false;
          pickupRoutePoints = [];
          tripRoutePoints = [];
          _stopDriverLocationListener();
        } else if (status == 'driver_assigned') {
          isGatheringMembers = false;
          isSearching = false;
          isOnTrip = false;
          isPaymentPending = false;
          isPickingUp = true;
          currentTabIndex = 0;
          if (driverId != null && driverId.isNotEmpty) {
            _startDriverLocationListener(driverId);
          }
          _maybeUpdatePickupRoute(force: true);
        } else if (status == 'active') {
          isGatheringMembers = false;
          isSearching = false;
          isOnTrip = true;
          isPaymentPending = false;
          isPickingUp = false;
          currentTabIndex = 0;
          pickupRoutePoints = [];
          if (driverId != null && driverId.isNotEmpty) {
            _startDriverLocationListener(driverId);
          }
          _maybeUpdateTripRoute(force: true);
        } else if (status == 'payment_pending' ||
            status == 'payment_confirmed') {
          isGatheringMembers = false;
          isSearching = false;
          isOnTrip = false;
          isPaymentPending = true;
          isPickingUp = false;
          currentTabIndex = 0;
          pickupRoutePoints = [];
          tripRoutePoints = [];
          if (driverId != null && driverId.isNotEmpty) {
            _startDriverLocationListener(driverId);
          }
        } else if (status == 'completed') {
          isGatheringMembers = false;
          isSearching = false;
          isOnTrip = false;
          isPaymentPending = false;
          isPickingUp = false;
          pickupRoutePoints = [];
          tripRoutePoints = [];
          _stopDriverLocationListener();
        }

        if (trip['offered_price'] != null) {
          offeredPrice = (trip['offered_price'] as num).toDouble();
        }
      }
      notifyListeners();
    });
  }

  void _stopPassengerCountListener() {
    _passengerCountSub?.cancel();
    _passengerCountSub = null;
    _passengerCountGroupId = null;
    activePassengerCount = 1;
  }

  void _startPassengerCountListener(String? groupId) {
    if (groupId == null || groupId.isEmpty) return;
    if (_passengerCountGroupId == groupId) return;
    _passengerCountSub?.cancel();
    _passengerCountGroupId = groupId;
    _passengerCountSub = _rideService
        .getPassengerCountStream(groupId: groupId)
        .listen((count) {
          activePassengerCount = count < 1 ? 1 : count;
          notifyListeners();
        });
  }

  double get perPersonFare {
    final total = offeredPrice ?? 0;
    final count = activePassengerCount < 1 ? 1 : activePassengerCount;
    return total / count;
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final String? searchesJson = prefs.getString('recent_searches');
    if (searchesJson != null) {
      recentSearches = List<Map<String, dynamic>>.from(
        json.decode(searchesJson),
      );
    }
    notifyListeners();
  }

  Future<void> _saveSearch(String address, LatLng point) async {
    final prefs = await SharedPreferences.getInstance();

    // Evitar duplicados y mantener solo los últimos 4
    recentSearches.removeWhere((item) => item['address'] == address);

    recentSearches.insert(0, {
      'address': address,
      'lat': point.latitude,
      'lng': point.longitude,
    });

    if (recentSearches.length > 4) {
      recentSearches = recentSearches.sublist(0, 4);
    }

    await prefs.setString('recent_searches', json.encode(recentSearches));
    notifyListeners();
  }

  Future<void> saveFavorite(String type, String address, LatLng point) async {
    // Ya no se usa para home/work, pero guardamos en historial
    await _saveSearch(address, point);
  }

  Future<LatLng?> geocodeAddress(String address) async {
    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(address)}&limit=1",
    );
    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'ridematch_community_app'},
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          return LatLng(lat, lon);
        }
      }
    } catch (_) {}
    return null;
  }

  void setAvailableSeats(int seats) {
    if (seats >= 1 && seats <= 4) {
      availableSeats = seats;
      notifyListeners();
    }
  }

  Future<void> _initRole() async {
    userRole = await _rideService.getCurrentUserRole();
    notifyListeners();
  }

  String getOriginTitle(String lang) =>
      customOriginTitle ?? AppDictionary.text(lang, originTitleKey);
  String getDestinationTitle(String lang) =>
      customDestinationTitle ?? AppDictionary.text(lang, destinationTitleKey);

  int currentTabIndex = 0;

  void setTabIndex(int index) {
    currentTabIndex = index;
    notifyListeners();
  }

  bool get isDriverOnline => activeTripData?['is_online'] ?? false;

  Future<void> toggleDriverOnline(bool val, BuildContext context) async {
    try {
      if (val) {
        if (currentPosition != null) {
          await _rideService.goOnline(
            currentPosition!.latitude,
            currentPosition!.longitude,
          );
        }
      } else {
        await _rideService.goOffline();
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> getLocation(BuildContext context, String currentLanguage) async {
    try {
      final position = await _locationService.getCurrentLocation();
      currentPosition = LatLng(position.latitude, position.longitude);
      notifyListeners();
      _getAddress(currentPosition!, true);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppDictionary.text(currentLanguage, 'location_permission_error'),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void setDestination(LatLng point, {String? address}) {
    destination = point;
    customDestinationTitle = null;
    destinationTitleKey = 'calculating_location';
    routePoints = [];
    routeDistance = null;
    routeDuration = null;
    aiSuggestedPrice = null;
    aiSuggestedTime = null;
    aiRecommendation = null;
    notifyListeners();

    _getAddress(point, false);
    if (address != null) {
      _saveSearch(address, point);
    }
    if (currentPosition != null) {
      fetchRoute(currentPosition!, destination!);
    }
  }

  Future<void> _calculateAiPrice() async {
    if (routeDistance == null) return;

    isAiCalculatingPrice = true;
    notifyListeners();

    try {
      final distanceKm = routeDistance! / 1000.0;
      final passengers = availableSeats;
      final now = DateTime.now();
      final hour = now.hour;

      final prompt =
          """
      Calcula el precio para un viaje en Pasto:
      - Origen: ${customOriginTitle ?? 'Ubicación actual'}
      - Destino: ${customDestinationTitle ?? 'Destino seleccionado'}
      - Distancia: ${distanceKm.toStringAsFixed(1)} km
      - Pasajeros: $passengers
      - Hora: $hour:00
      
      Usa el formato exacto:
      Precio estimado: \$XXXX COP
      Tiempo aproximado: XX minutos
      Recomendación: texto corto
      """;

      final response = await _aiService.preguntar(prompt);

      // Parsear respuesta
      final priceRegex = RegExp(r'Precio estimado: \$?([\d\.]+)');
      final timeRegex = RegExp(r'Tiempo aproximado: (.*)');
      final recRegex = RegExp(r'Recomendación: (.*)');

      final priceMatch = priceRegex.firstMatch(response);
      if (priceMatch != null) {
        aiSuggestedPrice = double.tryParse(
          priceMatch.group(1)!.replaceAll('.', ''),
        );
      }

      final timeMatch = timeRegex.firstMatch(response);
      if (timeMatch != null) {
        aiSuggestedTime = timeMatch.group(1);
      }

      final recMatch = recRegex.firstMatch(response);
      if (recMatch != null) {
        aiRecommendation = recMatch.group(1);
      }
    } catch (_) {
      // Fallback
      final distanceKm = routeDistance! / 1000.0;
      aiSuggestedPrice = 5000 + (distanceKm * 1000);
      if (aiSuggestedPrice! < 5000) aiSuggestedPrice = 5000;
      aiSuggestedTime = "${(distanceKm * 3).toStringAsFixed(0)} mins";
      aiRecommendation = "Precio base estimado por distancia.";
    } finally {
      isAiCalculatingPrice = false;
      notifyListeners();
    }
  }

  void clearDestination() {
    destination = null;
    customDestinationTitle = null;
    destinationTitleKey = 'select_destination';
    routePoints = [];
    routeDistance = null;
    routeDuration = null;
    notifyListeners();
  }

  void recenterMap() {
    if (currentPosition != null) {
      mapController.move(currentPosition!, 15);
    }
  }

  Future<void> _getAddress(LatLng point, bool isOrigin) async {
    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}",
    );
    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'ridematch_community_app'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final displayName = data['display_name'] ?? "";
        final parts = displayName.split(',');
        final concise = parts.length > 2
            ? "${parts[0]}, ${parts[1]}"
            : displayName;

        if (isOrigin) {
          customOriginTitle = concise;
        } else {
          customDestinationTitle = concise;
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchRoute(LatLng start, LatLng end) async {
    final options = RouteRequest(
      coordinates: [
        (start.longitude, start.latitude),
        (end.longitude, end.latitude),
      ],
      geometries: OsrmGeometries.geojson,
    );
    try {
      final route = await _osrm.route(options);
      if (route.routes.isNotEmpty) {
        final distance = route.routes.first.distance;
        final duration = route.routes.first.duration;

        final coords = route.routes.first.geometry?.lineString?.coordinates;
        if (coords != null) {
          routePoints = coords.map((c) => LatLng(c.$2, c.$1)).toList();
          routeDistance = distance;
          routeDuration = duration;
          notifyListeners();

          // Calcular precio con IA
          _calculateAiPrice();

          if (routePoints.isNotEmpty) {
            mapController.fitCamera(
              CameraFit.bounds(
                bounds: LatLngBounds.fromPoints([start, end, ...routePoints]),
                padding: const EdgeInsets.all(50.0),
              ),
            );
          }
        }
      }
    } catch (_) {}
  }

  LatLng? get pickupPoint {
    final trip = activeTripData;
    if (trip == null) return null;
    final lat = trip['origin_lat'];
    final lng = trip['origin_lng'];
    if (lat == null || lng == null) return null;
    return LatLng((lat as num).toDouble(), (lng as num).toDouble());
  }

  LatLng? get destinationPointFromTrip {
    final trip = activeTripData;
    if (trip == null) return null;
    final lat = trip['dest_lat'];
    final lng = trip['dest_lng'];
    if (lat == null || lng == null) return null;
    return LatLng((lat as num).toDouble(), (lng as num).toDouble());
  }

  String? get tripStatus => activeTripData?['status']?.toString();

  LatLng? _pickupRouteStartPoint() {
    if (userRole == 'driver') return currentPosition;
    return driverPosition;
  }

  LatLng? _tripRouteStartPoint() {
    if (userRole == 'driver') return currentPosition;
    return driverPosition;
  }

  void _maybeUpdatePickupRoute({bool force = false}) {
    final start = _pickupRouteStartPoint();
    final pickup = pickupPoint;
    if (start == null || pickup == null) return;

    final now = DateTime.now();
    final shouldThrottleByTime =
        _lastPickupRouteTime != null &&
        now.difference(_lastPickupRouteTime!).inSeconds < 20;

    final shouldThrottleByDistance =
        _lastPickupRouteStart != null &&
        Geolocator.distanceBetween(
              _lastPickupRouteStart!.latitude,
              _lastPickupRouteStart!.longitude,
              start.latitude,
              start.longitude,
            ) <
            50;

    if (!force &&
        pickupRoutePoints.isNotEmpty &&
        (shouldThrottleByTime || shouldThrottleByDistance)) {
      return;
    }

    _lastPickupRouteStart = start;
    _lastPickupRouteTime = now;
    fetchPickupRoute(start, pickup, fitCamera: userRole == 'driver');
  }

  void _maybeUpdateTripRoute({bool force = false}) {
    final start = _tripRouteStartPoint();
    final end = destinationPointFromTrip;
    if (start == null || end == null) return;

    final now = DateTime.now();
    final shouldThrottleByTime =
        _lastTripRouteTime != null &&
        now.difference(_lastTripRouteTime!).inSeconds < 20;

    final shouldThrottleByDistance =
        _lastTripRouteStart != null &&
        Geolocator.distanceBetween(
              _lastTripRouteStart!.latitude,
              _lastTripRouteStart!.longitude,
              start.latitude,
              start.longitude,
            ) <
            50;

    if (!force &&
        tripRoutePoints.isNotEmpty &&
        (shouldThrottleByTime || shouldThrottleByDistance)) {
      return;
    }

    _lastTripRouteStart = start;
    _lastTripRouteTime = now;
    fetchTripRoute(start, end, fitCamera: userRole == 'driver');
  }

  Future<void> fetchPickupRoute(
    LatLng start,
    LatLng end, {
    bool fitCamera = false,
  }) async {
    final options = RouteRequest(
      coordinates: [
        (start.longitude, start.latitude),
        (end.longitude, end.latitude),
      ],
      geometries: OsrmGeometries.geojson,
    );
    try {
      final route = await _osrm.route(options);
      if (route.routes.isNotEmpty) {
        final distance = route.routes.first.distance;
        final duration = route.routes.first.duration;
        final coords = route.routes.first.geometry?.lineString?.coordinates;
        if (coords != null) {
          pickupRoutePoints = coords.map((c) => LatLng(c.$2, c.$1)).toList();
          pickupRouteDistance = distance;
          pickupRouteDuration = duration;
          notifyListeners();

          if (fitCamera && pickupRoutePoints.isNotEmpty) {
            mapController.fitCamera(
              CameraFit.bounds(
                bounds: LatLngBounds.fromPoints([
                  start,
                  end,
                  ...pickupRoutePoints,
                ]),
                padding: const EdgeInsets.all(50.0),
              ),
            );
          }
        }
      }
    } catch (_) {}
  }

  Future<void> fetchTripRoute(
    LatLng start,
    LatLng end, {
    bool fitCamera = false,
  }) async {
    final options = RouteRequest(
      coordinates: [
        (start.longitude, start.latitude),
        (end.longitude, end.latitude),
      ],
      geometries: OsrmGeometries.geojson,
    );
    try {
      final route = await _osrm.route(options);
      if (route.routes.isNotEmpty) {
        final distance = route.routes.first.distance;
        final duration = route.routes.first.duration;
        final coords = route.routes.first.geometry?.lineString?.coordinates;
        if (coords != null) {
          tripRoutePoints = coords.map((c) => LatLng(c.$2, c.$1)).toList();
          tripRouteDistance = distance;
          tripRouteDuration = duration;
          notifyListeners();

          if (fitCamera && tripRoutePoints.isNotEmpty) {
            mapController.fitCamera(
              CameraFit.bounds(
                bounds: LatLngBounds.fromPoints([
                  start,
                  end,
                  ...tripRoutePoints,
                ]),
                padding: const EdgeInsets.all(50.0),
              ),
            );
          }
        }
      }
    } catch (_) {}
  }

  Future<void> createGroup(BuildContext context, String currentLanguage) async {
    if (destination == null || currentPosition == null) return;
    try {
      offeredPrice = aiSuggestedPrice ?? 6000;
      isGatheringMembers = true;
      notifyListeners();

      await _rideService.createGroup(
        originLat: currentPosition!.latitude,
        originLng: currentPosition!.longitude,
        destLat: destination!.latitude,
        destLng: destination!.longitude,
        availableSeats: availableSeats,
        offeredPrice: offeredPrice,
      );

      final active = await _rideService.getActiveGroup();
      currentGroupId = active?['id']?.toString();

      await NotificationService().showNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: AppDictionary.text(currentLanguage, 'gathering_members'),
        body: AppDictionary.text(currentLanguage, 'gathering_members_desc'),
      );
    } catch (e) {
      isGatheringMembers = false;
      notifyListeners();
      if (!context.mounted) return;
      final isAuth = e.toString().contains('auth-required');
      final msg = isAuth
          ? AppDictionary.text(currentLanguage, 'auth_required')
          : "Error: $e";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> startDriverSearch(
    BuildContext context,
    String currentLanguage,
  ) async {
    if (currentGroupId == null) return;
    try {
      isGatheringMembers = false;
      isSearching = true;
      notifyListeners();

      await _rideService.findDriver(currentGroupId!);

      await NotificationService().showNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: AppDictionary.text(currentLanguage, 'searching_driver'),
        body: AppDictionary.text(currentLanguage, 'searching_driver_desc'),
      );
    } catch (e) {
      isSearching = false;
      isGatheringMembers = true;
      notifyListeners();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> cancelSearch() async {
    if (currentGroupId != null) {
      await _rideService.cancelGroup(currentGroupId!);
    }
    isSearching = false;
    isGatheringMembers = false;
    currentGroupId = null;
    offeredPrice = null;
    notifyListeners();
  }

  Future<void> cancelCurrentTrip(BuildContext context, String lang) async {
    if (currentGroupId == null) return;

    final isDriver = userRole == 'driver';
    final status =
        tripStatus ??
        (isPickingUp
            ? 'driver_assigned'
            : (isOnTrip
                  ? 'active'
                  : (isSearching
                        ? 'searching_driver'
                        : (isGatheringMembers ? 'gathering' : ''))));

    final reasons = _getCancelReasons(lang, isDriver: isDriver, status: status);

    final String? selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        lang == 'es'
                            ? '¿Por qué cancelas el viaje?'
                            : 'Why are you cancelling?',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: scheme.onSurface),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: reasons.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final reason = reasons[index];
                    return ListTile(
                      title: Text(reason),
                      onTap: () => Navigator.pop(context, reason),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                      side: BorderSide(color: scheme.error),
                    ),
                    child: Text(lang == 'es' ? 'No cancelar' : 'Don’t cancel'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null) return;

    await _rideService.cancelGroup(currentGroupId!, reason: selected);
    _resetAfterCancel();
  }

  List<String> _getCancelReasons(
    String lang, {
    required bool isDriver,
    required String status,
  }) {
    if (lang != 'es') {
      return [
        'Changed my mind',
        'Wrong pickup location',
        'Driver / passenger not responding',
        'Too long waiting time',
        'Price not fair',
        'Other reason',
      ];
    }

    if (status == 'gathering' || status == 'searching_driver') {
      return [
        'Cambié de planes',
        'Me equivoqué de destino',
        'La espera es muy larga',
        'El precio no me convence',
        'Otro motivo',
      ];
    }

    if (status == 'driver_assigned') {
      return isDriver
          ? [
              'No puedo llegar al punto de recogida',
              'El usuario no responde',
              'Problema con el vehículo',
              'Otro motivo',
            ]
          : [
              'El conductor no se mueve',
              'El conductor está muy lejos',
              'Ya no necesito el viaje',
              'Otro motivo',
            ];
    }

    if (status == 'active') {
      return isDriver
          ? [
              'El usuario no pagará',
              'Problema de seguridad',
              'Problema con el vehículo',
              'Otro motivo',
            ]
          : [
              'Problema de seguridad',
              'El conductor tomó una ruta incorrecta',
              'No continuaré el viaje',
              'Otro motivo',
            ];
    }

    return ['Cambié de planes', 'Otro motivo'];
  }

  void _resetAfterCancel() {
    isSearching = false;
    isGatheringMembers = false;
    isOnTrip = false;
    isPaymentPending = false;
    isPickingUp = false;
    currentGroupId = null;
    _stopPassengerCountListener();
    offeredPrice = null;
    activeTripData = null;
    routePoints = [];
    pickupRoutePoints = [];
    tripRoutePoints = [];
    _stopDriverLocationListener();
    clearDestination();
    notifyListeners();
  }

  Future<void> updateOfferedPrice(double newPrice) async {
    if (newPrice < 5000) newPrice = 5000; // Mínimo absoluto
    offeredPrice = newPrice;
    notifyListeners();

    if (currentGroupId != null) {
      await _rideService.updateOfferedPrice(currentGroupId!, newPrice);
    }
  }

  void _stopDriverLocationListener() {
    _driverLocationSub?.cancel();
    _driverLocationSub = null;
    _driverLocationDriverId = null;
    driverPosition = null;
  }

  void _startDriverLocationListener(String driverId) {
    if (_driverLocationDriverId == driverId) return;
    _driverLocationSub?.cancel();
    _driverLocationDriverId = driverId;

    _driverLocationSub = _rideService.getDriverLocationStream(driverId).listen((
      data,
    ) {
      if (data != null &&
          data['last_lat'] != null &&
          data['last_lng'] != null) {
        driverPosition = LatLng(
          (data['last_lat'] as num).toDouble(),
          (data['last_lng'] as num).toDouble(),
        );
        if (isPickingUp) {
          _maybeUpdatePickupRoute();
        }
        if (isOnTrip) {
          _maybeUpdateTripRoute();
        }
        notifyListeners();
      }
    });
  }

  Future<void> confirmPayment() async {
    // En una app real, aquí se procesaría el pago
    if (currentGroupId != null) {
      // Podríamos llamar a un servicio para archivar el viaje
    }
    isPaymentPending = false;
    clearDestination();
    notifyListeners();
  }

  @override
  void dispose() {
    _driverLocationSub?.cancel();
    _passengerCountSub?.cancel();
    super.dispose();
  }
}
