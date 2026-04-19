import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Stream<AuthState> get authStateChanges => _remote.authStateChanges;

  @override
  User? get currentUser => _remote.currentUser;

  @override
  Future<AuthResponse> signUp(String email, String password) {
    return _remote.signUp(email, password);
  }

  @override
  Future<AuthResponse> signIn(String email, String password) {
    return _remote.signIn(email, password);
  }

  @override
  Future<void> signOut() {
    return _remote.signOut();
  }
}
