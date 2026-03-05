import 'package:flutter/material.dart';
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

  String locationText = "Obteniendo ubicación...";

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  Future<void> getLocation() async {

    try {

      final position = await locationService.getCurrentLocation();

      setState(() {
        locationText =
            "Lat: ${position.latitude}, Lng: ${position.longitude}";
      });

    } catch (e) {
      setState(() {
        locationText = "Error obteniendo ubicación";
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("RideMatch"),
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Text(locationText),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {

                final position =
                    await locationService.getCurrentLocation();

                await rideService.createRide(
                  originLat: position.latitude,
                  originLng: position.longitude,
                  destLat: position.latitude + 0.01,
                  destLng: position.longitude + 0.01,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Viaje creado")),
                );

              },
              child: const Text("Crear viaje"),
            )

          ],
        ),
      ),
    );
  }
}