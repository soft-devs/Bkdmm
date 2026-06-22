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

/// ER Diagram Canvas with infinite scrolling and draggable nodes
class _ERDiagramCanvas extends StatefulWidget {
  final Module module;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final Function(Entity) onEntityTap;
  final Function(Entity) onEntityDoubleTap;
  final Function(Entity) onEntityDelete;
  final VoidCallback onAddEntity;

  const _ERDiagramCanvas({
    required this.module,
    required this.theme,
    required this.colorScheme,
    required this.onEntityTap,
    required this.onEntityDoubleTap,
    required this.onEntityDelete,
    required this.onAddEntity,
  });

  @override
  State<_ERDiagramCanvas> createState() => _ERDiagramCanvasState();
}

class _ERDiagramCanvasState extends State<_ERDiagramCanvas> {
  // Interaction mode
  InteractionMode _interactionMode = InteractionMode.move; // 默认移动模式

  // Store entity positions
  final Map<String, Offset> _entityPositions = {};
  Offset _canvasOffset = Offset.zero;
  double _scale = 1.0;
  Offset _lastFocalPoint = Offset.zero;

  // For dragging
  String? _draggingEntityId;
  Offset _dragStartPosition = Offset.zero;

  // For edge creation
  bool _isCreatingEdge = false;
  String? _edgeStartEntityId;
  Offset _edgePreviewEnd = Offset.zero;

  @override
  void initState() {
    super.initState();
    // Initialize default positions for entities
    for (int i = 0; i < widget.module.entities.length; i++) {
      final entity = widget.module.entities[i];
      _entityPositions[entity.id] = Offset(
        50.0 + (i % 3) * 250,
        50.0 + (i / 3).floor() * 200,
      );
    }
  }

