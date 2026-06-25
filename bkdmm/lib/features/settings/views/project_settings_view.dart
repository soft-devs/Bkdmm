import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../../../shared/providers/providers.dart';
import '../widgets/widgets.dart';
import '../dialogs/database_type_dialog.dart';

/// Project settings view
class ProjectSettingsView extends ConsumerStatefulWidget {
  final bool hasProject;

  const ProjectSettingsView({
    super.key,
    required this.hasProject,
  });

  @override
  ConsumerState<ProjectSettingsView> createState() =>
      _ProjectSettingsViewState();
}

class _ProjectSettingsViewState extends ConsumerState<ProjectSettingsView> {
  @override
  void initState() {
    super.initState();
    // Load project settings when project is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProjectSettings();
    });
  }

  void _loadProjectSettings() {
    final project = ref.read(currentProjectProvider);
    ref.read(projectSettingsProvider.notifier).loadFromProject(project);
  }

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);

    if (!widget.hasProject) {
      return _buildNoProjectState(tdTheme);
    }

    final projectSettings = ref.watch(projectSettingsProvider);
    final globalSettings = ref.watch(settingsProvider);

    if (projectSettings == null) {
      return _buildNoProjectState(tdTheme);
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Project Info Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tdTheme.bgColorSecondaryContainer,
            borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
          ),
          child: Row(
            children: [
              Icon(TDIcons.info_circle, color: tdTheme.brandNormalColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TDText(
                  'Project settings can override global defaults. Toggle inheritance to use global values.',
                  font: tdTheme.fontBodySmall,
                  textColor: tdTheme.textColorPrimary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Default Database Section
        SettingsSection(
          title: 'Default Database',
          icon: TDIcons.data_base,
          children: [
            // Inheritance toggle
            SettingsSwitchTile(
              title: 'Inherit from Global',
              subtitle: 'Use global default database setting',
              value: projectSettings.inheritDefaultDatabase,
              onChanged: (value) {
                ref
                    .read(projectSettingsProvider.notifier)
                    .setInheritDefaultDatabase(value);
              },
            ),
            // Database selection (only if not inheriting)
            if (!projectSettings.inheritDefaultDatabase)
              SettingsTile(
                title: 'Default Database Type',
                subtitle: projectSettings.defaultDatabase ??
                    globalSettings.defaultDatabase ??
                    'Not set',
                leading: Icon(
                  TDIcons.data_base,
                  size: 24,
                  color: tdTheme.brandNormalColor,
                ),
                onTap: () => _showProjectDatabaseTypeDialog(
                    context, ref, projectSettings.defaultDatabase),
              ),
          ],
        ),

        const SizedBox(height: 24),

        // Default Fields Section
        SettingsSection(
          title: 'Default Fields',
          icon: TDIcons.list,
          description: 'Configure default fields for new tables in this project',
          children: [
            // Inheritance toggle
            SettingsSwitchTile(
              title: 'Inherit from Global',
              subtitle: 'Use global default fields settings',
              value: projectSettings.inheritDefaultFields,
              onChanged: (value) {
                ref
                    .read(projectSettingsProvider.notifier)
                    .setInheritDefaultFields(value);
              },
            ),
            // Field toggles (only if not inheriting)
            if (!projectSettings.inheritDefaultFields) ...[
              TDDivider(margin: const EdgeInsets.symmetric(horizontal: 16)),
              _buildFieldToggle(
                context: context,
                title: 'REVISION',
                subtitle: 'Add revision number field',
                projectValue: projectSettings.defaultFieldsRevision,
                globalValue: globalSettings.defaultFieldsRevision,
                onChanged: (value) {
                  ref
                      .read(projectSettingsProvider.notifier)
                      .setDefaultFieldsRevision(value);
                },
              ),
              _buildFieldToggle(
                context: context,
                title: 'CREATED_BY',
                subtitle: 'Add creator field',
                projectValue: projectSettings.defaultFieldsCreatedBy,
                globalValue: globalSettings.defaultFieldsCreatedBy,
                onChanged: (value) {
                  ref
                      .read(projectSettingsProvider.notifier)
                      .setDefaultFieldsCreatedBy(value);
                },
              ),
              _buildFieldToggle(
                context: context,
                title: 'CREATED_TIME',
                subtitle: 'Add creation timestamp field',
                projectValue: projectSettings.defaultFieldsCreatedTime,
                globalValue: globalSettings.defaultFieldsCreatedTime,
                onChanged: (value) {
                  ref
                      .read(projectSettingsProvider.notifier)
                      .setDefaultFieldsCreatedTime(value);
                },
              ),
              _buildFieldToggle(
                context: context,
                title: 'UPDATED_BY',
                subtitle: 'Add updater field',
                projectValue: projectSettings.defaultFieldsUpdatedBy,
                globalValue: globalSettings.defaultFieldsUpdatedBy,
                onChanged: (value) {
                  ref
                      .read(projectSettingsProvider.notifier)
                      .setDefaultFieldsUpdatedBy(value);
                },
              ),
              _buildFieldToggle(
                context: context,
                title: 'UPDATED_TIME',
                subtitle: 'Add update timestamp field',
                projectValue: projectSettings.defaultFieldsUpdatedTime,
                globalValue: globalSettings.defaultFieldsUpdatedTime,
                onChanged: (value) {
                  ref
                      .read(projectSettingsProvider.notifier)
                      .setDefaultFieldsUpdatedTime(value);
                },
              ),
            ],
          ],
        ),

        const SizedBox(height: 24),

        // Reset Section
        SettingsSection(
          title: 'Reset',
          icon: TDIcons.refresh,
          children: [
            SettingsTile(
              title: 'Reset to Inherit All',
              subtitle: 'Reset all project settings to inherit from global',
              leading: Icon(
                TDIcons.close_circle,
                size: 24,
                color: tdTheme.errorNormalColor,
              ),
              onTap: () => _showProjectResetConfirmation(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoProjectState(TDThemeData tdTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            TDIcons.folder_open,
            size: 64,
            color: tdTheme.textColorSecondary,
          ),
          const SizedBox(height: 16),
          TDText(
            'No Project Open',
            font: tdTheme.fontTitleMedium,
            textColor: tdTheme.textColorSecondary,
          ),
          const SizedBox(height: 8),
          TDText(
            'Open a project to configure project-specific settings',
            font: tdTheme.fontBodySmall,
            textColor: tdTheme.textColorPlaceholder,
          ),
        ],
      ),
    );
  }

  Widget _buildFieldToggle({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool? projectValue,
    required bool globalValue,
    required ValueChanged<bool?> onChanged,
  }) {
    final tdTheme = TDTheme.of(context);
    // If project value is null, show global value with indicator
    final displayValue = projectValue ?? globalValue;
    final isUsingGlobal = projectValue == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 40),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TDText(
                      title,
                      font: tdTheme.fontBodyMedium,
                      fontWeight: FontWeight.w500,
                    ),
                    if (isUsingGlobal) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: tdTheme.bgColorSecondaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: TDText(
                          'Global',
                          font: tdTheme.fontMarkSmall,
                          textColor: tdTheme.brandNormalColor,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                TDText(
                  subtitle,
                  font: tdTheme.fontBodySmall,
                  textColor: tdTheme.textColorSecondary,
                ),
              ],
            ),
          ),
          TDSwitch(
            isOn: displayValue,
            size: TDSwitchSize.medium,
            onChanged: (newValue) {
              onChanged(newValue);
              return false;
            },
          ),
        ],
      ),
    );
  }

  void _showProjectDatabaseTypeDialog(
      BuildContext context, WidgetRef ref, String? currentValue) {
    showDialog(
      context: context,
      builder: (context) => DatabaseTypeDialog(
        currentValue: currentValue,
        onChanged: (value) {
          ref.read(projectSettingsProvider.notifier).setDefaultDatabase(value);
        },
      ),
    );
  }

  void _showProjectResetConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: 'Reset Project Settings',
        content:
            'Reset all project settings to inherit from global settings? This action cannot be undone.',
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
            ref.read(projectSettingsProvider.notifier).resetToDefaults();
            Navigator.pop(context);
            TDToast.showSuccess('Project settings reset', context: context);
          },
        ),
      ),
    );
  }
}
