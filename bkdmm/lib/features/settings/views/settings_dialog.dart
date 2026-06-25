import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../../../shared/providers/providers.dart';
import '../panels/panels.dart';

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
      return const GlobalSettingsPanel();
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

/// Project settings panel wrapper
class _ProjectSettingsPanel extends ConsumerWidget {
  final String subNode;

  const _ProjectSettingsPanel({required this.subNode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (subNode == 'default_fields') {
      return const DefaultFieldsPanel();
    } else if (subNode == 'default_database') {
      return const DefaultDatabasePanel();
    }
    return const SizedBox();
  }
}