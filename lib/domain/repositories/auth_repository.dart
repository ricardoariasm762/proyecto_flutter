import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Stream<AuthState> get authStateChanges;
  User? get currentUser;

  Future<AuthResponse> signUp(String email, String password);
  Future<AuthResponse> signIn(String email, String password);
  Future<void> signOut();
}
