import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
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
      
      // Start listening to ride requests
      final rideService = context.read<RideService>();
      rideService.listenForRideRequests((requestData) {
        if (!mounted) return;
        final requestId = (requestData['id'] ?? '').toString();
        
        // Also show local notification for background cases
        NotificationService().showRequestNotification(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title: 'Nueva solicitud de viaje',
          body: 'Alguien quiere unirse a tu viaje.',
          requestId: requestId,
        );

        AwesomeDialog(
          context: context,
          dialogType: DialogType.infoReverse,
          headerAnimationLoop: true,
          animType: AnimType.bottomSlide,
          title: '¡Nueva Solicitud!',
          desc: 'Alguien ha solicitado unirse a tu viaje.\n¿Deseas aceptar o rechazar la solicitud?',
          btnCancelText: 'Rechazar',
          btnOkText: 'Aceptar',
          btnCancelOnPress: () async {
            try {
              await Supabase.instance.client
                  .from('ride_requests')
                  .update({'status': 'rejected'})
                  .eq('id', requestId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Solicitud rechazada')),
                );
              }
            } catch (_) {}
          },
          btnOkOnPress: () async {
            try {
              await Supabase.instance.client
                  .from('ride_requests')
                  .update({'status': 'accepted'})
                  .eq('id', requestId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Solicitud aceptada exitosamente')),
                );
              }
            } catch (_) {}
          },
        ).show();
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: controller.currentTabIndex,
        onDestinationSelected: (index) => controller.setTabIndex(index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map_rounded),
            label: AppDictionary.text(lang, 'trips'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_2_outlined),
            selectedIcon: const Icon(Icons.groups_2_rounded),
            label: AppDictionary.text(lang, 'community'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: AppDictionary.text(lang, 'profile'),
          ),
        ],
      ),
    );
  }
}
