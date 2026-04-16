import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../domain/models/ride.dart';
import '../../../widgets/empty_card/empty_card.dart';
import '../../../widgets/ride_card/ride_card.dart';
import '../home_controller.dart';

class CommunityTab extends StatelessWidget {
  final HomeController controller;
  final Function(VoidCallback) setState;

  const CommunityTab({
    super.key,
    required this.controller,
    required this.setState,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => controller.refreshRides(setState),
        child: FutureBuilder<List<Ride>>(
          future: controller.communityRides,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: const [
                  SizedBox(height: 260),
                  Center(child: Text(AppStrings.errorLoadingRides)),
                ],
              );
            }
            final rides = snapshot.data ?? [];
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                const Text(
                  AppStrings.communityTitle,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  "${rides.length} ${AppStrings.activeRoutes}",
                  style: const TextStyle(color: Color(0xFF67568A)),
                ),
                const SizedBox(height: 14),
                if (rides.isEmpty)
                  const EmptyCard()
                else
                  ...rides.map((ride) {
                    final membersCount = controller.calculateRideMembers(ride);
                    final total = controller.calculateRideTotalFare(ride);
                    final seats = 5 - membersCount;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RideCard(
                        ride: ride,
                        members: membersCount,
                        seatsLeft: seats,
                        totalFare: total,
                        splitFare: total / membersCount,
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
}
