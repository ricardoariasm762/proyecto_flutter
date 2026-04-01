import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/environment.dart';
import 'core/supabase/supabase_client_provider.dart';
import 'data/datasources/location_local_data_source.dart';
import 'data/datasources/ride_remote_data_source.dart';
import 'data/repositories/location_repository_impl.dart';
import 'data/repositories/ride_repository_impl.dart';
import 'domain/repositories/location_repository.dart';
import 'domain/repositories/ride_repository.dart';
import 'presentation/screens/home/home_screen.dart';
import 'screens/auth_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Environment.init();

  final supabaseUrl = Environment.supabaseUrl;
  final supabaseAnonKey = Environment.supabaseAnonKey;

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  SupabaseClientProvider.init(
    supabaseUrl: supabaseUrl,
    supabaseAnonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Dependency Injection (Simplified)
    final rideRemoteDataSource = RideRemoteDataSource(
      SupabaseClientProvider.instance.client,
    );
    final RideRepository rideRepository = RideRepositoryImpl(
      rideRemoteDataSource,
    );
    
    final locationLocalDataSource = LocationLocalDataSource();
    final LocationRepository locationRepository = LocationRepositoryImpl(
      locationLocalDataSource,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RideMatch Comunidad',
      theme: AppTheme.lightTheme,
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          final session = snapshot.data?.session;
          if (session != null) {
            return HomeScreen(
              rideRepository: rideRepository,
              locationRepository: locationRepository,
            );
          } else {
            return const AuthScreen();
          }
        },
      ),
    );
  }
}
