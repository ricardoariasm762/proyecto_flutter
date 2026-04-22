import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:osrm/osrm.dart';
import '../../services/location_service.dart';
import '../../services/ride_service.dart';
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

  int availableSeats = 1;
  num? routeDistance;
  num? routeDuration;

  List<LatLng> routePoints = [];

  HomeController(this._locationService, this._rideService);

  String getOriginTitle(String lang) =>
      customOriginTitle ?? AppDictionary.text(lang, originTitleKey);
  String getDestinationTitle(String lang) =>
      customDestinationTitle ?? AppDictionary.text(lang, destinationTitleKey);

  void setAvailableSeats(int seats) {
    availableSeats = seats.clamp(1, 5);
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

  void setDestination(LatLng point) {
    destination = point;
    customDestinationTitle = null;
    destinationTitleKey = 'calculating_location';
    routePoints = [];
    routeDistance = null;
    routeDuration = null;
    notifyListeners();

    _getAddress(point, false);
    if (currentPosition != null) {
      fetchRoute(currentPosition!, destination!);
    }
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

  Future<void> createRide(BuildContext context, String currentLanguage) async {
    if (destination == null || currentPosition == null) return;
    try {
      await _rideService.createRide(
        originLat: currentPosition!.latitude,
        originLng: currentPosition!.longitude,
        destLat: destination!.latitude,
        destLng: destination!.longitude,
        availableSeats: availableSeats,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppDictionary.text(currentLanguage, 'ride_created')),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final isAuth = e.toString().contains('auth-required');
      final raw = e.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
      final short = raw.length > 140 ? raw.substring(0, 140) : raw;
      final msg = isAuth
          ? AppDictionary.text(currentLanguage, 'auth_required')
          : "${AppDictionary.text(currentLanguage, 'ride_create_failed')}: $short";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    }
  }
}
