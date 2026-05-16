import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:provider/provider.dart';
import '../theme/theme_controller.dart';
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
        final colorScheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: isDark
              ? colorScheme.surface
              : const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: isDark ? colorScheme.surface : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              AppDictionary.text(lang, 'visual_settings'),
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSectionTitle(
                AppDictionary.text(lang, 'appearance_mode'),
                colorScheme,
              ),
              const SizedBox(height: 16),
              _buildThemeModeSelector(context, ctrl, colorScheme, isDark, lang),
              const SizedBox(height: 32),
              _buildSectionTitle(
                AppDictionary.text(lang, 'color_scheme'),
                colorScheme,
              ),
              const SizedBox(height: 16),
              _buildSchemeSelector(context, ctrl, colorScheme, isDark),
              const SizedBox(height: 32),
              _buildSectionTitle(
                AppDictionary.text(lang, 'preview'),
                colorScheme,
              ),
              const SizedBox(height: 16),
              _buildPreviewCard(context, colorScheme, isDark, lang),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildThemeModeSelector(
    BuildContext context,
    ThemeController ctrl,
    ColorScheme colorScheme,
    bool isDark,
    String lang,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildRadioOption(
            context,
            title: AppDictionary.text(lang, 'light_mode'),
            icon: Icons.light_mode_outlined,
            selected: ctrl.themeMode == ThemeMode.light,
            onTap: () => ctrl.setThemeMode(ThemeMode.light),
            colorScheme: colorScheme,
          ),
          const Divider(height: 1, indent: 56),
          _buildRadioOption(
            context,
            title: AppDictionary.text(lang, 'dark_mode'),
            icon: Icons.dark_mode_outlined,
            selected: ctrl.themeMode == ThemeMode.dark,
            onTap: () => ctrl.setThemeMode(ThemeMode.dark),
            colorScheme: colorScheme,
          ),
          const Divider(height: 1, indent: 56),
          _buildRadioOption(
            context,
            title: AppDictionary.text(lang, 'system_theme'),
            icon: Icons.brightness_auto_outlined,
            selected: ctrl.themeMode == ThemeMode.system,
            onTap: () => ctrl.setThemeMode(ThemeMode.system),
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: colorScheme.onSurface,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_circle, color: colorScheme.primary)
          : Icon(
              Icons.circle_outlined,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
    );
  }

  Widget _buildSchemeSelector(
    BuildContext context,
    ThemeController ctrl,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: FlexScheme.values.length,
        clipBehavior: Clip.none,
        itemBuilder: (context, index) {
          final scheme = FlexScheme.values[index];
          final isSelected = ctrl.usedScheme == scheme;
          final schemeColors = FlexColor.schemes[scheme]!;

          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => ctrl.setScheme(scheme),
              child: Container(
                width: 100,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary.withOpacity(0.1)
                      : (isDark
                            ? colorScheme.surfaceVariant
                            : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline.withOpacity(0.1),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark
                                ? schemeColors.dark.primary
                                : schemeColors.light.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 24,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        scheme.name[0].toUpperCase() + scheme.name.substring(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdvancedOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
    String lang,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 60,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(AppDictionary.text(lang, 'example_button')),
            ),
          ),
        ],
      ),
    );
  }
}
