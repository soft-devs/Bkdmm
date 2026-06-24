# shared/diagram_editor - 图表编辑框架

通用图表编辑基础设施，支持多种图表类型扩展。

## 概述

该模块提供图表编辑的核心抽象，使用 CustomPainter 进行高性能渲染，支持节点拖拽、缩放、平移等交互。

## 核心组件

### 核心类

| 类 | 文件 | 说明 |
|------|------|------|
| DiagramNode | diagram_node.dart | 节点抽象基类 |
| DiagramEdge | diagram_edge.dart | 连线抽象基类 |
| DiagramCanvas | diagram_canvas.dart | 画布组件 |
| DiagramState | diagram_state.dart | 图表状态管理 |

### 布局引擎

| 类 | 文件 | 说明 |
|------|------|------|
| LayoutEngine | layout_engine.dart | 布局引擎接口 |
| GraphviewLayout | graphview_layout.dart | 基于 graphview 的布局实现 |

### 渲染器

| 类 | 文件 | 说明 |
|------|------|------|
| NodeRenderer | renderers.dart | 节点渲染器接口 |
| EdgeRenderer | renderers.dart | 连线渲染器接口 |
| AnchorRenderer | anchor_renderer.dart | 锚点渲染器 |

## 架构设计

```
DiagramCanvas (画布组件)
├── DiagramState (状态管理)
│   ├── List<DiagramNode> nodes
│   ├── List<DiagramEdge> edges
│   ├── Viewport viewport
│   └── Selection selection
├── LayoutEngine (布局引擎)
├── NodeRenderer (节点渲染)
├── EdgeRenderer (连线渲染)
└── GestureHandler (手势处理)
```

## DiagramNode (节点)

```dart
abstract class DiagramNode {
  String get id;                    // 节点唯一标识
  Offset get position;              // 节点位置
  Size get size;                    // 节点大小
  void render(Canvas canvas, ...);  // 渲染方法
}
```

### 实现示例

```dart
class ERNode extends DiagramNode {
  final Entity entity;
  @override
  void render(Canvas canvas, DiagramTheme theme) {
    // 绘制表头
    // 绘制字段列表
    // 绘制索引图标
  }
}
```

## DiagramEdge (连线)

```dart
abstract class DiagramEdge {
  String get id;                    // 连线唯一标识
  String get sourceId;              // 源节点ID
  String get targetId;              // 目标节点ID
  void render(Canvas canvas, ...);  // 渲染方法
}
```

### 实现示例

```dart
class EREdge extends DiagramEdge {
  final GraphEdge edge;
  @override
  void render(Canvas canvas, DiagramTheme theme) {
    // 绘制连线
    // 绘制箭头
    // 绘制关系标签
  }
}
```

## DiagramCanvas (画布)

核心画布组件，使用 CustomPainter 实现高性能渲染。

```dart
class DiagramCanvas extends StatefulWidget {
  final List<DiagramNode> nodes;
  final List<DiagramEdge> edges;
  final DiagramTheme theme;
  final void Function(DiagramNode)? onNodeTap;
  final void Function(Offset)? onCanvasTap;
  final void Function(DiagramNode, Offset)? onNodeDrag;
}
```

### 功能特性

- **缩放** - 鼠标滚轮缩放
- **平移** - 拖拽空白区域平移
- **节点拖拽** - 拖拽节点改变位置
- **选择** - 单击选择节点
- **右键菜单** - 上下文菜单支持

## LayoutEngine (布局引擎)

### GraphviewLayout

基于 graphview 库的自动布局实现：

```dart
class GraphviewLayout implements LayoutEngine {
  @override
  void layout(List<DiagramNode> nodes, List<DiagramEdge> edges) {
    // 使用 BuchheimWalker 算法进行布局
    final builder = FruchtermanReingoldAlgorithm();
    // 计算节点位置
  }
}
```

## 扩展指南

### 1. 创建新图表类型

```dart
// 1. 定义节点类型
class MyNode extends DiagramNode {
  @override
  void render(Canvas canvas, DiagramTheme theme) {
    // 自定义渲染逻辑
  }
}

// 2. 定义连线类型
class MyEdge extends DiagramEdge {
  @override
  void render(Canvas canvas, DiagramTheme theme) {
    // 自定义渲染逻辑
  }
}

// 3. 创建画布组件
class MyDiagramCanvas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DiagramCanvas(
      nodes: nodes,
      edges: edges,
      // ...
    );
  }
}
```

### 2. 实现自定义布局

```dart
class MyLayout implements LayoutEngine {
  @override
  void layout(List<DiagramNode> nodes, List<DiagramEdge> edges) {
    // 自定义布局算法
  }
}
```

## 已实现图表

| 图表类型 | 位置 | 说明 |
|------|------|------|
| ER图 | features/modeling/er_diagram | 数据库ER图编辑器 |
| 流程图 | features/modeling/flowchart | 流程图编辑器（示例） |

## 注意事项

1. **性能优化** - 使用 `shouldRepaint` 控制重绘
2. **坐标转换** - 屏幕坐标与画布坐标需要根据 viewport 转换
3. **事件处理** - 手势处理需要考虑缩放和平移
4. **锚点计算** - 连线端点需要计算到节点的最近锚点
