import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/td_popup_menu.dart';
import '../../../utils/id_generator.dart';
import '../providers/tab_provider.dart';

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
                _showAddModuleDialog();
              } else if (value == 'add_entity') {
                _showAddEntityDialog();
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
              onTap: _showAddModuleDialog,
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

        return _ModuleTreeItem(
          module: module,
          isExpanded: isExpanded,
          isSelected: isSelected,
          selectedEntityId: _selectedEntityId,
          onToggleExpand: () => _toggleExpand(module.id),
          onSelectModule: () => _selectModule(module),
          onSelectEntity: (entity) => _selectEntity(entity, module),
          onDeleteModule: () => _showDeleteModuleDialog(module),
          onDeleteEntity: (entity) => _showDeleteEntityDialog(entity, module),
          onRenameModule: () => _showRenameModuleDialog(module),
          onRenameEntity: (entity) => _showRenameEntityDialog(entity, module),
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

  void _showAddModuleDialog() {
    final nameController = TextEditingController();
    final chnnameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: '创建模块',
        contentWidget: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TDInput(
                controller: nameController,
                leftLabel: '模块名称 (英文)',
                hintText: '例如: user',
                leftIcon: const Icon(TDIcons.code),
                backgroundColor: Colors.transparent,
              ),
              const SizedBox(height: 12),
              TDInput(
                controller: chnnameController,
                leftLabel: '中文名称',
                hintText: '例如: 用户模块',
                leftIcon: const Icon(TDIcons.translate),
                backgroundColor: Colors.transparent,
              ),
              const SizedBox(height: 12),
              TDInput(
                controller: descController,
                leftLabel: '描述',
                hintText: '模块描述 (可选)',
                leftIcon: const Icon(TDIcons.edit),
                backgroundColor: Colors.transparent,
                maxLines: 2,
              ),
            ],
          ),
        ),
        leftBtn: TDDialogButtonOptions(
          title: '取消',
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          action: () => Navigator.pop(context),
        ),
        rightBtn: TDDialogButtonOptions(
          title: '创建',
          theme: TDButtonTheme.primary,
          type: TDButtonType.fill,
          action: () {
            if (nameController.text.trim().isEmpty) {
              TDToast.showText('请输入模块名称', context: context);
              return;
            }
            Navigator.pop(context);

            final now = DateTime.now();
            final module = Module(
              id: IdGenerator.generate(),
              name: nameController.text.trim(),
              chnname: chnnameController.text.trim().isNotEmpty
                  ? chnnameController.text.trim()
                  : nameController.text.trim(),
              description: descController.text.trim().isNotEmpty
                  ? descController.text.trim()
                  : null,
              entities: [],
              graphCanvas: GraphCanvas(),
              createdAt: now,
              updatedAt: now,
            );
            ref.read(projectNotifierProvider.notifier).addModule(module);
            TDToast.showSuccess('模块已创建', context: context);
          },
        ),
      ),
    );
  }

  void _showAddEntityDialog({Module? selectedModule}) {
    final titleController = TextEditingController();
    final chnnameController = TextEditingController();
    final remarkController = TextEditingController();
    String selectedModuleId = selectedModule?.id ??
        (widget.project.modules.isNotEmpty ? widget.project.modules.first.id : '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return TDAlertDialog(
            title: '创建表',
            contentWidget: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 模块选择下拉框
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: TDTheme.of(context).componentBorderColor),
                      borderRadius: BorderRadius.circular(TDTheme.of(context).radiusDefault),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedModuleId.isEmpty ? null : selectedModuleId,
                        hint: const Text('选择归属模块'),
                        isExpanded: true,
                        items: widget.project.modules.map((m) {
                          return DropdownMenuItem(
                            value: m.id,
                            child: Text('${m.chnname} (${m.name})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedModuleId = value ?? '';
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TDInput(
                    controller: titleController,
                    leftLabel: '表名称 (英文)',
                    hintText: '例如: user_info',
                    leftIcon: const Icon(TDIcons.code),
                    backgroundColor: Colors.transparent,
                  ),
                  const SizedBox(height: 12),
                  TDInput(
                    controller: chnnameController,
                    leftLabel: '中文名称',
                    hintText: '例如: 用户信息表',
                    leftIcon: const Icon(TDIcons.translate),
                    backgroundColor: Colors.transparent,
                  ),
                  const SizedBox(height: 12),
                  TDInput(
                    controller: remarkController,
                    leftLabel: '备注',
                    hintText: '表描述 (可选)',
                    leftIcon: const Icon(TDIcons.edit),
                    backgroundColor: Colors.transparent,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            leftBtn: TDDialogButtonOptions(
              title: '取消',
              theme: TDButtonTheme.defaultTheme,
              type: TDButtonType.text,
              action: () => Navigator.pop(context),
            ),
            rightBtn: TDDialogButtonOptions(
              title: '创建',
              theme: TDButtonTheme.primary,
              type: TDButtonType.fill,
              action: () {
                if (selectedModuleId.isEmpty) {
                  TDToast.showText('请选择归属模块', context: context);
                  return;
                }
                if (titleController.text.trim().isEmpty) {
                  TDToast.showText('请输入表名称', context: context);
                  return;
                }
                Navigator.pop(context);

                final now = DateTime.now();
                final entity = Entity(
                  id: IdGenerator.generate(),
                  title: titleController.text.trim(),
                  chnname: chnnameController.text.trim().isNotEmpty
                      ? chnnameController.text.trim()
                      : titleController.text.trim(),
                  remark: remarkController.text.trim().isNotEmpty
                      ? remarkController.text.trim()
                      : null,
                  fields: [],
                  indexes: [],
                  createdAt: now,
                  updatedAt: now,
                );

                // Find the module and update it
                final module = widget.project.modules.firstWhere(
                  (m) => m.id == selectedModuleId,
                );
                final updatedModule = module.copyWith(
                  entities: [...module.entities, entity],
                  updatedAt: now,
                );
                ref.read(projectNotifierProvider.notifier).updateModule(
                  module.id,
                  updatedModule,
                );
                TDToast.showSuccess('表已创建', context: context);

                // Open the new entity in tab
                ref.read(tabProvider.notifier).openEntity(entity, selectedModuleId);
              },
            ),
          );
        },
      ),
    );
  }

  void _showDeleteModuleDialog(Module module) {
    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: '删除模块',
        content: '确定要删除模块 "${module.chnname}" 吗？\n'
            '这将同时删除 ${module.entities.length} 个表。',
        leftBtn: TDDialogButtonOptions(
          title: '取消',
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          action: () => Navigator.pop(context),
        ),
        rightBtn: TDDialogButtonOptions(
          title: '删除',
          theme: TDButtonTheme.danger,
          type: TDButtonType.fill,
          action: () {
            Navigator.pop(context);
            ref.read(projectNotifierProvider.notifier).removeModule(module.id);
            TDToast.showSuccess('模块已删除', context: context);
          },
        ),
      ),
    );
  }

  void _showDeleteEntityDialog(Entity entity, Module module) {
    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: '删除表',
        content: '确定要删除表 "${entity.chnname}" 吗？\n'
            '这将移除 ${entity.fields.length} 个字段。',
        leftBtn: TDDialogButtonOptions(
          title: '取消',
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          action: () => Navigator.pop(context),
        ),
        rightBtn: TDDialogButtonOptions(
          title: '删除',
          theme: TDButtonTheme.danger,
          type: TDButtonType.fill,
          action: () {
            Navigator.pop(context);
            final now = DateTime.now();
            final updatedModule = module.copyWith(
              entities: module.entities.where((e) => e.id != entity.id).toList(),
              updatedAt: now,
            );
            ref.read(projectNotifierProvider.notifier).updateModule(
              module.id,
              updatedModule,
            );
            TDToast.showSuccess('表已删除', context: context);
          },
        ),
      ),
    );
  }

  void _showRenameModuleDialog(Module module) {
    final controller = TextEditingController(text: module.name);
    final chnController = TextEditingController(text: module.chnname);
    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: '重命名模块',
        contentWidget: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TDInput(
                controller: controller,
                hintText: '模块名称 (英文)',
                leftLabel: '模块名称',
                autofocus: true,
                backgroundColor: Colors.transparent,
              ),
              const SizedBox(height: 12),
              TDInput(
                controller: chnController,
                hintText: '中文名称',
                leftLabel: '中文名称',
                backgroundColor: Colors.transparent,
              ),
            ],
          ),
        ),
        leftBtn: TDDialogButtonOptions(
          title: '取消',
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          action: () => Navigator.pop(context),
        ),
        rightBtn: TDDialogButtonOptions(
          title: '确定',
          theme: TDButtonTheme.primary,
          type: TDButtonType.fill,
          action: () {
            Navigator.pop(context);
            if (controller.text.trim().isNotEmpty) {
              final updated = module.copyWith(
                name: controller.text.trim(),
                chnname: chnController.text.trim().isNotEmpty
                    ? chnController.text.trim()
                    : controller.text.trim(),
                updatedAt: DateTime.now(),
              );
              ref.read(projectNotifierProvider.notifier).updateModule(
                module.id,
                updated,
              );
            }
          },
        ),
      ),
    );
  }

  void _showRenameEntityDialog(Entity entity, Module module) {
    final controller = TextEditingController(text: entity.title);
    final chnController = TextEditingController(text: entity.chnname);
    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: '重命名表',
        contentWidget: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TDInput(
                controller: controller,
                hintText: '表名称 (英文)',
                leftLabel: '表名称',
                autofocus: true,
                backgroundColor: Colors.transparent,
              ),
              const SizedBox(height: 12),
              TDInput(
                controller: chnController,
                hintText: '中文名称',
                leftLabel: '中文名称',
                backgroundColor: Colors.transparent,
              ),
            ],
          ),
        ),
        leftBtn: TDDialogButtonOptions(
          title: '取消',
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          action: () => Navigator.pop(context),
        ),
        rightBtn: TDDialogButtonOptions(
          title: '确定',
          theme: TDButtonTheme.primary,
          type: TDButtonType.fill,
          action: () {
            Navigator.pop(context);
            if (controller.text.trim().isNotEmpty) {
              final updatedEntity = entity.copyWith(
                title: controller.text.trim(),
                chnname: chnController.text.trim().isNotEmpty
                    ? chnController.text.trim()
                    : controller.text.trim(),
                updatedAt: DateTime.now(),
              );
              final updatedModule = module.copyWith(
                entities: module.entities
                    .map((e) => e.id == entity.id ? updatedEntity : e)
                    .toList(),
                updatedAt: DateTime.now(),
              );
              ref.read(projectNotifierProvider.notifier).updateModule(
                module.id,
                updatedModule,
              );
            }
          },
        ),
      ),
    );
  }
}

