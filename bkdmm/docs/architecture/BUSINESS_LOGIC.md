# Bkdmm 业务逻辑文档

## 1. 项目概述

BK Datasource Model Manager 是一个数据库模型建模工具，用于设计数据库表结构、管理数据模型、生成 DDL 语句。

### 核心功能
- 项目管理（创建、打开、保存）
- 模块管理（创建、编辑、删除）
- 实体/表管理（字段、索引设计）
- ER 图可视化（表关系图）
- DDL 代码生成

---

## 2. 数据模型层次结构

```
Project (项目)
    │
    ├── DataTypeDomains (数据类型域配置)
    │
    ├── Profile (项目配置)
    │   ├── defaultFields (默认字段列表)
    │   ├── defaultFieldsType (默认字段类型)
    │   └── defaultDatabase (默认数据库)
    │
    └── Module[] (模块列表)
            │
            ├── Entity[] (实体/表列表)
            │       │
            │       ├── Field[] (字段列表)
            │       │       ├── id (唯一标识)
            │       │       ├── name (字段名)
            │       │       ├── type (数据类型)
            │       │       ├── chnname (中文名)
            │       │       ├── pk (是否主键)
            │       │       ├── notNull (是否非空)
            │       │       └── ...
            │       │
            │       └── Index[] (索引列表)
            │
            └── GraphCanvas (ER图画布)
                    │
                    ├── GraphNode[] (图节点)
                    │       ├── title (表名:序号)
                    │       ├── x, y (坐标)
                    │       └── moduleName (实体ID)
                    │
                    └── GraphEdge[] (连线)
                            ├── source, target (节点引用)
                            ├── sourceField, targetField (字段级连线)
                            └── relationType (1:1, 1:N, N:M)
```

### 关键模型定义

| 模型 | 文件 | 说明 |
|------|------|------|
| Project | `shared/models/project.dart` | 项目根模型 |
| Module | `shared/models/module.dart` | 模块，包含多个实体和ER图 |
| Entity | `shared/models/entity.dart` | 数据表定义 |
| Field | `shared/models/entity.dart` | 字段定义 |
| Index | `shared/models/entity.dart` | 索引定义 |
| GraphNode | `shared/models/module.dart` | ER图节点（位置信息） |
| GraphEdge | `shared/models/module.dart` | ER图连线（关系信息） |

---

## 3. 状态管理架构

### Provider 层次

```
projectNotifierProvider (StateNotifier)
        │
        ├── project (Project?)
        ├── projectPath (String?)
        ├── isDirty (bool)
        ├── isLoading (bool)
        └── statistics (ProjectStatistics)
        │
        └─► 监听者: erDiagramProvider, tabProvider, layoutProvider

erDiagramProvider(moduleId) (Family StateNotifier)
        │
        ├── moduleId (String)
        ├── nodes (Map<String, DiagramNode>)
        ├── edges (Map<String, DiagramEdge>)
        └── 监听 projectNotifierProvider 变化自动刷新

tabProvider (StateNotifier)
        │
        ├── tabs (List<WorkspaceTab>)
        └── activeTabId (String?)
```

### Provider 文件索引

| Provider | 文件 | 状态类型 | 说明 |
|----------|------|----------|------|
| `projectNotifierProvider` | `features/project/providers/project_notifier.dart` | `ProjectState` | 项目全局状态 |
| `erDiagramProvider` | `features/modeling/er_diagram/providers/er_diagram_provider.dart` | `ERDiagramState` | ER图状态（按moduleId） |
| `tabProvider` | `features/workspace/providers/tab_provider.dart` | `TabState` | 工作区标签页 |
| `layoutProvider` | `features/workspace/providers/layout_provider.dart` | `LayoutState` | 工作区布局 |
| `codegenProvider` | `features/codegen/providers/codegen_provider.dart` | `CodegenState` | DDL生成状态 |
| `datatypeProvider` | `features/datatype/providers/datatype_provider.dart` | `DatatypeState` | 数据类型管理 |

