import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<AuthResponse> signUp(String email, String password, String name, String role) async {
    return await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'role': role},
    );
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> resendVerificationEmail(String email) async {
    await supabase.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  User? get currentUser => supabase.auth.currentUser;
}
