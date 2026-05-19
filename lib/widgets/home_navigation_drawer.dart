import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/controllers/home_controller.dart';
import '../core/localization/app_dictionary.dart';
import '../core/localization/language_controller.dart';
import '../screens/auth_screen.dart';
import '../screens/my_trips_screen.dart';
import '../screens/theme_tab.dart';
import '../services/auth_service.dart';

/// Menú lateral inspirado en el cajón del [Taxi-App](https://github.com/OpenConsultingGroup/Taxi-App),
/// conectado a pantallas reales de RideMatch.
class HomeNavigationDrawer extends StatelessWidget {
  const HomeNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>().currentLanguage;
    final user = AuthService().currentUser;
    final scheme = Theme.of(context).colorScheme;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary,
                  Color.lerp(scheme.primary, scheme.tertiary, 0.35)!,
                ],
              ),
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppDictionary.text(lang, 'app_title'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppDictionary.text(lang, 'drawer_quick_links'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onPrimary.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? AppDictionary.text(lang, 'user'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onPrimary.withOpacity(0.95),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.map_rounded, color: scheme.primary),
            title: Text(AppDictionary.text(lang, 'trips')),
            onTap: () {
              Navigator.pop(context);
              context.read<HomeController>().setTabIndex(0);
            },
          ),
          ListTile(
            leading: Icon(Icons.groups_2_rounded, color: scheme.primary),
            title: Text(AppDictionary.text(lang, 'community')),
            onTap: () {
              Navigator.pop(context);
              context.read<HomeController>().setTabIndex(1);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.directions_car_filled_rounded,
              color: scheme.primary,
            ),
            title: Text(AppDictionary.text(lang, 'my_trips')),
            subtitle: Text(AppDictionary.text(lang, 'my_trips_subtitle')),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const MyTripsScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.palette_rounded, color: scheme.primary),
            title: Text(AppDictionary.text(lang, 'visual_settings')),
            subtitle: Text(AppDictionary.text(lang, 'visual_settings_desc')),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: ThemeTab()),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.person_rounded, color: scheme.primary),
            title: Text(AppDictionary.text(lang, 'profile')),
            onTap: () {
              Navigator.pop(context);
              context.read<HomeController>().setTabIndex(2);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.logout_rounded, color: scheme.error),
            title: Text(AppDictionary.text(lang, 'logout')),
            subtitle: Text(AppDictionary.text(lang, 'logout_subtitle')),
            onTap: () async {
              Navigator.pop(context);
              await AuthService().signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const AuthScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
