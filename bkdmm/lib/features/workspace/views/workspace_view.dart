import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../../../shared/models/models.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/utils/responsive_utils.dart';
import '../../../utils/id_generator.dart';
import '../providers/tab_provider.dart';
import '../providers/layout_provider.dart';
import '../widgets/tab_bar.dart';
import '../widgets/icon_bar/icon_bar.dart';
import '../widgets/toolbar/top_menu_bar.dart';
import '../widgets/left_view/left_view_container.dart';
import '../widgets/bottom_view/bottom_view_container.dart';
import '../widgets/shortcuts/workspace_shortcuts.dart';
import '../widgets/property_section.dart';
import '../widgets/property_field.dart';
import '../widgets/stat_tile.dart';
import '../../modeling/entity_editor/views/entity_editor_view.dart';
import '../../modeling/er_diagram/er_diagram.dart';

/// Workspace view - Main project editing interface with tab management
///
/// New Layout (IDEA Style):
/// ┌─────────────────────────────────────────────────────┐
/// │ TopMenuBar (文件管理 | 视图管理 | 项目名 | 操作)    │
/// ├────┬────────────────────────────────────────────────┤
/// │Icon│ Tab Bar                                        │
/// │Bar ├────────────────────────────────────────────────┤
/// │    │                                                │
/// │左视│         Tab Content Area                       │
/// │图控│                                                │
/// │制  │                                                │
/// │────├────────────────────────────────────────────────┤
/// │底视│ BottomViewContainer (控制台/日志/输出)         │
/// │图控│                                                │
/// │制  │                                                │
/// ├────┴────────────────────────────────────────────────┤
/// │ StatusBar                                           │
/// └─────────────────────────────────────────────────────┘
///
/// IconBar is fixed and spans the full height, controlling both
/// left views (upper section) and bottom views (lower section).
class WorkspaceView extends ConsumerStatefulWidget {
  const WorkspaceView({super.key});

  @override
  ConsumerState<WorkspaceView> createState() => _WorkspaceViewState();
}

class _WorkspaceViewState extends ConsumerState<WorkspaceView> {
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
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
    final layoutState = ref.watch(layoutProvider);

