import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import '../theme/theme_controller.dart';
import 'package:provider/provider.dart';
import '../core/localization/language_controller.dart';
import '../core/localization/app_dictionary.dart';

class ThemeTab extends StatelessWidget {
  const ThemeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final ctrl = ThemeController.instance;
        final lang = context.watch<LanguageController>().currentLanguage;

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children: [
              Text(
                AppDictionary.text(lang, 'visual_settings'),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                AppDictionary.text(lang, 'visual_settings_desc'),
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              // Theme Mode
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  ),
                ),
              ),
              SwitchListTile(
                title: Text(AppDictionary.text(lang, 'dark_mode'), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(AppDictionary.text(lang, 'dark_mode_desc')),
                value: ctrl.themeMode == ThemeMode.dark,
                onChanged: (val) {
                  ctrl.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                },
              ),
              const Divider(),
              // Material 3
              SwitchListTile(
                title: Text(AppDictionary.text(lang, 'use_material3'), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(AppDictionary.text(lang, 'use_material3_desc')),
                value: ctrl.useMaterial3,
                onChanged: (val) {
                  ctrl.setUseMaterial3(val);
                },
              ),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                AppDictionary.text(lang, 'color_theme'),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              // Color Scheme Dropdown
              DropdownButtonFormField<FlexScheme>(
                initialValue: ctrl.usedScheme,
                decoration: InputDecoration(
                  labelText: AppDictionary.text(lang, 'select_flex_scheme'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: FlexScheme.values.map((scheme) {
                  return DropdownMenuItem<FlexScheme>(
                    value: scheme,
                    child: Text(scheme.name),
                  );
                }).toList(),
                onChanged: (newScheme) {
                  if (newScheme != null) {
                    ctrl.setScheme(newScheme);
                  }
                },
              ),
              const SizedBox(height: 24),
              Text(
                AppDictionary.text(lang, 'component_examples'),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(onPressed: () {}, child: const Text('Elevated')),
                  OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
                  TextButton(onPressed: () {}, child: const Text('TextBtn')),
                ],
              ),
              const SizedBox(height: 16),
              FloatingActionButton.extended(
                onPressed: () {},
                icon: const Icon(Icons.palette),
                label: const Text('Floating Action'),
              ),
            ],
          ),
        );
      },
    );
  }
}
