import '../models/ride.dart';

abstract class RideRepository {
  Future<void> createRide({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  });

  Future<List<Ride>> getRides();
}
