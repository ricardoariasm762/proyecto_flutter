import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/controllers/home_controller.dart';
import '../../../core/localization/language_controller.dart';
import '../../../core/localization/app_dictionary.dart';
import '../../../theme/theme_controller.dart';

class TripsTab extends StatelessWidget {
  const TripsTab({super.key});

  Future<void> _handleManualSearch(
    BuildContext context,
    HomeController controller,
    String lang,
  ) async {
    final addressController = TextEditingController();
    final String? address = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppDictionary.text(lang, 'select_destination')),
        content: TextField(
          controller: addressController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppDictionary.text(lang, 'enter_address'),
          ),
          onSubmitted: (val) => Navigator.pop(context, val),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppDictionary.text(lang, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, addressController.text),
            child: Text(AppDictionary.text(lang, 'save')),
          ),
        ],
      ),
    );

    if (address != null && address.isNotEmpty) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      final point = await controller.geocodeAddress(address);

      if (context.mounted) Navigator.pop(context); // Close loading

      if (point != null) {
        controller.setDestination(point, address: address);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppDictionary.text(lang, 'location_not_found')),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleRecentSelection(
    HomeController controller,
    Map<String, dynamic> search,
  ) async {
    final point = LatLng(search['lat'], search['lng']);
    controller.setDestination(point, address: search['address']);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();
    final lang = context.watch<LanguageController>().currentLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                urlTemplate: isDark
                    ? "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png"
                    : "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.ridematch.communityapp',
              ),
              if (controller.routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: controller.routePoints,
                      color: colorScheme.primary,
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
                        color: isDark ? colorScheme.surface : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black54 : Colors.black26,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
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
                        color: colorScheme.error,
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
            child: _buildTopSearch(
              context,
              controller,
              lang,
              colorScheme,
              isDark,
            ),
          ),

          if (ThemeController.instance.isHalaMadridMode)
            const Positioned(
              top: 110,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '¡HALA MADRID Y NADA MÁS!',
                  style: TextStyle(
                    color: Color(0xFFFEBE10),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
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
                  colorScheme: colorScheme,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // Bottom Sheet
          _buildBottomSheet(context, controller, lang, colorScheme, isDark),
        ],
      ),
    );
  }

  Widget _buildTopSearch(
    BuildContext context,
    HomeController controller,
    String lang,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => _handleManualSearch(context, controller, lang),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                controller.destination == null
                    ? AppDictionary.text(lang, 'select_destination')
                    : controller.getDestinationTitle(lang),
                style: TextStyle(
                  color: controller.destination == null
                      ? colorScheme.onSurfaceVariant.withOpacity(0.6)
                      : colorScheme.onSurface,
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
                icon: Icon(
                  Icons.close,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  controller.clearDestination();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControl({
    required IconData icon,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: colorScheme.onSurface),
      ),
    );
  }

  Widget _buildBottomSheet(
    BuildContext context,
    HomeController controller,
    String lang,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    if (controller.destination == null) {
      return Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _handleManualSearch(context, controller, lang),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppDictionary.text(lang, 'where_to'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (controller.recentSearches.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.recentSearches.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final search = controller.recentSearches[index];
                    return _buildLocationShortcut(
                      icon: Icons.history_rounded,
                      title: search['address'],
                      onTap: () => _handleRecentSelection(controller, search),
                      colorScheme: colorScheme,
                      isDark: isDark,
                    );
                  },
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
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
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
                        AppDictionary.text(lang, 'shared_ride'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        AppDictionary.text(lang, 'travel_save'),
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  () {
                    if (controller.aiSuggestedPrice != null &&
                        controller.aiSuggestedPrice!.isFinite) {
                      return '\$${controller.aiSuggestedPrice!.round()}';
                    }
                    final distance = controller.routeDistance ?? 0;
                    if (distance.isFinite && distance > 0) {
                      return '\$${((distance / 1000) * 1500).round()}';
                    }
                    return '\$0';
                  }(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (controller.userRole == 'passenger')
              Column(
                children: [
                  if (controller.aiSuggestedTime != null ||
                      controller.aiRecommendation != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (controller.aiSuggestedTime != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  controller.aiSuggestedTime!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          if (controller.aiRecommendation != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              controller.aiRecommendation!,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? colorScheme.surfaceVariant
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildSeatActionButton(
                              icon: Icons.remove,
                              onTap: () => controller.setAvailableSeats(
                                controller.availableSeats - 1,
                              ),
                              colorScheme: colorScheme,
                              isDark: isDark,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${controller.availableSeats}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    AppDictionary.text(lang, 'seats'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colorScheme.onSurfaceVariant,
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
                              colorScheme: colorScheme,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () =>
                                controller.createGroup(context, lang),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? colorScheme.primary
                                  : Colors.black,
                              foregroundColor: isDark
                                  ? colorScheme.onPrimary
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              AppDictionary.text(lang, 'confirm'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
          ],
        ),
        child: Icon(icon, size: 20, color: colorScheme.onSurface),
      ),
    );
  }

  Widget _buildLocationShortcut({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceVariant : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withOpacity(isDark ? 0.2 : 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverControls(BuildContext context, HomeController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppDictionary.text(
                context.read<LanguageController>().currentLanguage,
                'driver_mode',
              ),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colorScheme.onSurface,
              ),
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
              ? AppDictionary.text(
                  context.read<LanguageController>().currentLanguage,
                  'online',
                )
              : AppDictionary.text(
                  context.read<LanguageController>().currentLanguage,
                  'offline',
                ),
          style: TextStyle(
            color: controller.isDriverOnline
                ? Colors.green
                : colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