---

## 4. ER 图渲染流程

### 4.1 数据流

```
Project.modules[].entities
        │
        │  ERDiagramState.fromModule(module)
        ▼
ERDiagramState
    ├── nodes: Map<entity.id, ERNode>
    │       └── ERNode { entity, graphNode, position, size }
    │
    └── edges: Map<source:target, ERRelationEdge>
        │
        │  syncFromState(state)
        ▼
Graph (graphview)
    ├── Node.Id(entity.id)
    │       ├── position (x, y)
    │       └── size (width, height)
    │
    └── Edge(source, destination)
        │
        │  GraphView.builder
        ▼
Widget (ERTableNodeWidget)
```

### 4.2 ER 图组件结构

```
ERDiagramCanvas (ConsumerStatefulWidget)
        │
        ├── _graphSync (ERDiagramGraphSync)
        │       ├── graph (Graph) - graphview 图对象
        │       ├── anchorRegistry (FieldAnchorRegistry) - 字段锚点
        │       └── syncFromState() - 状态同步方法
        │
        ├── _layoutAdapter (GraphViewLayoutAdapter)
        │       ├── algorithm (Algorithm) - 布局算法
        │       └── useFixedPositionLayout() - 固定位置模式
        │
        └── build()
                │
                ├── _syncFromState() - 同步节点数据
                │
                └── _buildGraphView()
                        │
                        ├── entityMap 创建 (entity.id -> Entity)
                        │
                        ├── ERNodeWidgetBuilderState.createBuilder()
                        │       ├── showAnchors (是否显示字段锚点)
                        │       ├── isDraggable (是否可拖拽)
                        │       └── onNodeTap, onAnchorTap 等回调
                        │
                        └── GraphView.builder()
                                ├── graph: _graphSync.graph
                                ├── algorithm: NoOpLayoutAlgorithm (固定位置)
                                └── builder: ERNodeWidgetBuilder.build()
                                        │
                                        ▼
                                ERTableNodeWidget (每个节点)
```

### 4.3 关键类说明

| 类 | 文件 | 作用 |
|-----|------|------|
| `ERDiagramCanvas` | `widgets/er_diagram_canvas.dart` | ER图画布主组件 |
| `ERDiagramGraphSync` | `core/graph_sync.dart` | 状态与graphview同步 |
| `ERNodeWidgetBuilder` | `widgets/er_node_builder.dart` | 节点Widget构建器 |
| `ERTableNodeWidget` | `widgets/er_table_node_widget.dart` | 表格节点Widget |
| `NoOpLayoutAlgorithm` | `layout/layout_adapter.dart` | 无操作布局（保持位置） |
| `FieldAnchorRegistry` | `core/field_anchor_registry.dart` | 字段级锚点管理 |
| `ERRelationEdgeRenderer` | `renderers/er_edge_renderer.dart` | 关系连线渲染器 |

### 4.4 ER 图渲染时序

```
1. Widget 初始化
   └── initState()
       └── _graphSync = ERDiagramGraphSync()
       └── _layoutAdapter = GraphViewLayoutAdapter()
       └── WidgetsBinding.instance.addPostFrameCallback(_syncFromState)

2. 首次同步
   └── _syncFromState()
       └── ref.read(erDiagramProvider(moduleId))
       └── _graphSync.syncFromState(state)
           └── 清空 graph.nodes
           └── 遍历 state.nodes，创建 Node.Id(entity.id)
           └── 设置 node.position, node.size
           └── 注册字段锚点
       └── setState()

3. 每次构建
   └── build()
       └── ref.watch(erDiagramProvider(moduleId))
       └── _graphSync.syncFromState(state) (重新同步)
       └── _buildGraphView()
           └── 创建 entityMap (entity.id -> Entity)
           └── 创建 ERNodeWidgetBuilder
           └── GraphView.builder(graph, algorithm, builder)

4. graphview 渲染
   └── GraphView.builder 遍历 graph.nodes
       └── 对每个 Node，调用 builder(node)
           └── 从 node.key.value 获取 nodeId
           └── 从 entityMap[nodeId] 获取 Entity
           └── 返回 ERTableNodeWidget(node, entity)
```

