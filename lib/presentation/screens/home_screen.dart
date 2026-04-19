import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/models/ride.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/repositories/ride_repository.dart';
import '../widgets/empty_card.dart';
import '../widgets/option_tile.dart';
import '../widgets/profile_card.dart';
import '../widgets/ride_card.dart';
import 'ride_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.authRepository,
    required this.rideRepository,
    required this.locationRepository,
  });

  final AuthRepository authRepository;
  final RideRepository rideRepository;
  final LocationRepository locationRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final mapController = MapController();

  LatLng? currentPosition;
  LatLng? destination;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  Future<void> getLocation() async {
    final position = await widget.locationRepository.getCurrentLocation();
    setState(() {
      currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> createRide() async {
    final user = widget.authRepository.currentUser;
    if (user == null) return;
    if (destination == null || currentPosition == null) return;

    await widget.rideRepository.createRide(
      userId: user.id,
      originLat: currentPosition!.latitude,
      originLng: currentPosition!.longitude,
      destLat: destination!.latitude,
      destLng: destination!.longitude,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Viaje comunitario creado")));
  }

  int _rideMembers(Ride ride) {
    if (ride.participantsCount >= 1 && ride.participantsCount <= 5) {
      return ride.participantsCount;
    }
    return 1 + (ride.id.hashCode.abs() % 5);
  }

  double _rideTotalFare(Ride ride) {
    final origin = LatLng(ride.originLat, ride.originLng);
    final dest = LatLng(ride.destLat, ride.destLng);
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
            onTap: (_, point) => setState(() => destination = point),
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
      child: StreamBuilder<List<Ride>>(
        stream: widget.rideRepository.ridesStream(),
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

          final rides = snapshot.data ?? const [];

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
                const EmptyCard()
              else
                ...rides.map((ride) {
                  final members = _rideMembers(ride);
                  final total = _rideTotalFare(ride);
                  final seats = 5 - members;
                  final currentUser = widget.authRepository.currentUser;
                  final canJoin =
                      currentUser != null && currentUser.id != ride.userId;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RideCard(
                      rideId: ride.id.length >= 5
                          ? ride.id.substring(0, 5)
                          : ride.id,
                      originLabel:
                          "${ride.originLat.toStringAsFixed(4)}, ${ride.originLng.toStringAsFixed(4)}",
                      destLabel:
                          "${ride.destLat.toStringAsFixed(4)}, ${ride.destLng.toStringAsFixed(4)}",
                      status: ride.status,
                      members: members,
                      seatsLeft: seats,
                      totalFare: total,
                      splitFare: total / members,
                      onJoin: canJoin
                          ? () async {
                              await widget.rideRepository.requestJoinRide(
                                rideId: ride.id,
                                userId: currentUser.id,
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Solicitud enviada"),
                                ),
                              );
                            }
                          : null,
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileTab() {
    final user = widget.authRepository.currentUser;
    final email = user?.email ?? 'Usuario';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          ProfileCard(email: email),
          const SizedBox(height: 12),
          OptionTile(
            icon: Icons.history_rounded,
            title: "Historial de viajes",
            subtitle: "Tus rutas comunitarias recientes",
            onTap: user == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RideHistoryScreen(
                          rideRepository: widget.rideRepository,
                          userId: user.id,
                        ),
                      ),
                    );
                  },
          ),
          const SizedBox(height: 10),
          OptionTile(
            icon: Icons.logout_rounded,
            title: "Cerrar Sesión",
            subtitle: "Salir de tu cuenta",
            onTap: () async {
              await widget.authRepository.signOut();
            },
          ),
          const SizedBox(height: 10),
          const OptionTile(
            icon: Icons.payments_outlined,
            title: "Metodos de pago",
            subtitle: "Configura como dividir tus pagos",
          ),
          const SizedBox(height: 10),
          const OptionTile(
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
    final pages = [_buildTripsTab(), _buildCommunityTab(), _buildProfileTab()];
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
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
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
