import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../../../shared/providers/providers.dart';
import '../../../constants/app_constants.dart';

/// Settings dialog with left tree navigation and right content panel
///
/// Structure:
/// - Left: Tree navigation with Global Settings and Project Settings nodes
/// - Right: Settings content based on selected node
class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  String _selectedNode = 'global'; // 'global' or 'project'
  String? _selectedSubNode; // Sub-node within project settings

  @override
  void initState() {
    super.initState();
    // Load project settings if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final project = ref.read(currentProjectProvider);
      ref.read(projectSettingsProvider.notifier).loadFromProject(project);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive dialog size
    final dialogWidth = screenWidth.clamp(600.0, 900.0);
    final dialogHeight = screenHeight.clamp(400.0, 600.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: tdTheme.bgColorContainer,
          borderRadius: BorderRadius.circular(tdTheme.radiusLarge),
          border: Border.all(color: tdTheme.componentBorderColor),
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(tdTheme),
            // Body with tree and content
            Expanded(
              child: Row(
                children: [
                  // Left tree navigation
                  _buildTreeNavigation(tdTheme, dialogWidth),
                  // Divider
                  VerticalDivider(
                    width: 1,
                    color: tdTheme.componentBorderColor,
                  ),
                  // Right content
                  Expanded(
                    child: _buildContentPanel(tdTheme),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(TDThemeData tdTheme) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: tdTheme.bgColorSecondaryContainer,
        border: Border(
          bottom: BorderSide(color: tdTheme.componentBorderColor),
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(tdTheme.radiusLarge),
          topRight: Radius.circular(tdTheme.radiusLarge),
        ),
      ),
      child: Row(
        children: [
          Icon(TDIcons.setting, size: 24, color: tdTheme.brandNormalColor),
          const SizedBox(width: 12),
          TDText(
            'Settings',
            font: tdTheme.fontTitleMedium,
            fontWeight: FontWeight.w600,
          ),
          const Spacer(),
          TDButton(
            icon: TDIcons.close,
            theme: TDButtonTheme.defaultTheme,
            type: TDButtonType.text,
            size: TDButtonSize.small,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeNavigation(TDThemeData tdTheme, double dialogWidth) {
    final hasProject = ref.watch(hasProjectSettingsProvider);
    final treeWidth = dialogWidth * 0.25.clamp(150.0, 200.0);

    return Container(
      width: treeWidth,
      color: tdTheme.bgColorSecondaryContainer,
      child: Column(
        children: [
          // Global Settings node
          _buildTreeNode(
            tdTheme: tdTheme,
            id: 'global',
            icon: TDIcons.internet,
            title: 'Global Settings',
            isSelected: _selectedNode == 'global',
            onTap: () => setState(() {
              _selectedNode = 'global';
              _selectedSubNode = null;
            }),
          ),
          TDDivider(margin: const EdgeInsets.symmetric(horizontal: 12)),
          // Project Settings node (with children)
          _buildTreeNode(
            tdTheme: tdTheme,
            id: 'project',
            icon: TDIcons.folder,
            title: 'Project Settings',
            isSelected: _selectedNode == 'project',
            isExpanded: _selectedNode == 'project',
            hasChildren: hasProject,
            disabled: !hasProject,
            onTap: hasProject
                ? () => setState(() {
                      _selectedNode = 'project';
                      _selectedSubNode = 'default_fields';
                    })
                : null,
          ),
          // Project sub-nodes
          if (_selectedNode == 'project' && hasProject)
            _buildTreeSubNode(
              tdTheme: tdTheme,
              id: 'default_fields',
              icon: TDIcons.list,
              title: 'Default Fields',
              isSelected: _selectedSubNode == 'default_fields',
              onTap: () => setState(() => _selectedSubNode = 'default_fields'),
            ),
          if (_selectedNode == 'project' && hasProject)
            _buildTreeSubNode(
              tdTheme: tdTheme,
              id: 'default_database',
              icon: TDIcons.data_base,
              title: 'Default Database',
              isSelected: _selectedSubNode == 'default_database',
              onTap: () => setState(() => _selectedSubNode = 'default_database'),
            ),
        ],
      ),
    );
  }

  Widget _buildTreeNode({
    required TDThemeData tdTheme,
    required String id,
    required IconData icon,
    required String title,
    required bool isSelected,
    bool isExpanded = false,
    bool hasChildren = false,
    bool disabled = false,
    VoidCallback? onTap,
  }) {
    final bgColor = isSelected
        ? tdTheme.brandNormalColor.withValues(alpha: 0.1)
        : Colors.transparent;
    final textColor = disabled
        ? tdTheme.textColorPlaceholder
        : isSelected
            ? tdTheme.brandNormalColor
            : tdTheme.textColorPrimary;
    final iconColor = disabled
        ? tdTheme.textColorPlaceholder
        : isSelected
            ? tdTheme.brandNormalColor
            : tdTheme.textColorSecondary;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          border: isSelected
              ? Border(
                  left: BorderSide(
                    color: tdTheme.brandNormalColor,
                    width: 3,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: TDText(
                title,
                font: tdTheme.fontBodyMedium,
                textColor: textColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (hasChildren)
              Icon(
                isExpanded ? TDIcons.chevron_down : TDIcons.chevron_right,
                size: 16,
                color: iconColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeSubNode({
    required TDThemeData tdTheme,
    required String id,
    required IconData icon,
    required String title,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    final bgColor = isSelected
        ? tdTheme.brandNormalColor.withValues(alpha: 0.08)
        : Colors.transparent;
    final textColor = isSelected
        ? tdTheme.brandNormalColor
        : tdTheme.textColorPrimary;
    final iconColor = isSelected
        ? tdTheme.brandNormalColor
        : tdTheme.textColorSecondary;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(left: 40, right: 16, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: bgColor,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: TDText(
                title,
                font: tdTheme.fontBodySmall,
                textColor: textColor,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentPanel(TDThemeData tdTheme) {
    if (_selectedNode == 'global') {
      return _GlobalSettingsPanel();
    } else if (_selectedNode == 'project') {
      final hasProject = ref.watch(hasProjectSettingsProvider);
      if (!hasProject) {
        return _buildNoProjectPanel(tdTheme);
      }
      return _ProjectSettingsPanel(subNode: _selectedSubNode ?? 'default_fields');
    }
    return const SizedBox();
  }

  Widget _buildNoProjectPanel(TDThemeData tdTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            TDIcons.folder_open,
            size: 48,
            color: tdTheme.textColorSecondary.withValues(alpha: 0.5),
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
}

/// Global settings panel
class _GlobalSettingsPanel extends ConsumerWidget {
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
          _SettingsSection(
            title: 'Appearance',
            icon: TDIcons.palette,
            children: [
              _SettingsTile(
                title: 'Theme Mode',
                subtitle: _getThemeModeLabel(settings.themeMode),
                leading: Icon(_getThemeModeIcon(settings.themeMode), size: 20, color: tdTheme.brandNormalColor),
                onTap: () => _showThemeModeDialog(context, ref),
              ),
              _SettingsTile(
                title: 'Accent Color',
                subtitle: 'Customize accent color',
                leading: Icon(TDIcons.color_invert, size: 20, color: tdTheme.brandNormalColor),
                trailing: _ColorDot(color: settings.accentColorValue ?? tdTheme.brandNormalColor),
                onTap: () => _showAccentColorDialog(context, ref),
              ),
              _SettingsTile(
                title: 'Font Size',
                subtitle: '${settings.editorFontSize.toInt()} pt',
                leading: Icon(TDIcons.textformat_bold, size: 20, color: tdTheme.brandNormalColor),
                onTap: () => _showFontSizeDialog(context, ref),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Editor Section
          _SettingsSection(
            title: 'Editor',
            icon: TDIcons.edit,
            children: [
              _SettingsTile(
                title: 'Auto-save Interval',
                subtitle: _getAutoSaveLabel(settings.autoSaveInterval),
                leading: Icon(TDIcons.time, size: 20, color: tdTheme.brandNormalColor),
                onTap: () => _showAutoSaveDialog(context, ref),
              ),
              _SettingsSwitchTile(
                title: 'Show Line Numbers',
                subtitle: 'In code preview',
                value: settings.showLineNumbers,
                onChanged: (v) => ref.read(settingsProvider.notifier).setShowLineNumbers(v),
              ),
              _SettingsSwitchTile(
                title: 'Code Completion',
                subtitle: 'Enable auto-completion',
                value: settings.enableCodeCompletion,
                onChanged: (v) => ref.read(settingsProvider.notifier).setEnableCodeCompletion(v),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Default Fields Section
          _SettingsSection(
            title: 'Default Fields (Global)',
            icon: TDIcons.list,
            description: 'Default fields for new tables (used as project defaults)',
            children: [
              _SettingsSwitchTile(
                title: 'REVISION',
                subtitle: 'Revision number field',
                value: settings.defaultFieldsRevision,
                onChanged: (v) => ref.read(settingsProvider.notifier).setDefaultFieldsRevision(v),
              ),
              _SettingsSwitchTile(
                title: 'CREATED_BY',
                subtitle: 'Creator field',
                value: settings.defaultFieldsCreatedBy,
                onChanged: (v) => ref.read(settingsProvider.notifier).setDefaultFieldsCreatedBy(v),
              ),
              _SettingsSwitchTile(
                title: 'CREATED_TIME',
                subtitle: 'Creation timestamp',
                value: settings.defaultFieldsCreatedTime,
                onChanged: (v) => ref.read(settingsProvider.notifier).setDefaultFieldsCreatedTime(v),
              ),
              _SettingsSwitchTile(
                title: 'UPDATED_BY',
                subtitle: 'Updater field',
                value: settings.defaultFieldsUpdatedBy,
                onChanged: (v) => ref.read(settingsProvider.notifier).setDefaultFieldsUpdatedBy(v),
              ),
              _SettingsSwitchTile(
                title: 'UPDATED_TIME',
                subtitle: 'Update timestamp',
                value: settings.defaultFieldsUpdatedTime,
                onChanged: (v) => ref.read(settingsProvider.notifier).setDefaultFieldsUpdatedTime(v),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Default Database Section
          _SettingsSection(
            title: 'Default Database',
            icon: TDIcons.data_base,
            children: [
              _SettingsTile(
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
}

/// Project settings panel
class _ProjectSettingsPanel extends ConsumerWidget {
  final String subNode;

  const _ProjectSettingsPanel({required this.subNode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (subNode == 'default_fields') {
      return _DefaultFieldsPanel();
    } else if (subNode == 'default_database') {
      return _DefaultDatabasePanel();
    }
    return const SizedBox();
  }
}

/// Default fields settings panel (project)
class _DefaultFieldsPanel extends ConsumerWidget {
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
                        'Use global default fields settings',
                        font: tdTheme.fontBodySmall,
                        textColor: tdTheme.textColorSecondary,
                      ),
                    ],
                  ),
                ),
                TDSwitch(
                  isOn: projectSettings.inheritDefaultFields,
                  size: TDSwitchSize.medium,
                  onChanged: (v) {
                    ref.read(projectSettingsProvider.notifier).setInheritDefaultFields(v);
                    return false;
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Field settings (only if not inheriting)
          if (!projectSettings.inheritDefaultFields)
            _SettingsSection(
              title: 'Default Fields',
              icon: TDIcons.list,
              description: 'Configure default fields for new tables in this project',
              children: [
                _buildFieldSwitch(
                  context: context,
                  ref: ref,
                  title: 'REVISION',
                  subtitle: 'Revision number field',
                  projectValue: projectSettings.defaultFieldsRevision,
                  globalValue: globalSettings.defaultFieldsRevision,
                  onChanged: (v) => ref.read(projectSettingsProvider.notifier).setDefaultFieldsRevision(v),
                ),
                _buildFieldSwitch(
                  context: context,
                  ref: ref,
                  title: 'CREATED_BY',
                  subtitle: 'Creator field',
                  projectValue: projectSettings.defaultFieldsCreatedBy,
                  globalValue: globalSettings.defaultFieldsCreatedBy,
                  onChanged: (v) => ref.read(projectSettingsProvider.notifier).setDefaultFieldsCreatedBy(v),
                ),
                _buildFieldSwitch(
                  context: context,
                  ref: ref,
                  title: 'CREATED_TIME',
                  subtitle: 'Creation timestamp',
                  projectValue: projectSettings.defaultFieldsCreatedTime,
                  globalValue: globalSettings.defaultFieldsCreatedTime,
                  onChanged: (v) => ref.read(projectSettingsProvider.notifier).setDefaultFieldsCreatedTime(v),
                ),
                _buildFieldSwitch(
                  context: context,
                  ref: ref,
                  title: 'UPDATED_BY',
                  subtitle: 'Updater field',
                  projectValue: projectSettings.defaultFieldsUpdatedBy,
                  globalValue: globalSettings.defaultFieldsUpdatedBy,
                  onChanged: (v) => ref.read(projectSettingsProvider.notifier).setDefaultFieldsUpdatedBy(v),
                ),
                _buildFieldSwitch(
                  context: context,
                  ref: ref,
                  title: 'UPDATED_TIME',
                  subtitle: 'Update timestamp',
                  projectValue: projectSettings.defaultFieldsUpdatedTime,
                  globalValue: globalSettings.defaultFieldsUpdatedTime,
                  onChanged: (v) => ref.read(projectSettingsProvider.notifier).setDefaultFieldsUpdatedTime(v),
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

  Widget _buildFieldSwitch({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required bool? projectValue,
    required bool globalValue,
    required ValueChanged<bool?> onChanged,
  }) {
    final tdTheme = TDTheme.of(context);
    // When project inherits, show global value (read-only)
    // When not inheriting, show editable switch
    final displayValue = projectValue ?? globalValue;
    final isUsingGlobal = projectValue == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const SizedBox(width: 32),
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tdTheme.bgColorSecondaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: TDText(
                          'Global',
                          font: tdTheme.fontMarkExtraSmall,
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
            onChanged: (v) {
              onChanged(v);
              return false;
            },
          ),
        ],
      ),
    );
  }
}

/// Default database settings panel (project)
class _DefaultDatabasePanel extends ConsumerWidget {
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
            _SettingsSection(
              title: 'Default Database Type',
              icon: TDIcons.data_base,
              children: [
                _SettingsTile(
                  title: 'Database Type',
                  subtitle: projectSettings.defaultDatabase ?? globalSettings.defaultDatabase ?? 'Not set',
                  leading: Icon(TDIcons.data_base, size: 20, color: tdTheme.brandNormalColor),
                  onTap: () => _showDatabaseTypeDialog(context, ref, isGlobal: false),
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
}

// === Helper Widgets ===

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? description;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    this.description,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: tdTheme.bgColorContainer,
        borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
        border: Border.all(color: tdTheme.componentBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: tdTheme.brandNormalColor),
                const SizedBox(width: 10),
                TDText(
                  title,
                  font: tdTheme.fontTitleSmall,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
          if (description != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
              child: TDText(
                description!,
                font: tdTheme.fontBodySmall,
                textColor: tdTheme.textColorSecondary,
              ),
            ),
          TDDivider(margin: const EdgeInsets.symmetric(horizontal: 12)),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.leading,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TDText(
                    title,
                    font: tdTheme.fontBodyMedium,
                    fontWeight: FontWeight.w500,
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
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TDText(
                  title,
                  font: tdTheme.fontBodyMedium,
                  fontWeight: FontWeight.w500,
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
            isOn: value,
            size: TDSwitchSize.medium,
            onChanged: (v) {
              onChanged(v);
              return false;
            },
          ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;

  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: tdTheme.componentBorderColor),
      ),
    );
  }
}

// === Dialog Helpers ===

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
    builder: (ctx) => TDAlertDialog(
      title: 'Theme Mode',
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: ['system', 'light', 'dark'].map((mode) {
          final isSelected = ref.read(settingsProvider).themeMode == mode;
          return TDCell(
            leftIcon: _getThemeModeIcon(mode),
            title: _getThemeModeLabel(mode),
            arrow: false,
            rightIcon: isSelected ? TDIcons.check : null,
            onClick: (_) {
              ref.read(settingsProvider.notifier).setThemeMode(mode);
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
      leftBtn: TDDialogButtonOptions(
        title: 'Cancel',
        theme: TDButtonTheme.defaultTheme,
        type: TDButtonType.text,
        action: () => Navigator.pop(ctx),
      ),
    ),
  );
}

void _showAccentColorDialog(BuildContext context, WidgetRef ref) {
  final tdTheme = TDTheme.of(context);
  const colors = [
    Color(0xFF0052D9),
    Color(0xFF366EF4),
    Color(0xFF2BA471),
    Color(0xFFE37318),
    Color(0xFFD54941),
    Color(0xFF8E4EC6),
  ];

  showDialog(
    context: context,
    builder: (ctx) => TDAlertDialog(
      title: 'Accent Color',
      contentWidget: SizedBox(
        width: 280,
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: colors.map((color) {
            return InkWell(
              onTap: () {
                ref.read(settingsProvider.notifier).setAccentColor(color);
                Navigator.pop(ctx);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: tdTheme.componentBorderColor),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      leftBtn: TDDialogButtonOptions(
        title: 'Cancel',
        theme: TDButtonTheme.defaultTheme,
        type: TDButtonType.text,
        action: () => Navigator.pop(ctx),
      ),
    ),
  );
}

void _showFontSizeDialog(BuildContext context, WidgetRef ref) {
  double value = ref.read(settingsProvider).editorFontSize;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => TDAlertDialog(
        title: 'Font Size',
        contentWidget: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TDText('${value.toInt()} pt', font: TDTheme.of(ctx).fontBodyLarge),
              const SizedBox(height: 16),
              TDSlider(
                value: value,
                sliderThemeData: TDSliderThemeData(min: 10, max: 24, divisions: 14),
                onChanged: (v) => setState(() => value = v),
              ),
            ],
          ),
        ),
        leftBtn: TDDialogButtonOptions(
          title: 'Cancel',
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          action: () => Navigator.pop(ctx),
        ),
        rightBtn: TDDialogButtonOptions(
          title: 'Apply',
          theme: TDButtonTheme.primary,
          type: TDButtonType.fill,
          action: () {
            ref.read(settingsProvider.notifier).setEditorFontSize(value);
            Navigator.pop(ctx);
          },
        ),
      ),
    ),
  );
}

void _showAutoSaveDialog(BuildContext context, WidgetRef ref) {
  const intervals = [0, 30, 60, 120, 300];
  final current = ref.read(settingsProvider).autoSaveInterval;

  showDialog(
    context: context,
    builder: (ctx) => TDAlertDialog(
      title: 'Auto-save Interval',
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: intervals.map((interval) {
          final isSelected = current == interval;
          return TDCell(
            leftIcon: TDIcons.time,
            title: _getAutoSaveLabel(interval),
            arrow: false,
            rightIcon: isSelected ? TDIcons.check : null,
            onClick: (_) {
              ref.read(settingsProvider.notifier).setAutoSaveInterval(interval);
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
      leftBtn: TDDialogButtonOptions(
        title: 'Cancel',
        theme: TDButtonTheme.defaultTheme,
        type: TDButtonType.text,
        action: () => Navigator.pop(ctx),
      ),
    ),
  );
}

void _showDatabaseTypeDialog(BuildContext context, WidgetRef ref, {required bool isGlobal}) {
  final current = isGlobal
      ? ref.read(settingsProvider).defaultDatabase
      : ref.read(projectSettingsProvider)?.defaultDatabase;

  showDialog(
    context: context,
    builder: (ctx) => TDAlertDialog(
      title: 'Default Database Type',
      contentWidget: SizedBox(
        width: 280,
        child: ListView(
          shrinkWrap: true,
          children: [
            TDCell(
              leftIcon: TDIcons.close,
              title: 'Not Set',
              arrow: false,
              rightIcon: current == null ? TDIcons.check : null,
              onClick: (_) {
                if (isGlobal) {
                  ref.read(settingsProvider.notifier).setDefaultDatabase(null);
                } else {
                  ref.read(projectSettingsProvider.notifier).setDefaultDatabase(null);
                }
                Navigator.pop(ctx);
              },
            ),
            ...AppConstants.supportedDatabases.map((db) {
              return TDCell(
                leftIcon: TDIcons.data_base,
                title: db,
                arrow: false,
                rightIcon: current == db ? TDIcons.check : null,
                onClick: (_) {
                  if (isGlobal) {
                    ref.read(settingsProvider.notifier).setDefaultDatabase(db);
                  } else {
                    ref.read(projectSettingsProvider.notifier).setDefaultDatabase(db);
                  }
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
      leftBtn: TDDialogButtonOptions(
        title: 'Cancel',
        theme: TDButtonTheme.defaultTheme,
        type: TDButtonType.text,
        action: () => Navigator.pop(ctx),
      ),
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