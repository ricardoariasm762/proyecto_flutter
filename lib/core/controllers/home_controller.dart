import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:osrm/osrm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/location_service.dart';
import '../../services/ride_service.dart';
import '../../services/notification_service.dart';
import '../localization/app_dictionary.dart';

class HomeController extends ChangeNotifier {
  final LocationService _locationService;
  final RideService _rideService;
  final MapController mapController = MapController();
  final Osrm _osrm = Osrm();

  LatLng? currentPosition;
  LatLng? destination;

  String originTitleKey = 'getting_location';
  String destinationTitleKey = 'select_destination';
  String? customOriginTitle;
  String? customDestinationTitle;

  String userRole = 'passenger';
  bool isDriverOnline = false;

  num? routeDistance;
  num? routeDuration;

  List<LatLng> routePoints = [];
  int availableSeats = 1;

  // Historial de búsquedas recientes
  List<Map<String, dynamic>> recentSearches = [];

  HomeController(this._locationService, this._rideService) {
    _initRole();
    _loadRecentSearches();
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

  Future<void> toggleDriverOnline(bool val, BuildContext context) async {
    isDriverOnline = val;
    notifyListeners();
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
    notifyListeners();

    _getAddress(point, false);
    if (address != null) {
      _saveSearch(address, point);
    }
    if (currentPosition != null) {
      fetchRoute(currentPosition!, destination!);
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

  Future<void> createGroup(BuildContext context, String currentLanguage) async {
    if (destination == null || currentPosition == null) return;
    try {
      await _rideService.createGroup(
        originLat: currentPosition!.latitude,
        originLng: currentPosition!.longitude,
        destLat: destination!.latitude,
        destLng: destination!.longitude,
        availableSeats: availableSeats,
      );

      await NotificationService().showNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: AppDictionary.text(currentLanguage, 'ride_created'),
        body: AppDictionary.text(currentLanguage, 'ride_created'),
      );

      setTabIndex(1);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppDictionary.text(currentLanguage, 'ride_created')),
        ),
      );
    } catch (e) {
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
}
