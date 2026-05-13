import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authService = AuthService();
  bool _isLogin = true;
  String _role = 'passenger';
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _showResendButton = false;

  Future<void> _resendEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _authService.resendVerificationEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Correo de verificación re-enviado. Revisa tu bandeja de entrada.',
            ),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    setState(() {
      _isLoading = true;
      _showResendButton = false;
    });

    try {
      if (_isLogin) {
        await _authService.signIn(email, password);
      } else {
        final response = await _authService.signUp(
          email,
          password,
          name,
          _role,
        );
        if (mounted) {
          if (response.session == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '¡Cuenta creada! Revisa tu correo para verificarla antes de iniciar sesión.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 8),
              ),
            );
            setState(() {
              _isLogin = true;
              _showResendButton = true;
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Cuenta creada e iniciada exitosamente!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        final isUnconfirmed = e.message.toLowerCase().contains(
          'email not confirmed',
        );
        if (isUnconfirmed) {
          setState(() => _showResendButton = true);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUnconfirmed
                  ? 'Debes confirmar tu correo electrónico antes de entrar.'
                  : 'Error: ${e.message}',
            ),
            backgroundColor: isUnconfirmed ? Colors.orange : Colors.redAccent,
            action: isUnconfirmed
                ? SnackBarAction(
                    label: 'Re-enviar',
                    textColor: Colors.white,
                    onPressed: _resendEmail,
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.directions_car_filled_rounded,
                  size: 40,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isLogin ? 'Bienvenido de nuevo' : 'Crea tu cuenta',
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin
                    ? 'Inicia sesión para continuar con tus viajes.'
                    : 'Únete a nuestra comunidad de viajes compartidos.',
                style: textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 48),
              if (!_isLogin) ...[
                _buildLabel('Nombre Completo'),
                TextField(
                  controller: _nameController,
                  decoration: _inputDecoration(
                    'Tu nombre',
                    Icons.person_outline,
                  ),
                ),
                const SizedBox(height: 24),
                _buildLabel('Selecciona tu Rol'),
                Row(
                  children: [
                    Expanded(
                      child: _roleButton(
                        'Pasajero',
                        'passenger',
                        Icons.person_search_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _roleButton(
                        'Conductor',
                        'driver',
                        Icons.drive_eta_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              _buildLabel('Correo Electrónico'),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(
                  'nombre@ejemplo.com',
                  Icons.email_outlined,
                ),
              ),
              const SizedBox(height: 24),
              _buildLabel('Contraseña'),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: _inputDecoration('••••••••', Icons.lock_outline),
              ),
              if (_showResendButton && _isLogin) ...[
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: _isLoading ? null : _resendEmail,
                    icon: const Icon(Icons.mark_email_read_outlined, size: 18),
                    label: const Text('Re-enviar correo de verificación'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange[800],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isLogin ? 'Iniciar Sesión' : 'Registrarse',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                  child: RichText(
                    text: TextSpan(
                      text: _isLogin
                          ? '¿No tienes una cuenta? '
                          : '¿Ya tienes una cuenta? ',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      children: [
                        TextSpan(
                          text: _isLogin ? 'Regístrate' : 'Inicia Sesión',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
    );
  }

  Widget _roleButton(String title, String value, IconData icon) {
    final isSelected = _role == value;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => setState(() => _role = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey[600]),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
