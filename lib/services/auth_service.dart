import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // Registrar usuario con email y contraseña
  Future<AuthResponse> signUp(String email, String password) async {
    return await supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  // Iniciar sesión con email y contraseña
  Future<AuthResponse> signIn(String email, String password) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // Obtener el usuario actual
  User? get currentUser => supabase.auth.currentUser;

  // Stream de cambios en el estado de autenticación
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;
}
