import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/language_controller.dart';
import '../../../core/localization/app_dictionary.dart';
import '../../../services/auth_service.dart';
import '../../auth_screen.dart';
import '../../my_trips_screen.dart';
import '../../theme_tab.dart';
import '../widgets/profile_card.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final langController = context.watch<LanguageController>();
    final lang = langController.currentLanguage;
    final authService = AuthService();
    final user = authService.currentUser;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          ProfileCard(email: user?.email ?? AppDictionary.text(lang, 'user')),
          const SizedBox(height: 12),
          _OptionTile(
            icon: Icons.language_rounded,
            title: AppDictionary.text(lang, 'language'),
            subtitle: AppDictionary.text(lang, 'change_language'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lang == 'en' ? 'EN' : 'ES',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: lang == 'en',
                  onChanged: (value) {
                    langController.toggleLanguage();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _OptionTile(
            icon: Icons.palette_rounded,
            title: AppDictionary.text(lang, 'visual_settings'),
            subtitle: AppDictionary.text(lang, 'visual_settings_desc'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const Scaffold(body: ThemeTab()),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _OptionTile(
            icon: Icons.directions_car_filled_rounded,
            title: AppDictionary.text(lang, 'my_trips'),
            subtitle: AppDictionary.text(lang, 'my_trips_subtitle'),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const MyTripsScreen()));
            },
          ),
          const SizedBox(height: 8),
          _OptionTile(
            icon: Icons.logout_rounded,
            title: AppDictionary.text(lang, 'logout'),
            subtitle: AppDictionary.text(lang, 'logout_subtitle'),
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
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
