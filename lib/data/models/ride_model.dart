import '../../domain/models/ride.dart';

class RideModel extends Ride {
  RideModel({
    required super.id,
    required super.userId,
    required super.originLat,
    required super.originLng,
    required super.destLat,
    required super.destLng,
    required super.status,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['id'].toString(),
      userId: json['user_id'] ?? '',
      originLat: (json['origin_lat'] as num).toDouble(),
      originLng: (json['origin_lng'] as num).toDouble(),
      destLat: (json['dest_lat'] as num).toDouble(),
      destLng: (json['dest_lng'] as num).toDouble(),
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'origin_lat': originLat,
      'origin_lng': originLng,
      'dest_lat': destLat,
      'dest_lng': destLng,
      'status': status,
    };
  }
}