/// Individual module tree item
class _ModuleTreeItem extends StatelessWidget {
  final Module module;
  final bool isExpanded;
  final bool isSelected;
  final String? selectedEntityId;
  final VoidCallback onToggleExpand;
  final VoidCallback onSelectModule;
  final Function(Entity) onSelectEntity;
  final VoidCallback onDeleteModule;
  final Function(Entity) onDeleteEntity;
  final VoidCallback onRenameModule;
  final Function(Entity) onRenameEntity;
  final VoidCallback onOpenRelation;
  final TDThemeData tdTheme;

  const _ModuleTreeItem({
    required this.module,
    required this.isExpanded,
    required this.isSelected,
    required this.selectedEntityId,
    required this.onToggleExpand,
    required this.onSelectModule,
    required this.onSelectEntity,
    required this.onDeleteModule,
    required this.onDeleteEntity,
    required this.onRenameModule,
    required this.onRenameEntity,
    required this.onOpenRelation,
    required this.tdTheme,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBg = isSelected
        ? tdTheme.brandNormalColor.withValues(alpha: 0.1)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Module row
        InkWell(
          onTap: onSelectModule,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: selectedBg,
            ),
            child: Row(
              children: [
                // Expand/collapse button
                GestureDetector(
                  onTap: onToggleExpand,
                  child: AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      TDIcons.chevron_right,
                      size: 18,
                      color: tdTheme.textColorSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Module icon
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? tdTheme.brandNormalColor.withValues(alpha: 0.15)
                        : tdTheme.bgColorSecondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    TDIcons.view_module,
                    size: 14,
                    color: isSelected
                        ? tdTheme.brandNormalColor
                        : tdTheme.textColorSecondary,
                  ),
                ),
                const SizedBox(width: 8),

                // Module name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TDText(
                        module.name,
                        font: tdTheme.fontBodyMedium,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      TDText(
                        module.chnname,
                        font: tdTheme.fontBodySmall,
                        textColor: tdTheme.textColorSecondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Entity count badge
                if (module.entities.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tdTheme.bgColorSecondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TDText(
                      '${module.entities.length}',
                      font: tdTheme.fontBodySmall,
                      textColor: tdTheme.textColorSecondary,
                    ),
                  ),

                // Context menu button
                _buildModuleContextMenu(context),
              ],
            ),
          ),
        ),

