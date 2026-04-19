import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/environment.dart';
import 'core/supabase/supabase_client_provider.dart';
import 'data/datasources/auth_remote_data_source.dart';
import 'data/datasources/location_data_source.dart';
import 'data/datasources/ride_remote_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/location_repository_impl.dart';
import 'data/repositories/ride_repository_impl.dart';
import 'presentation/screens/auth_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Environment.init();

  final supabaseUrl = Environment.supabaseUrl;
  final supabaseAnonKey = Environment.supabaseAnonKey;

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

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
    final authRepository = AuthRepositoryImpl(AuthRemoteDataSource());
    final rideRepository = RideRepositoryImpl(RideRemoteDataSource());
    final locationRepository = LocationRepositoryImpl(LocationDataSource());

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RideMatch Comunidad',
      theme: AppTheme.lightTheme,
      home: StreamBuilder<AuthState>(
        stream: authRepository.authStateChanges,
        builder: (context, snapshot) {
          final session =
              snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;
          if (session != null) {
            return HomeScreen(
              authRepository: authRepository,
              rideRepository: rideRepository,
              locationRepository: locationRepository,
            );
          } else {
            return AuthScreen(authRepository: authRepository);
          }
        },
      ),
    );
  }
}
