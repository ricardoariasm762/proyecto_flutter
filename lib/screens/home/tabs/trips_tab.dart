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

    if (controller.currentPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
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
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: 'com.ridematch.communityapp',
            ),
            if (controller.routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: controller.routePoints,
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 4.0,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: controller.currentPosition!,
                  width: 50,
                  height: 50,
                  child: Icon(
                    Icons.my_location_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 40,
                  ),
                ),
                if (controller.destination != null)
                  Marker(
                    point: controller.destination!,
                    width: 50,
                    height: 50,
                    child: Icon(
                      Icons.location_pin,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 42,
                    ),
                  ),
              ],
            ),
          ],
        ),
        _buildRouteInfoCard(context, controller, lang),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 16),
                child: FloatingActionButton.extended(
                  onPressed: () async {
                    await controller.getLocation(context, lang);
                    controller.recenterMap();
                  },
                  icon: const Icon(Icons.gps_fixed_rounded),
                  label: Text(AppDictionary.text(lang, 'center')),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 26),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppDictionary.text(lang, 'available_seats'),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppDictionary.text(lang, 'max_participants'),
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (controller.availableSeats > 1) {
                                controller.setAvailableSeats(controller.availableSeats - 1);
                              }
                            },
                            icon: const Icon(Icons.remove),
                            color: controller.availableSeats > 1 ? Theme.of(context).colorScheme.primary : Colors.grey,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              "${controller.availableSeats}",
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              if (controller.availableSeats < 5) {
                                controller.setAvailableSeats(controller.availableSeats + 1);
                              }
                            },
                            icon: const Icon(Icons.add),
                            color: controller.availableSeats < 5 ? Theme.of(context).colorScheme.primary : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRouteInfoCard(BuildContext context, HomeController controller, String lang) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            _buildAddressRow(context, Icons.location_on, AppDictionary.text(lang, 'from'), controller.getOriginTitle(lang), true),
            const SizedBox(height: 12),
            _buildAddressRow(context, Icons.location_on, AppDictionary.text(lang, 'to'), controller.getDestinationTitle(lang), false),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.destination == null ? null : () => controller.createRide(context, lang),
                    icon: const Icon(Icons.directions_car_filled_rounded),
                    label: Text(AppDictionary.text(lang, 'publish_ride')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressRow(BuildContext context, IconData icon, String label, String address, bool isOrigin) {
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
