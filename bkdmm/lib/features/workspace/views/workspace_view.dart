import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/models.dart';
import '../../../shared/providers/providers.dart';
import '../../../utils/id_generator.dart';
import '../providers/tab_provider.dart';
import '../widgets/module_tree.dart';
import '../widgets/tab_bar.dart';
import '../../modeling/entity_editor/views/entity_editor_view.dart';
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
                  Icons.folder_open,
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
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProject,
              tooltip: 'Save (Ctrl+S)',
            ),

          // Toggle properties panel
          IconButton(
            icon: Icon(
              _showPropertiesPanel ? Icons.close_fullscreen : Icons.open_in_full,
            ),
            onPressed: () {
              setState(() {
                _showPropertiesPanel = !_showPropertiesPanel;
              });
            },
            tooltip: _showPropertiesPanel
                ? 'Hide Properties'
                : 'Show Properties',
          ),

          // More actions menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (action) => _handleMenuAction(action),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'save',
                child: ListTile(
                  leading: Icon(Icons.save),
                  title: Text('Save'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'save_as',
                child: ListTile(
                  leading: Icon(Icons.save_as),
                  title: Text('Save As...'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'close',
                child: ListTile(
                  leading: Icon(Icons.close),
                  title: Text('Close Project'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Project Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'datatype',
                child: ListTile(
                  leading: Icon(Icons.data_object),
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
              Icons.tab_outlined,
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
                  Icons.view_module,
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
              Icons.account_tree_outlined,
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
            FilledButton.icon(
              onPressed: () => _showAddEntityDialog(module),
              icon: const Icon(Icons.add),
              label: const Text('Add Entity'),
            ),
          ],
        ),
      );
    }

    return _ERDiagramCanvas(
      module: module,
      theme: theme,
      colorScheme: colorScheme,
      onEntityTap: (entity) => _openEntityInTab(module, entity),
      onEntityDoubleTap: (entity) => _openEntityInTab(module, entity),
      onEntityDelete: (entity) => _confirmDeleteEntity(module, entity),
      onAddEntity: () => _showAddEntityDialog(module),
    );
  }

  void _openEntityInTab(Module module, Entity entity) {
    ref.read(tabProvider.notifier).openEntity(entity, module.id);
  }

  void _showEditEntityDialog(Module module, Entity entity) {
    // For now, just open in tab for editing
    _openEntityInTab(module, entity);
  }

  void _confirmDeleteEntity(Module module, Entity entity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entity'),
        content: Text('Are you sure you want to delete "${entity.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final updatedEntities = module.entities.where((e) => e.id != entity.id).toList();
              final updatedModule = module.copyWith(
                entities: updatedEntities,
                updatedAt: DateTime.now(),
              );
              ref.read(projectProvider.notifier).updateModule(module.id, updatedModule);
              Navigator.pop(context);
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
                  Icons.account_tree,
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
                          Icons.account_tree_outlined,
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
                        leading: const Icon(Icons.arrow_forward),
                        title: Text('${edge.source} → ${edge.target}'),
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
                  Icons.settings,
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
            Icons.error_outline,
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
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    setState(() {
                      _showPropertiesPanel = false;
                    });
                  },
                  visualDensity: VisualDensity.compact,
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
        _StatTile(icon: Icons.list_alt, label: 'Fields', value: '${entity.fields.length}'),
        _StatTile(icon: Icons.key, label: 'Primary Keys', value: '${entity.primaryKeys.length}'),
        _StatTile(icon: Icons.sort, label: 'Indexes', value: '${entity.indexes.length}'),
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
        _StatTile(icon: Icons.table_chart, label: 'Entities', value: '${module.entities.length}'),
        _StatTile(icon: Icons.account_tree, label: 'Relations', value: '${module.graphCanvas.edges.length}'),
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
        _StatTile(icon: Icons.view_module, label: 'Modules', value: '${project.modules.length}'),
        _StatTile(
          icon: Icons.table_chart,
          label: 'Entities',
          value: '${project.modules.fold<int>(0, (sum, m) => sum + m.entities.length)}',
        ),
        _StatTile(
          icon: Icons.list_alt,
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
                  Icons.folder,
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
                  Icons.tab,
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
                    Icons.circle,
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
                    Icons.check,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Save As coming soon')),
    );
  }

  Future<void> _closeProject() async {
    // Set closing flag to prevent rebuild issues
    setState(() => _isClosing = true);

    final projectState = ref.read(projectProvider);

    // Check for unsaved changes
    if (projectState.isDirty) {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Save changes?'),
          content: const Text(
            'The project has unsaved changes. Do you want to save before closing?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Discard'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
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

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Module'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Module Name (English)',
                hintText: 'e.g., user',
                prefixIcon: Icon(Icons.code),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: chnnameController,
              decoration: const InputDecoration(
                labelText: 'Chinese Name',
                hintText: 'e.g., 用户模块',
                prefixIcon: Icon(Icons.translate),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final module = ref.read(projectProvider.notifier).createNewModule(
        name: nameController.text.trim(),
        chnname: chnnameController.text.trim().isNotEmpty
            ? chnnameController.text.trim()
            : nameController.text.trim(),
      );
      ref.read(projectProvider.notifier).addModule(module);
    }
  }

  Future<void> _showAddEntityDialog(Module module) async {
    final titleController = TextEditingController();
    final chnnameController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Entity to ${module.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Entity Title (English)',
                hintText: 'e.g., user',
                prefixIcon: Icon(Icons.code),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: chnnameController,
              decoration: const InputDecoration(
                labelText: 'Chinese Name',
                hintText: 'e.g., 用户',
                prefixIcon: Icon(Icons.translate),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Add'),
          ),
        ],
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

/// Entity node widget for ER diagram - interactive
class _EntityNode extends StatefulWidget {
  final Entity entity;
  final Module module;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EntityNode({
    required this.entity,
    required this.module,
    required this.theme,
    required this.colorScheme,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_EntityNode> createState() => _EntityNodeState();
}

class _EntityNodeState extends State<_EntityNode> {
  bool _isHovered = false;
  bool _isSelected = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() => _isSelected = !_isSelected);
          widget.onTap();
        },
        onDoubleTap: widget.onEdit,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 200,
          decoration: BoxDecoration(
            color: widget.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isSelected
                  ? widget.colorScheme.primary
                  : (_isHovered
                      ? widget.colorScheme.primary.withValues(alpha: 0.5)
                      : widget.colorScheme.outline),
              width: _isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.colorScheme.shadow.withValues(alpha: _isHovered ? 0.2 : 0.1),
                blurRadius: _isHovered ? 12 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.table_chart,
                      size: 16,
                      color: widget.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.entity.title,
                        style: widget.theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: widget.colorScheme.onPrimaryContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Context menu button
                    if (_isHovered)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          size: 14,
                          color: widget.colorScheme.onPrimaryContainer,
                        ),
                        tooltip: 'Actions',
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit, size: 18),
                              title: Text('Edit'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'fields',
                            child: ListTile(
                              leading: Icon(Icons.list_alt, size: 18),
                              title: Text('Edit Fields'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete, size: 18),
                              title: Text('Delete'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              widget.onEdit();
                              break;
                            case 'fields':
                              widget.onEdit();
                              break;
                            case 'delete':
                              widget.onDelete();
                              break;
                          }
                        },
                      ),
                  ],
                ),
              ),

              // Chinese name
              if (widget.entity.chnname.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    widget.entity.chnname,
                    style: widget.theme.textTheme.labelSmall?.copyWith(
                      color: widget.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // Fields
              if (widget.entity.fields.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.entity.fields.take(5).map((field) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            if (field.pk)
                              Icon(
                                Icons.key,
                                size: 12,
                                color: widget.colorScheme.primary,
                              )
                            else
                              const SizedBox(width: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                field.name,
                                style: widget.theme.textTheme.labelSmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              field.type,
                              style: widget.theme.textTheme.labelSmall?.copyWith(
                                color: widget.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // More fields indicator
              if (widget.entity.fields.length > 5)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
                  child: Text(
                    '+${widget.entity.fields.length - 5} more fields',
                    style: widget.theme.textTheme.labelSmall?.copyWith(
                      color: widget.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

              // Statistics footer
              if (_isHovered)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.colorScheme.surfaceContainerLow,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.list_alt, size: 12, color: widget.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.entity.fields.length}',
                            style: widget.theme.textTheme.labelSmall?.copyWith(
                              color: widget.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.sort, size: 12, color: widget.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.entity.indexes.length}',
                            style: widget.theme.textTheme.labelSmall?.copyWith(
                              color: widget.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid painter for canvas background
class _GridPainter extends CustomPainter {
  final ColorScheme colorScheme;

  _GridPainter(this.colorScheme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    const gridSize = 20.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
