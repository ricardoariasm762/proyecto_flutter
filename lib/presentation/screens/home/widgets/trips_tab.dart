import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../../core/localization/app_strings.dart';
import '../home_controller.dart';

class TripsTab extends StatelessWidget {
  final HomeController controller;
  final MapController mapController;
  final Function(VoidCallback) setState;
  final VoidCallback onCreateRide;

  const TripsTab({
    super.key,
    required this.controller,
    required this.mapController,
    required this.setState,
    required this.onCreateRide,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.currentPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: controller.currentPosition!,
            initialZoom: 15,
            onTap: (_, point) => controller.updateDestination(point, setState),
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: controller.currentPosition!,
                  width: 50,
                  height: 50,
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: Color(0xFF6E41D8),
                    size: 40,
                  ),
                ),
                if (controller.destination != null)
                  Marker(
                    point: controller.destination!,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_pin,
                      color: Color(0xFFB04CFF),
                      size: 42,
                    ),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5A2DB1), Color(0xFF8A55FF)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              controller.destination == null
                  ? AppStrings.selectDest
                  : AppStrings.destReady,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
            decoration: const BoxDecoration(
              color: Color(0xFFFDFBFF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.publishRide,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 6),
                const Text(
                  AppStrings.communityModel,
                  style: TextStyle(color: Color(0xFF665489)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.destination == null ? null : onCreateRide,
                    icon: const Icon(Icons.add_road_rounded),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(AppStrings.createRideBtn),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
