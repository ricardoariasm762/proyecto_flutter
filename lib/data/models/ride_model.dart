import '../../domain/models/ride.dart';

class RideModel {
  const RideModel({
    required this.id,
    required this.userId,
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
    required this.status,
    required this.participantsCount,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;
  final String status;
  final int participantsCount;
  final DateTime? createdAt;

  static RideModel fromMap(Map<String, dynamic> map) {
    return RideModel(
      id: (map['id'] ?? '').toString(),
      userId: (map['user_id'] ?? '').toString(),
      originLat: (map['origin_lat'] as num?)?.toDouble() ?? 0,
      originLng: (map['origin_lng'] as num?)?.toDouble() ?? 0,
      destLat: (map['dest_lat'] as num?)?.toDouble() ?? 0,
      destLng: (map['dest_lng'] as num?)?.toDouble() ?? 0,
      status: (map['status'] ?? 'waiting').toString(),
      participantsCount: (map['participants_count'] as num?)?.toInt() ?? 1,
      createdAt: map['created_at'] is String
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Ride toDomain() {
    return Ride(
      id: id,
      userId: userId,
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
      status: status,
      participantsCount: participantsCount,
      createdAt: createdAt,
    );
  }
}
