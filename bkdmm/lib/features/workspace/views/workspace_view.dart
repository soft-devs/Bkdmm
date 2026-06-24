import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../../../shared/models/models.dart';
import '../../../shared/providers/providers.dart';
import '../../../utils/id_generator.dart';
import '../providers/tab_provider.dart';
import '../widgets/module_tree.dart';
import '../widgets/tab_bar.dart';
import '../../modeling/entity_editor/views/entity_editor_view.dart';
import '../../modeling/er_diagram/widgets/er_diagram_canvas.dart';
import '../../datatype/views/datatype_view.dart';

/// Workspace view - Main project editing interface with tab management
///
/// Layout:
/// ┌─────────────────────────────────────────────────────┐
/// │ MenuBar                                             │
/// ├─────────┬───────────────────────────────────────────┤
/// │ Module  │ Tab Bar (closable, scrollable)            │
/// │ Tree    ├───────────────────────────────────────────┤
/// │         │                                           │
/// │ - Module│         Tab Content Area                  │
/// │   - Table1│                                         │
/// │   - Table2│   (EntityEditor / ERDiagram / etc)      │
/// │         │                                           │
/// ├─────────┴───────────────────────────────────────────┤
/// │ StatusBar                                           │
/// └─────────────────────────────────────────────────────┘
class WorkspaceView extends ConsumerStatefulWidget {
  const WorkspaceView({super.key});

  @override
  ConsumerState<WorkspaceView> createState() => _WorkspaceViewState();
}

class _WorkspaceViewState extends ConsumerState<WorkspaceView> {
  bool _showPropertiesPanel = true;
  final double _sidebarWidth = 240;
  final double _propertiesPanelWidth = 280;
  bool _isClosing = false; // Track if we're actively closing

  @override
  void initState() {
    super.initState();
    // Open settings tab by default if no tabs are open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tabState = ref.read(tabProvider);
      if (!tabState.hasTabs) {
        // Don't auto-open any tab, let user select from tree
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectProvider);
    final project = projectState.project;

    // If closing or no project, show loading indicator
    if (_isClosing || project == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TabShortcuts(
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: Column(
          children: [
            // Menu bar
            _buildMenuBar(project, projectState, theme, colorScheme),

            // Main content area
            Expanded(
              child: Row(
                children: [
                  // Module tree sidebar
                  SizedBox(
                    width: _sidebarWidth,
                    child: ModuleTree(
                      project: project,
                      onAddModule: () => _showAddModuleDialog(),
                      onAddEntity: (module) => _showAddEntityDialog(module),
                      onSelectModule: (module) => _onSelectModule(module),
                    ),
                  ),

                  // Main content
                  Expanded(
                    child: Column(
                      children: [
                        // Tab bar
                        WorkspaceTabBar(
                          onNewTab: () => _showAddModuleDialog(),
                          onSettingsTab: () =>
                              ref.read(tabProvider.notifier).openSettings(),
                        ),

                        // Tab content area
                        Expanded(
                          child: _buildTabContent(project, theme, colorScheme),
                        ),
                      ],
                    ),
                  ),

                  // Properties panel (toggleable)
                  if (_showPropertiesPanel)
                    SizedBox(
                      width: _propertiesPanelWidth,
                      child: _buildPropertiesPanel(project, theme, colorScheme),
                    ),
                ],
              ),
            ),

            // Status bar
            _buildStatusBar(project, projectState, theme, colorScheme),
          ],
        ),
        // Remove FAB - functionality is available from menu and module tree
      ),
    );
  }

