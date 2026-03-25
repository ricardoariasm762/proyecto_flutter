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

  LatLng? currentPosition;
  LatLng? destination;

  final mapController = MapController();

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  Future<void> getLocation() async {

    final position = await locationService.getCurrentLocation();

    setState(() {
      currentPosition = LatLng(
        position.latitude,
        position.longitude,
      );
    });
  }

  Future<void> createRide() async {

    if (destination == null) return;

    await rideService.createRide(
      originLat: currentPosition!.latitude,
      originLng: currentPosition!.longitude,
      destLat: destination!.latitude,
      destLng: destination!.longitude,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Viaje creado 🚗")),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("RideMatch"),
      ),

      body: currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(

              mapController: mapController,

              options: MapOptions(
                initialCenter: currentPosition!,
                initialZoom: 15,

                // 🔥 DETECTAR TAP EN EL MAPA
                onTap: (tapPosition, point) {
                  setState(() {
                    destination = point;
                  });
                },
              ),

              children: [

                // 🗺️ MAPA
                TileLayer(
                  urlTemplate:
                      "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                ),

                // 📍 MARCADORES
                MarkerLayer(
                  markers: [

                    // Usuario
                    Marker(
                      point: currentPosition!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),

                    // Destino
                    if (destination != null)
                      Marker(
                        point: destination!,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),

                  ],
                ),

              ],
            ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,

        children: [

          // 📍 Centrar ubicación
          FloatingActionButton(
            heroTag: "loc",
            onPressed: () async {
              await getLocation();
              mapController.move(currentPosition!, 15);
            },
            child: const Icon(Icons.my_location),
          ),

          const SizedBox(height: 10),

          // 🚗 Crear viaje
          FloatingActionButton(
            heroTag: "ride",
            backgroundColor: Colors.green,
            onPressed: createRide,
            child: const Icon(Icons.directions_car),
          ),

        ],
      ),
    );
  }
}