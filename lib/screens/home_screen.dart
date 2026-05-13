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
          title: 'Nueva Solicitud',
          body: 'Alguien quiere unirse a tu grupo',
          requestId: requestId,
        );

        Navigator.of(context).push(MaterialPageRoute(
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
        ));
      });

      // 2. Listen for Driver Pings (Driver online sees this)
      rideService.listenForDriverPings((groupData) {
        if (!mounted) return;
        if (!controller.isDriverOnline) return;

        final groupId = (groupData['id'] ?? '').toString();
        
        NotificationService().showRequestNotification(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title: 'Viaje Solicitado',
          body: 'Un grupo necesita un conductor',
          requestId: groupId,
        );

        Navigator.of(context).push(MaterialPageRoute(
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
        ));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();
    final lang = context.watch<LanguageController>().currentLanguage;
    
    final pages = [
      const TripsTab(),
      const CommunityTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      body: pages[controller.currentTabIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          height: 65,
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: Colors.black.withValues(alpha: 0.05),
          selectedIndex: controller.currentTabIndex,
          onDestinationSelected: (index) => controller.setTabIndex(index),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.map_outlined, color: Colors.grey),
              selectedIcon: const Icon(Icons.map_rounded, color: Colors.black),
              label: AppDictionary.text(lang, 'trips'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.groups_2_outlined, color: Colors.grey),
              selectedIcon: const Icon(Icons.groups_2_rounded, color: Colors.black),
              label: AppDictionary.text(lang, 'community'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded, color: Colors.grey),
              selectedIcon: const Icon(Icons.person_rounded, color: Colors.black),
              label: AppDictionary.text(lang, 'profile'),
            ),
          ],
        ),
      ),
    );
  }
}
