import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:osrm/osrm.dart';
import 'chat_screen.dart';
import '../services/location_service.dart';
import '../services/ride_service.dart';
import '../services/auth_service.dart';
import 'theme_tab.dart';
import 'auth_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final locationService = LocationService();
  final rideService = RideService();
  final authService = AuthService();
  final mapController = MapController();

  LatLng? currentPosition;
  LatLng? destination;
  
  String originTitle = "Obteniendo ubicación...";
  String destinationTitle = "Seleccione destino";
  num? routeDistance;
  num? routeDuration;

  List<LatLng> routePoints = [];
  int _selectedIndex = 0;
  final osrm = Osrm();

  Future<void> _getAddress(LatLng point, bool isOrigin) async {
    final url = Uri.parse("https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}");
    try {
      final response = await http.get(url, headers: {'User-Agent': 'ridematch_community_app'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final displayName = data['display_name'] ?? "";
        final parts = displayName.split(',');
        final concise = parts.length > 2 ? "${parts[0]}, ${parts[1]}" : displayName;
        if (mounted) {
          setState(() {
            if (isOrigin) {
              originTitle = concise;
            } else {
              destinationTitle = concise;
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> fetchRoute(LatLng start, LatLng end) async {
    final options = RouteRequest(
      coordinates: [(start.longitude, start.latitude), (end.longitude, end.latitude)],
      geometries: OsrmGeometries.geojson,
    );
    try {
      final route = await osrm.route(options);
      final distance = route.routes.first.distance;
      final duration = route.routes.first.duration;

      final coords = route.routes.first.geometry?.lineString?.coordinates;
      if (coords != null && mounted) {
        setState(() {
          routePoints = coords.map((c) => LatLng(c.$2, c.$1)).toList();
          routeDistance = distance;
          routeDuration = duration;
        });
        
        // Ajustar la cámara para ver ambos puntos si la ruta fue exitosa
        if (routePoints.isNotEmpty) {
          mapController.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds.fromPoints([start, end, ...routePoints]),
              padding: const EdgeInsets.all(50.0),
            ),
          );
        }
      }
    } catch (_) {
      // Ignorar e intentar trazar línea recta o nada
    }
  }
  late Stream<List<Map<String, dynamic>>> _communityRides;

  @override
  void initState() {
    super.initState();
    getLocation();
    _communityRides = rideService.getRidesStream();
  }

  Future<void> getLocation() async {
    try {
      final position = await locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          currentPosition = LatLng(position.latitude, position.longitude);
        });
        _getAddress(currentPosition!, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Es necesario otorgar permisos de ubicación para buscar viajes"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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
              setState(() {
                destination = point;
                destinationTitle = "Calculando ubicación...";
                routePoints = [];
                routeDistance = null;
                routeDuration = null;
              });
              _getAddress(point, false);
              if (currentPosition != null) {
                fetchRoute(currentPosition!, destination!);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: 'com.ridematch.communityapp',
            ),
            if (routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 4.0,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: currentPosition!,
                  width: 50,
                  height: 50,
                  child: Icon(
                    Icons.my_location_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 40,
                  ),
                ),
                if (destination != null)
                  Marker(
                    point: destination!,
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
        _buildRouteInfoCard(),
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
                    await getLocation();
                    if (currentPosition != null) {
                      mapController.move(currentPosition!, 15);
                    }
                  },
                  icon: const Icon(Icons.gps_fixed_rounded),
                  label: const Text("Centrar"),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                Text(
                  "Modelo comunitario: 5 cupos maximos y division de pago.",
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityTab() {
    return SafeArea(
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _communityRides,
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
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              if (rides.isEmpty)
                const _EmptyCard()
              else
                ...rides.map((ride) {
                  final members = _rideMembers(ride);
                  final total = _rideTotalFare(ride);
                  final seats = 5 - members;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RideCard(
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
                        await rideService.requestJoinRide(rideId: rideId);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Solicitud enviada")),
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

  Widget _buildProfileTab() {
    final user = authService.currentUser;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          _ProfileCard(email: user?.email ?? 'Usuario'),
          const SizedBox(height: 12),
          _OptionTile(
            icon: Icons.logout_rounded,
            title: "Cerrar Sesión",
            subtitle: "Salir de tu cuenta",
            onTap: () async {
              await authService.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfoCard() {
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
            _buildAddressRow(Icons.location_on, "Desde", originTitle, true),
            const SizedBox(height: 12),
            _buildAddressRow(Icons.location_on, "Hacia", destinationTitle, false),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: destination == null ? null : createRide,
                  icon: const Icon(Icons.directions_car_filled_rounded),
                  label: const Text("Publicar Viaje"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
                const SizedBox(width: 12),
                if (routeDuration != null && routeDistance != null)
                  Expanded(
                    child: Text(
                      "| ${(routeDuration! / 3600).toStringAsFixed(1)} h - ${(routeDistance! / 1000).toStringAsFixed(1)} km",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAddressRow(IconData icon, String label, String address, bool isOrigin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: isOrigin ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "$label: $address",
              style: TextStyle(
                color: address.contains("Cargando") || address.contains("Seleccione") || address.contains("Obteniendo") 
                    ? Theme.of(context).colorScheme.onSurfaceVariant 
                    : Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
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
      const ThemeTab(),
    ];
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
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
          NavigationDestination(
            icon: Icon(Icons.palette_outlined),
            selectedIcon: Icon(Icons.palette_rounded),
            label: "Temas",
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
    this.onJoin,
    this.onOpenChat,
  });

  final Map<String, dynamic> ride;
  final int members;
  final int seatsLeft;
  final double totalFare;
  final double splitFare;
  final VoidCallback? onJoin;
  final VoidCallback? onOpenChat;

  @override
  Widget build(BuildContext context) {
    final oLat = (ride['origin_lat'] as num?)?.toDouble();
    final oLng = (ride['origin_lng'] as num?)?.toDouble();
    final dLat = (ride['dest_lat'] as num?)?.toDouble();
    final dLng = (ride['dest_lng'] as num?)?.toDouble();
    final status = (ride['status'] ?? 'waiting').toString();
    final isPending = status == 'pending' || status == 'esperando usuario';

    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPending ? colorScheme.errorContainer : colorScheme.surfaceContainerHighest,
          width: isPending ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isPending
                    ? colorScheme.errorContainer
                    : colorScheme.primaryContainer,
                child: Icon(
                  isPending ? Icons.hourglass_top_rounded : Icons.route,
                  color: isPending
                      ? colorScheme.error
                      : colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Ruta #${ride['id'] ?? '--'}",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending
                      ? colorScheme.errorContainer
                      : colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPending ? "ESPERANDO USUARIO" : status.toUpperCase(),
                  style: TextStyle(
                    color: isPending
                        ? colorScheme.error
                        : colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Origen: ${(oLat ?? 0).toStringAsFixed(4)}, ${(oLng ?? 0).toStringAsFixed(4)}",
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            "Destino: ${(dLat ?? 0).toStringAsFixed(4)}, ${(dLng ?? 0).toStringAsFixed(4)}",
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$members/5 personas • Cupos: $seatsLeft",
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Creador del viaje #${ride['id'] ?? 'N/A'}",
                      style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "Tarifa",
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      "${(totalFare).toStringAsFixed(0)} COP",
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
                children: [
                  if (onOpenChat != null)
                    OutlinedButton.icon(
                      onPressed: onOpenChat,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 32),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                      label: const Text("Chat"),
                    ),
                  if (!isPending && onJoin != null) ...[
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: onJoin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 0,
                        ),
                        minimumSize: const Size(0, 32),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text("Unirme"),
                    ),
                  ],
                ],
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            size: 34,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 8),
          const Text("Todavia no hay viajes", style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            "Crea uno desde la pestaña Viajes y aparecera en esta lista.",
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.2),
            child: Icon(Icons.person, color: colorScheme.onPrimary, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email.contains('@') ? email.split('@')[0] : email,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(email, style: TextStyle(color: colorScheme.onPrimary.withValues(alpha: 0.8))),
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
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(icon, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colorScheme.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
