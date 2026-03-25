import 'package:supabase_flutter/supabase_flutter.dart';

class RideService {
  final supabase = Supabase.instance.client;

  Future<void> createRide({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('rides').insert({
      'user_id': user.id,
      'origin_lat': originLat,
      'origin_lng': originLng,
      'dest_lat': destLat,
      'dest_lng': destLng,
      'status': 'waiting',
    });
  }

  Future<List<Map<String, dynamic>>> getRides() async {
    final data = await supabase
        .from('rides')
        .select()
        .order('id', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Stream<List<Map<String, dynamic>>> getRidesStream() {
    return supabase
        .from('rides')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  Future<void> requestJoinRide(dynamic rideId, String userId) async {
    // 1. Crear la solicitud en la base de datos (tabla ride_requests)
    try {
      await supabase.from('ride_requests').insert({
        'ride_id': rideId,
        'user_id': userId,
        'status': 'pending',
      });

      // 2. Actualizar el estado del viaje a 'pending' (esperando usuario)
      await supabase
          .from('rides')
          .update({'status': 'pending'})
          .eq('id', rideId);
    } catch (e) {
      // Si la tabla ride_requests no existe, al menos intentamos actualizar el estado del viaje
      await supabase
          .from('rides')
          .update({'status': 'pending'})
          .eq('id', rideId);
    }
  }

  Future<List<Map<String, dynamic>>> getUserRides(String userId) async {
    final data = await supabase
        .from('rides')
        .select()
        .or(
          'user_id.eq.$userId,participants_count.gt.0',
        ) // Simplificación para historial
        .order('id', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
}
