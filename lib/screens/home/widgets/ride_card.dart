import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../../core/localization/language_controller.dart';
import '../../../core/localization/app_dictionary.dart';

class RideCard extends StatelessWidget {
  const RideCard({
    required this.ride,
    required this.members,
    required this.seatsLeft,
    required this.totalFare,
    required this.splitFare,
    this.onOpenDetails,
    this.onJoin,
    this.onAccept,
    this.onOpenChat,
    this.onRate,
    super.key,
  });

  final Map<String, dynamic> ride;
  final int members;
  final int seatsLeft;
  final double totalFare;
  final double splitFare;
  final VoidCallback? onOpenDetails;
  final VoidCallback? onJoin;
  final VoidCallback? onAccept;
  final VoidCallback? onOpenChat;
  final VoidCallback? onRate;

  static final Map<String, Future<String>> _destinationCache = {};

  static String _coordLabel(double lat, double lng) {
    return "${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}";
  }

  static Future<String> _resolveDestinationTitle(double lat, double lng) {
    final key = "${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)}";
    return _destinationCache.putIfAbsent(key, () async {
      final url = Uri.parse(
        "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng",
      );
      try {
        final response = await http.get(
          url,
          headers: {'User-Agent': 'ridematch_community_app'},
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final displayName = (data['display_name'] ?? '').toString();
          if (displayName.trim().isEmpty) return _coordLabel(lat, lng);
          final parts = displayName.split(',');
          final concise = parts.length > 2
              ? "${parts[0]}, ${parts[1]}"
              : displayName;
          return concise.trim().isEmpty ? _coordLabel(lat, lng) : concise;
        }
      } catch (_) {}
      return _coordLabel(lat, lng);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>().currentLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dLat = (ride['dest_lat'] as num?)?.toDouble();
    final dLng = (ride['dest_lng'] as num?)?.toDouble();
    final status = (ride['status'] ?? 'gathering').toString();
    final statusRaw = status.toLowerCase();
    final destinationFuture = (dLat == null || dLng == null)
        ? Future.value('--')
        : _resolveDestinationTitle(dLat, dLng);

    final isPending = statusRaw == 'gathering' || statusRaw == 'pending';
    final isSearching = statusRaw == 'searching_driver';
    final isActive = statusRaw == 'driver_assigned' || statusRaw == 'active';

    String statusLabel = AppDictionary.text(lang, 'available');
    if (isPending) statusLabel = AppDictionary.text(lang, 'status_gathering');
    if (isSearching) statusLabel = AppDictionary.text(lang, 'status_searching');
    if (isActive) statusLabel = AppDictionary.text(lang, 'status_assigned');

    final statusFg = isPending
        ? const Color(0xFFE65100)
        : (isActive ? const Color(0xFF1B5E20) : const Color(0xFF6B42C7));
    final statusBg = isPending
        ? const Color(0xFFFFE0B2)
        : (isActive ? const Color(0xFFC8E6C9) : const Color(0x1A6D3FD1));

    final displayFare =
        (ride['offered_price'] as num?)?.toDouble() ?? splitFare;

    final availableSeats =
        (ride['available_seats'] as int?) ?? (seatsLeft > 0 ? seatsLeft : 1);
    final totalSeats = availableSeats + 1;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenDetails,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [colorScheme.surface, colorScheme.surfaceContainerHighest]
                  : [Colors.white, colorScheme.surfaceContainerLow],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: isPending
                  ? colorScheme.primary.withValues(alpha: isDark ? 0.35 : 0.22)
                  : colorScheme.outlineVariant.withValues(
                      alpha: isDark ? 0.25 : 0.35,
                    ),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: isDark ? 0.35 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.group_rounded,
                      color: colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<String>(
                          future: destinationFuture,
                          builder: (context, snapshot) {
                            final dest = (snapshot.data ?? '').trim();
                            return Text(
                              dest.isNotEmpty && dest != '--'
                                  ? dest
                                  : AppDictionary.text(
                                      lang,
                                      'calculating_location',
                                    ),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                        Text(
                          AppDictionary.text(lang, 'destination'),
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      statusLabel.toUpperCase(),
                      style: TextStyle(
                        color: statusFg,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.people_outline,
                    "$members/$totalSeats",
                    colorScheme,
                    isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.event_seat_outlined,
                    "$seatsLeft ${AppDictionary.text(lang, 'seats')}",
                    colorScheme,
                    isDark,
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "\$${displayFare.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        AppDictionary.text(lang, 'per_person'),
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (onJoin != null && isPending) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onJoin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      AppDictionary.text(lang, 'join_group'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
              if (onAccept != null && isSearching) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.tertiary,
                      foregroundColor: colorScheme.onTertiary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'ACEPTAR VIAJE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String label,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.2 : 0.3,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
