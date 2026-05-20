import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/localization/app_dictionary.dart';
import '../core/localization/language_controller.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
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

  Future<List<Map<String, dynamic>>> _fetchMyGroups() async {
    final userId =
        Supabase.instance.client.auth.currentSession?.user.id ??
        Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      final client = Supabase.instance.client;

      final myOwnedOrDriven = await client
          .from('groups')
          .select()
          .or('creator_id.eq.$userId,driver_id.eq.$userId')
          .order('created_at', ascending: false);

      final memberships = await client
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId);

      final memberGroupIds = memberships
          .map((r) => (r['group_id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(growable: false);

      final fromMembership = memberGroupIds.isEmpty
          ? const <Map<String, dynamic>>[]
          : await client.from('groups').select().inFilter('id', memberGroupIds);

      final mergedById = <String, Map<String, dynamic>>{};
      for (final r in myOwnedOrDriven) {
        final id = (r['id'] ?? '').toString();
        if (id.isEmpty) continue;
        mergedById[id] = Map<String, dynamic>.from(r);
      }
      for (final r in fromMembership) {
        final id = (r['id'] ?? '').toString();
        if (id.isEmpty) continue;
        mergedById.putIfAbsent(id, () => Map<String, dynamic>.from(r));
      }

      final merged = mergedById.values.toList(growable: false);
      merged.sort((a, b) {
        final aCreated = (a['created_at'] ?? '').toString();
        final bCreated = (b['created_at'] ?? '').toString();
        return bCreated.compareTo(aCreated);
      });

      return merged;
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>().currentLanguage;

    return Scaffold(
      appBar: AppBar(title: Text(AppDictionary.text(lang, 'my_trips'))),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchMyGroups(),
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
            padding: const EdgeInsets.all(16),
            itemCount: rides.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ride = rides[index];
              final seats = ride['available_seats']?.toString() ?? '0';
              final status = (ride['status'] ?? 'pending').toString();
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
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: ListTile(
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
                  subtitle: Text("Estado: $status | Cupos restantes: $seats"),
                  trailing: const Icon(Icons.history),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
