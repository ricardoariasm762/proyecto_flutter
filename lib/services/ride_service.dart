import 'package:supabase_flutter/supabase_flutter.dart';

class RideService {
  final supabase = Supabase.instance.client;

  Future<void> createRide({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required int availableSeats,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('rides').insert({
      'user_id': user.id,
      'origin_lat': originLat,
      'origin_lng': originLng,
      'dest_lat': destLat,
      'dest_lng': destLng,
      'available_seats': availableSeats,
      'status': 'waiting',
    });
  }

  Stream<List<Map<String, dynamic>>> getRidesStream() {
    return supabase
        .from('rides')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  Future<void> requestJoinRide({required String rideId}) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('ride_requests').insert({
      'ride_id': rideId,
      'user_id': user.id,
      'status': 'pending',
    });

    await supabase.from('rides').update({'status': 'pending'}).eq('id', rideId);
  }

  Future<List<Map<String, dynamic>>> getUserRides() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final data = await supabase
        .from('rides')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
}
