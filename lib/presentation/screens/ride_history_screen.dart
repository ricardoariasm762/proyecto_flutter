import 'package:flutter/material.dart';
import '../../domain/models/ride.dart';
import '../../domain/repositories/ride_repository.dart';

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({
    super.key,
    required this.rideRepository,
    required this.userId,
  });

  final RideRepository rideRepository;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Historial de Viajes",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Ride>>(
        future: rideRepository.getUserRides(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text("Error al cargar historial"));
          }

          final rides = snapshot.data!;
          if (rides.isEmpty) {
            return const Center(child: Text("Aún no tienes viajes en tu historial"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              final isPending =
                  ride.status == 'pending' || ride.status == 'esperando usuario';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: isPending
                        ? const Color(0xFFFFE0B2)
                        : const Color(0xFFF2E8FF),
                    child: Icon(
                      isPending ? Icons.hourglass_top_rounded : Icons.history,
                      color: isPending
                          ? const Color(0xFFE65100)
                          : const Color(0xFF673AB7),
                    ),
                  ),
                  title: Text(
                    "De: ${ride.originLat.toStringAsFixed(3)}, ${ride.originLng.toStringAsFixed(3)}",
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "A: ${ride.destLat.toStringAsFixed(3)}, ${ride.destLng.toStringAsFixed(3)}",
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Estado: ${ride.status.toUpperCase()}",
                        style: TextStyle(
                          color: isPending
                              ? const Color(0xFFE65100)
                              : const Color(0xFF6B42C7),
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    "ID: ${ride.id.length >= 5 ? ride.id.substring(0, 5) : ride.id}...",
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
