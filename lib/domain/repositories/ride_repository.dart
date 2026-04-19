import '../models/ride.dart';

abstract class RideRepository {
  Stream<List<Ride>> ridesStream();
  Future<void> createRide({
    required String userId,
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  });
  Future<void> requestJoinRide({
    required String rideId,
    required String userId,
  });
  Future<List<Ride>> getUserRides(String userId);
}
