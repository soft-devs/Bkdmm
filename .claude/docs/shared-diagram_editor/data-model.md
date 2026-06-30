# 数据模型

## DiagramNode - 核心节点抽象

```dart
abstract class DiagramNode {
  String get id;
  Offset get position;
  Size get size;
  Rect get bounds;
}
```

## DiagramEdge - 核心边抽象

```dart
abstract class DiagramEdge {
  String get id;
  String get sourceNodeId;
  String get targetNodeId;
}
```

## DiagramState - 编辑器状态

```dart
class DiagramState {
  Set<String> selectedNodeIds;
  Set<String> selectedEdgeIds;
  String? hoveredNodeId;
  String? hoveredEdgeId;
  InteractionMode interactionMode;
}
```

## NodeModel - 节点数据模型

```dart
class NodeModel implements DiagramNode {
  final String id;
  final Offset position;     // 位置（本地坐标）
  final Size size;           // 尺寸
  final Map<String, dynamic> data; // 自定义数据

  Rect get bounds => Rect.fromLTWH(position.dx, position.dy, size.width, size.height);

  NodeModel copyWith({
    String? id,
    Offset? position,
    Size? size,
    Map<String, dynamic>? data,
  });
}
```

## EdgeModel - 边数据模型

```dart
class EdgeModel implements DiagramEdge {
  final String id;
  final String sourceNodeId;
  final String targetNodeId;
  final String? sourceAnchor;  // 源锚点ID
  final String? targetAnchor;  // 目标锚点ID
  final Map<String, dynamic> data; // 自定义数据

  EdgeModel copyWith({...});
}
```

## GraphModel - 图数据模型

```dart
class GraphModel {
  final Map<String, NodeModel> _nodes;
  final Map<String, EdgeModel> _edges;

  // 节点操作
  void addNode(NodeModel node);
  void removeNode(String nodeId);
  NodeModel? getNode(String nodeId);
  List<NodeModel> get nodes;

  // 边操作
  void addEdge(EdgeModel edge);
  void removeEdge(String edgeId);
  EdgeModel? getEdge(String edgeId);
  List<EdgeModel> get edges;

  // 查询
  List<EdgeModel> getEdgesForNode(String nodeId);
  List<EdgeModel> getOutgoingEdges(String nodeId);
  List<EdgeModel> getIncomingEdges(String nodeId);
}
```

## TransformModel - 变换模型

```dart
class TransformModel {
  double scale = 1.0;       // 缩放比例
  Offset offset = Offset.zero; // 偏移量

  // 坐标转换
  Offset toLocal(Offset screenPoint) {
    return (screenPoint - offset) / scale;
  }

  Offset toScreen(Offset localPoint) {
    return localPoint * scale + offset;
  }

  // 视口变换
  void zoom(double factor, Offset focalPoint);
  void pan(Offset delta);
  void reset();
}
```

## ER 扩展模型

### ERTableNodeModel

```dart
class ERTableNodeModel extends NodeModel {
  final String tableName;
  final String tableChnName;
  final List<FieldData> fields;
  final bool isSelected;
  final bool isHovered;

  // 字段锚点位置
  Map<String, Offset> getFieldAnchorPositions();
}
```

### ERRelationEdgeModel

```dart
class ERRelationEdgeModel extends EdgeModel {
  final String relationType;  // '1:1', '1:N', 'N:1', 'N:M'
  final String? sourceField;  // 源字段名
  final String? targetField;  // 目标字段名
  final String? label;        // 关系标签
}
```

## InteractionMode - 交互模式

```dart
enum InteractionMode {
  edit,       // 编辑模式（默认）
  view,       // 查看模式
  connect,    // 连线模式
}
```

## ViewportConfig - 视口配置

```dart
class ViewportConfig {
  final double minScale;      // 最小缩放 (0.1)
  final double maxScale;      // 最大缩放 (5.0)
  final double zoomStep;      // 缩放步长 (0.1)
  final bool showGrid;        // 显示网格
  final double gridSpacing;   // 网格间距 (20)
  final Color gridColor;      // 网格颜色
}
```