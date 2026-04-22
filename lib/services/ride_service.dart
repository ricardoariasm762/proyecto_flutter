import 'package:supabase_flutter/supabase_flutter.dart';

class RideService {
  RideService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> createRide({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required int availableSeats,
  }) async {
    final user = _client.auth.currentSession?.user ?? _client.auth.currentUser;
    if (user == null) {
      throw Exception('auth-required');
    }

    final payload = <String, dynamic>{
      'user_id': user.id,
      'origin_lat': originLat,
      'origin_lng': originLng,
      'dest_lat': destLat,
      'dest_lng': destLng,
      'available_seats': availableSeats,
      'status': 'waiting',
    };

    try {
      await _client.from('rides').insert(payload);
    } catch (e) {
      final msg = e.toString();
      final undefinedAvailableSeats = msg.contains('available_seats') &&
          (msg.toLowerCase().contains('column') ||
              msg.toLowerCase().contains('schema') ||
              msg.toLowerCase().contains('does not exist'));
      if (!undefinedAvailableSeats) rethrow;

      final fallbackPayload = Map<String, dynamic>.from(payload)..remove('available_seats');
      await _client.from('rides').insert(fallbackPayload);
    }
  }

  Stream<List<Map<String, dynamic>>> getRidesStream() {
    return getRidesStreamExcludingUser();
  }

  Stream<List<Map<String, dynamic>>> getRidesStreamExcludingUser({String? excludeUserId}) {
    final query = _client
        .from('rides')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
    if (excludeUserId == null || excludeUserId.isEmpty) return query;
    return query.map((rows) {
      return rows.where((r) => (r['user_id'] ?? '').toString() != excludeUserId).toList(growable: false);
    });
  }

  Future<void> requestJoinRide({required String rideId}) async {
    final user = _client.auth.currentSession?.user ?? _client.auth.currentUser;
    if (user == null) return;

    await _client.from('ride_requests').insert({
      'ride_id': rideId,
      'user_id': user.id,
      'status': 'pending',
    });

    await _client.from('rides').update({'status': 'pending'}).eq('id', rideId);
  }

  Future<List<Map<String, dynamic>>> getUserRides() async {
    final user = _client.auth.currentSession?.user ?? _client.auth.currentUser;
    if (user == null) return [];

    final data = await _client
        .from('rides')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getRideRequests({required String rideId}) async {
    final data = await _client
        .from('ride_requests')
        .select()
        .eq('ride_id', rideId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
}
