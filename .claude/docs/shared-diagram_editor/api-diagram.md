# API 文档

## DiagramEditor - 主入口类

图编辑器的统一门面API。

### 构造函数

```dart
DiagramEditor({
  String? id,                          // 唯一标识
  String diagramType = 'default',      // 图表类型
  ViewportConfig? viewportConfig,      // 视口配置
  InteractionMode interactionMode = InteractionMode.edit, // 交互模式
})
```

### 节点操作

| 方法 | 描述 |
|------|------|
| `addNode(node)` | 添加节点 |
| `removeNode(nodeId)` | 删除节点 |
| `getNode(nodeId)` | 获取节点 |
| `nodes` | 所有节点列表 |
| `selectedNodes` | 选中的节点列表 |

### 边操作

| 方法 | 描述 |
|------|------|
| `addEdge(edge)` | 添加边 |
| `removeEdge(edgeId)` | 删除边 |
| `getEdge(edgeId)` | 获取边 |
| `edges` | 所有边列表 |
| `selectedEdges` | 选中的边列表 |

### 选择管理

| 方法 | 描述 |
|------|------|
| `selectNode(nodeId)` | 选中节点 |
| `selectEdge(edgeId)` | 选中边 |
| `clearSelection()` | 清除选择 |
| `selectAll()` | 全选 |
| `selectedNodeIds` | 选中节点ID集合 |
| `selectedEdgeIds` | 选中边ID集合 |

### 视口控制

| 方法 | 描述 |
|------|------|
| `zoomIn()` | 放大 |
| `zoomOut()` | 缩小 |
| `zoomToFit()` | 适应视口 |
| `resetViewport()` | 重置视口 |
| `panTo(position)` | 平移到指定位置 |
| `scale` | 当前缩放比例 |
| `offset` | 当前偏移量 |

### 命令系统

| 方法 | 描述 |
|------|------|
| `executeCommand(command)` | 执行命令 |
| `undo()` | 撤销 |
| `redo()` | 重做 |
| `canUndo` | 是否可撤销 |
| `canRedo` | 是否可重做 |
| `clearHistory()` | 清空历史 |

### 事件系统

```dart
// 监听节点选中事件
editor.eventCenter.on<NodeSelectedEvent>((e) {
  print('Node selected: ${e.nodeId}');
});

// 监听边创建事件
editor.eventCenter.on<EdgeCreatedEvent>((e) {
  print('Edge created: ${e.edgeId}');
});
```

### 事件类型

| 事件类型 | 描述 |
|----------|------|
| `NodeSelectedEvent` | 节点选中 |
| `NodeDeselectedEvent` | 节点取消选中 |
| `EdgeSelectedEvent` | 边选中 |
| `NodeMovedEvent` | 节点移动 |
| `EdgeCreatedEvent` | 边创建 |
| `EdgeDeletedEvent` | 边删除 |
| `ViewportChangedEvent` | 视口变化 |

## GraphModel - 图数据模型

```dart
class GraphModel {
  final Map<String, NodeModel> nodes;
  final Map<String, EdgeModel> edges;

  void addNode(NodeModel node);
  void removeNode(String nodeId);
  void addEdge(EdgeModel edge);
  void removeEdge(String edgeId);
  List<EdgeModel> getEdgesForNode(String nodeId);
}
```

## NodeModel - 节点模型

```dart
class NodeModel {
  final String id;
  final Offset position;
  final Size size;
  final Map<String, dynamic> data;

  NodeModel copyWith({Offset? position, Size? size});
}
```

## EdgeModel - 边模型

```dart
class EdgeModel {
  final String id;
  final String sourceNodeId;
  final String targetNodeId;
  final String? sourceAnchor;
  final String? targetAnchor;
  final Map<String, dynamic> data;
}
```

## TransformModel - 变换模型

```dart
class TransformModel {
  double scale;      // 缩放比例
  Offset offset;     // 偏移量

  Offset toLocal(Offset screenPoint);   // 屏幕坐标转本地坐标
  Offset toScreen(Offset localPoint);   // 本地坐标转屏幕坐标
}
```

## 使用示例

### 基本使用

```dart
// 创建编辑器
final editor = DiagramEditor(
  diagramType: 'er-diagram',
);

// 添加节点
editor.addNode(ERTableNodeModel(
  id: 'table-1',
  position: Offset(100, 100),
  tableName: 'user',
));

// 添加边
editor.addEdge(ERRelationEdgeModel(
  id: 'relation-1',
  sourceNodeId: 'table-1',
  targetNodeId: 'table-2',
  relationType: '1:N',
));

// 选择节点
editor.selectNode('table-1');

// 撤销
if (editor.canUndo) {
  editor.undo();
}

// 清理
editor.dispose();
```

### 在 Widget 中使用

```dart
class DiagramView extends StatefulWidget {
  @override
  State<DiagramView> createState() => _DiagramViewState();
}

class _DiagramViewState extends State<DiagramView> {
  late DiagramEditor _editor;

  @override
  void initState() {
    super.initState();
    _editor = DiagramEditor();
    _editor.eventCenter.on<NodeSelectedEvent>(_onNodeSelected);
  }

  void _onNodeSelected(NodeSelectedEvent e) {
    setState(() {});
  }

  @override
  void dispose() {
    _editor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GraphView(editor: _editor);
  }
}
```