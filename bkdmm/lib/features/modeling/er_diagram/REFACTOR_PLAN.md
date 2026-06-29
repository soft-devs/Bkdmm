# ER 图模块重构方案

## 一、功能点清单

### 1. 画布基础功能
| 功能 | 描述 | 当前状态 |
|------|------|----------|
| 背景网格 | 显示网格背景，辅助对齐 | ✅ 已实现 |
| 缩放 | 放大/缩小/适应屏幕 | ✅ 已实现 |
| 平移 | 移动画布视图 | ✅ 已实现 |
| 坐标显示 | 左下角显示鼠标坐标 | ✅ 已实现 |

### 2. 节点功能
| 功能 | 描述 | 当前状态 |
|------|------|----------|
| 节点渲染 | 显示表名、字段、类型 | ✅ 已实现 |
| 节点位置记忆 | 保存/恢复节点位置 | ❌ 有问题 |
| 节点选择 | 单选/多选节点 | ✅ 已实现 |
| 节点拖动 | 编辑模式下拖动节点 | ❌ 与锚点冲突 |
| 节点双击 | 打开实体编辑弹窗 | ✅ 已实现 |
| 节点创建 | 新建实体时自动创建节点 | ❌ 位置重叠 |

### 3. 字段锚点功能
| 功能 | 描述 | 当前状态 |
|------|------|----------|
| 锚点显示 | 编辑模式显示字段左右锚点 | ✅ 已实现 |
| 锚点点击 | 点击锚点开始连线 | ❌ 与拖动冲突 |
| 连线预览 | 拖动时显示连线预览 | ✅ 已实现 |
| 关系创建 | 完成连线并设置关系类型 | ✅ 已实现 |

### 4. 边（关系）功能
| 功能 | 描述 | 当前状态 |
|------|------|----------|
| 边渲染 | 绘制关系线 | ✅ 已实现 |
| 关系标记 | 绘制 1:N、N:M 标记 | ✅ 已实现 |
| 鸦脚标记 | 绘制鸦脚符号 | ✅ 已实现 |
| 字段级连线 | 连接指定字段 | ✅ 已实现 |

### 5. 交互模式
| 模式 | 描述 | 当前状态 |
|------|------|----------|
| 移动模式 | 平移/缩放画布，不可编辑 | ✅ 已实现 |
| 编辑模式 | 拖动节点、创建连线 | ❌ 有问题 |

### 6. 工具栏功能
| 功能 | 描述 | 当前状态 |
|------|------|----------|
| 模式切换 | 移动/编辑模式切换 | ✅ 已实现 |
| 缩放按钮 | 放大/缩小/适应屏幕 | ✅ 已实现 |
| 自动布局 | 自动排列节点 | ✅ 已实现 |

---

## 二、当前问题分析

### 问题1: 节点位置重叠
**现象**: 创建新表时，多个节点位置相同 (100, 100)
**原因**:
- `ERDiagramState.fromModule()` 为新实体创建 GraphNode 时，`col`/`row` 计算逻辑有问题
- 可能是已删除实体的 GraphNode 残留在 `module.graphCanvas.nodes` 中

### 问题2: 锚点与拖动冲突
**现象**: 编辑模式下，点击锚点会触发节点拖动
**原因**:
- 锚点的 GestureDetector 被父级 GestureDetector 拦截
- 事件传播顺序问题

### 问题3: 数据同步复杂
**现象**: 多处数据转换和同步逻辑
**原因**:
- `ERDiagramState` 与 `Module` 双向转换
- `ERDiagramState` 与 `Graph` 双向同步
- `Graph` 与 `Project` 双向同步
- 链路过长，容易出错

### 问题4: 状态管理混乱
**现象**: 状态分散在多个地方
**原因**:
- `ERDiagramNotifier` 管理业务状态
- `ERDiagramGraphSync` 管理图状态
- `FieldAnchorRegistry` 管理锚点状态
- `GraphViewController` 管理视图状态
- 各状态之间需要手动同步

---

## 三、重构方案

### 方案概述
简化数据流，统一状态管理，明确职责边界。

### 3.1 数据模型简化

```
┌─────────────────────────────────────────────────────────────┐
│                      单一数据源                               │
│                                                             │
│   Project                                                   │
│     └── Module                                              │
│           ├── Entity[] (实体数据)                            │
│           └── GraphCanvas                                   │
│                 ├── GraphNode[] (节点位置)                   │
│                 └── GraphEdge[] (关系连线)                   │
└─────────────────────────────────────────────────────────────┘
```

**原则**:
- `Project` 是唯一数据源
- ER 图只读取和修改 `Project` 数据
- 不维护中间状态

### 3.2 状态管理重构

```dart
/// ER 图状态（精简版）
class ERDiagramState {
  final String moduleId;

  // 只存储 UI 状态，不存储业务数据
  final Set<String> selectedNodeIds;
  final String? hoveredNodeId;
  final InteractionMode interactionMode;
  final ViewportState viewport;

  // 业务数据直接从 Project 读取
}

/// ER 图 Notifier
class ERDiagramNotifier extends StateNotifier<ERDiagramState> {
  // 不维护 nodes/edges 副本
  // 直接操作 projectNotifier

  void moveNode(String nodeId, double x, double y) {
    // 直接更新 project.module.graphCanvas.nodes
    projectNotifier.updateNodePosition(moduleId, nodeId, x, y);
  }
}
```

### 3.3 渲染层简化

