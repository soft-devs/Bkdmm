# ER 图重构工作流

## 概述

本工作流基于以下文档：
- [BUSINESS_LOGIC.md](../../../docs/architecture/BUSINESS_LOGIC.md) - 数据模型业务文档
- [FEATURE_DESIGN.md](FEATURE_DESIGN.md) - 功能设计文档
- [REFACTOR_PLAN.md](REFACTOR_PLAN.md) - 重构方案

---

## 阶段一：数据层重构

### 任务 1.1：清理冗余状态
**问题**：`ERDiagramState` 维护了 `nodes` 和 `edges` 副本，与 `Project` 数据重复。

**修改文件**：
- `models/er_diagram_models.dart`

**具体改动**：
```dart
// 改动前
class ERDiagramState extends DiagramState {
  final Map<String, DiagramNode> nodes;  // 冗余副本
  final Map<String, DiagramEdge> edges;  // 冗余副本
}

// 改动后
class ERDiagramState {
  final String moduleId;

  // UI 状态（不存储业务数据）
  final Set<String> selectedNodeIds;
  final String? hoveredNodeId;
  final InteractionMode interactionMode;
  final ViewportState viewport;

  // 连线状态
  final FieldAnchor? connectingSource;
  final Offset connectingPreviewEnd;
  final bool isConnecting;

  // 业务数据从 Project 实时读取，不缓存
}
```

### 任务 1.2：简化 Provider
**问题**：`ERDiagramNotifier` 维护数据副本，需要双向同步。

**修改文件**：
- `providers/er_diagram_provider.dart`

**具体改动**：
```dart
// 改动前
class ERDiagramNotifier extends StateNotifier<ERDiagramState> {
  void _loadFromModule() {
    state = ERDiagramState.fromModule(module);  // 创建副本
  }
  void _syncToProject() {
    // 将副本同步回 Project
  }
}

// 改动后
class ERDiagramNotifier extends StateNotifier<ERDiagramState> {
  // 只管理 UI 状态
  void selectNode(String nodeId) {
    state = state.copyWith(selectedNodeIds: {...state.selectedNodeIds, nodeId});
  }

  void setInteractionMode(InteractionMode mode) {
    state = state.copyWith(interactionMode: mode);
  }

  // 业务操作直接调用 projectNotifier
  void moveNode(String entityId, double x, double y) {
    ref.read(projectNotifierProvider.notifier).updateGraphNode(moduleId, entityId, x, y);
  }

  void addEdge(GraphEdge edge) {
    ref.read(projectNotifierProvider.notifier).addGraphEdge(moduleId, edge);
  }
}
```

### 任务 1.3：扩展 ProjectNotifier
**问题**：缺少直接操作 GraphNode/GraphEdge 的方法。

**修改文件**：
- `features/project/providers/project_notifier.dart`

**新增方法**：
```dart
class ProjectNotifier extends StateNotifier<ProjectState> {
  // 新增：更新节点位置
  void updateGraphNode(String moduleId, String entityId, double x, double y) {
    final project = state.project;
    if (project == null) return;

    final modules = project.modules.map((m) {
      if (m.id == moduleId) {
        final nodes = m.graphCanvas.nodes.map((n) {
          if (n.moduleName == entityId) {
            return n.copyWith(x: x, y: y);
          }
          return n;
        }).toList();

        // 如果节点不存在，创建新节点
        if (!nodes.any((n) => n.moduleName == entityId)) {
          nodes.add(GraphNode(
            title: '${entity.title}:0',
            x: x,
            y: y,
            moduleName: entityId,
          ));
        }

        return m.copyWith(
          graphCanvas: m.graphCanvas.copyWith(nodes: nodes),
        );
      }
      return m;
    }).toList();

    updateProject(project.copyWith(modules: modules));
  }

  // 新增：添加关系连线
  void addGraphEdge(String moduleId, GraphEdge edge) {
    final project = state.project;
    if (project == null) return;

    final modules = project.modules.map((m) {
      if (m.id == moduleId) {
        final edges = [...m.graphCanvas.edges, edge];
        return m.copyWith(
          graphCanvas: m.graphCanvas.copyWith(edges: edges),
        );
      }
      return m;
    }).toList();

    updateProject(project.copyWith(modules: modules));
  }

  // 新增：删除关系连线
  void removeGraphEdge(String moduleId, String sourceId, String targetId) {
    // ...
  }

  // 新增：批量更新节点位置（用于自动布局）
  void applyGraphLayout(String moduleId, Map<String, Offset> positions) {
    // ...
  }
}
```

---

## 阶段二：渲染层重构

### 任务 2.1：简化 GraphSync
**问题**：`ERDiagramGraphSync` 做双向同步，复杂度高。

**修改文件**：
- `core/graph_sync.dart`

