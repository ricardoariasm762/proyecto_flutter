import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../core/localization/app_strings.dart';
import '../../../domain/repositories/location_repository.dart';
import '../../../domain/repositories/ride_repository.dart';
import 'home_controller.dart';
import 'widgets/community_tab.dart';
import 'widgets/profile_tab.dart';
import 'widgets/trips_tab.dart';

class HomeScreen extends StatefulWidget {
  final RideRepository rideRepository;
  final LocationRepository locationRepository;

  const HomeScreen({
    super.key,
    required this.rideRepository,
    required this.locationRepository,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController controller;
  final mapController = MapController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    controller = HomeController(
      rideRepository: widget.rideRepository,
      locationRepository: widget.locationRepository,
    );
    controller.init(setState);
  }

  void _onCreateRide() async {
    await controller.createRide(
      onSuccess: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.rideCreated)),
        );
      },
      setState: setState,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      TripsTab(
        controller: controller,
        mapController: mapController,
        setState: setState,
        onCreateRide: _onCreateRide,
      ),
      CommunityTab(
        controller: controller,
        setState: setState,
      ),
      const ProfileTab(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                await controller.getLocation(setState);
                if (controller.currentPosition != null) {
                  mapController.move(controller.currentPosition!, 15);
                }
              },
              icon: const Icon(Icons.gps_fixed_rounded),
              label: const Text(AppStrings.centerMap),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: AppStrings.tabTrips,
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_2_outlined),
            selectedIcon: Icon(Icons.groups_2_rounded),
            label: AppStrings.tabCommunity,
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: AppStrings.tabProfile,
          ),
        ],
      ),
    );
  }
}
