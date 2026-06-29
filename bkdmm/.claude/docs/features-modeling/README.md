# features/modeling 模块

Bkdmm 项目数据建模模块，提供实体编辑、ER图可视化、流程图绘制功能。

## 模块结构

```
features/modeling/
  entity_editor/          # 实体编辑器
    entity_editor.dart    # 模块入口（导出所有公共 API）
    providers/
      entity_provider.dart    # Entity 状态管理 Provider
    views/
      entity_editor_view.dart # 实体编辑主视图
    widgets/
      field_table.dart       # 字段表格组件
      index_editor.dart      # 索引编辑器组件
      code_preview.dart      # DDL 代码预览组件

  er_diagram/             # ER 图编辑器
    er_diagram.dart       # 模块入口（导出所有公共 API）
    models/
      er_diagram_models.dart # ERNode/ERRelationEdge 数据模型
    providers/
      er_diagram_provider.dart # ER 图状态管理 Provider
    core/
      graph_sync.dart        # GraphView 双向同步器
      field_anchor_registry.dart # 字段级锚点注册表
      er_graph_edge.dart     # GraphView Edge 包装
    widgets/
      er_diagram_canvas.dart  # ER 图画布（基于 GraphView）
      er_table_node_widget.dart # 表节点渲染 Widget
      er_node_builder.dart   # 节点 Widget 构建器
    renderers/
      er_edge_renderer.dart  # 关系边渲染器
    layout/
      layout_adapter.dart    # 布局算法适配器

  flowchart/              # 流程图编辑器
    flowchart.dart        # 模块入口
    models/
      flowchart_models.dart # FlowNode/FlowEdge 数据模型
    renderers/
      flowchart_renderers.dart # 流程图渲染器
    widgets/
      flowchart_canvas.dart   # 流程图画布
```

## 模块功能

### 1. Entity Editor（实体编辑器）

数据库表编辑功能，支持：
- 表基本信息编辑（表名、中文名、备注）
- 字段管理（添加、编辑、删除、重排序）
- 索引管理（NORMAL/UNIQUE/FULLTEXT）
- DDL 代码预览（支持 MySQL/PostgreSQL/Oracle/SQL Server）
- 自动同步到项目数据

**主要组件：**
- `EntityEditorView` - 主编辑视图，包含 Summary/Fields/Indexes/Preview 四个标签页
- `FieldTable` - 字段表格，支持响应式列宽、内联编辑、行选择
- `IndexEditor` - 索引编辑器，支持字段多选、类型配置
- `CodePreview` - DDL 预览，支持数据库切换、复制、下载

### 2. ER Diagram（ER 图编辑器）

实体关系可视化功能，基于 `graphview` 库实现：
- 层次布局（Sugiyama 算法）
- 字段级连线锚点
- 节点拖拽移动
- 交互模式切换（移动/编辑）
- 视口缩放、平移、自适应

**核心机制：**
- `ERDiagramState` - ER 图状态模型，包含节点、边、视口、交互状态
- `ERDiagramGraphSync` - 双向同步器，转换 State <-> GraphView Graph
- `FieldAnchorRegistry` - 字段锚点管理，支持命中测试

### 3. Flowchart（流程图编辑器）

流程图绘制功能（开发中），支持：
- 基础节点类型（开始/结束、流程、判断、输入输出）
- 正交连线
- 条件分支标注

## 对外 API

### Entity Editor

```dart
// 导入
import 'package:bkdmm/features/modeling/entity_editor/entity_editor.dart';

// Provider
final entityEditProvider = StateNotifierProvider.family<
  EntityEditNotifier, EntityEditState, (Entity, String)
>();

// 使用示例
EntityEditorView(
  entity: entity,
  moduleId: moduleId,
)
```

### ER Diagram

```dart
// 导入
import 'package:bkdmm/features/modeling/er_diagram/er_diagram.dart';

// Provider
final erDiagramProvider = StateNotifierProvider.family<
  ERDiagramNotifier, ERDiagramState, String
>();

final hasEntitiesProvider = Provider.family<bool, String>((ref, moduleId) => ...);
final entityCountProvider = Provider.family<int, String>((ref, moduleId) => ...);

// 使用示例
ERDiagramCanvas(
  moduleId: moduleId,
  onEntityEdit: (entity) => ...,
  onContextMenu: (position, entity) => ...,
)
```

### Flowchart

```dart
// 导入
import 'package:bkdmm/features/modeling/flowchart/flowchart.dart';

// 使用示例
FlowDiagramState.createSample()  // 创建示例流程图
```

## 技术栈

- **状态管理**: Riverpod (StateNotifierProvider.family)
- **UI 组件**: TDesign Flutter
- **图布局**: graphview (SugiyamaAlgorithm)
- **数据持久化**: 通过 ProjectProvider 同步到 Hive

## 数据流向

```
EntityEditor -> EntityEditNotifier -> ProjectNotifier -> Hive
ERDiagramCanvas -> ERDiagramNotifier -> ProjectNotifier -> Hive
```

所有编辑操作最终通过 `ProjectNotifier` 同步到项目数据，由上层统一持久化。

## 与其他模块的依赖

- `shared/models` - Entity, Field, Index, Module, Project 等数据模型
- `shared/providers` - ProjectNotifierProvider 项目状态管理
- `shared/diagram_editor` - DiagramNode, DiagramEdge 等图表基础接口
- `utils/id_generator` - 唯一 ID 生成器

## 设计模式

1. **Feature-First 架构** - 每个子模块独立完整，有明确的入口文件
2. **双向数据绑定** - ERDiagramGraphSync 实现 State <-> Graph 的双向转换
3. **Provider Family** - 按 Entity 或 Module ID 创建独立 Provider 实例
4. **组合优于继承** - ERNode 包装 Entity + GraphNode，而非继承