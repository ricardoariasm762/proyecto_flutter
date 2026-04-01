class Ride {
  final String id;
  final String userId;
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;
  final String status;

  Ride({
    required this.id,
    required this.userId,
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
    required this.status,
  });
}
