import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  late Stream<List<Map<String, dynamic>>> _communityRides;

  @override
  void initState() {
    super.initState();
    final userId = Supabase.instance.client.auth.currentSession?.user.id ??
        Supabase.instance.client.auth.currentUser?.id;
    _communityRides = _rideService.getRidesStreamExcludingUser(excludeUserId: userId);
  }

  int _rideMembers(Map<String, dynamic> ride) {
    final raw = ride['members_count'] ?? ride['participants_count'] ?? ride['occupancy'];
    if (raw is int && raw >= 1 && raw <= 5) return raw;
    final id = (ride['id'] ?? '').toString();
    return 1 + (id.hashCode.abs() % 5);
  }

  double _rideTotalFare(Map<String, dynamic> ride) {
    final origin = LatLng(
      (ride['origin_lat'] as num?)?.toDouble() ?? 0,
      (ride['origin_lng'] as num?)?.toDouble() ?? 0,
    );
    final dest = LatLng(
      (ride['dest_lat'] as num?)?.toDouble() ?? 0,
      (ride['dest_lng'] as num?)?.toDouble() ?? 0,
    );
    final km = const Distance().as(LengthUnit.Kilometer, origin, dest);
    return 6000 + (km * 1300);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>().currentLanguage;

    return SafeArea(
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _communityRides,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ListView(
              children: [
                const SizedBox(height: 260),
                Center(child: Text(AppDictionary.text(lang, 'no_rides_loaded'))),
              ],
            );
          }

          final rides = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Text(
                AppDictionary.text(lang, 'community_ridematch'),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                "${rides.length} ${AppDictionary.text(lang, 'active_routes_now')}",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              if (rides.isEmpty)
                const EmptyCard()
              else
                ...rides.map((ride) {
                  final members = _rideMembers(ride);
                  final total = _rideTotalFare(ride);
                  final seats = 5 - members;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RideCard(
                      ride: ride,
                      members: members,
                      seatsLeft: seats,
                      totalFare: total,
                      splitFare: total / members,
                      onOpenChat: () {
                        final rideId = (ride['id'] ?? '--').toString();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(rideId: rideId),
                          ),
                        );
                      },
                      onJoin: () async {
                        final rideId = (ride['id'] ?? '').toString();
                        if (rideId.isEmpty) return;
                        await _rideService.requestJoinRide(rideId: rideId);
                        
                        await NotificationService().showNotification(
                          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
                          title: AppDictionary.text(lang, 'request_sent') ?? 'Solicitud enviada',
                          body: 'Has solicitado unirte al viaje exitosamente.',
                        );

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppDictionary.text(lang, 'request_sent'))),
                        );
                      },
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