```dart
/// ER 图画布
class ERDiagramCanvas extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    // 直接从 project 读取数据
    final project = ref.watch(projectNotifierProvider).project;
    final module = project.modules.firstWhere((m) => m.id == moduleId);

    // 构建 graphview
    return GraphView.builder(
      graph: _buildGraph(module),  // 实时构建
      builder: _buildNodeBuilder(module),
    );
  }

  Graph _buildGraph(Module module) {
    final graph = Graph();
    for (final entity in module.entities) {
      final node = _findOrCreateGraphNode(module, entity);
      graph.addNode(Node.Id(entity.id)..position = Offset(node.x, node.y));
    }
    for (final edge in module.graphCanvas.edges) {
      // 添加边
    }
    return graph;
  }
}
```

### 3.4 节点 Widget 重构

```dart
/// ER 表节点 Widget
class ERTableNodeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 节点主体
        _buildNodeBody(),
        // 锚点层（只在编辑模式显示）
        if (showAnchors) _buildAnchorLayer(),
      ],
    );
  }

  Widget _buildAnchorLayer() {
    // 使用 Listener 而非 GestureDetector
    // 避免与父级手势冲突
    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final anchor in anchors)
            Positioned(
              left: anchor.left,
              top: anchor.top,
              child: _AnchorWidget(
                anchor: anchor,
                onTap: onAnchorTap,
              ),
            ),
        ],
      ),
    );
  }
}

/// 锚点 Widget（独立处理手势）
class _AnchorWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 使用 Listener 的 onPointerDown 处理点击
    // 返回 Handled 可以阻止事件传播
    return Listener(
      onPointerDown: (event) {
        onTap?.call(anchor);
        return true; // 阻止事件传播
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.cell,
        child: Container(/* 锚点视觉 */),
      ),
    );
  }
}
```

### 3.5 拖动处理重构

```dart
/// 节点拖动处理
class NodeDragHandler {
  String? _draggedNodeId;
  Offset _dragStart = Offset.zero;
  Offset _nodeStartPos = Offset.zero;

  void onPointerDown(PointerDownEvent event, String nodeId) {
    if (!isEditMode) return;

    _draggedNodeId = nodeId;
    _dragStart = event.localPosition;
    _nodeStartPos = getNodePosition(nodeId);
  }

  void onPointerMove(PointerMoveEvent event) {
    if (_draggedNodeId == null) return;

    final delta = event.localPosition - _dragStart;
    final newPos = _nodeStartPos + delta;

    // 直接更新 project
    updateNodePosition(_draggedNodeId!, newPos);
  }

  void onPointerUp(PointerUpEvent event) {
    _draggedNodeId = null;
  }
}
```

---

## 四、重构步骤

### 第一阶段：数据模型清理
1. 移除 `ERDiagramState` 中的 `nodes` 和 `edges` 字段
2. 直接从 `Project` 读取数据
3. 简化 `ERDiagramState.fromModule()` 工厂方法

### 第二阶段：状态管理简化
1. `ERDiagramNotifier` 只管理 UI 状态
2. 业务操作直接调用 `projectNotifier`
3. 移除 `_syncToProject()` 方法

### 第三阶段：渲染层重构
1. 简化 `ERDiagramGraphSync`，只做单向转换
2. 优化 `ERTableNodeWidget` 手势处理
3. 修复锚点点击与拖动冲突

### 第四阶段：功能完善
1. 修复节点位置计算逻辑
2. 完善连线预览功能
3. 添加撤销/重做支持

---

## 五、关键接口设计

### 5.1 数据读取接口

```dart
/// ER 图数据读取器
mixin ERDiagramDataReader {
  Project? get project;
  String get moduleId;

  Module? get module => project?.modules.firstWhereOrNull((m) => m.id == moduleId);
  List<Entity> get entities => module?.entities ?? [];
  List<GraphNode> get graphNodes => module?.graphCanvas.nodes ?? [];
  List<GraphEdge> get graphEdges => module?.graphCanvas.edges ?? [];

  GraphNode? getGraphNode(String entityId) {
    return graphNodes.firstWhereOrNull((n) => n.moduleName == entityId);
  }

  Entity? getEntity(String entityId) {
    return entities.firstWhereOrNull((e) => e.id == entityId);
  }
}
```

### 5.2 数据写入接口

```dart
/// ER 图数据写入器
mixin ERDiagramDataWriter {
  void updateNodePosition(String entityId, double x, double y);
  void createNode(String entityId, {double? x, double? y});
  void deleteNode(String entityId);
  void createEdge(GraphEdge edge);
  void deleteEdge(String sourceId, String targetId);
}
```

### 5.3 交互状态接口

```dart
/// ER 图交互状态
class ERInteractionState {
  final InteractionMode mode;
  final Set<String> selectedIds;
  final String? hoveredId;
  final String? draggingId;
  final FieldAnchor? connectingAnchor;
}
```

---

## 六、测试验证点

1. **节点位置**
   - 创建新节点，位置正确（不重叠）
   - 移动节点，位置保存
   - 刷新页面，位置恢复

2. **节点拖动**
   - 移动模式：不可拖动
   - 编辑模式：可拖动
   - 拖动流畅，不卡顿

3. **锚点连线**
   - 编辑模式显示锚点
   - 点击锚点不触发拖动
   - 连线预览正确显示
   - 关系创建成功

4. **数据持久化**
   - 节点位置保存到项目文件
   - 关系数据保存到项目文件
   - 重新打开项目，数据恢复
