import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ride_model.dart';

class RideRemoteDataSource {
  final SupabaseClient client;

  RideRemoteDataSource(this.client);

  Future<void> createRide(RideModel ride) async {
    await client.from('rides').insert(ride.toJson());
  }

  Future<List<RideModel>> getRides() async {
    final response = await client
        .from('rides')
        .select()
        .order('id', ascending: false);
    
    return (response as List)
        .map((ride) => RideModel.fromJson(ride))
        .toList();
  }
}
