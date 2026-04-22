import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../core/localization/app_dictionary.dart';
import '../core/localization/language_controller.dart';
import '../services/ride_service.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  final _rideService = RideService();

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

    return Scaffold(
      appBar: AppBar(title: Text(AppDictionary.text(lang, 'my_trips'))),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _rideService.getUserRides(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(AppDictionary.text(lang, 'no_rides_loaded')),
            );
          }

          final rides = snapshot.data ?? [];
          if (rides.isEmpty) {
            return Center(child: Text(AppDictionary.text(lang, 'no_my_trips')));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            itemCount: rides.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ride = rides[index];
              final rideId = (ride['id'] ?? '').toString();
              final dLat = (ride['dest_lat'] as num?)?.toDouble();
              final dLng = (ride['dest_lng'] as num?)?.toDouble();
              final destinationFuture = (dLat == null || dLng == null)
                  ? Future.value(AppDictionary.text(lang, 'destination'))
                  : _resolveDestinationTitle(dLat, dLng);

              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  title: FutureBuilder<String>(
                    future: destinationFuture,
                    builder: (context, destSnap) {
                      final title =
                          (destSnap.data ??
                                  AppDictionary.text(lang, 'destination'))
                              .trim();
                      return Text(
                        title.isEmpty
                            ? AppDictionary.text(lang, 'destination')
                            : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      );
                    },
                  ),
                  subtitle: Text(
                    "${AppDictionary.text(lang, 'route')} #${rideId.isEmpty ? '--' : rideId}",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  children: [
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: rideId.isEmpty
                          ? Future.value(const [])
                          : _rideService.getRideRequests(rideId: rideId),
                      builder: (context, reqSnap) {
                        if (reqSnap.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final requests = reqSnap.data ?? [];
                        if (requests.isEmpty) {
                          return Text(
                            AppDictionary.text(lang, 'no_join_requests'),
                          );
                        }

                        return Column(
                          children: requests
                              .map((r) {
                                final requesterId = (r['user_id'] ?? '--')
                                    .toString();
                                final status = (r['status'] ?? 'pending')
                                    .toString();
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                        child: Icon(
                                          Icons.person_rounded,
                                          size: 18,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          requesterId,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              })
                              .toList(growable: false),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
