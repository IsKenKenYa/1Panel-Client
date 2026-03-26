import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/theme/theme_controller.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  static const List<Color> _presetColors = [
    AppDesignTokens.brand,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.brown,
    Colors.blueGrey,
    Colors.grey,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeController = context.watch<ThemeController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTheme),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, l10n.settingsTheme),
          RadioGroup<ThemeMode>(
            groupValue: themeController.themeMode,
            onChanged: (value) {
              if (value == null) {
                return;
              }
              themeController.updateThemeMode(value);
            },
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text(l10n.themeSystem),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  title: Text(l10n.themeLight),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text(l10n.themeDark),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(l10n.themeDynamicColor),
            subtitle: Text(l10n.themeDynamicColorDesc),
            value: themeController.useDynamicColor,
            onChanged: (value) {
              themeController.updateUseDynamicColor(value);
            },
          ),
          const Divider(),
          _buildSectionHeader(context, l10n.themeSeedColor),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignTokens.spacingLg,
              vertical: AppDesignTokens.spacingSm,
            ),
            child: Text(
              l10n.themeSeedColorFallbackDesc,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignTokens.spacingLg,
              vertical: AppDesignTokens.spacingSm,
            ),
            child: Wrap(
              spacing: AppDesignTokens.spacingMd,
              runSpacing: AppDesignTokens.spacingMd,
              children: _presetColors.map((color) {
                final isSelected =
                    themeController.seedColor.toARGB32() == color.toARGB32();
                return GestureDetector(
                  onTap: () {
                    themeController.updateSeedColor(color);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: theme.colorScheme.onSurface,
                              width: 3,
                            )
                          : null,
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: theme.colorScheme.shadow.withValues(
                              alpha: 0.2,
                            ),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color:
                                ThemeData.estimateBrightnessForColor(color) ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDesignTokens.spacingLg,
        AppDesignTokens.spacingLg,
        AppDesignTokens.spacingLg,
        AppDesignTokens.spacingSm,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