  Widget _buildMenuBar(
    Project project,
    ProjectState projectState,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Project name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  TDIcons.folder_open,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  project.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (projectState.isDirty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      '*',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Spacer(),

          // Actions
          if (projectState.isDirty)
            TDButton(
              icon: TDIcons.save,
              size: TDButtonSize.small,
              type: TDButtonType.text,
              theme: TDButtonTheme.primary,
              onTap: _saveProject,
            ),

          // Toggle properties panel
          TDButton(
            icon: _showPropertiesPanel ? TDIcons.fullscreen_exit : TDIcons.fullscreen,
            size: TDButtonSize.small,
            type: TDButtonType.text,
            theme: TDButtonTheme.defaultTheme,
            onTap: () {
              setState(() {
                _showPropertiesPanel = !_showPropertiesPanel;
              });
            },
          ),

          // More actions menu
          PopupMenuButton<String>(
            icon: const Icon(TDIcons.more),
            onSelected: (action) => _handleMenuAction(action),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'save',
                child: ListTile(
                  leading: Icon(TDIcons.save),
                  title: Text('Save'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'save_as',
                child: ListTile(
                  leading: Icon(TDIcons.folder),
                  title: Text('Save As...'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'close',
                child: ListTile(
                  leading: Icon(TDIcons.close),
                  title: Text('Close Project'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(TDIcons.setting),
                  title: Text('Project Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'datatype',
                child: ListTile(
                  leading: Icon(TDIcons.code),
                  title: Text('Data Types'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(
    Project project,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final tabState = ref.watch(tabProvider);
    final activeTab = tabState.activeTab;

    if (activeTab == null) {
      return _buildEmptyTabContent(project, theme, colorScheme);
    }

    switch (activeTab.type) {
      case TabType.entity:
        return _buildEntityEditor(activeTab, project, theme, colorScheme);
      case TabType.module:
        return _buildModuleView(activeTab, project, theme, colorScheme);
      case TabType.relation:
        return _buildRelationView(activeTab, project, theme, colorScheme);
      case TabType.settings:
        return _buildSettingsView(theme, colorScheme);
      case TabType.datatype:
        return const DataTypeView();
    }
  }

  Widget _buildEmptyTabContent(
    Project project,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      color: colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              TDIcons.browser,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Select an item from the tree',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Double-click a module or entity to open it in a tab',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntityEditor(
    WorkspaceTab tab,
    Project project,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // Find the entity
    Entity? entity;
    String? moduleId;
    for (final module in project.modules) {
      if (module.id == tab.moduleId) {
        moduleId = module.id;
        entity = module.entities.firstWhere(
          (e) => e.id == tab.entityId,
          orElse: () => throw StateError('Entity not found'),
        );
        break;
      }
    }

    if (entity == null || moduleId == null) {
      return _buildNotFoundContent('Entity', tab.title, theme, colorScheme);
    }

    return EntityEditorView(
      entity: entity,
      moduleId: moduleId,
    );
  }

  Widget _buildModuleView(
    WorkspaceTab tab,
    Project project,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // Find the module
    final module = project.modules.firstWhere(
      (m) => m.id == tab.moduleId,
      orElse: () => throw StateError('Module not found'),
    );

    return Container(
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Module header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  TDIcons.view_module,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  module.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  module.chnname,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '${module.entities.length} entities',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Module content (ER diagram placeholder)
          Expanded(
            child: _buildERDiagram(module, theme, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildERDiagram(
    Module module,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (module.entities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              TDIcons.view_module,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No entities in this module',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TDButton(
              text: 'Add Entity',
              icon: TDIcons.add,
              theme: TDButtonTheme.primary,
              type: TDButtonType.fill,
              onTap: () => _showAddEntityDialog(module),
            ),
          ],
        ),
      );
    }

    // 使用 ERDiagramWidget 替代 _ERDiagramCanvas
    // v1: ERDiagramWidget, v2: ERDiagramCanvas
    return ERDiagramCanvas(
      moduleId: module.id,
      onEntityEdit: (entity) => _showEntityEditorDialog(module, entity),
      onContextMenu: (position, entity) => _showDiagramContextMenu(position, entity, module),
    );
  }

  void _showDiagramContextMenu(Offset position, Entity? entity, Module module) {
    // 显示右键菜单
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        if (entity != null) ...[
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(TDIcons.edit),
              title: Text('Edit Entity'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(TDIcons.delete, color: Colors.red),
              title: Text('Delete Entity', style: TextStyle(color: Colors.red)),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ] else ...[
          const PopupMenuItem(
            value: 'add_entity',
            child: ListTile(
              leading: Icon(TDIcons.add),
              title: Text('Add Entity'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ],
    ).then((value) {
      if (value == 'edit' && entity != null) {
        _showEntityEditorDialog(module, entity);
      } else if (value == 'delete' && entity != null) {
        _confirmDeleteEntity(module, entity);
      } else if (value == 'add_entity') {
        _showAddEntityDialog(module);
      }
    });
  }

  void _showEntityEditorDialog(Module module, Entity entity) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 900,
          height: 700,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      TDIcons.table,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entity.title} - ${entity.chnname}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TDButton(
                      icon: TDIcons.close,
                      size: TDButtonSize.small,
                      type: TDButtonType.text,
                      theme: TDButtonTheme.defaultTheme,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Entity editor content
              Expanded(
                child: EntityEditorView(
                  entity: entity,
                  moduleId: module.id,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteEntity(Module module, Entity entity) {
    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: 'Delete Entity',
        content: 'Are you sure you want to delete "${entity.title}"?',
        leftBtn: TDButton(
          text: 'Cancel',
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          onTap: () => Navigator.pop(context),
        ),
        rightBtn: TDButton(
          text: 'Delete',
          theme: TDButtonTheme.danger,
          type: TDButtonType.fill,
          onTap: () {
            final updatedEntities = module.entities.where((e) => e.id != entity.id).toList();
            final updatedModule = module.copyWith(
              entities: updatedEntities,
              updatedAt: DateTime.now(),
            );
            ref.read(projectProvider.notifier).updateModule(module.id, updatedModule);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _buildRelationView(
    WorkspaceTab tab,
    Project project,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // Find the module
    final module = project.modules.firstWhere(
      (m) => m.id == tab.moduleId,
      orElse: () => throw StateError('Module not found'),
    );

    return Container(
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  TDIcons.relation,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Relations - ${module.name}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Relations content
          Expanded(
            child: module.graphCanvas.edges.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          TDIcons.view_module,
                          size: 64,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No relations defined',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: module.graphCanvas.edges.length,
                    itemBuilder: (context, index) {
                      final edge = module.graphCanvas.edges[index];
                      return ListTile(
                        leading: const Icon(TDIcons.arrow_right),
                        title: Text('${edge.source} -> ${edge.target}'),
                        subtitle: Text(edge.label ?? 'No label'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsView(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  TDIcons.setting,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Project Settings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Settings content
          Expanded(
            child: Center(
              child: Text(
                'Settings editor coming soon',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundContent(
    String type,
    String name,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            TDIcons.info_circle,
            size: 64,
            color: colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            '$type not found',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesPanel(
    Project project,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final tabState = ref.watch(tabProvider);
    final activeTab = tabState.activeTab;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Properties',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TDButton(
                  icon: TDIcons.close,
                  size: TDButtonSize.small,
                  type: TDButtonType.text,
                  theme: TDButtonTheme.defaultTheme,
                  onTap: () {
                    setState(() {
                      _showPropertiesPanel = false;
                    });
                  },
                ),
              ],
            ),
          ),

          // Properties content
          Expanded(
            child: activeTab != null
                ? _buildTabProperties(activeTab, project, theme, colorScheme)
                : _buildProjectProperties(project, theme, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildTabProperties(
    WorkspaceTab tab,
    Project project,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    switch (tab.type) {
      case TabType.entity:
        return _buildEntityProperties(tab, project, theme, colorScheme);
      case TabType.module:
        return _buildModuleProperties(tab, project, theme, colorScheme);
      case TabType.relation:
      case TabType.settings:
      case TabType.datatype:
        return _buildProjectProperties(project, theme, colorScheme);
    }
  }

  Widget _buildEntityProperties(
    WorkspaceTab tab,
    Project project,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // Find the entity
    Entity? entity;
    for (final module in project.modules) {
      if (module.id == tab.moduleId) {
        entity = module.entities.firstWhere(
          (e) => e.id == tab.entityId,
          orElse: () => throw StateError('Entity not found'),
        );
        break;
      }
    }

    if (entity == null) {
      return _buildProjectProperties(project, theme, colorScheme);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PropertySection(title: 'Entity Info'),
        _PropertyField(label: 'Title', value: entity.title),
        _PropertyField(label: 'Chinese Name', value: entity.chnname),
        _PropertyField(label: 'Remark', value: entity.remark ?? 'None'),
        _PropertyField(label: 'ID', value: entity.id),
        const SizedBox(height: 16),
        _PropertySection(title: 'Statistics'),
        _StatTile(icon: TDIcons.unordered_list, label: 'Fields', value: '${entity.fields.length}'),
        _StatTile(icon: TDIcons.key, label: 'Primary Keys', value: '${entity.primaryKeys.length}'),
        _StatTile(icon: TDIcons.chart, label: 'Indexes', value: '${entity.indexes.length}'),
        const SizedBox(height: 16),
        _PropertySection(title: 'Timestamps'),
        _PropertyField(label: 'Created', value: _formatDateTime(entity.createdAt)),
        _PropertyField(label: 'Updated', value: _formatDateTime(entity.updatedAt)),
      ],
    );
  }

  Widget _buildModuleProperties(
    WorkspaceTab tab,
    Project project,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // Find the module
    final module = project.modules.firstWhere(
      (m) => m.id == tab.moduleId,
      orElse: () => throw StateError('Module not found'),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PropertySection(title: 'Module Info'),
        _PropertyField(label: 'Name', value: module.name),
        _PropertyField(label: 'Chinese Name', value: module.chnname),
        _PropertyField(label: 'Description', value: module.description ?? 'None'),
        _PropertyField(label: 'ID', value: module.id),
        const SizedBox(height: 16),
        _PropertySection(title: 'Statistics'),
        _StatTile(icon: TDIcons.table, label: 'Entities', value: '${module.entities.length}'),
        _StatTile(icon: TDIcons.relation, label: 'Relations', value: '${module.graphCanvas.edges.length}'),
        const SizedBox(height: 16),
        _PropertySection(title: 'Timestamps'),
        _PropertyField(label: 'Created', value: _formatDateTime(module.createdAt)),
        _PropertyField(label: 'Updated', value: _formatDateTime(module.updatedAt)),
      ],
    );
  }

  Widget _buildProjectProperties(
    Project project,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PropertySection(title: 'Project Info'),
        _PropertyField(label: 'Name', value: project.name),
        _PropertyField(label: 'Description', value: project.description ?? 'None'),
        _PropertyField(label: 'Version', value: project.version),
        _PropertyField(label: 'ID', value: project.id),
        const SizedBox(height: 16),
        _PropertySection(title: 'Statistics'),
        _StatTile(icon: TDIcons.view_module, label: 'Modules', value: '${project.modules.length}'),
        _StatTile(
          icon: TDIcons.table,
          label: 'Entities',
          value: '${project.modules.fold<int>(0, (sum, m) => sum + m.entities.length)}',
        ),
        _StatTile(
          icon: TDIcons.unordered_list,
          label: 'Fields',
          value: '${project.modules.fold<int>(0, (sum, m) => sum + m.entities.fold<int>(0, (s, e) => s + e.fields.length))}',
        ),
        const SizedBox(height: 16),
        _PropertySection(title: 'Timestamps'),
        _PropertyField(label: 'Created', value: _formatDateTime(project.createdAt)),
        _PropertyField(label: 'Updated', value: _formatDateTime(project.updatedAt)),
      ],
    );
  }

  Widget _buildStatusBar(
    Project project,
    ProjectState projectState,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final tabState = ref.watch(tabProvider);

    return Container(
      height: 24,
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
          // Project info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  TDIcons.folder,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  project.name,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Separator
          Container(
            width: 1,
            height: 14,
            color: colorScheme.outlineVariant,
          ),

          // Tab count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  TDIcons.browser,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${tabState.tabs.length} tabs',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Save status
          if (projectState.isDirty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    TDIcons.circle,
                    size: 8,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Unsaved',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            )
          else if (projectState.lastSavedAt != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    TDIcons.check,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Saved',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _onSelectModule(Module module) {
    // Open module in tab when selected
    ref.read(tabProvider.notifier).openModule(module);
  }

  Future<void> _saveProject() async {
    try {
      await ref.read(projectProvider.notifier).saveProject();

      if (mounted) {
        TDToast.showText('Project saved', context: context);
      }
    } catch (e) {
      if (mounted) {
        TDToast.showText('Failed to save: $e', context: context);
      }
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'save':
        _saveProject();
        break;
      case 'save_as':
        _saveProjectAs();
        break;
      case 'close':
        _closeProject();
        break;
      case 'settings':
        ref.read(tabProvider.notifier).openSettings();
        break;
      case 'datatype':
        ref.read(tabProvider.notifier).openDatatype();
        break;
    }
  }

  Future<void> _saveProjectAs() async {
    // TODO: Implement save as dialog
    TDToast.showText('Save As coming soon', context: context);
  }

  Future<void> _closeProject() async {
    // Set closing flag to prevent rebuild issues
    setState(() => _isClosing = true);

    final projectState = ref.read(projectProvider);

    // Check for unsaved changes
    if (projectState.isDirty) {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) => TDAlertDialog(
          title: 'Save changes?',
          content: 'The project has unsaved changes. Do you want to save before closing?',
          leftBtn: TDButton(
            text: 'Discard',
            theme: TDButtonTheme.defaultTheme,
            type: TDButtonType.text,
            onTap: () => Navigator.pop(context, false),
          ),
          rightBtn: TDButton(
            text: 'Save',
            theme: TDButtonTheme.primary,
            type: TDButtonType.fill,
            onTap: () => Navigator.pop(context, true),
          ),
        ),
      );

      if (shouldSave == true) {
        await _saveProject();
      }
    }

    // Clear all tabs first
    ref.read(tabProvider.notifier).closeAllTabs();

    // Close project
    await ref.read(projectProvider.notifier).closeProject(promptSave: false);

    if (mounted) {
      // Pop to return to home view
      Navigator.of(context).pop();
    }
  }

  Future<void> _showAddModuleDialog() async {
    final nameController = TextEditingController();
    final chnnameController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TDAlertDialog(
        title: 'Create New Module',
        content: 'A module is a container for related database tables/entities.',
        leftBtn: TDButton(
          text: 'Cancel',
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          onTap: () => Navigator.pop(context, false),
        ),
        rightBtn: TDButton(
          text: 'Create Module',
          theme: TDButtonTheme.primary,
          type: TDButtonType.fill,
          onTap: () {
            if (nameController.text.trim().isNotEmpty) {
              Navigator.pop(context, true);
            }
          },
        ),
      ),
    );

    if (result == true && mounted) {
      final module = ref.read(projectProvider.notifier).createNewModule(
        name: nameController.text.trim(),
        chnname: chnnameController.text.trim().isNotEmpty
            ? chnnameController.text.trim()
            : nameController.text.trim(),
        description: descController.text.trim().isNotEmpty
            ? descController.text.trim()
            : null,
      );
      ref.read(projectProvider.notifier).addModule(module);
    }
  }

  Future<void> _showAddEntityDialog(Module module) async {
    final titleController = TextEditingController();
    final chnnameController = TextEditingController();
    final remarkController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TDAlertDialog(
        title: 'Create Table in "${module.name}"',
        content: 'Create a new database table/entity in module "${module.chnname}".',
        leftBtn: TDButton(
          text: 'Cancel',
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          onTap: () => Navigator.pop(context, false),
        ),
        rightBtn: TDButton(
          text: 'Create Table',
          theme: TDButtonTheme.primary,
          type: TDButtonType.fill,
          onTap: () {
            if (titleController.text.trim().isNotEmpty) {
              Navigator.pop(context, true);
            }
          },
        ),
      ),
    );

    if (result == true && mounted) {
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

      final updatedModule = module.copyWith(
        entities: [...module.entities, entity],
        updatedAt: now,
      );
      ref.read(projectProvider.notifier).updateModule(module.id, updatedModule);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Property section widget
class _PropertySection extends StatelessWidget {
  final String title;

  const _PropertySection({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Property field widget
class _PropertyField extends StatelessWidget {
  final String label;
  final String value;

  const _PropertyField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Stat tile widget
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}