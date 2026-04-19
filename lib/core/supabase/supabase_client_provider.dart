import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientProvider {
  SupabaseClientProvider._(this.client);

  final SupabaseClient client;

  static late final SupabaseClientProvider instance;

  static void init({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) {
    instance = SupabaseClientProvider._(Supabase.instance.client);
  }
}
