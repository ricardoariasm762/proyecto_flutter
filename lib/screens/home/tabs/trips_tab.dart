import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../../../core/controllers/home_controller.dart';
import '../../../core/localization/language_controller.dart';
import '../../../core/localization/app_dictionary.dart';

class TripsTab extends StatelessWidget {
  const TripsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();
    final lang = context.watch<LanguageController>().currentLanguage;
    final colorScheme = Theme.of(context).colorScheme;

    if (controller.currentPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: controller.mapController,
            options: MapOptions(
              initialCenter: controller.currentPosition!,
              initialZoom: 15,
              onTap: (_, point) {
                controller.setDestination(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.ridematch.communityapp',
              ),
              if (controller.routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: controller.routePoints,
                      color: Colors.black,
                      strokeWidth: 5.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: controller.currentPosition!,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (controller.destination != null)
                    Marker(
                      point: controller.destination!,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_on_rounded,
                        color: Colors.redAccent,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Top Search Bar
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: _buildTopSearch(context, controller, lang),
          ),

          // Map Controls
          Positioned(
            right: 20,
            bottom: controller.destination != null ? 300 : 160,
            child: Column(
              children: [
                _buildMapControl(
                  icon: Icons.my_location_rounded,
                  onTap: () async {
                    await controller.getLocation(context, lang);
                    controller.recenterMap();
                  },
                ),
              ],
            ),
          ),

          // Bottom Sheet
          _buildBottomSheet(context, controller, lang),
        ],
      ),
    );
  }

  Widget _buildTopSearch(
    BuildContext context,
    HomeController controller,
    String lang,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.destination == null
                  ? AppDictionary.text(lang, 'select_destination')
                  : controller.getDestinationTitle(lang),
              style: TextStyle(
                color: controller.destination == null
                    ? Colors.grey[500]
                    : Colors.black,
                fontWeight: controller.destination == null
                    ? FontWeight.normal
                    : FontWeight.w600,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (controller.destination != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () {
                // Clear destination logic
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMapControl({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black87),
      ),
    );
  }

  Widget _buildBottomSheet(
    BuildContext context,
    HomeController controller,
    String lang,
  ) {
    if (controller.destination == null) {
      return Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿A dónde vamos?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildLocationShortcut(
                icon: Icons.home_rounded,
                title: 'Casa',
                onTap: () {},
              ),
              const Divider(height: 1),
              _buildLocationShortcut(
                icon: Icons.work_rounded,
                title: 'Trabajo',
                onTap: () {},
              ),
            ],
          ),
        ),
      );
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Viaje Compartido',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Viaja con otros y ahorra',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${(controller.routeDistance ?? 0 / 1000 * 1500).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (controller.userRole == 'passenger')
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildSeatActionButton(
                          icon: Icons.remove,
                          onTap: () => controller.setAvailableSeats(
                            controller.availableSeats - 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            children: [
                              Text(
                                '${controller.availableSeats}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const Text(
                                'asientos',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildSeatActionButton(
                          icon: Icons.add,
                          onTap: () => controller.setAvailableSeats(
                            controller.availableSeats + 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => controller.createGroup(context, lang),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Confirmar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              _buildDriverControls(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    );
  }

  Widget _buildLocationShortcut({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDriverControls(BuildContext context, HomeController controller) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Modo Conductor",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Switch(
              value: controller.isDriverOnline,
              onChanged: (val) => controller.toggleDriverOnline(val, context),
              activeColor: Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          controller.isDriverOnline
              ? "En línea: Esperando solicitudes"
              : "Desconectado",
          style: TextStyle(
            color: controller.isDriverOnline ? Colors.green : Colors.grey,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressRow(
    BuildContext context,
    IconData icon,
    String label,
    String address,
    bool isOrigin,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isOrigin
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.secondaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isOrigin
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
