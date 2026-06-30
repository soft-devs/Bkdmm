import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import 'package:bkdmm/shared/models/models.dart';
import 'package:bkdmm/shared/widgets/td_popup_menu.dart';
import '../providers/tab_provider.dart';
import '../widgets/module_tree_item.dart';
import '../dialogs/module_dialogs.dart';

/// Module tree widget - displays project modules and entities in a tree structure
class ModuleTree extends ConsumerStatefulWidget {
  final Project project;

  const ModuleTree({
    super.key,
    required this.project,
  });

  @override
  ConsumerState<ModuleTree> createState() => _ModuleTreeState();
}

class _ModuleTreeState extends ConsumerState<ModuleTree> {
  final Set<String> _expandedModules = {};
  String? _selectedModuleId;
  String? _selectedEntityId;

  @override
  void initState() {
    super.initState();
    // Auto-expand all modules
    for (final module in widget.project.modules) {
      _expandedModules.add(module.id);
    }
    if (widget.project.modules.isNotEmpty) {
      _selectedModuleId = widget.project.modules.first.id;
    }
  }

  @override
  void didUpdateWidget(ModuleTree oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset selection if modules changed
    if (oldWidget.project.modules != widget.project.modules) {
      if (widget.project.modules.isNotEmpty) {
        if (_selectedModuleId == null ||
            !widget.project.modules.any((m) => m.id == _selectedModuleId)) {
          _selectedModuleId = widget.project.modules.first.id;
        }
        // Auto-expand new modules
        for (final module in widget.project.modules) {
          if (!_expandedModules.contains(module.id)) {
            _expandedModules.add(module.id);
          }
        }
      }
    }
  }

  void _toggleExpand(String moduleId) {
    setState(() {
      if (_expandedModules.contains(moduleId)) {
        _expandedModules.remove(moduleId);
      } else {
        _expandedModules.add(moduleId);
      }
    });
  }

  void _selectModule(Module module) {
    setState(() {
      _selectedModuleId = module.id;
      _selectedEntityId = null;
    });
    ref.read(tabProvider.notifier).openModule(module);
  }

  void _selectEntity(Entity entity, Module module) {
    setState(() {
      _selectedModuleId = module.id;
      _selectedEntityId = entity.id;
    });
    // Open entity in tab
    ref.read(tabProvider.notifier).openEntity(entity, module.id);
  }

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);
    final modules = widget.project.modules;

    return Container(
      decoration: BoxDecoration(
        color: tdTheme.bgColorContainer,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(tdTheme),

          // Tree content
          Expanded(
            child: modules.isEmpty
                ? _buildEmptyState(tdTheme)
                : _buildTree(modules, tdTheme),
          ),

          // Status bar
          _buildStatusBar(modules, tdTheme),
        ],
      ),
    );
  }

  Widget _buildHeader(TDThemeData tdTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: tdTheme.bgColorSecondaryContainer,
        border: Border(
          bottom: BorderSide(
            color: tdTheme.componentBorderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Collapse/Expand all
          TDButton(
            icon: TDIcons.unfold_more,
            size: TDButtonSize.small,
            type: TDButtonType.text,
            theme: TDButtonTheme.defaultTheme,
            onTap: () {
              setState(() {
                _expandedModules.addAll(widget.project.modules.map((m) => m.id));
              });
            },
          ),
          TDButton(
            icon: TDIcons.unfold_less,
            size: TDButtonSize.small,
            type: TDButtonType.text,
            theme: TDButtonTheme.defaultTheme,
            onTap: () {
              setState(() {
                _expandedModules.clear();
              });
            },
          ),
          const Spacer(),
          // Add button with dropdown menu
          TDPopupMenuButton(
            icon: TDIcons.add,
            iconSize: 18,
            iconColor: tdTheme.brandNormalColor,
            items: [
              const TDPopupMenuItem(
                value: 'add_module',
                icon: TDIcons.view_module,
                label: '新建模块',
              ),
              const TDPopupMenuItem(
                value: 'add_entity',
                icon: TDIcons.table,
                label: '新建表',
              ),
            ],
            onSelected: (value) {
              if (value == 'add_module') {
                showAddModuleDialog(context, ref, widget.project.modules);
              } else if (value == 'add_entity') {
                showAddEntityDialog(context, ref, widget.project.modules);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(TDThemeData tdTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              TDIcons.view_module,
              size: 48,
              color: tdTheme.textColorSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            TDText(
              '暂无模块',
              font: tdTheme.fontBodyMedium,
              textColor: tdTheme.textColorSecondary,
            ),
            const SizedBox(height: 8),
            TDButton(
              icon: TDIcons.add,
              text: '新建模块',
              theme: TDButtonTheme.primary,
              type: TDButtonType.fill,
              size: TDButtonSize.small,
              onTap: () => showAddModuleDialog(context, ref, widget.project.modules),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTree(List<Module> modules, TDThemeData tdTheme) {
    return ListView.builder(
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        final isExpanded = _expandedModules.contains(module.id);
        final isSelected = _selectedModuleId == module.id;

        return ModuleTreeItem(
          module: module,
          isExpanded: isExpanded,
          isSelected: isSelected,
          selectedEntityId: _selectedEntityId,
          onToggleExpand: () => _toggleExpand(module.id),
          onSelectModule: () => _selectModule(module),
          onSelectEntity: (entity) => _selectEntity(entity, module),
          onDeleteModule: () => showDeleteModuleDialog(context, ref, module),
          onDeleteEntity: (entity) => showDeleteEntityDialog(context, ref, entity, module),
          onRenameModule: () => showRenameModuleDialog(context, ref, module),
          onRenameEntity: (entity) => showRenameEntityDialog(context, ref, entity, module),
          onOpenRelation: () =>
              ref.read(tabProvider.notifier).openRelation(module.id, module.name),
          tdTheme: tdTheme,
        );
      },
    );
  }

  Widget _buildStatusBar(List<Module> modules, TDThemeData tdTheme) {
    final entityCount = modules.fold<int>(0, (sum, m) => sum + m.entities.length);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: tdTheme.bgColorSecondaryContainer,
        border: Border(
          top: BorderSide(
            color: tdTheme.componentBorderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            TDIcons.view_module,
            size: 14,
            color: tdTheme.textColorSecondary,
          ),
          const SizedBox(width: 4),
          TDText(
            '${modules.length}',
            font: tdTheme.fontBodySmall,
            textColor: tdTheme.textColorSecondary,
          ),
          const SizedBox(width: 12),
          Icon(
            TDIcons.table,
            size: 14,
            color: tdTheme.textColorSecondary,
          ),
          const SizedBox(width: 4),
          TDText(
            '$entityCount',
            font: tdTheme.fontBodySmall,
            textColor: tdTheme.textColorSecondary,
          ),
        ],
      ),
    );
  }
}