        // Entity list (if expanded)
        if (isExpanded)
          ...module.entities.map((entity) => _EntityTreeItem(
                entity: entity,
                isSelected: selectedEntityId == entity.id,
                onSelect: () => onSelectEntity(entity),
                onDelete: () => onDeleteEntity(entity),
                onRename: () => onRenameEntity(entity),
                tdTheme: tdTheme,
              )),
      ],
    );
  }

  Widget _buildModuleContextMenu(BuildContext context) {
    return TDPopupMenuButton(
      icon: TDIcons.more,
      iconSize: 16,
      iconColor: tdTheme.textColorSecondary,
      items: [
        TDPopupMenuItem(
          value: 'open_relation',
          icon: TDIcons.link,
          label: '打开关系图',
        ),
        const TDPopupMenuItem.divider(),
        TDPopupMenuItem(
          value: 'rename',
          icon: TDIcons.edit,
          label: '重命名',
        ),
        const TDPopupMenuItem.divider(),
        TDPopupMenuItem(
          value: 'delete',
          icon: TDIcons.delete,
          label: '删除',
          iconColor: tdTheme.errorNormalColor,
          textColor: tdTheme.errorNormalColor,
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'open_relation':
            onOpenRelation();
            break;
          case 'rename':
            onRenameModule();
            break;
          case 'delete':
            onDeleteModule();
            break;
        }
      },
    );
  }
}

