import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/controllers/home_controller.dart';
import '../core/localization/language_controller.dart';
import '../core/localization/app_dictionary.dart';
import 'home/tabs/trips_tab.dart';
import 'home/tabs/community_tab.dart';
import 'home/tabs/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<HomeController>();
      final lang = context.read<LanguageController>().currentLanguage;
      controller.getLocation(context, lang);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>().currentLanguage;
    
    final pages = [
      const TripsTab(),
      const CommunityTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
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
