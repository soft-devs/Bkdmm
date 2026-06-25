import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../../../shared/providers/providers.dart';
import '../widgets/widgets.dart';
import '../dialogs/database_type_dialog.dart';

/// Default database settings panel for project settings
class DefaultDatabasePanel extends ConsumerWidget {
  const DefaultDatabasePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tdTheme = TDTheme.of(context);
    final projectSettings = ref.watch(projectSettingsProvider);
    final globalSettings = ref.watch(settingsProvider);

    if (projectSettings == null) {
      return Center(
        child: TDText(
          'No project loaded',
          textColor: tdTheme.textColorSecondary,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tdTheme.bgColorSecondaryContainer,
              borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
            ),
            child: Row(
              children: [
                Icon(TDIcons.info_circle, size: 16, color: tdTheme.brandNormalColor),
                const SizedBox(width: 10),
                Expanded(
                  child: TDText(
                    'Project settings can inherit from global defaults. Turn off inheritance to customize.',
                    font: tdTheme.fontBodySmall,
                    textColor: tdTheme.textColorSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Inheritance toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tdTheme.bgColorContainer,
              borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
              border: Border.all(color: tdTheme.componentBorderColor),
            ),
            child: Row(
              children: [
                Icon(TDIcons.link, size: 20, color: tdTheme.brandNormalColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TDText(
                        'Inherit from Global Settings',
                        font: tdTheme.fontBodyMedium,
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(height: 4),
                      TDText(
                        'Use global default database setting',
                        font: tdTheme.fontBodySmall,
                        textColor: tdTheme.textColorSecondary,
                      ),
                    ],
                  ),
                ),
                TDSwitch(
                  isOn: projectSettings.inheritDefaultDatabase,
                  size: TDSwitchSize.medium,
                  onChanged: (v) {
                    ref.read(projectSettingsProvider.notifier).setInheritDefaultDatabase(v);
                    return false;
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Database selection (only if not inheriting)
          if (!projectSettings.inheritDefaultDatabase)
            SettingsSection(
              title: 'Default Database Type',
              icon: TDIcons.data_base,
              children: [
                SettingsTile(
                  title: 'Database Type',
                  subtitle: projectSettings.defaultDatabase ?? globalSettings.defaultDatabase ?? 'Not set',
                  leading: Icon(TDIcons.data_base, size: 20, color: tdTheme.brandNormalColor),
                  onTap: () => _showDatabaseTypeDialog(context, ref),
                ),
              ],
            ),

          const SizedBox(height: 20),

          // Reset button
          TDButton(
            text: 'Reset to Inherit',
            icon: TDIcons.refresh,
            theme: TDButtonTheme.defaultTheme,
            type: TDButtonType.outline,
            size: TDButtonSize.medium,
            onTap: () => ref.read(projectSettingsProvider.notifier).resetToDefaults(),
          ),
        ],
      ),
    );
  }

  void _showDatabaseTypeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => DatabaseTypeDialog(
        currentValue: ref.read(projectSettingsProvider)?.defaultDatabase,
        onChanged: (value) {
          ref.read(projectSettingsProvider.notifier).setDefaultDatabase(value);
        },
      ),
    );
  }
}