/// Individual entity tree item
class _EntityTreeItem extends StatelessWidget {
  final Entity entity;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final TDThemeData tdTheme;

  const _EntityTreeItem({
    required this.entity,
    required this.isSelected,
    required this.onSelect,
    required this.onDelete,
    required this.onRename,
    required this.tdTheme,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBg = isSelected
        ? tdTheme.brandNormalColor.withValues(alpha: 0.1)
        : null;

    return InkWell(
      onTap: onSelect,
      onDoubleTap: onSelect,
      child: Container(
        padding: const EdgeInsets.only(left: 44, right: 8, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: selectedBg,
        ),
        child: Row(
          children: [
            // Entity icon
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected
                    ? tdTheme.brandNormalColor.withValues(alpha: 0.15)
                    : tdTheme.bgColorSecondaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                TDIcons.table,
                size: 12,
                color: isSelected
                    ? tdTheme.brandNormalColor
                    : tdTheme.textColorSecondary,
              ),
            ),
            const SizedBox(width: 8),

            // Entity name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TDText(
                    entity.title,
                    font: tdTheme.fontBodySmall,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  TDText(
                    entity.chnname,
                    font: tdTheme.fontBodySmall,
                    textColor: tdTheme.textColorSecondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Field count
            if (entity.fields.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: tdTheme.bgColorSecondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TDText(
                  '${entity.fields.length}',
                  font: tdTheme.fontBodySmall,
                  textColor: tdTheme.textColorSecondary,
                ),
              ),

            // Context menu
            _buildEntityContextMenu(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEntityContextMenu(BuildContext context) {
    return TDPopupMenuButton(
      icon: TDIcons.more,
      iconSize: 14,
      iconColor: tdTheme.textColorSecondary,
      items: [
        TDPopupMenuItem(
          value: 'rename',
          icon: TDIcons.edit,
          label: '重命名',
        ),
        const TDPopupMenuItem.divider(),
        TDPopupMenuItem(
          value: 'delete',
          icon: TDIcons.delete,
          label: '删除',
          iconColor: tdTheme.errorNormalColor,
          textColor: tdTheme.errorNormalColor,
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'rename':
            onRename();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
    );
  }
}
