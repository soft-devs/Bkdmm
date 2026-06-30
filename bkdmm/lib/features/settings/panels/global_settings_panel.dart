import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import 'package:bkdmm/shared/providers/providers.dart';
import '../widgets/widgets.dart';
import '../dialogs/dialogs.dart';

/// Global settings panel for settings dialog
class GlobalSettingsPanel extends ConsumerWidget {
  const GlobalSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tdTheme = TDTheme.of(context);
    final settings = ref.watch(settingsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Appearance Section
          SettingsSection(
            title: 'Appearance',
            icon: TDIcons.palette,
            children: [
              SettingsTile(
                title: 'Theme Mode',
                subtitle: _getThemeModeLabel(settings.themeMode),
                leading: Icon(_getThemeModeIcon(settings.themeMode), size: 20, color: tdTheme.brandNormalColor),
                onTap: () => _showThemeModeDialog(context, ref),
              ),
              SettingsTile(
                title: 'Accent Color',
                subtitle: 'Customize accent color',
                leading: Icon(TDIcons.color_invert, size: 20, color: tdTheme.brandNormalColor),
                trailing: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: settings.accentColorValue ?? tdTheme.brandNormalColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: tdTheme.componentBorderColor),
                  ),
                ),
                onTap: () => _showAccentColorDialog(context, ref),
              ),
              SettingsTile(
                title: 'Font Size',
                subtitle: '${settings.editorFontSize.toInt()} pt',
                leading: Icon(TDIcons.textformat_bold, size: 20, color: tdTheme.brandNormalColor),
                onTap: () => _showFontSizeDialog(context, ref),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Editor Section
          SettingsSection(
            title: 'Editor',
            icon: TDIcons.edit,
            children: [
              SettingsTile(
                title: 'Auto-save Interval',
                subtitle: _getAutoSaveLabel(settings.autoSaveInterval),
                leading: Icon(TDIcons.time, size: 20, color: tdTheme.brandNormalColor),
                onTap: () => _showAutoSaveDialog(context, ref),
              ),
              SettingsSwitchTile(
                title: 'Show Line Numbers',
                subtitle: 'In code preview',
                value: settings.showLineNumbers,
                onChanged: (v) => ref.read(settingsProvider.notifier).setShowLineNumbers(v),
              ),
              SettingsSwitchTile(
                title: 'Code Completion',
                subtitle: 'Enable auto-completion',
                value: settings.enableCodeCompletion,
                onChanged: (v) => ref.read(settingsProvider.notifier).setEnableCodeCompletion(v),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Default Fields Section
          SettingsSection(
            title: 'Default Fields (Global)',
            icon: TDIcons.list,
            description: 'Default fields for new tables (used as project defaults)',
            children: [
              SettingsSwitchTile(
                title: 'REVISION',
                subtitle: 'Revision number field',
                value: settings.defaultFieldsRevision,
                onChanged: (v) => ref.read(settingsProvider.notifier).setDefaultFieldsRevision(v),
              ),
              SettingsSwitchTile(
                title: 'CREATED_BY',
                subtitle: 'Creator field',
                value: settings.defaultFieldsCreatedBy,
                onChanged: (v) => ref.read(settingsProvider.notifier).setDefaultFieldsCreatedBy(v),
              ),
              SettingsSwitchTile(
                title: 'CREATED_TIME',
                subtitle: 'Creation timestamp',
                value: settings.defaultFieldsCreatedTime,
                onChanged: (v) => ref.read(settingsProvider.notifier).setDefaultFieldsCreatedTime(v),
              ),
              SettingsSwitchTile(
                title: 'UPDATED_BY',
                subtitle: 'Updater field',
                value: settings.defaultFieldsUpdatedBy,
                onChanged: (v) => ref.read(settingsProvider.notifier).setDefaultFieldsUpdatedBy(v),
              ),
              SettingsSwitchTile(
                title: 'UPDATED_TIME',
                subtitle: 'Update timestamp',
                value: settings.defaultFieldsUpdatedTime,
                onChanged: (v) => ref.read(settingsProvider.notifier).setDefaultFieldsUpdatedTime(v),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Default Database Section
          SettingsSection(
            title: 'Default Database',
            icon: TDIcons.data_base,
            children: [
              SettingsTile(
                title: 'Default Database Type',
                subtitle: settings.defaultDatabase ?? 'Not set',
                leading: Icon(TDIcons.data_base, size: 20, color: tdTheme.brandNormalColor),
                onTap: () => _showDatabaseTypeDialog(context, ref, isGlobal: true),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Reset button
          TDButton(
            text: 'Reset to Defaults',
            icon: TDIcons.refresh,
            theme: TDButtonTheme.defaultTheme,
            type: TDButtonType.outline,
            size: TDButtonSize.medium,
            onTap: () => _showResetConfirmation(context, ref),
          ),
        ],
      ),
    );
  }

  String _getThemeModeLabel(String mode) {
    switch (mode) {
      case 'light': return 'Light';
      case 'dark': return 'Dark';
      default: return 'System';
    }
  }

  IconData _getThemeModeIcon(String mode) {
    switch (mode) {
      case 'light': return TDIcons.sun_rising;
      case 'dark': return TDIcons.moon;
      default: return TDIcons.brightness;
    }
  }

  String _getAutoSaveLabel(int seconds) {
    if (seconds == 0) return 'Disabled';
    if (seconds < 60) return '$seconds seconds';
    final minutes = seconds ~/ 60;
    return '$minutes minute${minutes > 1 ? 's' : ''}';
  }

  void _showThemeModeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => ThemeModeDialog(
        currentValue: ref.read(settingsProvider).themeMode,
        onChanged: (mode) {
          ref.read(settingsProvider.notifier).setThemeMode(mode);
        },
      ),
    );
  }

  void _showAccentColorDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AccentColorDialog(
        onChanged: (color) {
          ref.read(settingsProvider.notifier).setAccentColor(color);
        },
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => FontSizeDialog(
        currentValue: ref.read(settingsProvider).editorFontSize,
        onChanged: (value) {
          ref.read(settingsProvider.notifier).setEditorFontSize(value);
        },
      ),
    );
  }

  void _showAutoSaveDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AutoSaveDialog(
        currentValue: ref.read(settingsProvider).autoSaveInterval,
        onChanged: (value) {
          ref.read(settingsProvider.notifier).setAutoSaveInterval(value);
        },
      ),
    );
  }

  void _showDatabaseTypeDialog(BuildContext context, WidgetRef ref, {required bool isGlobal}) {
    showDialog(
      context: context,
      builder: (ctx) => DatabaseTypeDialog(
        currentValue: isGlobal
            ? ref.read(settingsProvider).defaultDatabase
            : ref.read(projectSettingsProvider)?.defaultDatabase,
        onChanged: (value) {
          if (isGlobal) {
            ref.read(settingsProvider.notifier).setDefaultDatabase(value);
          } else {
            ref.read(projectSettingsProvider.notifier).setDefaultDatabase(value);
          }
        },
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => TDAlertDialog(
        title: 'Reset Settings',
        content: 'Reset all settings to defaults?',
        leftBtn: TDDialogButtonOptions(
          title: 'Cancel',
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          action: () => Navigator.pop(ctx),
        ),
        rightBtn: TDDialogButtonOptions(
          title: 'Reset',
          theme: TDButtonTheme.danger,
          type: TDButtonType.fill,
          action: () {
            ref.read(settingsProvider.notifier).resetToDefaults();
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }
}
