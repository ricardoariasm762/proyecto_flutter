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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          title: const Text(
            "Comunidad",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          bottom: TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: "Explorar"),
              Tab(text: "Mi Grupo"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildExploreTab(context, lang),
            _buildMyGroupTab(context, lang),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreTab(BuildContext context, String lang) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _communityGroups,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
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
                    const Text(
                      "Grupos Cercanos",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Encuentra personas que van en tu misma dirección.",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            final group = groups[index - 1];
            final availableSeats = group['available_seats'] as int? ?? 4;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: RideCard(
                ride: group,
                members: 1,
                seatsLeft: availableSeats,
                totalFare: 6000,
                splitFare: 6000,
                onJoin: () async {
                  final groupId = (group['id'] ?? '').toString();
                  if (groupId.isEmpty) return;

                  final hasActive = await _rideService.hasActiveGroupRequest();
                  if (hasActive) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Ya perteneces a un grupo activo."),
                        backgroundColor: Colors.black,
                      ),
                    );
                    return;
                  }

                  await _rideService.requestJoinGroup(groupId: groupId);

                  await NotificationService().showNotification(
                    id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
                    title: 'Solicitud enviada',
                    body: 'Has solicitado unirte al grupo exitosamente.',
                  );

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Solicitud enviada')),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyGroupTab(BuildContext context, String lang) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _rideService.getActiveGroup(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );

        final activeGroup = snapshot.data;
        if (activeGroup == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.group_off_rounded,
                    size: 64,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Sin grupo activo",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Únete a uno en la pestaña Explorar.",
                  style: TextStyle(color: Colors.grey[600]),
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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusHeader(status),
              const SizedBox(height: 32),
              const Text(
                "Detalles del Viaje",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildDetailCard(activeGroup),
              const SizedBox(height: 32),
              if (isCreator && status == 'gathering')
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _rideService.searchDriverForGroup(groupId);
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Buscar Conductor Ahora",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(rideId: groupId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text(
                    "Chat Grupal",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusHeader(String status) {
    IconData icon = Icons.people_outline;
    String title = "Reuniendo personas";
    String desc = "Esperando a que más miembros se unan al grupo.";
    Color color = Colors.orange;

    if (status == 'searching_driver') {
      icon = Icons.search_rounded;
      title = "Buscando conductor";
      desc = "Estamos buscando un conductor disponible cerca.";
      color = Colors.blue;
    } else if (status == 'driver_assigned') {
      icon = Icons.check_circle_outline_rounded;
      title = "¡Conductor asignado!";
      desc = "Tu viaje está listo para comenzar.";
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(Map<String, dynamic> group) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.calendar_today_outlined, "Fecha", "Hoy"),
          const Divider(height: 32),
          _buildInfoRow(Icons.person_outline, "Miembros", "1/5 personas"),
          const Divider(height: 32),
          _buildInfoRow(
            Icons.attach_money_rounded,
            "Costo estimado",
            "\$6,000 COP",
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: Colors.grey[600])),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
