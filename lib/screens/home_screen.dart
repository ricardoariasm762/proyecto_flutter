import 'package:flutter/material.dart';
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

    final isDriver = controller.userRole == 'driver';

    final pages = isDriver
        ? (controller.isPickingUp ||
                  controller.isOnTrip ||
                  controller.isPaymentPending
              ? [const TripsTab(), const CommunityTab(), const ProfileTab()]
              : [const CommunityTab(), const ProfileTab()])
        : [const TripsTab(), const CommunityTab(), const ProfileTab()];
    final safeTabIndex = controller.currentTabIndex < pages.length
        ? controller.currentTabIndex
        : 0;

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final isMadrid = ThemeController.instance.isHalaMadridMode;

        return Scaffold(
          appBar: AppBar(
            title: Text(AppDictionary.text(lang, 'app_title')),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              if (isDriver)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Row(
                    children: [
                      Text(
                        controller.isDriverOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: controller.isDriverOnline
                              ? colorScheme.tertiary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Switch(
                        value: controller.isDriverOnline,
                        onChanged: (val) =>
                            controller.toggleDriverOnline(val, context),
                        activeColor: colorScheme.tertiary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          body: Stack(
            children: [
              pages[safeTabIndex],
              if (controller.isSearching ||
                  controller.isGatheringMembers ||
                  controller.isPickingUp ||
                  controller.isOnTrip ||
                  controller.isPaymentPending)
                _buildActiveSearchOverlay(
                  context,
                  controller,
                  lang,
                  colorScheme,
                  isDark,
                ),
            ],
          ),
          floatingActionButton: isMadrid
              ? FloatingActionButton(
                  heroTag: 'madrid_fab',
                  onPressed: () {},
                  backgroundColor: const Color(0xFFFEBE10),
                  child: const Text('⚽', style: TextStyle(fontSize: 24)),
                )
              : null,
          bottomNavigationBar:
              (controller.isSearching ||
                  controller.isGatheringMembers ||
                  controller.isPickingUp ||
                  controller.isOnTrip ||
                  controller.isPaymentPending)
              ? null
              : Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.35 : 0.08,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: NavigationBar(
                    height: 65,
                    backgroundColor: colorScheme.surface,
                    elevation: 0,
                    indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
                    selectedIndex: safeTabIndex,
                    onDestinationSelected: (index) =>
                        controller.setTabIndex(index),
                    destinations: [
                      if (!isDriver)
                        NavigationDestination(
                          icon: Icon(
                            Icons.map_outlined,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          selectedIcon: Icon(
                            Icons.map_rounded,
                            color: colorScheme.primary,
                          ),
                          label: isMadrid
                              ? 'Copa'
                              : AppDictionary.text(lang, 'trips'),
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

  Widget _buildActiveSearchOverlay(
    BuildContext context,
    HomeController controller,
    String lang,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    if (controller.isOnTrip || controller.isPickingUp) {
      // Modo Viaje o Recogida: Panel inferior pequeño para ver el mapa
      final isPickingUp = controller.isPickingUp;
      final isDriver = controller.userRole == 'driver';
      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isPickingUp
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPickingUp
                          ? Icons.hail_rounded
                          : Icons.directions_car_rounded,
                      color: isPickingUp ? Colors.orange : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPickingUp
                              ? (isDriver
                                    ? 'Yendo a recoger'
                                    : 'Conductor en camino')
                              : 'Viaje en curso',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          isPickingUp
                              ? (isDriver
                                    ? 'Dirígete al punto de recogida'
                                    : 'Encuéntrate con tu conductor')
                              : (isDriver
                                    ? 'Dirígete al destino'
                                    : 'El conductor se dirige al destino'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    controller.activePassengerCount > 1
                        ? '\$${controller.perPersonFare.round()} c/u'
                        : '\$${(controller.offeredPrice ?? 0).round()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              if (isDriver && isPickingUp) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final groupId = controller.currentGroupId;
                      if (groupId == null) return;
                      await context.read<RideService>().markPickedUp(groupId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('YA RECOGÍ AL USUARIO'),
                  ),
                ),
              ],
              if (isDriver && controller.isOnTrip) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final groupId = controller.currentGroupId;
                      if (groupId == null) return;
                      await context.read<RideService>().markArrived(groupId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('LLEGAMOS AL DESTINO'),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => controller.cancelCurrentTrip(context, lang),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    lang == 'es' ? 'CANCELAR VIAJE' : 'CANCEL TRIP',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    String statusTitle = 'Buscando acompañantes...';
    String statusSubtitle = 'Esperando que otros se unan a tu viaje';
    IconData statusIcon = Icons.groups_rounded;
    Color statusColor = Colors.orange;
    String primaryButtonLabel = 'BUSCAR CONDUCTOR AHORA';
    VoidCallback? onPrimaryTap = () =>
        controller.startDriverSearch(context, lang);

    if (controller.isSearching) {
      statusTitle = 'Buscando conductor...';
      statusSubtitle = 'Estamos enviando tu oferta a conductores cercanos';
      statusIcon = Icons.search_rounded;
      statusColor = colorScheme.primary;
      primaryButtonLabel = ''; // No hay botón primario en búsqueda
      onPrimaryTap = null;
    } else if (controller.isPaymentPending) {
      final isDriver = controller.userRole == 'driver';
      final status = controller.tripStatus ?? '';
      final amount = controller.activePassengerCount > 1
          ? controller.perPersonFare.round()
          : (controller.offeredPrice ?? 0).round();

      statusTitle = 'Cobro del viaje';
      statusIcon = Icons.payments_rounded;
      statusColor = Colors.green;

      if (!isDriver && status == 'payment_pending') {
        statusSubtitle = 'Paga al conductor la cantidad de \$$amount';
        primaryButtonLabel = 'YA PAGUÉ';
        onPrimaryTap = () async {
          final groupId = controller.currentGroupId;
          if (groupId == null) return;
          await context.read<RideService>().confirmPassengerPaid(groupId);
        };
      } else if (!isDriver && status == 'payment_confirmed') {
        statusSubtitle = 'Pago reportado. Esperando confirmación del conductor';
        primaryButtonLabel = '';
        onPrimaryTap = null;
      } else if (isDriver && status == 'payment_pending') {
        statusSubtitle = 'Esperando que el usuario pague \$$amount';
        primaryButtonLabel = '';
        onPrimaryTap = null;
      } else if (isDriver && status == 'payment_confirmed') {
        statusSubtitle = 'El usuario reportó el pago. Confirma para terminar';
        primaryButtonLabel = 'CONFIRMAR PAGO Y TERMINAR';
        onPrimaryTap = () async {
          final groupId = controller.currentGroupId;
          if (groupId == null) return;
          await context.read<RideService>().completeAfterPayment(groupId);
        };
      } else {
        statusSubtitle = 'Procesando...';
        primaryButtonLabel = '';
        onPrimaryTap = null;
      }
    }

    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: (controller.isSearching)
                    ? const CircularProgressIndicator()
                    : Icon(statusIcon, size: 48, color: statusColor),
              ),
              const SizedBox(height: 24),
              Text(
                statusTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                statusSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.activePassengerCount > 1
                              ? 'Total por persona'
                              : 'Total a pagar',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          '\$${controller.activePassengerCount > 1 ? controller.perPersonFare.round() : (controller.offeredPrice ?? 0).round()}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    if (controller.isSearching)
                      Row(
                        children: [
                          _buildQuickPriceBtn(
                            '-500',
                            () => controller.updateOfferedPrice(
                              (controller.offeredPrice ?? 0) - 500,
                            ),
                            colorScheme,
                          ),
                          const SizedBox(width: 8),
                          _buildQuickPriceBtn(
                            '+500',
                            () => controller.updateOfferedPrice(
                              (controller.offeredPrice ?? 0) + 500,
                            ),
                            colorScheme,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (primaryButtonLabel.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: onPrimaryTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      primaryButtonLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              if (!controller.isPaymentPending)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () =>
                        controller.cancelCurrentTrip(context, lang),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      lang == 'es' ? 'CANCELAR VIAJE' : 'CANCEL TRIP',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPriceBtn(
    String label,
    VoidCallback onTap,
    ColorScheme colorScheme,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
