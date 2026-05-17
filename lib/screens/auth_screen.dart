import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../core/localization/language_controller.dart';
import '../core/localization/app_dictionary.dart';

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

  Future<void> _resendEmail(String lang) async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _authService.resendVerificationEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppDictionary.text(lang, 'resend_verification')),
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

  Future<void> _submit(String lang) async {
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
          email: email,
          password: password,
          fullName: name,
          role: _role,
        );
        if (mounted) {
          if (response.session == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppDictionary.text(lang, 'account_created_verify'),
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 8),
              ),
            );
            setState(() {
              _isLogin = true;
              _showResendButton = true;
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Success!'),
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
                  ? AppDictionary.text(lang, 'email_unconfirmed')
                  : 'Error: ${e.message}',
            ),
            backgroundColor: isUnconfirmed ? Colors.orange : Colors.redAccent,
            action: isUnconfirmed
                ? SnackBarAction(
                    label: AppDictionary.text(lang, 'send'),
                    textColor: Colors.white,
                    onPressed: () => _resendEmail(lang),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<LanguageController>().currentLanguage;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : Colors.white,
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
                  color: colorScheme.primary.withOpacity(0.1),
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
                _isLogin
                    ? AppDictionary.text(lang, 'welcome_back')
                    : AppDictionary.text(lang, 'create_account'),
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? colorScheme.onSurface : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin
                    ? AppDictionary.text(lang, 'login_subtitle')
                    : AppDictionary.text(lang, 'signup_subtitle'),
                style: textTheme.bodyLarge?.copyWith(
                  color: isDark
                      ? colorScheme.onSurfaceVariant
                      : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),
              if (!_isLogin) ...[
                _buildLabel(AppDictionary.text(lang, 'full_name')),
                TextField(
                  controller: _nameController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    AppDictionary.text(lang, 'full_name'),
                    Icons.person_outline,
                  ),
                ),
                const SizedBox(height: 24),
                _buildLabel(AppDictionary.text(lang, 'select_role')),
                Row(
                  children: [
                    Expanded(
                      child: _roleButton(
                        AppDictionary.text(lang, 'passenger'),
                        'passenger',
                        Icons.person_outline,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _roleButton(
                        AppDictionary.text(lang, 'driver'),
                        'driver',
                        Icons.directions_car_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              _buildLabel(AppDictionary.text(lang, 'email')),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: _inputDecoration(
                  'nombre@ejemplo.com',
                  Icons.email_outlined,
                ),
              ),
              const SizedBox(height: 24),
              _buildLabel(AppDictionary.text(lang, 'password')),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: _inputDecoration('••••••••', Icons.lock_outline),
              ),
              if (_showResendButton && _isLogin) ...[
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: _isLoading ? null : () => _resendEmail(lang),
                    icon: const Icon(Icons.mark_email_read_outlined, size: 18),
                    label: Text(
                      AppDictionary.text(lang, 'resend_verification'),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? colorScheme.secondary
                          : Colors.orange[800],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _submit(lang),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? colorScheme.primary
                        : Colors.black,
                    foregroundColor: isDark
                        ? colorScheme.onPrimary
                        : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: isDark
                                ? colorScheme.onPrimary
                                : Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isLogin
                              ? AppDictionary.text(lang, 'login_btn')
                              : AppDictionary.text(lang, 'signup_btn'),
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
                          ? AppDictionary.text(lang, 'no_account')
                          : AppDictionary.text(lang, 'have_account'),
                      style: TextStyle(
                        color: isDark
                            ? colorScheme.onSurfaceVariant
                            : Colors.grey[600],
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: _isLogin
                              ? AppDictionary.text(lang, 'signup_btn')
                              : AppDictionary.text(lang, 'login_btn'),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface.withOpacity(0.8),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
      ),
      prefixIcon: Icon(icon, size: 20, color: colorScheme.primary),
      filled: true,
      fillColor: isDark ? colorScheme.surfaceVariant : const Color(0xFFF5F5F5),
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
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
    );
  }

  Widget _roleButton(String title, String value, IconData icon) {
    final isSelected = _role == value;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _role = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : (isDark ? colorScheme.surfaceVariant : const Color(0xFFF5F5F5)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
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
