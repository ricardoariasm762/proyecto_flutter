import '../../domain/models/ride.dart';
import '../../domain/repositories/ride_repository.dart';
import '../models/ride_model.dart';
import '../datasources/ride_remote_data_source.dart';

class RideRepositoryImpl implements RideRepository {
  RideRepositoryImpl(this._remote);

  final RideRemoteDataSource _remote;

  @override
  Stream<List<Ride>> ridesStream() {
    return _remote.ridesStreamRaw().map((rows) {
      return rows.map(RideModel.fromMap).map((m) => m.toDomain()).toList(growable: false);
    });
  }

  @override
  Future<void> createRide({
    required String userId,
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    await _remote.createRide(
      userId: userId,
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
    );
  }

  @override
  Future<void> requestJoinRide({
    required String rideId,
    required String userId,
  }) {
    return _remote.requestJoinRide(rideId: rideId, userId: userId);
  }

  @override
  Future<List<Ride>> getUserRides(String userId) async {
    final rows = await _remote.getUserRidesRaw(userId);
    return rows.map(RideModel.fromMap).map((m) => m.toDomain()).toList(growable: false);
  }
}
