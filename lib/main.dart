import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
<<<<<<< HEAD
    url: 'TU_URL',
    anonKey: 'TU_ANON_KEY',
=======
    url: 'https://mowhkgekfndkbjddchiz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vd2hrZ2VrZm5ka2JqZGRjaGl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4NjQ3MjUsImV4cCI6MjA4OTQ0MDcyNX0.mBn0tIQocTy2pFgXrwgx2PBmctEOY8mLvWpxfQp_iNs',
>>>>>>> 10f07298e606398b90d5086095e6ff47a095c2b7
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}