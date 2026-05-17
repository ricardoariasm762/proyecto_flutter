import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/controllers/home_controller.dart';
import '../../../core/localization/language_controller.dart';
import '../../../core/localization/app_dictionary.dart';
import '../../../services/ride_service.dart';
import '../../../services/notification_service.dart';
import '../../chat_screen.dart';
import '../widgets/empty_card.dart';
import '../widgets/ride_card.dart';

class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});

  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab> {
  final _rideService = RideService();
  late Stream<List<Map<String, dynamic>>> _communityGroups;

  @override
  void initState() {
    super.initState();
    final userId =
        Supabase.instance.client.auth.currentSession?.user.id ??
        Supabase.instance.client.auth.currentUser?.id;
    _communityGroups = _rideService.getGatheringGroupsStreamExcludingUser(
      excludeUserId: userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>().currentLanguage;
    final controller = context.watch<HomeController>();
    final isDriver = controller.userRole == 'driver';
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: isDriver ? 1 : 2,
      child: Scaffold(
        backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: isDark ? colorScheme.surface : Colors.white,
          elevation: 0,
          centerTitle: false,
          title: Text(
            isDriver
                ? 'Viajes Disponibles'
                : AppDictionary.text(lang, 'community'),
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          bottom: isDriver
              ? null
              : TabBar(
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurfaceVariant,
                  indicatorColor: colorScheme.primary,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  tabs: [
                    Tab(text: AppDictionary.text(lang, 'explore')),
                    Tab(text: AppDictionary.text(lang, 'my_group')),
                  ],
                ),
        ),
        body: isDriver
            ? _buildExploreTab(context, lang, colorScheme, isDark, isDriver)
            : TabBarView(
                children: [
                  _buildExploreTab(
                    context,
                    lang,
                    colorScheme,
                    isDark,
                    isDriver,
                  ),
                  _buildMyGroupTab(context, lang, colorScheme, isDark),
                ],
              ),
      ),
    );
  }

  Widget _buildExploreTab(
    BuildContext context,
    String lang,
    ColorScheme colorScheme,
    bool isDark,
    bool isDriver,
  ) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _communityGroups,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(AppDictionary.text(lang, 'no_rides_loaded')),
          );
        }

        final groups = snapshot.data ?? [];
        if (groups.isEmpty) {
          return const Center(child: EmptyCard());
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: groups.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppDictionary.text(lang, 'nearby_groups'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppDictionary.text(lang, 'nearby_subtitle'),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            final group = groups[index - 1];
            final availableSeats = group['available_seats'] as int? ?? 4;
            final offeredPrice =
                (group['offered_price'] as num?)?.toDouble() ?? 6000.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: RideCard(
                ride: group,
                members: 1,
                seatsLeft: availableSeats,
                totalFare: offeredPrice,
                splitFare: offeredPrice,
                onJoin: isDriver
                    ? null
                    : () async {
                        final groupId = (group['id'] ?? '').toString();
                        if (groupId.isEmpty) return;

                        final hasActive = await _rideService
                            .hasActiveGroupRequest();
                        if (hasActive) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppDictionary.text(lang, 'already_in_group'),
                              ),
                              backgroundColor: colorScheme.error,
                            ),
                          );
                          return;
                        }

                        await _rideService.requestJoinGroup(groupId: groupId);

                        await NotificationService().showNotification(
                          id: DateTime.now().millisecondsSinceEpoch.remainder(
                            100000,
                          ),
                          title: AppDictionary.text(lang, 'request_sent'),
                          body: AppDictionary.text(
                            lang,
                            'join_request_success',
                          ),
                        );

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppDictionary.text(lang, 'request_sent'),
                            ),
                          ),
                        );
                      },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyGroupTab(
    BuildContext context,
    String lang,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _rideService.getActiveGroupStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          );
        }

        final activeGroup = snapshot.data;
        if (activeGroup == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceVariant
                        : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.group_off_rounded,
                    size: 64,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppDictionary.text(lang, 'no_active_group'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppDictionary.text(lang, 'join_one_explore'),
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        final status = activeGroup['status']?.toString() ?? 'gathering';
        final isCreator =
            Supabase.instance.client.auth.currentUser?.id ==
            activeGroup['creator_id'];
        final groupId = activeGroup['id']?.toString() ?? '';
        final offeredPrice =
            (activeGroup['offered_price'] as num?)?.toDouble() ?? 6000.0;
        final availableSeats = activeGroup['available_seats'] as int? ?? 1;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusHeader(status, lang, colorScheme, isDark),
              const SizedBox(height: 32),
              Text(
                AppDictionary.text(lang, 'trip_details'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              RideCard(
                ride: activeGroup,
                members: 1,
                seatsLeft: availableSeats,
                totalFare: offeredPrice,
                splitFare: offeredPrice,
              ),
              const SizedBox(height: 32),
              Text(
                'Acciones del Viaje',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              if (isCreator && status == 'gathering')
                _buildActionButton(
                  icon: Icons.search_rounded,
                  title: AppDictionary.text(lang, 'search_driver_now'),
                  subtitle: 'Comienza a buscar transporte para el grupo',
                  color: colorScheme.primary,
                  onTap: () => context.read<HomeController>().startDriverSearch(
                    context,
                    lang,
                  ),
                ),
              const SizedBox(height: 12),
              _buildActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                title: AppDictionary.text(lang, 'group_chat'),
                subtitle: 'Comunícate con los demás miembros',
                color: Colors.blue,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(rideId: groupId),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                icon: Icons.cancel_outlined,
                title: 'Cancelar Viaje',
                subtitle: 'Eliminar esta petición de viaje',
                color: colorScheme.error,
                onTap: () => context.read<HomeController>().cancelSearch(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceVariant : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
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
            Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(
    String status,
    String lang,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    IconData icon = Icons.people_outline;
    String title = AppDictionary.text(lang, 'status_gathering');
    String desc = AppDictionary.text(lang, 'status_gathering_desc');
    Color color = Colors.orange;

    if (status == 'searching_driver') {
      icon = Icons.search_rounded;
      title = AppDictionary.text(lang, 'status_searching');
      desc = AppDictionary.text(lang, 'status_searching_desc');
      color = Colors.blue;
    } else if (status == 'driver_assigned') {
      icon = Icons.check_circle_outline_rounded;
      title = AppDictionary.text(lang, 'status_assigned');
      desc = AppDictionary.text(lang, 'status_assigned_desc');
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(color: color.withOpacity(0.8), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