### 4.5 节点位置来源

节点位置有两个来源：

1. **已保存的位置**：`module.graphCanvas.nodes` 中的 `GraphNode.x, y`
2. **自动计算的位置**：新实体没有 GraphNode 时，按网格布局计算：
   ```dart
   startX = 100, startY = 100
   offsetX = 250, offsetY = 300
   maxCols = 4
   ```

---

## 5. ER Diagram Provider 刷新机制

### 5.1 初始化流程

```dart
ERDiagramNotifier(this.ref, this.moduleId)
    : super(ERDiagramState.empty) {
    _init();
}

void _init() {
    // 1. 首次加载
    _loadFromModule();
    
    // 2. 监听项目变化
    ref.listen<ProjectState>(
        projectNotifierProvider,
        (previous, next) {
            if (_shouldReload(previous, next)) {
                _loadFromModule();
            }
        },
    );
    
    _initialized = true;
}
```

### 5.2 刷新触发条件

```dart
bool _shouldReload(ProjectState? previous, ProjectState? next) {
    // 1. 项目从无到有
    if (previous?.project == null && next.project != null) return true;
    
    // 2. 模块数量变化
    if (prevModuleIds != nextModuleIds) return true;
    
    // 3. 当前模块实体数量变化
    if (prevModule.entities.length != nextModule.entities.length) return true;
    
    // 4. 图谱边数量变化
    if (prevModule.graphCanvas.edges.length != nextModule.graphCanvas.edges.length) return true;
    
    // 5. 实体字段数量变化
    // ...
    
    return false;
}
```

### 5.3 数据加载

```dart
void _loadFromModule() {
    final project = ref.read(projectNotifierProvider).project;
    if (project == null) return;
    
    try {
        final module = project.modules.firstWhere((m) => m.id == moduleId);
        state = ERDiagramState.fromModule(module);
    } catch (_) {
        // 模块未找到
        if (_initialized) {
            state = ERDiagramState.empty;
        }
    }
}
```

---

## 6. 状态同步机制

### 6.1 双向同步

```
┌─────────────────────────────────────────────────────────────┐
│                    Riverpod State                           │
│  ERDiagramState                                             │
│  ├── nodes: Map<entity.id, ERNode>                         │
│  └── edges: Map<source:target, ERRelationEdge>             │
└─────────────────────────────────────────────────────────────┘
                      │
                      │ syncFromState(state)
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    Graphview Graph                          │
│  Graph                                                      │
│  ├── nodes: List<Node>                                      │
│  │   └── Node.Id(entity.id)                                │
│  │       └── position, size                                │
│  ├── edges: List<Edge>                                      │
│  └── nodeCount(), edgeCount()                              │
└─────────────────────────────────────────────────────────────┘
                      │
                      │ builder(node)
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Widgets                          │
│  ERTableNodeWidget                                          │
│  ├── 表头 (entity.title, entity.chnname)                   │
│  ├── 字段行 (Field.name, Field.type)                       │
│  └── 字段锚点 (FieldAnchor, 左右各一个)                    │
└─────────────────────────────────────────────────────────────┘
```

### 6.2 同步到项目持久化

