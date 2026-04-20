import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import '../../domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client_provider.dart';
import '../../data/datasources/location_local_data_source.dart';
import '../../data/datasources/ride_remote_data_source.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../data/repositories/ride_repository_impl.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {

  Future<String?> _authUser(LoginData data) async {
    // Mock user temporal para que puedas ingresar sin Supabase configurado
    if (data.name == 'admin@admin.com' && data.password == '123456') {
      return null; // El valor nulo indica éxito
    }

    try {
      await widget.authRepository.signIn(data.name, data.password);
      return null;
    } catch (e) {
      return 'Error o conexión fallida. Sugerencia: Usa admin@admin.com y contraseña 123456';
    }
  }

  Future<String?> _signupUser(SignupData data) async {
    if (data.name == 'admin@admin.com') return 'El usuario ya existe';
    
    try {
      await widget.authRepository.signUp(data.name!, data.password!);
      return null;
    } catch (e) {
       return 'Error al registrar. Sugerencia: Inicia sesión con admin@admin.com';
    }
  }

  Future<String> _recoverPassword(String name) async {
    return 'Revisa tu correo para recuperar la contraseña';
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: 'RideMatch',
      onLogin: _authUser,
      onSignup: _signupUser,
      onRecoverPassword: _recoverPassword,
      onSubmitAnimationCompleted: () {
        // Redirigir al HomeScreen con las dependencias necesarias cuando el login es válido (ej. mock)
        final rideRemoteDataSource = RideRemoteDataSource(
          SupabaseClientProvider.instance.client,
        );
        final rideRepository = RideRepositoryImpl(rideRemoteDataSource);
        
        final locationLocalDataSource = LocationLocalDataSource();
        final locationRepository = LocationRepositoryImpl(locationLocalDataSource);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              rideRepository: rideRepository,
              locationRepository: locationRepository,
            ),
          ),
        );
      },
      theme: LoginTheme(
        primaryColor: Colors.deepPurple,
        accentColor: Colors.orange,
        errorColor: Colors.red,
        pageColorLight: Colors.deepPurple[300],
        pageColorDark: Colors.deepPurple[800],
        titleStyle: const TextStyle(
          color: Colors.orange,
          fontFamily: 'OpenSans',
          fontSize: 45,
          fontWeight: FontWeight.w400,
        ),
        bodyStyle: TextStyle(
          fontFamily: 'NotoSans',
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: Colors.deepPurple[300],
        ),
        textFieldStyle: const TextStyle(
          color: Colors.deepPurple,
          fontFamily: 'OpenSans',
        ),
        buttonTheme: const LoginButtonTheme(
          splashColor: Colors.deepPurple,
          backgroundColor: Colors.orange,
          highlightColor: Colors.deepPurpleAccent,
          elevation: 9.0,
          highlightElevation: 6.0,
        ),
      ),
      messages: LoginMessages(
        userHint: 'Email',
        passwordHint: 'Contraseña',
        confirmPasswordHint: 'Confirmar Contraseña',
        loginButton: 'ENTRAR',
        signupButton: 'REGISTRARSE',
        forgotPasswordButton: '¿Olvidaste tu contraseña?',
        recoverPasswordButton: 'RECUPERAR',
        goBackButton: 'VOLVER',
        confirmPasswordError: 'Las contraseñas no coinciden',
        recoverPasswordIntro: 'Recupera tu contraseña',
        recoverPasswordDescription:
            'Te enviaremos un enlace a tu correo para que restaures tu acceso.',
        recoverPasswordSuccess: 'Enlace enviado exitosamente',
      ),
    );
  }
}
