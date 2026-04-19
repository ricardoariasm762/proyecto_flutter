import 'package:flutter/material.dart';

class EmptyCard extends StatelessWidget {
  const EmptyCard({super.key});

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
          Icon(
            Icons.hourglass_empty_rounded,
            size: 34,
            color: Color(0xFF7445D3),
          ),
          SizedBox(height: 8),
          Text("Todavia no hay viajes", style: TextStyle(fontWeight: FontWeight.w700)),
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