    return WorkspaceShortcuts(
      child: Scaffold(
        backgroundColor: tdTheme.bgColorPage,
        body: Column(
          children: [
            // 顶部菜单栏
            const TopMenuBar(),

            // 主内容区域
            Expanded(
              child: Row(
                children: [
                  // 左侧图标栏 - 固定独占整个高度
                  const IconBar(),

                  // 内容区域（包含左侧视图、主内容、右侧面板、底部视图）
                  Expanded(
                    child: Column(
                      children: [
                        // 上部区域：左侧视图 + 主内容 + 右侧面板
                        Expanded(
                          child: Row(
                            children: [
                              // 左侧视图容器 (模块树/数据类型)
                              const LeftViewContainer(),

                              // 主内容区
                              Expanded(
                                child: Column(
                                  children: [
                                    // 标签栏
                                    WorkspaceTabBar(
                                      onNewTab: () => _showAddModuleDialog(),
                                      onSettingsTab: () =>
                                          ref.read(tabProvider.notifier).openSettings(),
                                    ),

                                    // 标签内容区
                                    Expanded (
                                      child: _buildTabContent(project, tdTheme),
                                    ),
                                  ],
                                ),
                              ),

                              // 右侧属性面板 (根据布局状态显示)
                              if (layoutState.rightViewVisible)
                                SizedBox(
                                  width: layoutState.rightViewWidth,
                                  child: _buildPropertiesPanel(project, tdTheme),
                                ),
                            ],
                          ),
                        ),

                        // 底部视图容器 (控制台/日志/输出)
                        const BottomViewContainer(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 状态栏
            _buildStatusBar(project, projectState, tdTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(Project project, TDThemeData tdTheme) {
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
        return _buildDatatypeView(tdTheme);
    }
  }

  Widget _buildEmptyTabContent(Project project, TDThemeData tdTheme) {
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
              '从左侧模块树选择项目',
              font: tdTheme.fontBodyLarge,
              textColor: tdTheme.textColorSecondary,
            ),
            const SizedBox(height: 8),
            TDText(
              '双击模块或表打开编辑器',
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
    Entity? entity;
    String? moduleId;
    for (final module in project.modules) {
      if (module.id == tab.moduleId) {
        moduleId = module.id;
        final found = module.entities.where((e) => e.id == tab.entityId);
        if (found.isNotEmpty) {
          entity = found.first;
        }
        break;
      }
    }

    if (entity == null || moduleId == null) {
      return _buildNotFoundContent('实体', tab.title, tdTheme);
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
    final modules = project.modules.where((m) => m.id == tab.moduleId);
    if (modules.isEmpty) {
      return _buildNotFoundContent('模块', tab.title, tdTheme);
    }
    final module = modules.first;

    return Container(
      color: tdTheme.bgColorContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 模块标题栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tdTheme.bgColorSecondaryContainer,
              border: Border(
                bottom: BorderSide(color: tdTheme.componentStrokeColor),
              ),
            ),
            child: Row(
              children: [
                Icon(TDIcons.view_module, color: tdTheme.brandNormalColor),
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
                  '${module.entities.length} 个表',
                  font: tdTheme.fontBodySmall,
                  textColor: tdTheme.textColorSecondary,
                ),
              ],
            ),
          ),

          // ER 图
          Expanded(
            child: _buildERDiagram(module, tdTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildERDiagram(Module module, TDThemeData tdTheme) {
    if (module.entities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(TDIcons.view_module,
                size: 64, color: tdTheme.textColorPlaceholder),
            const SizedBox(height: 16),
            TDText(
              '此模块没有表',
              font: tdTheme.fontTitleMedium,
              textColor: tdTheme.textColorSecondary,
            ),
            const SizedBox(height: 8),
            TDButton(
              text: '添加表',
              icon: TDIcons.add,
              theme: TDButtonTheme.primary,
              type: TDButtonType.fill,
              onTap: () => _showAddEntityDialog(module),
            ),
          ],
        ),
      );
    }

    return ERDiagramView(
      moduleId: module.id,
      onEntityEdit: (entity) => _showEntityEditorDialog(module, entity),
      onEntityPreview: (entity) => _showEntityPreviewDialog(module, entity),
      onContextMenu: (position, entity) =>
          _showDiagramContextMenu(position, entity, module),
    );
  }

  void _showEntityPreviewDialog(Module module, Entity entity) {
    // 预览模式下双击显示只读弹窗
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entity.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('中文名称: ${entity.chnname}'),
              const SizedBox(height: 8),
              Text('字段列表:'),
              ...entity.fields.map((f) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text('• ${f.name}: ${f.type}${f.pk ? ' (主键)' : ''}'),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showDiagramContextMenu(
      Offset position, Entity? entity, Module module) {
    // TODO: 实现右键菜单
  }

  void _showEntityEditorDialog(Module module, Entity entity) {
    // TODO: 实现实体编辑对话框
  }

  Widget _buildRelationView(
    WorkspaceTab tab,
    Project project,
    TDThemeData tdTheme,
  ) {
    final modules = project.modules.where((m) => m.id == tab.moduleId);
    if (modules.isEmpty) {
      return _buildNotFoundContent('模块', tab.title, tdTheme);
    }

    return Container(
      color: tdTheme.bgColorContainer,
      child: Center(
        child: TDText(
          '关系视图开发中',
          textColor: tdTheme.textColorSecondary,
        ),
      ),
    );
  }

  Widget _buildSettingsView(TDThemeData tdTheme) {
    return Container(
      color: tdTheme.bgColorContainer,
      child: Center(
        child: TDText(
          '设置页面开发中',
          textColor: tdTheme.textColorSecondary,
        ),
      ),
    );
  }

  Widget _buildDatatypeView(TDThemeData tdTheme) {
    return Container(
      color: tdTheme.bgColorContainer,
      child: Center(
        child: TDText(
          '数据类型管理',
          textColor: tdTheme.textColorSecondary,
        ),
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
          Icon(TDIcons.info_circle, size: 64, color: tdTheme.errorNormalColor),
          const SizedBox(height: 16),
          TDText('$type 未找到', font: tdTheme.fontTitleMedium),
          const SizedBox(height: 8),
          TDText(name,
              font: tdTheme.fontBodyMedium,
              textColor: tdTheme.textColorSecondary),
        ],
      ),
    );
  }

  Widget _buildPropertiesPanel(Project project, TDThemeData tdTheme) {
    final tabState = ref.watch(tabProvider);
    final activeTab = tabState.activeTab;

    return Container(
      decoration: BoxDecoration(
        color: tdTheme.bgColorContainer,
        border: Border(
          left: BorderSide(color: tdTheme.componentStrokeColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: tdTheme.componentStrokeColor),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TDText(
                  '属性',
                  font: tdTheme.fontTitleSmall,
                  fontWeight: FontWeight.w600,
                ),
                TDButton(
                  icon: TDIcons.close,
                  size: TDButtonSize.small,
                  type: TDButtonType.text,
                  theme: TDButtonTheme.defaultTheme,
                  onTap: () =>
                      ref.read(layoutProvider.notifier).hideRightView(),
                ),
              ],
            ),
          ),

          // 属性内容
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
    Entity? entity;
    for (final module in project.modules) {
      if (module.id == tab.moduleId) {
        final found = module.entities.where((e) => e.id == tab.entityId);
        if (found.isNotEmpty) {
          entity = found.first;
        }
        break;
      }
    }

    if (entity == null) {
      return _buildProjectProperties(project, tdTheme);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PropertySection(title: '实体信息'),
        PropertyField(label: '标题', value: entity.title),
        PropertyField(label: '中文名', value: entity.chnname),
        PropertyField(label: '备注', value: entity.remark ?? '无'),
        const SizedBox(height: 16),
        PropertySection(title: '统计'),
        StatTile(
            icon: TDIcons.view_list, label: '字段', value: '${entity.fields.length}'),
        StatTile(
            icon: TDIcons.key, label: '主键', value: '${entity.primaryKeys.length}'),
        StatTile(
            icon: TDIcons.chart, label: '索引', value: '${entity.indexes.length}'),
      ],
    );
  }

  Widget _buildModuleProperties(
    WorkspaceTab tab,
    Project project,
    TDThemeData tdTheme,
  ) {
    final modules = project.modules.where((m) => m.id == tab.moduleId);
    if (modules.isEmpty) {
      return _buildProjectProperties(project, tdTheme);
    }
    final module = modules.first;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PropertySection(title: '模块信息'),
        PropertyField(label: '名称', value: module.name),
        PropertyField(label: '中文名', value: module.chnname),
        const SizedBox(height: 16),
        PropertySection(title: '统计'),
        StatTile(
            icon: TDIcons.table, label: '表', value: '${module.entities.length}'),
      ],
    );
  }

  Widget _buildProjectProperties(Project project, TDThemeData tdTheme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PropertySection(title: '项目信息'),
        PropertyField(label: '名称', value: project.name),
        PropertyField(label: '描述', value: project.description ?? '无'),
        PropertyField(label: '版本', value: project.version),
        const SizedBox(height: 16),
        PropertySection(title: '统计'),
        StatTile(
          icon: TDIcons.view_module,
          label: '模块',
          value: '${project.modules.length}',
        ),
        StatTile(
          icon: TDIcons.table,
          label: '表',
          value:
              '${project.modules.fold<int>(0, (sum, m) => sum + m.entities.length)}',
        ),
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
          top: BorderSide(color: tdTheme.componentStrokeColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 项目信息
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(TDIcons.folder, size: 14, color: tdTheme.textColorSecondary),
                const SizedBox(width: 4),
                TDText(
                  project.name,
                  font: tdTheme.fontBodyExtraSmall,
                  textColor: tdTheme.textColorSecondary,
                ),
              ],
            ),
          ),

          // 分隔符
          Container(width: 1, height: 14, color: tdTheme.componentStrokeColor),

          // Tab 数量
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(TDIcons.view_module,
                    size: 14, color: tdTheme.textColorSecondary),
                const SizedBox(width: 4),
                TDText(
                  '${tabState.tabs.length} 个标签',
                  font: tdTheme.fontBodyExtraSmall,
                  textColor: tdTheme.textColorSecondary,
                ),
              ],
            ),
          ),

          const Spacer(),

          // 保存状态
          if (projectState.isDirty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(TDIcons.circle, size: 8, color: tdTheme.brandNormalColor),
                  const SizedBox(width: 4),
                  TDText(
                    '未保存',
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
                  Icon(TDIcons.check,
                      size: 14, color: tdTheme.textColorSecondary),
                  const SizedBox(width: 4),
                  TDText(
                    '已保存',
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

  Future<void> _showAddModuleDialog() async {
    final nameController = TextEditingController();
    final chnnameController = TextEditingController();
    final descController = TextEditingController();

    final dialogWidth = ResponsiveUtils.getDialogWidth(context, DialogSizePreset.form);
    final formSpacing = ResponsiveUtils.getFormFieldSpacing(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TDAlertDialog(
        title: '创建模块',
        contentWidget: SizedBox(
          width: dialogWidth,
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
              SizedBox(height: formSpacing),
              TDInput(
                controller: chnnameController,
                leftLabel: '中文名称',
                hintText: '例如: 用户模块',
                leftIcon: const Icon(TDIcons.translate),
                backgroundColor: Colors.transparent,
              ),
              SizedBox(height: formSpacing),
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
          action: () => Navigator.pop(context, false),
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
            Navigator.pop(context, true);
          },
        ),
      ),
    );

    if (result == true && mounted) {
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
      TDToast.showText('模块已创建', context: context);
    }
  }

  Future<void> _showAddEntityDialog(Module module) async {
    final titleController = TextEditingController();
    final chnnameController = TextEditingController();
    final remarkController = TextEditingController();

    final dialogWidth = ResponsiveUtils.getDialogWidth(context, DialogSizePreset.form);
    final formSpacing = ResponsiveUtils.getFormFieldSpacing(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TDAlertDialog(
        title: '在 "${module.chnname}" 中创建表',
        contentWidget: SizedBox(
          width: dialogWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TDInput(
                controller: titleController,
                leftLabel: '表名称 (英文)',
                hintText: '例如: user_info',
                leftIcon: const Icon(TDIcons.code),
                backgroundColor: Colors.transparent,
              ),
              SizedBox(height: formSpacing),
              TDInput(
                controller: chnnameController,
                leftLabel: '中文名称',
                hintText: '例如: 用户信息表',
                leftIcon: const Icon(TDIcons.translate),
                backgroundColor: Colors.transparent,
              ),
              SizedBox(height: formSpacing),
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
          action: () => Navigator.pop(context, false),
        ),
        rightBtn: TDDialogButtonOptions(
          title: '创建',
          theme: TDButtonTheme.primary,
          type: TDButtonType.fill,
          action: () {
            if (titleController.text.trim().isEmpty) {
              TDToast.showText('请输入表名称', context: context);
              return;
            }
            Navigator.pop(context, true);
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
      ref.read(projectNotifierProvider.notifier).updateModule(
        module.id,
        updatedModule,
      );
      TDToast.showText('表已创建', context: context);

      // 打开新创建的表编辑器
      ref.read(tabProvider.notifier).openEntity(entity, module.id);
    }
  }
}