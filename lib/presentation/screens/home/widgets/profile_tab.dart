import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../widgets/option_tile/option_tile.dart';
import '../../../widgets/profile_card/profile_card.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: const [
          ProfileCard(),
          SizedBox(height: 12),
          OptionTile(
            icon: Icons.history_rounded,
            title: AppStrings.historyTitle,
            subtitle: AppStrings.historySubtitle,
          ),
          SizedBox(height: 10),
          OptionTile(
            icon: Icons.payments_outlined,
            title: AppStrings.paymentsTitle,
            subtitle: AppStrings.paymentsSubtitle,
          ),
          SizedBox(height: 10),
          OptionTile(
            icon: Icons.shield_moon_outlined,
            title: AppStrings.securityTitle,
            subtitle: AppStrings.securitySubtitle,
          ),
        ],
      ),
    );
  }
}
