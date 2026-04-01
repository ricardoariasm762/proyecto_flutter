import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../domain/models/ride.dart';
import '../../../domain/repositories/location_repository.dart';
import '../../../domain/repositories/ride_repository.dart';

class HomeController {
  final RideRepository rideRepository;
  final LocationRepository locationRepository;

  HomeController({
    required this.rideRepository,
    required this.locationRepository,
  });

  LatLng? currentPosition;
  LatLng? destination;
  late Future<List<Ride>> communityRides;

  Future<void> init(Function(VoidCallback) setState) async {
    await getLocation(setState);
    communityRides = rideRepository.getRides();
  }

  Future<void> getLocation(Function(VoidCallback) setState) async {
    try {
      final position = await locationRepository.getCurrentLocation();
      setState(() {
        currentPosition = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> createRide({
    required VoidCallback onSuccess,
    required Function(VoidCallback) setState,
  }) async {
    if (destination == null || currentPosition == null) return;
    
    await rideRepository.createRide(
      originLat: currentPosition!.latitude,
      originLng: currentPosition!.longitude,
      destLat: destination!.latitude,
      destLng: destination!.longitude,
    );
    
    onSuccess();
    refreshRides(setState);
  }

  void refreshRides(Function(VoidCallback) setState) {
    setState(() {
      communityRides = rideRepository.getRides();
    });
  }

  int calculateRideMembers(Ride ride) {
    return 1 + (ride.id.hashCode.abs() % 5);
  }

  double calculateRideTotalFare(Ride ride) {
    final origin = LatLng(ride.originLat, ride.originLng);
    final dest = LatLng(ride.destLat, ride.destLng);
    final km = const Distance().as(LengthUnit.Kilometer, origin, dest);
    return 6000 + (km * 1300);
  }
  
  void updateDestination(LatLng point, Function(VoidCallback) setState) {
    setState(() {
      destination = point;
    });
  }
}
