import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/language_controller.dart';
import '../../../core/localization/app_dictionary.dart';
import '../../../services/auth_service.dart';
import '../../auth_screen.dart';
import '../../my_trips_screen.dart';
import '../../theme_tab.dart';
import '../../language_screen.dart';
import '../../../theme/theme_controller.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final langController = context.watch<LanguageController>();
    final lang = langController.currentLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = AuthService();
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: isDark ? colorScheme.surface : Colors.white,
        elevation: 0,
        title: Text(
          AppDictionary.text(lang, 'profile'),
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildUserHeader(
            user?.email ?? AppDictionary.text(lang, 'user'),
            colorScheme,
            isDark,
          ),
          const SizedBox(height: 32),
          Text(
            AppDictionary.text(lang, 'visual_settings'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _OptionTile(
            icon: Icons.language_rounded,
            title: AppDictionary.text(lang, 'language'),
            subtitle: lang == 'en' ? 'English' : 'Español',
            colorScheme: colorScheme,
            isDark: isDark,
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const LanguageScreen()));
            },
          ),
          const SizedBox(height: 12),
          _OptionTile(
            icon: Icons.palette_outlined,
            title: AppDictionary.text(lang, 'visual_settings'),
            subtitle: AppDictionary.text(lang, 'visual_settings_desc'),
            colorScheme: colorScheme,
            isDark: isDark,
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ThemeTab()));
            },
            onLongPress: () {
              ThemeController.instance.toggleHalaMadridMode();
              final isMadrid = ThemeController.instance.isHalaMadridMode;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isMadrid
                        ? AppDictionary.text(lang, 'hala_madrid')
                        : AppDictionary.text(lang, 'standard_mode'),
                  ),
                  backgroundColor: isMadrid ? const Color(0xFF00529F) : null,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _OptionTile(
            icon: Icons.directions_car_outlined,
            title: AppDictionary.text(lang, 'my_trips'),
            subtitle: AppDictionary.text(lang, 'my_trips_subtitle'),
            colorScheme: colorScheme,
            isDark: isDark,
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const MyTripsScreen()));
            },
          ),
          const SizedBox(height: 32),
          Text(
            AppDictionary.text(lang, 'logout'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _OptionTile(
            icon: Icons.logout_rounded,
            title: AppDictionary.text(lang, 'logout'),
            subtitle: AppDictionary.text(lang, 'logout_subtitle'),
            isDestructive: true,
            colorScheme: colorScheme,
            isDark: isDark,
            onTap: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(String email, ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.person, color: colorScheme.onPrimary, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email.split('@')[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  email,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colorScheme,
    required this.isDark,
    this.onTap,
    this.onLongPress,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? colorScheme.error.withValues(alpha: 0.1)
                      : colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDestructive
                      ? colorScheme.error
                      : colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDestructive
                            ? colorScheme.error
                            : colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
