import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import '../services/ride_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final locationService = LocationService();
  final rideService = RideService();
  final mapController = MapController();

  LatLng? currentPosition;
  LatLng? destination;
  int _selectedIndex = 0;
  late Future<List<Map<String, dynamic>>> _communityRides;

  @override
  void initState() {
    super.initState();
    getLocation();
    _communityRides = rideService.getRides();
  }

  Future<void> getLocation() async {
    final position = await locationService.getCurrentLocation();
    setState(() {
      currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> createRide() async {
    if (destination == null || currentPosition == null) return;

    await rideService.createRide(
      originLat: currentPosition!.latitude,
      originLng: currentPosition!.longitude,
      destLat: destination!.latitude,
      destLng: destination!.longitude,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Viaje comunitario creado")),
    );
    _refreshRides();
  }

  Future<void> _refreshRides() async {
    setState(() {
      _communityRides = rideService.getRides();
    });
    await _communityRides;
  }

  int _rideMembers(Map<String, dynamic> ride) {
    final raw =
        ride['members_count'] ?? ride['participants_count'] ?? ride['occupancy'];
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

  Widget _buildTripsTab() {
    if (currentPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: currentPosition!,
            initialZoom: 15,
            onTap: (_, point) {
              setState(() => destination = point);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: currentPosition!,
                  width: 50,
                  height: 50,
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: Color(0xFF6E41D8),
                    size: 40,
                  ),
                ),
                if (destination != null)
                  Marker(
                    point: destination!,
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
              destination == null
                  ? "Selecciona destino para publicar viaje comunitario"
                  : "Destino listo. Podran unirse hasta 4 personas",
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
                  "Publicar viaje",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Modelo comunitario: 5 cupos maximos y division de pago.",
                  style: TextStyle(color: Color(0xFF665489)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: destination == null ? null : createRide,
                    icon: const Icon(Icons.add_road_rounded),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text("Crear viaje comunitario"),
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

  Widget _buildCommunityTab() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshRides,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _communityRides,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: const [
                  SizedBox(height: 260),
                  Center(child: Text("No se pudieron cargar viajes")),
                ],
              );
            }
            final rides = snapshot.data ?? [];
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                const Text(
                  "Comunidad RideMatch",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  "${rides.length} rutas activas ahora",
                  style: const TextStyle(color: Color(0xFF67568A)),
                ),
                const SizedBox(height: 14),
                if (rides.isEmpty)
                  const _EmptyCard()
                else
                  ...rides.map((ride) {
                    final members = _rideMembers(ride);
                    final total = _rideTotalFare(ride);
                    final seats = 5 - members;
                    final split = total / members;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RideCard(
                        ride: ride,
                        members: members,
                        seatsLeft: seats,
                        totalFare: total,
                        splitFare: split,
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: const [
          _ProfileCard(),
          SizedBox(height: 12),
          _OptionTile(
            icon: Icons.history_rounded,
            title: "Historial de viajes",
            subtitle: "Tus rutas comunitarias recientes",
          ),
          SizedBox(height: 10),
          _OptionTile(
            icon: Icons.payments_outlined,
            title: "Metodos de pago",
            subtitle: "Configura como dividir tus pagos",
          ),
          SizedBox(height: 10),
          _OptionTile(
            icon: Icons.shield_moon_outlined,
            title: "Seguridad",
            subtitle: "Contactos y opciones de emergencia",
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildTripsTab(),
      _buildCommunityTab(),
      _buildProfileTab(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                await getLocation();
                if (currentPosition != null) {
                  mapController.move(currentPosition!, 15);
                }
              },
              icon: const Icon(Icons.gps_fixed_rounded),
              label: const Text("Centrar"),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: "Viajes",
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_2_outlined),
            selectedIcon: Icon(Icons.groups_2_rounded),
            label: "Comunidad",
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: "Perfil",
          ),
        ],
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  const _RideCard({
    required this.ride,
    required this.members,
    required this.seatsLeft,
    required this.totalFare,
    required this.splitFare,
  });

  final Map<String, dynamic> ride;
  final int members;
  final int seatsLeft;
  final double totalFare;
  final double splitFare;

  @override
  Widget build(BuildContext context) {
    final oLat = (ride['origin_lat'] as num?)?.toDouble();
    final oLng = (ride['origin_lng'] as num?)?.toDouble();
    final dLat = (ride['dest_lat'] as num?)?.toDouble();
    final dLng = (ride['dest_lng'] as num?)?.toDouble();
    final status = (ride['status'] ?? 'waiting').toString();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEADFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFF2E8FF),
                child: Icon(Icons.route, color: Color(0xFF673AB7)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Ruta #${ride['id'] ?? '--'}",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                status,
                style: const TextStyle(
                  color: Color(0xFF6B42C7),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Origen: ${(oLat ?? 0).toStringAsFixed(4)}, ${(oLng ?? 0).toStringAsFixed(4)}",
            style: const TextStyle(fontSize: 12, color: Color(0xFF645886)),
          ),
          const SizedBox(height: 4),
          Text(
            "Destino: ${(dLat ?? 0).toStringAsFixed(4)}, ${(dLng ?? 0).toStringAsFixed(4)}",
            style: const TextStyle(fontSize: 12, color: Color(0xFF645886)),
          ),
          const SizedBox(height: 8),
          Text(
            "$members/5 personas • Cupos: $seatsLeft",
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4F3F76),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Total: \$${totalFare.toStringAsFixed(0)} • Por persona: \$${splitFare.toStringAsFixed(0)}",
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4F3F76),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.hourglass_empty_rounded, size: 34, color: Color(0xFF7445D3)),
          SizedBox(height: 8),
          Text(
            "Todavia no hay viajes",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4),
          Text(
            "Crea uno desde la pestaña Viajes y aparecera en esta lista.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF675A87)),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5128A9), Color(0xFF8B59FF)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white, size: 30),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Nicolas",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Conductor comunitario • 24 viajes",
                  style: TextStyle(color: Color(0xFFE8DBFF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFF2E8FF),
            child: Icon(icon, color: const Color(0xFF6338BF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6A5C89)),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.black45),
        ],
      ),
    );
  }
}