```dart
void _syncToProject() {
    final projectNotifier = ref.read(projectNotifierProvider.notifier);
    
    // 转换回 GraphNode 和 GraphEdge
    final graphNodes = state.nodes.values.map((n) {
        final erNode = n as ERNode;
        return erNode.graphNode.copyWith(
            x: erNode.position.dx,
            y: erNode.position.dy,
        );
    }).toList();
    
    final graphEdges = state.edges.values.map((e) {
        final erEdge = e as ERRelationEdge;
        return erEdge.graphEdge;
    }).toList();
    
    // 更新模块的 graphCanvas
    final modules = project.modules.map((m) {
        if (m.id == moduleId) {
            return m.copyWith(
                graphCanvas: m.graphCanvas.copyWith(
                    nodes: graphNodes,
                    edges: graphEdges,
                ),
            );
        }
        return m;
    }).toList();
    
    projectNotifier.updateProject(project.copyWith(modules: modules));
}
```

---

## 7. 功能模块索引

### 7.1 项目管理 (features/project)

| 文件 | 功能 |
|------|------|
| `providers/project_notifier.dart` | 项目状态管理，CRUD操作 |
| `services/project_file_service.dart` | 文件读写、验证、备份 |
| `services/data_migration.dart` | 数据迁移（旧格式兼容） |
| `views/create_project_dialog.dart` | 创建项目对话框 |
| `views/open_project_dialog.dart` | 打开项目对话框 |

### 7.2 工作区 (features/workspace)

| 文件 | 功能 |
|------|------|
| `views/workspace_view.dart` | 主工作区界面 |
| `providers/tab_provider.dart` | 标签页管理 |
| `providers/layout_provider.dart` | 左视图/底视图显示控制 |
| `widgets/module_tree.dart` | 左侧模块/实体树 |
| `widgets/tab_bar.dart` | 标签页栏 |
| `widgets/icon_bar/icon_bar.dart` | 左侧图标栏 |
| `widgets/toolbar/top_menu_bar.dart` | 顶部菜单栏 |

### 7.3 实体编辑 (features/modeling/entity_editor)

| 文件 | 功能 |
|------|------|
| `views/entity_editor_view.dart` | 实体编辑界面 |
| `providers/entity_provider.dart` | 实体编辑状态 |
| `widgets/field_table.dart` | 字段表格 |
| `widgets/index_editor.dart` | 索引编辑器 |
| `widgets/code_preview.dart` | DDL预览 |

### 7.4 ER 图 (features/modeling/er_diagram)

| 文件 | 功能 |
|------|------|
| `widgets/er_diagram_canvas.dart` | ER图画布 |
| `providers/er_diagram_provider.dart` | ER图状态 |
| `models/er_diagram_models.dart` | ERNode, ERRelationEdge |
| `core/graph_sync.dart` | graphview同步 |
| `core/field_anchor_registry.dart` | 字段锚点管理 |
| `layout/layout_adapter.dart` | 布局算法适配 |
| `widgets/er_table_node_widget.dart` | 表格节点Widget |
| `widgets/er_node_builder.dart` | 节点构建器 |
| `renderers/er_edge_renderer.dart` | 边渲染器 |

### 7.5 代码生成 (features/codegen)

| 文件 | 功能 |
|------|------|
| `views/codegen_view.dart` | DDL生成预览界面 |
| `providers/codegen_provider.dart` | 生成状态 |
| `services/codegen_service.dart` | DDL生成逻辑 |
| `services/template_service.dart` | 模板管理 |

### 7.6 设置 (features/settings)

| 文件 | 功能 |
|------|------|
| `views/settings_view.dart` | 设置入口 |
| `views/global_settings_view.dart` | 全局设置 |
| `views/project_settings_view.dart` | 项目设置 |
| `panels/default_fields_panel.dart` | 默认字段配置 |
| `panels/default_database_panel.dart` | 默认数据库配置 |

---

## 8. 用户操作流程

### 8.1 创建新项目

```
1. 首页点击"新建项目"
   └── CreateProjectDialog.show()
       └── 输入项目名、描述、路径
       └── projectNotifier.createProject()
           ├── 创建 Project (id: UUID, modules: [])
           ├── 保存到文件
           └── 更新 state.project
       └── Navigator.push(WorkspaceView)

2. WorkspaceView 初始化
   └── 项目无模块，显示空状态

3. 用户创建模块
   └── 输入模块名、中文名
   └── projectNotifier.addModule(module)
       └── 更新 project.modules
       └── 触发 ER Diagram Provider 监听刷新
```

