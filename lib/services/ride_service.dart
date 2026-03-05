import 'package:supabase_flutter/supabase_flutter.dart';

class RideService {

  final supabase = Supabase.instance.client;

  Future<void> createRide({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {

    await supabase.from('rides').insert({
      'user_id': 'user_demo',
      'origin_lat': originLat,
      'origin_lng': originLng,
      'dest_lat': destLat,
      'dest_lng': destLng,
      'status': 'waiting'
    });

  }

  Future<List> getRides() async {
    return await supabase.from('rides').select();
  }

}