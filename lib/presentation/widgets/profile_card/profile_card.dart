import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5128A9), Color(0xFF8B59FF)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white, size: 30),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.profileName,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  AppStrings.profileRole,
                  style: TextStyle(color: Color(0xFFE8DBFF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
