import 'package:flutter/material.dart';

class RideCard extends StatelessWidget {
  const RideCard({
    super.key,
    required this.rideId,
    required this.originLabel,
    required this.destLabel,
    required this.status,
    required this.members,
    required this.seatsLeft,
    required this.totalFare,
    required this.splitFare,
    this.onJoin,
  });

  final String rideId;
  final String originLabel;
  final String destLabel;
  final String status;
  final int members;
  final int seatsLeft;
  final double totalFare;
  final double splitFare;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'pending' || status == 'esperando usuario';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPending ? const Color(0xFFFFE0B2) : const Color(0xFFEADFFF),
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
                    ? const Color(0xFFFFF3E0)
                    : const Color(0xFFF2E8FF),
                child: Icon(
                  isPending ? Icons.hourglass_top_rounded : Icons.route,
                  color: isPending
                      ? const Color(0xFFE65100)
                      : const Color(0xFF673AB7),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Ruta #$rideId",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending
                      ? const Color(0xFFFFE0B2)
                      : const Color(0x1A6D3FD1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPending ? "ESPERANDO USUARIO" : status.toUpperCase(),
                  style: TextStyle(
                    color: isPending
                        ? const Color(0xFFE65100)
                        : const Color(0xFF6B42C7),
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Origen: $originLabel",
            style: const TextStyle(fontSize: 12, color: Color(0xFF645886)),
          ),
          const SizedBox(height: 4),
          Text(
            "Destino: $destLabel",
            style: const TextStyle(fontSize: 12, color: Color(0xFF645886)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$members/5 personas • Cupos: $seatsLeft",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4F3F76),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Total: \$${totalFare.toStringAsFixed(0)} • Pago: \$${splitFare.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4F3F76),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (!isPending && onJoin != null)
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
          ),
        ],
      ),
    );
  }
}
