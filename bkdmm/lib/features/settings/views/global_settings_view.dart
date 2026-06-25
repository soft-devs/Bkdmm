import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../../../shared/providers/providers.dart';
import '../widgets/widgets.dart';
import '../dialogs/dialogs.dart';

/// Global settings view
class GlobalSettingsView extends ConsumerWidget {
  const GlobalSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tdTheme = TDTheme.of(context);
    final settings = ref.watch(settingsProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Appearance Section
        SettingsSection(
          title: 'Appearance',
          icon: TDIcons.palette,
          children: [
            // Theme Mode
            SettingsTile(
              title: 'Theme Mode',
              subtitle: _getThemeModeLabel(settings.themeMode),
              leading: Icon(
                _getThemeModeIcon(settings.themeMode),
                size: 24,
                color: tdTheme.brandNormalColor,
              ),
              onTap: () => _showThemeModeDialog(context, ref),
            ),
            // Accent Color
            SettingsTile(
              title: 'Accent Color',
              subtitle: 'Customize the app accent color',
              leading: Icon(
                TDIcons.color_invert,
                size: 24,
                color: tdTheme.brandNormalColor,
              ),
              trailing: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: settings.accentColorValue ?? tdTheme.brandNormalColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: tdTheme.componentStrokeColor,
                    width: 1,
                  ),
                ),
              ),
              onTap: () => _showAccentColorDialog(context, ref),
            ),
            // Font Size
            SettingsTile(
              title: 'Font Size',
              subtitle: 'Editor font size: ${settings.editorFontSize.toInt()}',
              leading: Icon(
                TDIcons.textformat_bold,
                size: 24,
                color: tdTheme.brandNormalColor,
              ),
              onTap: () => _showFontSizeDialog(context, ref),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Editor Section
        SettingsSection(
          title: 'Editor',
          icon: TDIcons.edit,
          children: [
            // Default Database Type
            SettingsTile(
              title: 'Default Database Type',
              subtitle: settings.defaultDatabase ?? 'Not set',
              leading: Icon(
                TDIcons.data_base,
                size: 24,
                color: tdTheme.brandNormalColor,
              ),
              onTap: () => _showDatabaseTypeDialog(context, ref),
            ),
            // Auto-save Interval
            SettingsTile(
              title: 'Auto-save Interval',
              subtitle: _getAutoSaveLabel(settings.autoSaveInterval),
              leading: Icon(
                TDIcons.time,
                size: 24,
                color: tdTheme.brandNormalColor,
              ),
              onTap: () => _showAutoSaveDialog(context, ref),
            ),
            // Show Line Numbers
            SettingsSwitchTile(
              title: 'Show Line Numbers',
              subtitle: 'Display line numbers in code preview',
              value: settings.showLineNumbers,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setShowLineNumbers(value);
              },
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Default Fields Section (Global defaults)
        SettingsSection(
          title: 'Default Fields (Global)',
          icon: TDIcons.list,
          description: 'Configure default fields for new tables (used as project defaults)',
          children: [
            SettingsSwitchTile(
              title: 'REVISION',
              subtitle: 'Add revision number field',
              value: settings.defaultFieldsRevision,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setDefaultFieldsRevision(value);
              },
            ),
            SettingsSwitchTile(
              title: 'CREATED_BY',
              subtitle: 'Add creator field',
              value: settings.defaultFieldsCreatedBy,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setDefaultFieldsCreatedBy(value);
              },
            ),
            SettingsSwitchTile(
              title: 'CREATED_TIME',
              subtitle: 'Add creation timestamp field',
              value: settings.defaultFieldsCreatedTime,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setDefaultFieldsCreatedTime(value);
              },
            ),
            SettingsSwitchTile(
              title: 'UPDATED_BY',
              subtitle: 'Add updater field',
              value: settings.defaultFieldsUpdatedBy,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setDefaultFieldsUpdatedBy(value);
              },
            ),
            SettingsSwitchTile(
              title: 'UPDATED_TIME',
              subtitle: 'Add update timestamp field',
              value: settings.defaultFieldsUpdatedTime,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setDefaultFieldsUpdatedTime(value);
              },
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Data Type Settings Section
        SettingsSection(
          title: 'Data Types',
          icon: TDIcons.data,
          children: [
            SettingsTile(
              title: 'Manage Data Types',
              subtitle: 'Configure custom data types',
              leading: Icon(
                TDIcons.chevron_right,
                size: 24,
                color: tdTheme.brandNormalColor,
              ),
              onTap: () => _navigateToDataTypes(context),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Reset Section
        SettingsSection(
          title: 'Reset',
          icon: TDIcons.refresh,
          children: [
            SettingsTile(
              title: 'Reset to Defaults',
              subtitle: 'Restore all settings to default values',
              leading: Icon(
                TDIcons.close_circle,
                size: 24,
                color: tdTheme.errorNormalColor,
              ),
              onTap: () => _showResetConfirmation(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  String _getThemeModeLabel(String mode) {
    switch (mode) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      default:
        return 'System';
    }
  }

  IconData _getThemeModeIcon(String mode) {
    switch (mode) {
      case 'light':
        return TDIcons.sun_rising;
      case 'dark':
        return TDIcons.moon;
      default:
        return TDIcons.brightness;
    }
  }

  String _getAutoSaveLabel(int seconds) {
    if (seconds == 0) {
      return 'Disabled';
    } else if (seconds < 60) {
      return '$seconds seconds';
    } else {
      final minutes = seconds ~/ 60;
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    }
  }

  void _showThemeModeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => ThemeModeDialog(
        currentValue: ref.read(settingsProvider).themeMode,
        onChanged: (value) {
          ref.read(settingsProvider.notifier).setThemeMode(value);
        },
      ),
    );
  }

  void _showAccentColorDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AccentColorDialog(
        onChanged: (color) {
          ref.read(settingsProvider.notifier).setAccentColor(color);
        },
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => FontSizeDialog(
        currentValue: ref.read(settingsProvider).editorFontSize,
        onChanged: (value) {
          ref.read(settingsProvider.notifier).setEditorFontSize(value);
        },
      ),
    );
  }

  void _showDatabaseTypeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => DatabaseTypeDialog(
        currentValue: ref.read(settingsProvider).defaultDatabase,
        onChanged: (value) {
          ref.read(settingsProvider.notifier).setDefaultDatabase(value);
        },
      ),
    );
  }

  void _showAutoSaveDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AutoSaveDialog(
        currentValue: ref.read(settingsProvider).autoSaveInterval,
        onChanged: (value) {
          ref.read(settingsProvider.notifier).setAutoSaveInterval(value);
        },
      ),
    );
  }

  void _navigateToDataTypes(BuildContext context) {
    TDToast.showText('Data type management coming soon', context: context);
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: 'Reset Settings',
        content:
            'Are you sure you want to reset all settings to their default values? This action cannot be undone.',
        leftBtn: TDDialogButtonOptions(
          title: 'Cancel',
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          action: () => Navigator.pop(context),
        ),
        rightBtn: TDDialogButtonOptions(
          title: 'Reset',
          theme: TDButtonTheme.danger,
          type: TDButtonType.fill,
          action: () {
            ref.read(settingsProvider.notifier).resetToDefaults();
            Navigator.pop(context);
            TDToast.showSuccess('Settings reset to defaults', context: context);
          },
        ),
      ),
    );
  }
}
