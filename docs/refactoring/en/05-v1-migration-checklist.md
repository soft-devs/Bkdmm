# ER 图画布功能清单

## 概述

本文档记录当前 ER 图画布的所有功能，用于测试验证和未来扩展参考。

---

## 一、架构概览

### 1.1 当前实现方式

ER 图基于 `diagram_editor` 框架实现：

```
ERDiagramCanvas
    │
    ├── 使用 diagram_editor 框架
    │   ├── DiagramState 状态管理
    │   ├── GraphView 分层渲染
    │   ├── ERInteractionManager 交互处理
    │   └── NodeModel/EdgeModel 数据封装
    │
    └── ER 图特有组件
        ├── ERTableNodeWidget 表节点渲染
        ├── ERFieldAnchorWidget 字段锚点
        └── ERDiagramUIState/UIProvider UI 状态管理
```

### 1.2 数据流

```
┌──────────────────────────────────────────────────────────────────────┐
│                         数据流向                                      │
│                                                                       │
│  ProjectNotifier (Riverpod)                                          │
│       │                                                               │
│       │ 提供                                                          │
│       ▼                                                               │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ Module                                                           ││
│  │  ├── entities: List<Entity>      # 实体数据                      ││
│  │  └── graphCanvas.nodes: List<GraphNode>  # 节点位置              ││
│  │  └── graphCanvas.edges: List<GraphEdge>  # 关系连线              ││
│  └─────────────────────────────────────────────────────────────────┘│
│       │                                                               │
│       │ 转换                                                          │
│       ▼                                                               │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ DiagramState (diagram_editor)                                    ││
│  │  ├── nodes: Map<String, DiagramNode>                             ││
│  │  ├── nodeStates: Map<String, NodeState>                          ││
│  │  └── viewport/interaction/selection 状态                         ││
│  └─────────────────────────────────────────────────────────────────┘│
│       │                                                               │
│       │ 渲染                                                          │
│       ▼                                                               │
│  GraphView → ERTableNodeWidget                                       │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                         UI 状态管理                                   │
│                                                                       │
│  erDiagramUIProvider(moduleId)                                       │
│       │                                                               │
│       ▼                                                               │
│  ERDiagramUIState                                                    │
│  ├── interactionMode: preview/edit                                   │
│  ├── selectedNodeIds: Set<String>                                    │
│  ├── hoveredNodeId: String?                                          │
│  ├── draggingNodeIds: Set<String>                                    │
│  ├── viewport: ERViewportState                                       │
│  ├── connection: ERConnectionState                                   │
│  └── selection: ERSelectionState                                     │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 二、画布功能 (Canvas Features)

### 2.1 视口控制

| 功能 | 操作 | 预览模式 | 编辑模式 | 实现位置 |
|------|------|:--------:|:--------:|----------|
| 平移画布 | 左键拖动 | ✅ | ❌ | GraphView 内部 |
| 平移画布 | 右键拖动 | ❌ | ✅ | ERInteractionManager |
| 缩放画布 | 滚轮 | ✅ | ✅ | GraphView 内部 |
| 缩放画布 | 工具栏按钮 | ✅ | ✅ | `_zoomIn()`, `_zoomOut()` |
| 适应屏幕 | 工具栏按钮 | ✅ | ✅ | `_fitToScreen()` |
| 显示坐标 | 鼠标悬停 | ✅ | ✅ | `_buildCoordinateDisplay()` |

### 2.2 交互模式

| 模式 | 说明 | 可用操作 |
|------|------|----------|
| 预览模式 (Preview) | 仅查看，不可编辑 | 左键拖动画布、滚轮缩放、双击预览实体 |
| 编辑模式 (Edit) | 可编辑实体和关系 | 左键选节点/框选/拖动/连线、右键拖动画布、双击编辑实体 |

### 2.3 工具栏功能

| 按钮 | 功能 | 实现方法 |
|------|------|----------|
| 预览模式 | 切换到预览模式 | `notifier.enterPreviewMode()` |
| 编辑模式 | 切换到编辑模式 | `notifier.enterEditMode()` |
| 放大 | 放大画布 | `_zoomIn()` |
| 缩小 | 缩小画布 | `_zoomOut()` |
| 适应屏幕 | 缩放以适应所有节点 | `_fitToScreen()` |
| 撤销 | 撤销操作 | `_undo()` |
| 重做 | 重做操作 | `_redo()` |
| 自动布局 | 自动排列节点 | `_autoLayout()` (TODO) |

### 2.4 渲染层

| 层级 | 内容 | 实现方式 |
|------|------|----------|
| 主画布 | GraphView 分层渲染 | diagram_editor 框架 |
| 工具栏 | 右上角工具按钮 | Positioned Widget |
| 坐标显示 | 左下角坐标信息 | Positioned Widget |
| 连线预览 | 连线时的虚线预览 | `_ConnectionPreviewPainter` |
| 框选预览 | 框选矩形 | `_SelectionRectPainter` |

---

## 三、节点功能 (Node Features)

### 3.1 节点渲染 (ERTableNodeWidget)

| 功能 | 说明 | 实现位置 |
|------|------|----------|
| 表头 | 显示表名和中文名 | `_buildHeader()` |
| 字段列表 | 显示字段名和类型 | `_buildFieldRow()` |
| 主键标记 | 钥匙图标 | `Icons.vpn_key` |
| 选中状态 | 蓝色边框 + 阴影 | `isSelected` 参数 |
| 尺寸计算 | 根据字段数量计算高度 | `calculateNodeSize()` |
| 锚点显示 | 字段两侧连接点 | `ERFieldAnchorWidget` |

### 3.2 节点交互

| 操作 | 模式 | 功能 | 实现方式 |
|------|------|------|----------|
| 单击 | 编辑 | 选中节点 | `_onNodeTap()` |
| Ctrl+单击 | 编辑 | 多选/取消选中 | `selectNodeMultiple()` |
| 双击 | 预览 | 打开预览弹窗 | `onEntityPreview` 回调 |
| 双击 | 编辑 | 打开编辑弹窗 | `onEntityEdit` 回调 |
| 拖动 | 编辑 | 移动节点 | `_onNodeDragStart/Update/End()` |
| 拖动 (多选) | 编辑 | 移动所有选中节点 | `_multiDragStartPositions` |

### 3.3 节点尺寸常量

```dart
static const double defaultWidth = 200.0;
static const double headerHeight = 40.0;
static const double fieldRowHeight = 28.0;
static const double minNodeHeight = 80.0;
```

---

## 四、锚点功能 (Anchor Features)

### 4.1 锚点渲染 (ERFieldAnchorWidget)

| 功能 | 说明 |
|------|------|
| 位置 | 字段行左右两侧，距离节点边缘 8px |
| 尺寸 | 视觉 6px，点击区域 20px |
| 颜色 | 主键字段黄色，普通字段蓝色 |
| 显示条件 | 仅编辑模式显示 |

### 4.2 锚点交互

| 操作 | 功能 | 实现方式 |
|------|------|----------|
| 第一次点击 | 开始连线 | `startConnection()` |
| 第二次点击 | 完成连线 | `completeConnection()` |
| 移动预览 | 显示连线预览 | `connection.previewEnd` |

### 4.3 锚点数据结构

```dart
class ERFieldAnchor {
  final String nodeId;         // 所属节点ID（实体ID）
  final int fieldIndex;        // 字段索引
  final ERAnchorDirection direction;  // 锚点方向 (left/right)
  final Offset position;       // 锚点位置（绝对坐标）
  
