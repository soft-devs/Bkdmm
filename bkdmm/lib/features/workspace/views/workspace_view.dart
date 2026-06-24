import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../../../shared/models/models.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/td_popup_menu.dart';
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

    final tdTheme = TDTheme.of(context);

    return TabShortcuts(
      child: Scaffold(
        backgroundColor: tdTheme.bgColorPage,
        body: Column(
          children: [
            // Menu bar
            _buildMenuBar(project, projectState, tdTheme),

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
                          child: _buildTabContent(project, tdTheme),
                        ),
                      ],
                    ),
                  ),

                  // Properties panel (toggleable)
                  if (_showPropertiesPanel)
                    SizedBox(
                      width: _propertiesPanelWidth,
                      child: _buildPropertiesPanel(project, tdTheme),
                    ),
                ],
              ),
            ),

            // Status bar
            _buildStatusBar(project, projectState, tdTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuBar(
    Project project,
    ProjectState projectState,
    TDThemeData tdTheme,
  ) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: tdTheme.bgColorContainer,
        border: Border(
          bottom: BorderSide(
            color: tdTheme.componentStrokeColor,
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
                  color: tdTheme.brandNormalColor,
                ),
                const SizedBox(width: 8),
                TDText(
                  project.name,
                  font: tdTheme.fontTitleMedium,
                  fontWeight: FontWeight.w600,
                ),
                if (projectState.isDirty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: TDText(
                      '*',
                      font: tdTheme.fontTitleMedium,
                      fontWeight: FontWeight.w600,
                      textColor: tdTheme.brandNormalColor,
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
          TDPopupMenuButton(
            icon: TDIcons.more,
            iconColor: tdTheme.textColorPrimary,
            items: [
              TDPopupMenuItem(
                value: 'save',
                icon: TDIcons.save,
                label: 'Save',
              ),
              TDPopupMenuItem(
                value: 'save_as',
                icon: TDIcons.folder,
                label: 'Save As...',
              ),
              const TDPopupMenuItem.divider(),
              TDPopupMenuItem(
                value: 'close',
                icon: TDIcons.close,
                label: 'Close Project',
              ),
              const TDPopupMenuItem.divider(),
              TDPopupMenuItem(
                value: 'settings',
                icon: TDIcons.setting,
                label: 'Project Settings',
              ),
              TDPopupMenuItem(
                value: 'datatype',
                icon: TDIcons.code,
                label: 'Data Types',
              ),
            ],
            onSelected: (action) => _handleMenuAction(action),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(
    Project project,
    TDThemeData tdTheme,
  ) {
    final tabState = ref.watch(tabProvider);
    final activeTab = tabState.activeTab;

    if (activeTab == null) {
      return _buildEmptyTabContent(project, tdTheme);
    }

    switch (activeTab.type) {
      case TabType.entity:
        return _buildEntityEditor(activeTab, project, tdTheme);
      case TabType.module:
        return _buildModuleView(activeTab, project, tdTheme);
      case TabType.relation:
        return _buildRelationView(activeTab, project, tdTheme);
      case TabType.settings:
        return _buildSettingsView(tdTheme);
      case TabType.datatype:
        return const DataTypeView();
    }
  }

  Widget _buildEmptyTabContent(
    Project project,
    TDThemeData tdTheme,
  ) {
    return Container(
      color: tdTheme.bgColorContainer,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              TDIcons.view_module,
              size: 64,
              color: tdTheme.textColorPlaceholder,
            ),
            const SizedBox(height: 16),
            TDText(
              'Select an item from the tree',
              font: tdTheme.fontBodyLarge,
              textColor: tdTheme.textColorSecondary,
            ),
            const SizedBox(height: 8),
            TDText(
              'Double-click a module or entity to open it in a tab',
              font: tdTheme.fontBodyMedium,
              textColor: tdTheme.textColorSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntityEditor(
    WorkspaceTab tab,
    Project project,
    TDThemeData tdTheme,
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
      return _buildNotFoundContent('Entity', tab.title, tdTheme);
    }

    return EntityEditorView(
      entity: entity,
      moduleId: moduleId,
    );
  }

  Widget _buildModuleView(
    WorkspaceTab tab,
    Project project,
    TDThemeData tdTheme,
  ) {
    // Find the module
    final module = project.modules.firstWhere(
      (m) => m.id == tab.moduleId,
      orElse: () => throw StateError('Module not found'),
    );

    return Container(
      color: tdTheme.bgColorContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Module header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tdTheme.bgColorSecondaryContainer,
              border: Border(
                bottom: BorderSide(
                  color: tdTheme.componentStrokeColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  TDIcons.view_module,
                  color: tdTheme.brandNormalColor,
                ),
                const SizedBox(width: 8),
                TDText(
                  module.name,
                  font: tdTheme.fontTitleMedium,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(width: 8),
                TDText(
                  module.chnname,
                  font: tdTheme.fontBodyMedium,
                  textColor: tdTheme.textColorSecondary,
                ),
                const Spacer(),
                TDText(
                  '${module.entities.length} entities',
                  font: tdTheme.fontBodySmall,
                  textColor: tdTheme.textColorSecondary,
                ),
              ],
            ),
          ),

          // Module content (ER diagram placeholder)
          Expanded(
            child: _buildERDiagram(module, tdTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildERDiagram(
    Module module,
    TDThemeData tdTheme,
  ) {
    if (module.entities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              TDIcons.view_module,
              size: 64,
              color: tdTheme.textColorPlaceholder,
            ),
            const SizedBox(height: 16),
            TDText(
              'No entities in this module',
              font: tdTheme.fontTitleMedium,
              textColor: tdTheme.textColorSecondary,
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

    // Use ERDiagramCanvas for v1 ER diagram rendering
    return ERDiagramCanvas(
      moduleId: module.id,
      onEntityEdit: (entity) => _showEntityEditorDialog(module, entity),
      onContextMenu: (position, entity) =>
          _showDiagramContextMenu(position, entity, module),
    );
  }

  void _showDiagramContextMenu(
      Offset position, Entity? entity, Module module) {
    final tdTheme = TDTheme.of(context);

    // Build menu items based on context
    final items = <TDPopupMenuItem>[];
    if (entity != null) {
      items.addAll([
        TDPopupMenuItem(
          value: 'edit',
          icon: TDIcons.edit,
          label: 'Edit Entity',
        ),
        TDPopupMenuItem(
          value: 'delete',
          icon: TDIcons.delete,
          label: 'Delete Entity',
          iconColor: tdTheme.errorNormalColor,
          textColor: tdTheme.errorNormalColor,
        ),
      ]);
    } else {
      items.add(TDPopupMenuItem(
        value: 'add_entity',
        icon: TDIcons.add,
        label: 'Add Entity',
      ));
    }

    showTDPopupMenu(
      context: context,
      position: position,
      items: items,
      onSelected: (value) {
        if (value == 'edit' && entity != null) {
          _showEntityEditorDialog(module, entity);
        } else if (value == 'delete' && entity != null) {
          _confirmDeleteEntity(module, entity);
        } else if (value == 'add_entity') {
          _showAddEntityDialog(module);
        }
      },
    );
  }

  void _showEntityEditorDialog(Module module, Entity entity) {
    final tdTheme = TDTheme.of(context);
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
                  color: tdTheme.bgColorSecondaryContainer,
                  border: Border(
                    bottom: BorderSide(
                      color: tdTheme.componentStrokeColor,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      TDIcons.table,
                      color: tdTheme.brandNormalColor,
                    ),
                    const SizedBox(width: 8),
                    TDText(
                      '${entity.title} - ${entity.chnname}',
                      font: tdTheme.fontTitleMedium,
                      fontWeight: FontWeight.w600,
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
        leftBtn: TDDialogButtonOptions(
          title: 'Cancel',
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          action: () => Navigator.pop(context),
        ),
        rightBtn: TDDialogButtonOptions(
          title: 'Delete',
          theme: TDButtonTheme.danger,
          type: TDButtonType.fill,
          action: () {
            final updatedEntities =
                module.entities.where((e) => e.id != entity.id).toList();
            final updatedModule = module.copyWith(
              entities: updatedEntities,
              updatedAt: DateTime.now(),
            );
            ref
                .read(projectProvider.notifier)
                .updateModule(module.id, updatedModule);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _buildRelationView(
    WorkspaceTab tab,
    Project project,
    TDThemeData tdTheme,
  ) {
    // Find the module
    final module = project.modules.firstWhere(
      (m) => m.id == tab.moduleId,
      orElse: () => throw StateError('Module not found'),
    );

    return Container(
      color: tdTheme.bgColorContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tdTheme.bgColorSecondaryContainer,
              border: Border(
                bottom: BorderSide(
                  color: tdTheme.componentStrokeColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  TDIcons.relation,
                  color: tdTheme.brandNormalColor,
                ),
                const SizedBox(width: 8),
                TDText(
                  'Relations - ${module.name}',
                  font: tdTheme.fontTitleMedium,
                  fontWeight: FontWeight.w600,
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
                          color: tdTheme.textColorPlaceholder,
                        ),
                        const SizedBox(height: 16),
                        TDText(
                          'No relations defined',
                          font: tdTheme.fontTitleMedium,
                          textColor: tdTheme.textColorSecondary,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: module.graphCanvas.edges.length,
                    itemBuilder: (context, index) {
                      final edge = module.graphCanvas.edges[index];
                      final listTheme = TDTheme.of(context);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              TDIcons.arrow_right,
                              size: 20,
                              color: listTheme.textColorSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TDText(
                                    '${edge.source} -> ${edge.target}',
                                    font: listTheme.fontBodyMedium,
                                  ),
                                  TDText(
                                    edge.label ?? 'No label',
                                    font: listTheme.fontBodySmall,
                                    textColor: listTheme.textColorSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsView(TDThemeData tdTheme) {
    return Container(
      color: tdTheme.bgColorContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tdTheme.bgColorSecondaryContainer,
              border: Border(
                bottom: BorderSide(
                  color: tdTheme.componentStrokeColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  TDIcons.setting,
                  color: tdTheme.brandNormalColor,
                ),
                const SizedBox(width: 8),
                TDText(
                  'Project Settings',
                  font: tdTheme.fontTitleMedium,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),

          // Settings content
          Expanded(
            child: Center(
              child: TDText(
                'Settings editor coming soon',
                font: tdTheme.fontBodyMedium,
                textColor: tdTheme.textColorSecondary,
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
    TDThemeData tdTheme,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            TDIcons.info_circle,
            size: 64,
            color: tdTheme.errorNormalColor,
          ),
          const SizedBox(height: 16),
          TDText(
            '$type not found',
            font: tdTheme.fontTitleMedium,
          ),
          const SizedBox(height: 8),
          TDText(
            name,
            font: tdTheme.fontBodyMedium,
            textColor: tdTheme.textColorSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesPanel(
    Project project,
    TDThemeData tdTheme,
  ) {
    final tabState = ref.watch(tabProvider);
    final activeTab = tabState.activeTab;

    return Container(
      decoration: BoxDecoration(
        color: tdTheme.bgColorContainer,
        border: Border(
          left: BorderSide(
            color: tdTheme.componentStrokeColor,
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
                  color: tdTheme.componentStrokeColor,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TDText(
                  'Properties',
                  font: tdTheme.fontTitleSmall,
                  fontWeight: FontWeight.w600,
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
                ? _buildTabProperties(activeTab, project, tdTheme)
                : _buildProjectProperties(project, tdTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildTabProperties(
    WorkspaceTab tab,
    Project project,
    TDThemeData tdTheme,
  ) {
    switch (tab.type) {
      case TabType.entity:
        return _buildEntityProperties(tab, project, tdTheme);
      case TabType.module:
        return _buildModuleProperties(tab, project, tdTheme);
      case TabType.relation:
      case TabType.settings:
      case TabType.datatype:
        return _buildProjectProperties(project, tdTheme);
    }
  }

  Widget _buildEntityProperties(
    WorkspaceTab tab,
    Project project,
    TDThemeData tdTheme,
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
      return _buildProjectProperties(project, tdTheme);
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
        _StatTile(
            icon: TDIcons.view_list,
            label: 'Fields',
            value: '${entity.fields.length}'),
        _StatTile(
            icon: TDIcons.key,
            label: 'Primary Keys',
            value: '${entity.primaryKeys.length}'),
        _StatTile(
            icon: TDIcons.chart,
            label: 'Indexes',
            value: '${entity.indexes.length}'),
        const SizedBox(height: 16),
        _PropertySection(title: 'Timestamps'),
        _PropertyField(
            label: 'Created', value: _formatDateTime(entity.createdAt)),
        _PropertyField(
            label: 'Updated', value: _formatDateTime(entity.updatedAt)),
      ],
    );
  }

  Widget _buildModuleProperties(
    WorkspaceTab tab,
    Project project,
    TDThemeData tdTheme,
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
        _PropertyField(
            label: 'Description', value: module.description ?? 'None'),
        _PropertyField(label: 'ID', value: module.id),
        const SizedBox(height: 16),
        _PropertySection(title: 'Statistics'),
        _StatTile(
            icon: TDIcons.table,
            label: 'Entities',
            value: '${module.entities.length}'),
        _StatTile(
            icon: TDIcons.relation,
            label: 'Relations',
            value: '${module.graphCanvas.edges.length}'),
        const SizedBox(height: 16),
        _PropertySection(title: 'Timestamps'),
        _PropertyField(
            label: 'Created', value: _formatDateTime(module.createdAt)),
        _PropertyField(
            label: 'Updated', value: _formatDateTime(module.updatedAt)),
      ],
    );
  }

  Widget _buildProjectProperties(
    Project project,
    TDThemeData tdTheme,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PropertySection(title: 'Project Info'),
        _PropertyField(label: 'Name', value: project.name),
        _PropertyField(
            label: 'Description', value: project.description ?? 'None'),
        _PropertyField(label: 'Version', value: project.version),
        _PropertyField(label: 'ID', value: project.id),
        const SizedBox(height: 16),
        _PropertySection(title: 'Statistics'),
        _StatTile(
            icon: TDIcons.view_module,
            label: 'Modules',
            value: '${project.modules.length}'),
        _StatTile(
          icon: TDIcons.table,
          label: 'Entities',
          value:
              '${project.modules.fold<int>(0, (sum, m) => sum + m.entities.length)}',
        ),
        _StatTile(
          icon: TDIcons.view_list,
          label: 'Fields',
          value:
              '${project.modules.fold<int>(0, (sum, m) => sum + m.entities.fold<int>(0, (s, e) => s + e.fields.length))}',
        ),
        const SizedBox(height: 16),
        _PropertySection(title: 'Timestamps'),
        _PropertyField(
            label: 'Created', value: _formatDateTime(project.createdAt)),
        _PropertyField(
            label: 'Updated', value: _formatDateTime(project.updatedAt)),
      ],
    );
  }

  Widget _buildStatusBar(
    Project project,
    ProjectState projectState,
    TDThemeData tdTheme,
  ) {
    final tabState = ref.watch(tabProvider);

    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: tdTheme.grayColor1,
        border: Border(
          top: BorderSide(
            color: tdTheme.componentStrokeColor,
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
                  color: tdTheme.textColorSecondary,
                ),
                const SizedBox(width: 4),
                TDText(
                  project.name,
                  font: tdTheme.fontBodyExtraSmall,
                  textColor: tdTheme.textColorSecondary,
                ),
              ],
            ),
          ),

          // Separator
          Container(
            width: 1,
            height: 14,
            color: tdTheme.componentStrokeColor,
          ),

          // Tab count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  TDIcons.view_module,
                  size: 14,
                  color: tdTheme.textColorSecondary,
                ),
                const SizedBox(width: 4),
                TDText(
                  '${tabState.tabs.length} tabs',
                  font: tdTheme.fontBodyExtraSmall,
                  textColor: tdTheme.textColorSecondary,
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
                    color: tdTheme.brandNormalColor,
                  ),
                  const SizedBox(width: 4),
                  TDText(
                    'Unsaved',
                    font: tdTheme.fontBodyExtraSmall,
                    textColor: tdTheme.brandNormalColor,
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
                    color: tdTheme.textColorSecondary,
                  ),
                  const SizedBox(width: 4),
                  TDText(
                    'Saved',
                    font: tdTheme.fontBodyExtraSmall,
                    textColor: tdTheme.textColorSecondary,
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
          content:
              'The project has unsaved changes. Do you want to save before closing?',
          leftBtn: TDDialogButtonOptions(
            title: 'Discard',
            theme: TDButtonTheme.defaultTheme,
            type: TDButtonType.text,
            action: () => Navigator.pop(context, false),
          ),
          rightBtn: TDDialogButtonOptions(
            title: 'Save',
            theme: TDButtonTheme.primary,
            type: TDButtonType.fill,
            action: () => Navigator.pop(context, true),
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
        content:
            'A module is a container for related database tables/entities.',
        leftBtn: TDDialogButtonOptions(
          title: 'Cancel',
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          action: () => Navigator.pop(context, false),
        ),
        rightBtn: TDDialogButtonOptions(
          title: 'Create Module',
          theme: TDButtonTheme.primary,
          type: TDButtonType.fill,
          action: () {
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
        content:
            'Create a new database table/entity in module "${module.chnname}".',
        leftBtn: TDDialogButtonOptions(
          title: 'Cancel',
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          action: () => Navigator.pop(context, false),
        ),
        rightBtn: TDDialogButtonOptions(
          title: 'Create Table',
          theme: TDButtonTheme.primary,
          type: TDButtonType.fill,
          action: () {
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

/// Property section widget - uses TDTheme colors.
class _PropertySection extends StatelessWidget {
  final String title;

  const _PropertySection({required this.title});

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TDText(
        title,
        font: tdTheme.fontTitleSmall,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Property field widget - uses TDTheme colors and TDText.
class _PropertyField extends StatelessWidget {
  final String label;
  final String value;

  const _PropertyField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TDText(
            label,
            font: tdTheme.fontBodySmall,
            textColor: tdTheme.textColorSecondary,
          ),
          const SizedBox(height: 2),
          TDText(
            value,
            font: tdTheme.fontBodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Stat tile widget - uses TDTheme colors and TDText.
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
    final tdTheme = TDTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: tdTheme.textColorSecondary,
          ),
          const SizedBox(width: 8),
          TDText(
            label,
            font: tdTheme.fontBodySmall,
            textColor: tdTheme.textColorSecondary,
          ),
          const Spacer(),
          TDText(
            value,
            font: tdTheme.fontBodySmall,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}
