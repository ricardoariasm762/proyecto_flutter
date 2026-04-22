import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/language_controller.dart';
import '../../../core/localization/app_dictionary.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({required this.email, super.key});

  final String email;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>().currentLanguage;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
            child: Icon(
              Icons.person_rounded,
              size: 32,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppDictionary.text(lang, 'user'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
