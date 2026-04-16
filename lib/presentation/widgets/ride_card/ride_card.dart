import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../domain/models/ride.dart';

class RideCard extends StatelessWidget {
  const RideCard({
    super.key,
    required this.ride,
    required this.members,
    required this.seatsLeft,
    required this.totalFare,
    required this.splitFare,
  });

  final Ride ride;
  final int members;
  final int seatsLeft;
  final double totalFare;
  final double splitFare;

  @override
  Widget build(BuildContext context) {
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
                  "Ruta #${ride.id}",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                ride.status,
                style: const TextStyle(
                  color: Color(0xFF6B42C7),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "${AppStrings.origin}: ${ride.originLat.toStringAsFixed(4)}, ${ride.originLng.toStringAsFixed(4)}",
            style: const TextStyle(fontSize: 12, color: Color(0xFF645886)),
          ),
          const SizedBox(height: 4),
          Text(
            "${AppStrings.destination}: ${ride.destLat.toStringAsFixed(4)}, ${ride.destLng.toStringAsFixed(4)}",
            style: const TextStyle(fontSize: 12, color: Color(0xFF645886)),
          ),
          const SizedBox(height: 8),
          Text(
            "$members/5 ${AppStrings.members} • ${AppStrings.seats}: $seatsLeft",
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4F3F76),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${AppStrings.total}: \$${totalFare.toStringAsFixed(0)} • ${AppStrings.perPerson}: \$${splitFare.toStringAsFixed(0)}",
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
