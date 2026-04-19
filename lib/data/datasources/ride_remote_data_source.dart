import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client_provider.dart';

class RideRemoteDataSource {
  SupabaseClient get _client => SupabaseClientProvider.instance.client;

  Stream<List<Map<String, dynamic>>> ridesStreamRaw() {
    return _client
        .from('rides')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  Future<void> createRide({
    required String userId,
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    await _client.from('rides').insert({
      'user_id': userId,
      'origin_lat': originLat,
      'origin_lng': originLng,
      'dest_lat': destLat,
      'dest_lng': destLng,
      'status': 'waiting',
    });
  }

  Future<void> requestJoinRide({required String rideId, required String userId}) async {
    try {
      await _client.from('ride_requests').insert({
        'ride_id': rideId,
        'user_id': userId,
        'status': 'pending',
      });

      await _client.from('rides').update({'status': 'pending'}).eq('id', rideId);
    } catch (_) {
      await _client.from('rides').update({'status': 'pending'}).eq('id', rideId);
    }
  }

  Future<List<Map<String, dynamic>>> getUserRidesRaw(String userId) async {
    final data = await _client
        .from('rides')
        .select()
        .or('user_id.eq.$userId,participants_count.gt.0')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
}
