import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
  }

  static String get supabaseUrl {
    final value = dotenv.env['SUPABASE_URL'];
    if (value == null || value.isEmpty) {
      throw Exception('SUPABASE_URL is not defined in .env');
    }
    return value;
  }

  static String get supabaseAnonKey {
    final value = dotenv.env['SUPABASE_ANON_KEY'];
    if (value == null || value.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY is not defined in .env');
    }
    return value;
  }
}
