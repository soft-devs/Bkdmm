import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/models.dart';
import '../providers/tab_provider.dart';

/// Module tree widget - displays project modules and entities in a tree structure
class ModuleTree extends ConsumerStatefulWidget {
  final Project project;
  final VoidCallback? onAddModule;
  final Function(Module)? onAddEntity;
  final Function(Module)? onSelectModule;

  const ModuleTree({
    super.key,
    required this.project,
    this.onAddModule,
    this.onAddEntity,
    this.onSelectModule,
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
    widget.onSelectModule?.call(module);
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final modules = widget.project.modules;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(theme, colorScheme),

          // Tree content
          Expanded(
            child: modules.isEmpty
                ? _buildEmptyState(theme, colorScheme)
                : _buildTree(modules, theme, colorScheme),
          ),

          // Status bar
          _buildStatusBar(modules, theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Collapse/Expand all
          IconButton(
            icon: const Icon(Icons.unfold_more, size: 18),
            onPressed: () {
              setState(() {
                _expandedModules.addAll(widget.project.modules.map((m) => m.id));
              });
            },
            tooltip: 'Expand all',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.unfold_less, size: 18),
            onPressed: () {
              setState(() {
                _expandedModules.clear();
              });
            },
            tooltip: 'Collapse all',
            visualDensity: VisualDensity.compact,
          ),
          const Spacer(),
          // Add module button
          if (widget.onAddModule != null)
            IconButton(
              icon: const Icon(Icons.add, size: 18),
              onPressed: widget.onAddModule,
              tooltip: 'Add module',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.view_module_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No modules',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.onAddModule != null)
              FilledButton.icon(
                onPressed: widget.onAddModule,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Module'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTree(List<Module> modules, ThemeData theme, ColorScheme colorScheme) {
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
          onAddEntity: widget.onAddEntity != null
              ? () => widget.onAddEntity!(module)
              : null,
          onDeleteModule: () => _showDeleteModuleDialog(module, context),
          onDeleteEntity: (entity) =>
              _showDeleteEntityDialog(entity, module, context),
          onRenameModule: () => _showRenameModuleDialog(module, context),
          onRenameEntity: (entity) =>
              _showRenameEntityDialog(entity, module, context),
          onOpenRelation: () =>
              ref.read(tabProvider.notifier).openRelation(module.id, module.name),
          theme: theme,
          colorScheme: colorScheme,
        );
      },
    );
  }

  Widget _buildStatusBar(List<Module> modules, ThemeData theme, ColorScheme colorScheme) {
    final entityCount = modules.fold<int>(0, (sum, m) => sum + m.entities.length);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.view_module,
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            '${modules.length}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.table_chart,
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            '$entityCount',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteModuleDialog(Module module, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Module'),
        content: Text(
          'Are you sure you want to delete "${module.name}"?\n'
          'This will also delete ${module.entities.length} entities.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Call project notifier to delete module
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteEntityDialog(Entity entity, Module module, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entity'),
        content: Text(
          'Are you sure you want to delete "${entity.title}"?\n'
          'This will remove ${entity.fields.length} fields.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Call project notifier to delete entity
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRenameModuleDialog(Module module, BuildContext context) {
    final controller = TextEditingController(text: module.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Module'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Module Name',
            hintText: 'Enter new module name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Call project notifier to rename module
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showRenameEntityDialog(Entity entity, Module module, BuildContext context) {
    final controller = TextEditingController(text: entity.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Entity'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Entity Name',
            hintText: 'Enter new entity name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Call project notifier to rename entity
            },
            child: const Text('Rename'),
          ),
        ],
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
  final VoidCallback? onAddEntity;
  final VoidCallback onDeleteModule;
  final Function(Entity) onDeleteEntity;
  final VoidCallback onRenameModule;
  final Function(Entity) onRenameEntity;
  final VoidCallback onOpenRelation;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _ModuleTreeItem({
    required this.module,
    required this.isExpanded,
    required this.isSelected,
    required this.selectedEntityId,
    required this.onToggleExpand,
    required this.onSelectModule,
    required this.onSelectEntity,
    required this.onAddEntity,
    required this.onDeleteModule,
    required this.onDeleteEntity,
    required this.onRenameModule,
    required this.onRenameEntity,
    required this.onOpenRelation,
    required this.theme,
    required this.colorScheme,
  });

  IconData _getModuleIcon() {
    return Icons.view_module;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Module row
        InkWell(
          onTap: onSelectModule,
          onDoubleTap: () {
            // Open module in tab
            // TODO: Need to pass ref to access tab provider
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : null,
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
                      Icons.chevron_right,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
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
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getModuleIcon(),
                    size: 14,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),

                // Module name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        module.chnname,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
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
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${module.entities.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
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
                theme: theme,
                colorScheme: colorScheme,
              )),

        // Add entity button (if expanded)
        if (isExpanded && onAddEntity != null)
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: TextButton.icon(
              onPressed: onAddEntity,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Entity'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildModuleContextMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        size: 16,
        color: colorScheme.onSurfaceVariant,
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'open_relation',
          child: const ListTile(
            leading: Icon(Icons.account_tree),
            title: Text('Open Relation'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'rename',
          child: const ListTile(
            leading: Icon(Icons.edit),
            title: Text('Rename'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'add_entity',
          child: const ListTile(
            leading: Icon(Icons.add),
            title: Text('Add Entity'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: colorScheme.error),
            title: Text('Delete', style: TextStyle(color: colorScheme.error)),
            contentPadding: EdgeInsets.zero,
          ),
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
          case 'add_entity':
            onAddEntity?.call();
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
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _EntityTreeItem({
    required this.entity,
    required this.isSelected,
    required this.onSelect,
    required this.onDelete,
    required this.onRename,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      onDoubleTap: onSelect,
      child: Container(
        padding: const EdgeInsets.only(left: 44, right: 8, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
        ),
        child: Row(
          children: [
            // Entity icon
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.table_chart,
                size: 12,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),

            // Entity name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entity.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    entity.chnname,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
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
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${entity.fields.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
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
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        size: 14,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'rename',
          child: const ListTile(
            leading: Icon(Icons.edit),
            title: Text('Rename'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: colorScheme.error),
            title: Text('Delete', style: TextStyle(color: colorScheme.error)),
            contentPadding: EdgeInsets.zero,
          ),
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