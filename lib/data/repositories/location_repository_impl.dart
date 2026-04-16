import 'package:geolocator/geolocator.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_local_data_source.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationLocalDataSource localDataSource;

  LocationRepositoryImpl(this.localDataSource);

  @override
  Future<Position> getCurrentLocation() async {
    return await localDataSource.getCurrentLocation();
  }
}