  String get id => '$nodeId:field:$fieldIndex:${direction.name}';
}

enum ERAnchorDirection {
  left,   // 出边连接点
  right,  // 入边连接点
}
```

---

## 五、状态管理 (State Management)

### 5.1 UI 状态 (ERDiagramUIState)

| 字段 | 类型 | 说明 |
|------|------|------|
| `moduleId` | `String` | 模块 ID |
| `interactionMode` | `ERInteractionMode` | 当前交互模式 |
| `selectedNodeIds` | `Set<String>` | 选中的节点 ID 集合 |
| `hoveredNodeId` | `String?` | 悬停的节点 ID |
| `draggingNodeIds` | `Set<String>` | 正在拖动的节点 ID 集合 |
| `viewport` | `ERViewportState` | 视口状态 (zoom, pan) |
| `connection` | `ERConnectionState` | 连线状态 |
| `selection` | `ERSelectionState` | 框选状态 |

### 5.2 Provider 结构

```
projectNotifierProvider
    └── Project
        └── Module
            ├── entities: List<Entity>      # 实体数据
            └── graphCanvas.nodes: List<GraphNode>  # 节点位置

erDiagramUIProvider(moduleId)
    └── ERDiagramUIState                    # UI 状态
```

### 5.3 状态更新方法

```dart
// 模式切换
void enterPreviewMode();
void enterEditMode();
void toggleMode();