**具体改动**：
```dart
// 改动前：双向同步
class ERDiagramGraphSync {
  void syncFromState(ERDiagramState state) { ... }
  ERDiagramState syncToState(ERDiagramState base) { ... }
}

// 改动后：单向转换
class ERGraphBuilder {
  /// 从 Module 构建 Graph（每次 build 重新构建）
  Graph buildGraph(Module module) {
    final graph = Graph();

    // 添加节点
    for (final entity in module.entities) {
      final graphNode = _findOrCreateGraphNode(module, entity);
      final node = Node.Id(entity.id);
      node.position = Offset(graphNode.x, graphNode.y);
      node.size = _calculateNodeSize(entity);
      graph.addNode(node);
    }

    // 添加边
    for (final edge in module.graphCanvas.edges) {
      final sourceNode = graph.getNodeUsingKey(Node.Id(edge.source));
      final targetNode = graph.getNodeUsingKey(Node.Id(edge.target));
      if (sourceNode != null && targetNode != null) {
        graph.addEdge(sourceNode, targetNode);
      }
    }

    return graph;
  }

  GraphNode _findOrCreateGraphNode(Module module, Entity entity) {
    // 查找已存在的节点
    final existing = module.graphCanvas.nodes
        .where((n) => n.moduleName == entity.id)
        .firstOrNull;

    if (existing != null) return existing;

    // 创建新节点（使用网格布局）
    return GraphNode(
      title: '${entity.title}:0',
      x: _calculateNewX(module),
      y: _calculateNewY(module),
      moduleName: entity.id,
    );
  }
}
```

### 任务 2.2：重构 Canvas Widget
**问题**：状态分散，同步逻辑复杂。

**修改文件**：
- `widgets/er_diagram_canvas.dart`

**具体改动**：
```dart
class ERDiagramCanvas extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 从 project 直接读取数据
    final project = ref.watch(projectNotifierProvider).project;
    final module = project?.modules.firstWhereOrNull((m) => m.id == moduleId);

    // 2. 从 erDiagramProvider 读取 UI 状态
    final uiState = ref.watch(erDiagramProvider(moduleId));

    if (module == null || module.entities.isEmpty) {
      return _buildEmptyState();
    }

    // 3. 构建 Graph（实时）
    final graph = ERGraphBuilder().buildGraph(module);

    // 4. 创建节点构建器
    final nodeBuilder = ERNodeWidgetBuilder(
      module: module,
      uiState: uiState,
      onNodeTap: (id) => ref.read(erDiagramProvider(moduleId).notifier).selectNode(id),
      onNodeDrag: (id, pos) => ref.read(projectNotifierProvider.notifier).updateGraphNode(moduleId, id, pos.dx, pos.dy),
      onAnchorTap: (anchor) => _handleAnchorTap(ref, anchor),
    );

    // 5. 渲染
    return Stack(
      children: [
        _buildBackgroundGrid(uiState.isDarkMode),
        GraphView.builder(
          graph: graph,
          algorithm: NoOpLayoutAlgorithm(),
          builder: nodeBuilder.build(),
        ),
        _buildToolbar(uiState),
        _buildCoordinateDisplay(uiState),
        if (uiState.isConnecting) _buildConnectionPreview(uiState),
      ],
    );
  }
}
```

### 任务 2.3：修复节点位置计算
**问题**：新节点位置重叠。

**修改文件**：
- `core/graph_sync.dart` (或新的 `ERGraphBuilder`)

**具体改动**：
```dart
double _calculateNewX(Module module) {
  final existingNodes = module.graphCanvas.nodes;
  if (existingNodes.isEmpty) return 100.0;

  // 找到最右侧节点的 X 坐标
  final maxX = existingNodes.map((n) => n.x).reduce((a, b) => a > b ? a : b);
  return maxX + 250.0;  // 新节点放在右侧，间隔 250
}

double _calculateNewY(Module module) {
  final existingNodes = module.graphCanvas.nodes;
  if (existingNodes.isEmpty) return 100.0;

  // 找到同一行的节点数量
  final lastY = existingNodes.last.y;
  final sameRowCount = existingNodes.where((n) => n.y == lastY).length;

  if (sameRowCount >= 4) {
    return lastY + 300.0;  // 新行
  }
  return lastY;  // 同一行
}
```

---

## 阶段三：交互层重构

### 任务 3.1：修复锚点与拖动冲突
**问题**：点击锚点触发节点拖动。

**修改文件**：
- `widgets/er_table_node_widget.dart`

**具体改动**：
```dart
// 使用 Listener 代替 GestureDetector
// Listener 可以更精细地控制事件传播

Widget _buildAnchorWidget(FieldAnchor anchor) {
  return Listener(
    onPointerDown: (event) {
      // 消费事件，阻止传播到父级
      onAnchorTap?.call(anchor);
    },
    behavior: HitTestBehavior.opaque,  // 确保事件被捕获
    child: MouseRegion(
      cursor: SystemMouseCursors.cell,
      child: Container(
        width: 20,  // 点击区域
        height: 20,
        child: Center(
          child: Container(
            width: 6,   // 视觉大小
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // ...
            ),
          ),
        ),
      ),
    ),
  );
}

// 节点拖动使用独立的 Listener
Widget build(BuildContext context) {
  return Listener(
    onPointerDown: (event) {
      if (isDraggable && !isAnchorArea(event.localPosition)) {
        _startDrag(event);
      }
    },
    onPointerMove: (event) {
      if (_isDragging) {
        _updateDrag(event);
      }
    },
    onPointerUp: (event) {
      if (_isDragging) {
        _endDrag();
      }
    },
    child: Stack(
      children: [
        _buildNodeBody(),
        if (showAnchors) _buildAnchors(),
      ],
    ),
  );
}

// 判断点击位置是否在锚点区域
bool isAnchorArea(Offset localPosition) {
  for (final anchor in anchors) {
    final anchorRect = Rect.fromLTWH(anchor.left, anchor.top, 20, 20);
    if (anchorRect.contains(localPosition)) {
      return true;
    }
  }
  return false;
}
```