### 8.2 创建实体/表

```
1. 点击模块下的"添加表"
   └── _showAddEntityDialog()
       └── 输入表名、中文名
       └── 创建 Entity (id: UUID, fields: [])
       └── projectNotifier.updateModule(module.copyWith(entities: [..., entity]))
       └── 触发 ER Diagram Provider 刷新
           └── _loadFromModule()
           └── ERDiagramState.fromModule(module)
               └── 为新实体创建 GraphNode (自动位置)
               └── nodes[entity.id] = ERNode(entity, graphNode)

2. ER 图自动渲染新节点
   └── _graphSync.syncFromState(state)
   └── GraphView.builder 渲染新节点
```

### 8.3 编辑实体字段

```
1. 双击 ER 图节点或点击左侧树节点
   └── tabProvider.openEntity(entity, moduleId)
   └── 创建 EntityEditorView 标签页

2. EntityEditorView 加载
   └── ref.watch(entityEditProvider(entity.id))
   └── 显示字段表格

3. 编辑字段
   └── entityEditNotifier.addField/removeField/updateField
   └── 保存时调用 projectNotifier.updateModule
   └── 触发 ER Diagram Provider 刷新（字段数量变化）
```

### 8.4 创建关系连线

```
1. 切换到编辑模式
   └── _interactionMode = InteractionMode.edit
   └── ERNodeWidgetBuilderState.showAnchors = true

2. 点击字段锚点
   └── _onAnchorTap(anchor)
       └── 如果未连线：记录 _sourceAnchor
       └── 如果已连线：调用 _createRelation(source, target)
           └── 显示关系对话框
           └── erDiagramNotifier.addEdgeWithFields()
           └── _syncToProject() 更新持久化
```

---

## 9. 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Flutter | 3.8+ | UI框架 |
| Riverpod | 2.x | 状态管理 |
| TDesign Flutter | 0.2.7 | UI组件库 |
| graphview | 1.5.1 | 图布局渲染 |
| Hive | 本地存储 | 项目持久化 |
| json_annotation | JSON序列化 | 数据模型 |

---

## 10. 当前问题与待修复

### 10.1 ER 图刷新机制问题

**问题描述**：新建项目或创建模块后，ER 图可能显示"模块未找到"

**原因分析**：
1. Provider 初始化时序问题
2. 模块创建后未触发 ER Diagram Provider 刷新

**修复方案**（已实施）：
- 在 `ERDiagramNotifier` 中添加 `ref.listen()` 监听项目变化
- 添加 `_shouldReload()` 判断是否需要刷新

### 10.2 多节点显示问题

**问题描述**：ER 图只显示一个节点，多个实体时只渲染第一个

**可能原因**：
1. 实体 ID 生成问题（重复 ID）
2. graphview Node.Id() 使用相同的 ID 值导致节点被合并
3. 状态同步延迟

**调试方法**（已添加日志）：
```dart
debugPrint('syncFromState: state.nodes.length = ${state.nodes.length}');
for (final entry in state.nodes.entries) {
    debugPrint('  - node key=${entry.key}, entity.id=${erNode.entity.id}');
}
debugPrint('syncFromState: graph.nodeCount() = ${graph.nodeCount()}');
```

---

## 11. 后续优化建议

1. **ER 图渲染性能**
   - 使用缓存避免每次 build 重建 Graph
   - 按需同步，只在节点数量变化时调用 syncFromState

2. **布局算法**
   - 添加更多布局选项（层次、力导向、圆形）
   - 支持用户手动调整节点位置后保存

3. **交互体验**
   - 添加节点拖拽动画
   - 添加连线预览动画
   - 支持多选、批量操作

4. **状态管理**
   - 添加 undo/redo 功能
   - 添加变更历史记录