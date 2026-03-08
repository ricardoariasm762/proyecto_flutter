import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final locationService = LocationService();

  LatLng? currentPosition;

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
              ),

              children: [

                TileLayer(
                  urlTemplate:
                      "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                ),

                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentPosition!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    )
                  ],
                ),

              ],
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await getLocation();

          mapController.move(currentPosition!, 15);
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}