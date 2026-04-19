import 'package:geolocator/geolocator.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_data_source.dart';

class LocationRepositoryImpl implements LocationRepository {
  LocationRepositoryImpl(this._dataSource);

  final LocationDataSource _dataSource;

  @override
  Future<Position> getCurrentLocation() {
    return _dataSource.getCurrentLocation();
  }
}
