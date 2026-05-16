import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../core/controllers/home_controller.dart';
import '../core/localization/language_controller.dart';
import '../core/localization/app_dictionary.dart';
import '../services/ride_service.dart';
import '../services/notification_service.dart';
import 'home/tabs/trips_tab.dart';
import 'home/tabs/community_tab.dart';
import 'home/tabs/profile_tab.dart';
import '../widgets/incoming_request_screen.dart';
import '../theme/theme_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<HomeController>();
      final lang = context.read<LanguageController>().currentLanguage;
      controller.getLocation(context, lang);

      final rideService = context.read<RideService>();

      // 1. Listen for Group Requests (Passenger creator sees this)
      rideService.listenForGroupRequests((requestData) {
        if (!mounted) return;
        final requestId = (requestData['id'] ?? '').toString();

        NotificationService().showRequestNotification(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title: AppDictionary.text(lang, 'new_request'),
          body: AppDictionary.text(lang, 'passenger_ping_desc'),
          requestId: requestId,
        );

        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => IncomingRequestScreen(
              requestData: requestData,
              isDriverPing: false,
              onAccept: () {
                rideService.acceptGroupRequest(membershipId: requestId);
                Navigator.of(context).pop();
              },
              onReject: () {
                rideService.rejectGroupRequest(membershipId: requestId);
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      });

      // 2. Listen for Driver Pings (Driver online sees this)
      rideService.listenForDriverPings((groupData) {
        if (!mounted) return;
        if (!controller.isDriverOnline) return;

        final groupId = (groupData['id'] ?? '').toString();

        NotificationService().showRequestNotification(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title: AppDictionary.text(lang, 'ride_requested'),
          body: AppDictionary.text(lang, 'driver_ping_desc'),
          requestId: groupId,
        );

        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => IncomingRequestScreen(
              requestData: groupData,
              isDriverPing: true,
              onAccept: () {
                rideService.acceptDriverPing(groupId);
                Navigator.of(context).pop();
              },
              onReject: () {
                rideService.rejectDriverPing(groupId);
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();
    final lang = context.watch<LanguageController>().currentLanguage;

    final pages = [const TripsTab(), const CommunityTab(), const ProfileTab()];

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final isMadrid = ThemeController.instance.isHalaMadridMode;

        return Scaffold(
          body: pages[controller.currentTabIndex],
          floatingActionButton: isMadrid ? FloatingActionButton(
                  onPressed: () {},
                  backgroundColor: const Color(0xFFFEBE10),
                  child: const Text('⚽', style: TextStyle(fontSize: 24)),
                )
              : null,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surface : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: NavigationBar(
              height: 65,
              backgroundColor: isDark ? colorScheme.surface : Colors.white,
              elevation: 0,
              indicatorColor: colorScheme.primary.withValues(alpha: 0.1),
              selectedIndex: controller.currentTabIndex,
              onDestinationSelected: (index) => controller.setTabIndex(index),
              destinations: [
                NavigationDestination(
                  icon: Icon(
                    Icons.map_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  selectedIcon: Icon(
                    Icons.map_rounded,
                    color: colorScheme.primary,
                  ),
                  label: isMadrid ? 'Copa' : AppDictionary.text(lang, 'trips'),
                ),
                NavigationDestination(
                  icon: Icon(
                    isMadrid
                        ? Icons.emoji_events_outlined
                        : Icons.groups_2_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  selectedIcon: Icon(
                    isMadrid
                        ? Icons.emoji_events_rounded
                        : Icons.groups_2_rounded,
                    color: colorScheme.primary,
                  ),
                  label: isMadrid
                      ? 'Afición'
                      : AppDictionary.text(lang, 'community'),
                ),
                NavigationDestination(
                  icon: Icon(
                    isMadrid
                        ? Icons.workspace_premium_outlined
                        : Icons.person_outline_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  selectedIcon: Icon(
                    isMadrid
                        ? Icons.workspace_premium_rounded
                        : Icons.person_rounded,
                    color: colorScheme.primary,
                  ),
                  label: isMadrid
                      ? 'Socio'
                      : AppDictionary.text(lang, 'profile'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
