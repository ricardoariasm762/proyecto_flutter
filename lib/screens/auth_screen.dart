import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authService = AuthService();

  Future<String?> _authUser(LoginData data) async {
    try {
      await _authService.signIn(data.name, data.password);
      return null;
    } catch (e) {
      return 'Error de conexión o credenciales incorrectas.';
    }
  }

  Future<String?> _signupUser(SignupData data) async {
    try {
      await _authService.signUp(data.name!, data.password!);
      return null;
    } catch (e) {
       return 'Error al registrar el usuario.';
    }
  }

  Future<String> _recoverPassword(String name) async {
    return 'Revisa tu correo para recuperar la contraseña';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return FlutterLogin(
      title: 'RideMatch',
      onLogin: _authUser,
      onSignup: _signupUser,
      onRecoverPassword: _recoverPassword,
      onSubmitAnimationCompleted: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      },
      theme: LoginTheme(
        primaryColor: colorScheme.primary,
        accentColor: colorScheme.secondary,
        errorColor: colorScheme.error,
        titleStyle: TextStyle(
          color: colorScheme.primary,
          fontSize: 45,
          fontWeight: FontWeight.w800,
        ),
        bodyStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
        ),
        textFieldStyle: TextStyle(
          color: colorScheme.onSurface,
        ),
        buttonTheme: LoginButtonTheme(
          splashColor: colorScheme.primaryContainer,
          backgroundColor: colorScheme.primary,
          highlightColor: colorScheme.primary.withValues(alpha: 0.8),
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