// 选择
void selectNodeSingle(String nodeId);
void selectNodeMultiple(String nodeId);
void selectNodesByRect(Set<String> nodeIds);
void clearSelection();
void selectAll(List<String> nodeIds);

// 悬停
void setHoveredNode(String? nodeId);

// 拖动
void startDragging(String nodeId);
void endDragging();

// 连线
void startConnection(ERFieldAnchor anchor);
void updateConnectionPreview(Offset position);
void completeConnection(ERFieldAnchor anchor);
void cancelConnection();

// 框选
void startSelection(Offset startPoint);
void updateSelection(Offset currentPoint);
void endSelection();
```

---

## 六、diagram_editor 框架集成

### 6.1 核心组件映射

| ER 图组件 | diagram_editor 组件 |
|-----------|---------------------|
| `ERDiagramCanvas` | `GraphView` |
| Entity | `DiagramNode` (通过 NodeModel) |
| GraphNode (位置) | `NodeModel.position` |
| 关系连线 | `DiagramEdge` (TODO) |
| `ERInteractionManager` | 处理交互逻辑 |
| `ERDiagramUIState` | `DiagramState` 的一部分 |

### 6.2 DiagramState 构建

```dart
void _updateDiagramState(Module module, ERDiagramUIState uiState) {
  final nodes = <String, DiagramNode>{};
  final nodeStates = <String, NodeState>{};
  
  for (final entity in module.entities) {
    final node = NodeModel(
      id: entity.id,
      type: 'er_table',
      title: entity.title,
      position: Offset(graphNode.x, graphNode.y),
      size: ERTableNodeWidget.calculateNodeSize(entity.fields.length),
      data: entity,
    );
    
    nodes[entity.id] = node;
    nodeStates[entity.id] = NodeState(
      isSelected: uiState.selectedNodeIds.contains(entity.id),
      isHovered: uiState.hoveredNodeId == entity.id,
      isDragging: uiState.draggingNodeIds.contains(entity.id),
    );
  }
  
  _diagramState = DiagramState(
    diagramId: widget.moduleId,
    diagramType: 'er_diagram',
    nodes: nodes,
    nodeStates: nodeStates,
    ...
  );
}
```

---

## 七、测试验证清单

### 7.1 画布测试

- [ ] 预览模式：左键拖动平移画布
- [ ] 编辑模式：右键拖动平移画布
- [ ] 滚轮缩放画布
- [ ] 工具栏缩放按钮
- [ ] 适应屏幕功能
- [ ] 坐标显示正确

### 7.2 节点测试

- [ ] 单击选中节点
- [ ] Ctrl+单击多选节点
- [ ] 双击打开弹窗（预览/编辑模式）
- [ ] 拖动单个节点
- [ ] 多选拖动多个节点
- [ ] 节点选中状态视觉反馈
- [ ] 字段列表正确显示

### 7.3 锚点测试

- [ ] 锚点仅在编辑模式显示
- [ ] 点击锚点开始连线
- [ ] 连线预览显示
- [ ] 点击目标锚点完成连线
- [ ] 主键/普通字段锚点颜色区分

### 7.4 框选测试

- [ ] 空白区域开始框选
- [ ] 框选矩形显示
- [ ] 框选结束后正确选中节点
- [ ] 框选不干扰节点交互

---

## 八、待完成功能

| 功能 | 优先级 | 说明 |
|------|:------:|------|
| 连线完成创建关系 | 高 | 点击第二个锚点后创建 Edge |
| 关系线渲染 | 高 | ERRelationEdgeModel/Painter |
| 自动布局 | 中 | Sugiyama 或其他算法 |
| Undo/Redo 集成 | 中 | 历史记录功能 |
| 键盘快捷键 | 低 | Ctrl+A 全选、Delete 删除等 |
| 右键菜单 | 低 | 节点/画布右键菜单 |

---

*文档版本: 2.0*
*基于 diagram_editor 框架*
*最后更新: 2026-06-29*