  @override
  void didUpdateWidget(_ERDiagramCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update positions when entities change
    for (int i = 0; i < widget.module.entities.length; i++) {
      final entity = widget.module.entities[i];
      if (!_entityPositions.containsKey(entity.id)) {
        _entityPositions[entity.id] = Offset(
          50.0 + (i % 3) * 250,
          50.0 + (i / 3).floor() * 200,
        );
      }
    }
    // Remove positions for deleted entities
    final entityIds = widget.module.entities.map((e) => e.id).toSet();
    _entityPositions.keys.where((id) => !entityIds.contains(id)).toList().forEach(
      (id) => _entityPositions.remove(id),
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    // Don't move canvas if dragging an entity
    if (_draggingEntityId != null) return;

    setState(() {
      // Update scale
      final newScale = details.scale * _scale;
      _scale = newScale.clamp(0.5, 2.0);

      // Update offset based on focal point movement
      final focalPointDelta = details.localFocalPoint - _lastFocalPoint;
      _canvasOffset += focalPointDelta;
      _lastFocalPoint = details.localFocalPoint;
    });
  }

  void _onEntityPanStart(String entityId, DragStartDetails details) {
    setState(() {
      _draggingEntityId = entityId;
      _dragStartPosition = _entityPositions[entityId] ?? Offset.zero;
    });
  }

  void _onEntityPanUpdate(DragUpdateDetails details) {
    if (_draggingEntityId == null) return;

    setState(() {
      _entityPositions[_draggingEntityId!] = _dragStartPosition + details.delta;
    });
  }

  void _onEntityPanEnd(DragEndDetails details) {
    setState(() {
      _draggingEntityId = null;
    });
  }

  void _resetView() {
    setState(() {
      _canvasOffset = Offset.zero;
      _scale = 1.0;
    });
  }

  void _autoLayout() {
    setState(() {
      for (int i = 0; i < widget.module.entities.length; i++) {
        final entity = widget.module.entities[i];
        _entityPositions[entity.id] = Offset(
          50.0 + (i % 3) * 250,
          50.0 + (i / 3).floor() * 200,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Canvas with gestures - use only scale gesture
        GestureDetector(
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          child: Container(
            color: widget.colorScheme.surface,
            child: CustomPaint(
              painter: _GridPainter(widget.colorScheme, offset: _canvasOffset, scale: _scale),
              size: Size.infinite,
            ),
          ),
        ),

        // Entity nodes (transformed with canvas offset and scale)
        ...widget.module.entities.map((entity) {
          final position = (_entityPositions[entity.id] ?? Offset(50, 50)) + _canvasOffset;
          return Positioned(
            left: position.dx * _scale,
            top: position.dy * _scale,
            child: Transform.scale(
              scale: _scale,
              child: _DraggableEntityNode(
                entity: entity,
                theme: widget.theme,
                colorScheme: widget.colorScheme,
                onTap: () => widget.onEntityTap(entity),
                onDoubleTap: () => widget.onEntityDoubleTap(entity),
                onDelete: () => widget.onEntityDelete(entity),
                onPanStart: (details) => _onEntityPanStart(entity.id, details),
                onPanUpdate: _onEntityPanUpdate,
                onPanEnd: _onEntityPanEnd,
                isDragging: _draggingEntityId == entity.id,
              ),
            ),
          );
        }),

        // Toolbar overlay
        Positioned(
          right: 16,
          top: 16,
          child: _buildToolbar(),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: () => setState(() => _scale = (_scale + 0.1).clamp(0.5, 2.0)),
              tooltip: 'Zoom In',
              iconSize: 20,
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: () => setState(() => _scale = (_scale - 0.1).clamp(0.5, 2.0)),
              tooltip: 'Zoom Out',
              iconSize: 20,
            ),
            IconButton(
              icon: const Icon(Icons.fit_screen),
              onPressed: _resetView,
              tooltip: 'Reset View',
              iconSize: 20,
            ),
            IconButton(
              icon: const Icon(Icons.auto_fix_high),
              onPressed: _autoLayout,
              tooltip: 'Auto Layout',
              iconSize: 20,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: widget.onAddEntity,
              tooltip: 'Add Entity',
              iconSize: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Draggable entity node for ER diagram
class _DraggableEntityNode extends StatelessWidget {
  final Entity entity;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onDelete;
  final Function(DragStartDetails) onPanStart;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function(DragEndDetails) onPanEnd;
  final bool isDragging;

  const _DraggableEntityNode({
    required this.entity,
    required this.theme,
    required this.colorScheme,
    required this.onTap,
    required this.onDoubleTap,
    required this.onDelete,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.isDragging,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: MouseRegion(
        cursor: isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 200,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDragging ? colorScheme.primary : colorScheme.outline,
              width: isDragging ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: isDragging ? 0.3 : 0.1),
                blurRadius: isDragging ? 16 : 8,
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
                  color: colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(7),
                    topRight: Radius.circular(7),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.table_chart,
                      size: 16,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entity.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        size: 14,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      onPressed: () => _showContextMenu(context),
                      tooltip: 'Actions',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    ),
                  ],
                ),
              ),

              // Chinese name
              if (entity.chnname.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Text(
                    entity.chnname,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // Fields preview
              if (entity.fields.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: entity.fields.take(5).map((field) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            if (field.pk)
                              Icon(Icons.key, size: 12, color: colorScheme.primary)
                            else
                              const SizedBox(width: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                field.name,
                                style: theme.textTheme.labelSmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              field.type,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // More fields indicator
              if (entity.fields.length > 5)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
                  child: Text(
                    '+${entity.fields.length - 5} more',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

              // Footer with stats
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(7),
                    bottomRight: Radius.circular(7),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.list_alt, size: 12, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('${entity.fields.length}', style: theme.textTheme.labelSmall),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.sort, size: 12, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('${entity.indexes.length}', style: theme.textTheme.labelSmall),
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

  void _showContextMenu(BuildContext context) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final RenderBox button = context.findRenderObject()! as RenderBox;
    final Offset position = button.localToGlobal(Offset.zero, ancestor: overlay);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + button.size.height,
        position.dx + button.size.width,
        position.dy,
      ),
      items: [
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
            leading: Icon(Icons.delete, size: 18, color: Colors.red),
            title: Text('Delete', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    ).then((value) {
      if (value == 'edit' || value == 'fields') {
        onDoubleTap();
      } else if (value == 'delete') {
        onDelete();
      }
    });
  }
}

/// Grid painter for canvas background
class _GridPainter extends CustomPainter {
  final ColorScheme colorScheme;
  final Offset offset;
  final double scale;

  _GridPainter(this.colorScheme, {this.offset = Offset.zero, this.scale = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    final gridSize = 20.0 * scale;

    // Calculate starting positions based on offset
    final startX = (offset.dx % gridSize) - gridSize;
    final startY = (offset.dy % gridSize) - gridSize;

    // Draw vertical lines
    for (double x = startX; x < size.width + gridSize; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = startY; y < size.height + gridSize; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.offset != offset || oldDelegate.scale != scale;
  }
}