### 任务 3.2：完善连线预览
**问题**：连线预览可能不流畅。

**修改文件**：
- `widgets/er_diagram_canvas.dart`

**具体改动**：
```dart
void _handleAnchorTap(WidgetRef ref, FieldAnchor anchor) {
  final notifier = ref.read(erDiagramProvider(moduleId).notifier);

  if (!notifier.state.isConnecting) {
    // 开始连线
    notifier.startConnection(anchor);
  } else {
    // 完成连线
    final source = notifier.state.connectingSource;
    if (source != null && source.nodeId != anchor.nodeId) {
      _createRelation(ref, source, anchor);
    }
    notifier.endConnection();
  }
}

Widget _buildConnectionPreview(ERDiagramState uiState) {
  if (uiState.connectingSource == null) return const SizedBox();

  return Positioned.fill(
    child: MouseRegion(
      onHover: (event) {
        // 更新预览终点
        ref.read(erDiagramProvider(moduleId).notifier)
            .updateConnectionPreview(event.localPosition);
      },
      child: CustomPaint(
        painter: ConnectionPreviewPainter(
          source: uiState.connectingSource!.position,
          target: uiState.connectingPreviewEnd,
        ),
      ),
    ),
  );
}
```

---

## 阶段四：功能完善

### 任务 4.1：完善模式切换
**问题**：模式切换后锚点显示可能不正确。

**修改文件**：
- `widgets/er_diagram_canvas.dart`
- `widgets/er_node_builder.dart`

**验证点**：
- 移动模式：无锚点，不可拖动
- 编辑模式：显示锚点，可拖动
- 切换后立即生效

### 任务 4.2：完善工具栏功能
**功能**：放大、缩小、适应屏幕、自动布局

**修改文件**：
- `widgets/er_diagram_canvas.dart`

**验证点**：
- 放大/缩小按钮有效
- 适应屏幕正确计算边界
- 自动布局后位置保存

### 任务 4.3：完善双击打开实体编辑
**功能**：双击节点打开实体编辑弹窗

**修改文件**：
- `widgets/er_diagram_canvas.dart`

**验证点**：
- 两种模式下双击都有效
- 正确传递 entity 数据

---

## 阶段五：清理与优化

### 任务 5.1：移除冗余代码
- 移除旧的同步逻辑
- 移除冗余的状态字段
- 移除废弃的方法

### 任务 5.2：添加日志追踪
- 关键操作添加日志
- 使用项目统一的 `logging` 实例
- 设置合适的日志级别

### 任务 5.3：编写单元测试
- Provider 状态管理测试
- GraphNode/GraphEdge 操作测试
- 位置计算逻辑测试

---

## 实施顺序

```
阶段一：数据层重构
├── 1.1 清理 ERDiagramState 冗余状态
├── 1.2 简化 ERDiagramNotifier
└── 1.3 扩展 ProjectNotifier

阶段二：渲染层重构
├── 2.1 简化 GraphSync → ERGraphBuilder
├── 2.2 重构 Canvas Widget
└── 2.3 修复节点位置计算

阶段三：交互层重构
├── 3.1 修复锚点与拖动冲突
└── 3.2 完善连线预览

阶段四：功能完善
├── 4.1 完善模式切换
├── 4.2 完善工具栏功能
└── 4.3 完善双击打开实体编辑

阶段五：清理与优化
├── 5.1 移除冗余代码
├── 5.2 添加日志追踪
└── 5.3 编写单元测试
```

---

## 验证清单

### 数据层验证
- [ ] 节点位置正确保存到 `project.modules[].graphCanvas.nodes`
- [ ] 关系连线正确保存到 `project.modules[].graphCanvas.edges`
- [ ] 刷新页面后位置恢复正确
- [ ] 新建实体自动创建 GraphNode 并保存

### 渲染层验证
- [ ] 所有节点正确显示
- [ ] 节点位置不重叠
- [ ] 关系连线正确渲染
- [ ] 关系标记（1:N）正确显示

### 交互层验证
- [ ] 移动模式：不可拖动节点，不显示锚点
- [ ] 编辑模式：可拖动节点，显示锚点
- [ ] 点击锚点不触发拖动
- [ ] 连线预览正确显示
- [ ] 双击打开实体编辑弹窗

### 工具栏验证
- [ ] 模式切换按钮有效
- [ ] 放大/缩小按钮有效
- [ ] 适应屏幕有效
- [ ] 自动布局有效且位置保存