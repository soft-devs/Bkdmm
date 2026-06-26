# 数据模型设计

基于 LogicFlow 的 Model-View 分离架构设计。

---

## 一、模型架构概览

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           GraphModel (根模型)                            │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                      元素模型 (Element Models)                    │   │
│   │                                                                   │   │
│   │   ┌─────────────────┐     ┌─────────────────┐                   │   │
│   │   │   NodeModel     │     │   EdgeModel     │                   │   │
│   │   │   (抽象基类)     │     │   (抽象基类)     │                   │   │
│   │   │                 │     │                 │                   │   │
│   │   │  - id           │     │  - id           │                   │   │
│   │   │  - type         │     │  - type         │                   │   │
│   │   │  - position     │     │  - sourceId     │                   │   │
│   │   │  - size         │     │  - targetId     │                   │   │
│   │   │  - anchors      │     │  - points       │                   │   │
│   │   │  - state        │     │  - text         │                   │   │
│   │   │                 │     │                 │                   │   │
│   │   │  具体实现:       │     │  具体实现:       │                   │   │
│   │   │  - RectNode     │     │  - LineEdge     │                   │   │
│   │   │  - CircleNode   │     │  - PolylineEdge │                   │   │
│   │   │  - ERTableNode  │     │  - ERRelation   │                   │   │
│   │   └─────────────────┘     └─────────────────┘                   │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                      功能模型 (Feature Models)                    │   │
│   │                                                                   │   │
│   │   ┌─────────────────┐     ┌─────────────────┐                   │   │
│   │   │ TransformModel  │     │ SelectionModel  │                   │   │
│   │   │ (视口变换)       │     │ (选择状态)       │                   │   │
│   │   │                 │     │                 │                   │   │
│   │   │  - scale        │     │  - selectedIds  │                   │   │
│   │   │  - offset       │     │  - selectionRect│                   │   │
│   │   │  - transform    │     │  - isSelecting  │                   │   │
│   │   └─────────────────┘     └─────────────────┘                   │   │
│   │                                                                   │   │
│   │   ┌─────────────────┐     ┌─────────────────┐                   │   │
│   │   │ EditConfigModel │     │ SnaplineModel   │                   │   │
│   │   │ (编辑配置)       │     │ (对齐线)        │                   │   │
│   │   │                 │     │                 │                   │   │
│   │   │  - isEditable   │     │  - lines        │                   │   │
│   │   │  - isSilentMode │     │  - epsilon      │                   │   │
│   │   │  - snapGrid     │     │                 │                   │   │
│   │   └─────────────────┘     └─────────────────┘                   │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                        AnchorModel (锚点)                         │   │
│   │                                                                   │   │
│   │   - id: String              // 锚点 ID                           │   │
│   │   - nodeId: String          // 所属节点 ID                       │   │
│   │   - direction: Direction    // 方向 (left/top/right/bottom)      │   │
│   │   - position: Offset        // 绝对位置                          │   │
│   │   - offset: Offset          // 相对于节点的偏移                  │   │
│   └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 二、GraphModel - 图数据模型

```dart
/// 图数据模型 - 所有数据的单一来源
///
/// 参考 LogicFlow 的 GraphModel 设计，管理节点、边、变换等所有状态。
class GraphModel with ChangeNotifier {
  // ═══════════════════════════════════════════════════════════════════
  // 核心属性
  // ═══════════════════════════════════════════════════════════════════

  /// 画布尺寸
  Size _canvasSize = Size.zero;

  /// 节点映射表 (id -> model)
  final Map<String, NodeModel> _nodeMap = {};

  /// 边映射表 (id -> model)
  final Map<String, EdgeModel> _edgeMap = {};

  /// 节点列表（保持顺序）
  final List<NodeModel> _nodes = [];

  /// 边列表（保持顺序）
  final List<EdgeModel> _edges = [];

  // ═══════════════════════════════════════════════════════════════════
  // 功能模型
  // ═══════════════════════════════════════════════════════════════════

  /// 视口变换模型
  final TransformModel transformModel = TransformModel();

  /// 选择状态模型
  final SelectionModel selectionModel = SelectionModel();

  /// 编辑配置模型
  final EditConfigModel editConfigModel = EditConfigModel();

  /// 对齐线模型
  final SnaplineModel snaplineModel = SnaplineModel();

  /// 事件中心
  final EventCenter eventCenter = EventCenter();

  /// 历史控制器
  final HistoryController historyController = HistoryController();

  // ═══════════════════════════════════════════════════════════════════
  // 属性访问器
  // ═══════════════════════════════════════════════════════════════════

  Size get canvasSize => _canvasSize;
  List<NodeModel> get nodes => List.unmodifiable(_nodes);
  List<EdgeModel> get edges => List.unmodifiable(_edges);

  // ═══════════════════════════════════════════════════════════════════
  // 初始化
  // ═══════════════════════════════════════════════════════════════════

  GraphModel() {
    // 监听子模型变化
    transformModel.addListener(notifyListeners);
    selectionModel.addListener(notifyListeners);
    editConfigModel.addListener(notifyListeners);
  }

  // ═══════════════════════════════════════════════════════════════════
  // 节点操作
  // ═══════════════════════════════════════════════════════════════════

  /// 添加节点
  NodeModel addNode(NodeConfig config) {
    final node = _createNode(config);
    node._graphModel = this;
    _nodeMap[node.id] = node;
    _nodes.add(node);

    eventCenter.emit(EventType.nodeAdd, NodeEventArgs(node: node));
    notifyListeners();

    return node;
  }

  /// 删除节点
  bool removeNode(String nodeId) {
    final node = _nodeMap[nodeId];
    if (node == null) return false;

    // 先删除关联的边
    final connectedEdges = _edges.where((e) =>
      e.sourceId == nodeId || e.targetId == nodeId
    ).toList();

    for (final edge in connectedEdges) {
      removeEdge(edge.id);
    }

    _nodeMap.remove(nodeId);
    _nodes.remove(node);
    selectionModel.deselect(nodeId);

    eventCenter.emit(EventType.nodeDelete, NodeEventArgs(node: node));
    notifyListeners();

    return true;
  }

  /// 获取节点
  NodeModel? getNode(String id) => _nodeMap[id];

  /// 批量添加节点
  void addNodes(List<NodeConfig> configs) {
    for (final config in configs) {
      addNode(config);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 边操作
  // ═══════════════════════════════════════════════════════════════════

  /// 添加边
  EdgeModel addEdge(EdgeConfig config) {
    final edge = _createEdge(config);
    edge._graphModel = this;
    _edgeMap[edge.id] = edge;
    _edges.add(edge);

    eventCenter.emit(EventType.edgeAdd, EdgeEventArgs(edge: edge));
    notifyListeners();

    return edge;
  }

  /// 删除边
  bool removeEdge(String edgeId) {
    final edge = _edgeMap[edgeId];
    if (edge == null) return false;

    _edgeMap.remove(edgeId);
    _edges.remove(edge);

    eventCenter.emit(EventType.edgeDelete, EdgeEventArgs(edge: edge));
    notifyListeners();

    return true;
  }

  /// 获取边
  EdgeModel? getEdge(String id) => _edgeMap[id];

  // ═══════════════════════════════════════════════════════════════════
  // 数据导入导出
  // ═══════════════════════════════════════════════════════════════════

  /// 加载图数据
  void loadData(GraphData data) {
    clear();

    for (final nodeData in data.nodes) {
      addNode(NodeConfig.fromNodeData(nodeData));
    }

    for (final edgeData in data.edges) {
      addEdge(EdgeConfig.fromEdgeData(edgeData));
    }
  }

  /// 导出图数据
  GraphData exportData() {
    return GraphData(
      nodes: _nodes.map((n) => n.toNodeData()).toList(),
      edges: _edges.map((e) => e.toEdgeData()).toList(),
    );
  }

  /// 清空所有数据
  void clear() {
    _nodeMap.clear();
    _edgeMap.clear();
    _nodes.clear();
    _edges.clear();
    selectionModel.clear();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  // 坐标变换
  // ═══════════════════════════════════════════════════════════════════

  /// 屏幕坐标 → 画布坐标
  Offset toScenePoint(Offset screenPoint) {
    return transformModel.toScenePoint(screenPoint);
  }

  /// 画布坐标 → 屏幕坐标
  Offset toScreenPoint(Offset scenePoint) {
    return transformModel.toScreenPoint(scenePoint);
  }

  // ═══════════════════════════════════════════════════════════════════
  // 命中测试
  // ═══════════════════════════════════════════════════════════════════

  /// 命中测试：获取指定位置的元素
  HitTestResult hitTest(Offset scenePoint) {
    // 1. 先检查锚点（最高优先级）
    for (final node in _nodes.reversed) {
      if (node.bounds.contains(scenePoint)) {
        for (final anchor in node.anchors) {
          if (anchor.containsPoint(scenePoint)) {
            return HitTestResult.onAnchor(anchor, node);
          }
        }
      }
    }

    // 2. 检查节点
    for (final node in _nodes.reversed) {
      if (node.bounds.contains(scenePoint)) {
        return HitTestResult.onNode(node);
      }
    }

    // 3. 检查边
    for (final edge in _edges.reversed) {
      if (edge.containsPoint(scenePoint)) {
        return HitTestResult.onEdge(edge);
      }
    }

    return HitTestResult.onCanvas(scenePoint);
  }

  /// 命中测试：获取框选矩形内的节点
  List<NodeModel> hitTestRect(Rect sceneRect) {
    return _nodes.where((node) {
      return sceneRect.overlaps(node.bounds);
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════
  // 内部方法
  // ═══════════════════════════════════════════════════════════════════

  NodeModel _createNode(NodeConfig config) {
    return NodeRegistry.createModel(config);
  }

  EdgeModel _createEdge(EdgeConfig config) {
    return EdgeRegistry.createModel(config);
  }
}
```

---

## 三、NodeModel - 节点模型

```dart
/// 节点模型基类
///
/// 所有节点类型的基础类，提供位置、尺寸、状态等核心属性。
abstract class NodeModel with ChangeNotifier {
  // ═══════════════════════════════════════════════════════════════════
  // 核心数据属性
  // ═══════════════════════════════════════════════════════════════════

  /// 节点 ID
  final String id;

  /// 节点类型
  final String type;

  /// 位置
  Offset _position = Offset.zero;

  /// 尺寸
  Size _size = const Size(100, 80);

  /// 文本
  TextConfig _text = const TextConfig();

  /// 自定义属性
  Map<String, dynamic> properties = {};

  // ═══════════════════════════════════════════════════════════════════
  // 状态属性
  // ═══════════════════════════════════════════════════════════════════

  /// 是否选中
  bool _isSelected = false;

  /// 是否悬停
  bool _isHovered = false;

  /// 是否显示锚点
  bool _isShowAnchor = false;

  /// 是否正在拖动
  bool _isDragging = false;

  /// 是否可交互
  bool _isHittable = true;

  /// 是否可拖动
  bool _isDraggable = true;

  /// 是否可见
  bool _isVisible = true;

  /// 层级
  int _zIndex = 1;

  // ═══════════════════════════════════════════════════════════════════
  // 锚点
  // ═══════════════════════════════════════════════════════════════════

  /// 锚点列表
  final List<AnchorModel> _anchors = [];

  // ═══════════════════════════════════════════════════════════════════
  // 关联引用
  // ═══════════════════════════════════════════════════════════════════

  /// 所属图模型
  GraphModel? _graphModel;

  // ═══════════════════════════════════════════════════════════════════
  // 构造函数
  // ═══════════════════════════════════════════════════════════════════

  NodeModel({
    required this.id,
    required this.type,
    Offset position = Offset.zero,
    Size size = const Size(100, 80),
  }) : _position = position, _size = size {
    _initDefaultAnchors();
  }

  /// 从配置创建
  factory NodeModel.fromConfig(NodeConfig config) {
    return NodeRegistry.createModel(config);
  }

  // ═══════════════════════════════════════════════════════════════════
  // 属性访问器
  // ═══════════════════════════════════════════════════════════════════

  Offset get position => _position;
  double get x => _position.dx;
  double get y => _position.dy;
  Size get size => _size;
  double get width => _size.width;
  double get height => _size.height;
  TextConfig get text => _text;

  bool get isSelected => _isSelected;
  bool get isHovered => _isHovered;
  bool get isShowAnchor => _isShowAnchor;
  bool get isDragging => _isDragging;
  bool get isHittable => _isHittable;
  bool get isDraggable => _isDraggable;
  bool get isVisible => _isVisible;
  int get zIndex => _zIndex;

  List<AnchorModel> get anchors => List.unmodifiable(_anchors);
  GraphModel? get graphModel => _graphModel;

  // ═══════════════════════════════════════════════════════════════════
  // 几何属性
  // ═══════════════════════════════════════════════════════════════════

  /// 边界矩形
  Rect get bounds => Rect.fromLTWH(x, y, width, height);

  /// 中心点
  Offset get center => Offset(x + width / 2, y + height / 2);

  // ═══════════════════════════════════════════════════════════════════
  // 位置操作
  // ═══════════════════════════════════════════════════════════════════

  /// 设置位置
  set position(Offset value) {
    if (_position != value) {
      _position = value;
      _updateAnchorsPosition();
      notifyListeners();
    }
  }

  /// 移动
  void move(double deltaX, double deltaY) {
    position = Offset(x + deltaX, y + deltaY);
  }

  /// 移动到指定位置
  void moveTo(double newX, double newY) {
    position = Offset(newX, newY);
  }

  // ═══════════════════════════════════════════════════════════════════
  // 尺寸操作
  // ═══════════════════════════════════════════════════════════════════

  /// 设置尺寸
  set size(Size value) {
    if (_size != value) {
      _size = value;
      _updateAnchorsPosition();
      notifyListeners();
    }
  }

  /// 调整尺寸
  void resize(double newWidth, double newHeight) {
    size = Size(newWidth, newHeight);
  }

  // ═══════════════════════════════════════════════════════════════════
  // 状态操作
  // ═══════════════════════════════════════════════════════════════════

  void setSelected(bool selected) {
    if (_isSelected != selected) {
      _isSelected = selected;
      notifyListeners();
    }
  }

  void setHovered(bool hovered) {
    if (_isHovered != hovered) {
      _isHovered = hovered;
      if (hovered && _graphModel?.editConfigModel.isEditable == true) {
        _isShowAnchor = true;
      } else if (!hovered && !_isSelected) {
        _isShowAnchor = false;
      }
      notifyListeners();
    }
  }

  void setShowAnchor(bool show) {
    if (_isShowAnchor != show) {
      _isShowAnchor = show;
      notifyListeners();
    }
  }

  void setDragging(bool dragging) {
    if (_isDragging != dragging) {
      _isDragging = dragging;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 锚点管理
  // ═══════════════════════════════════════════════════════════════════

  /// 初始化默认锚点（四边中点）
  void _initDefaultAnchors() {
    _anchors.addAll([
      AnchorModel(
        id: '${id}_top',
        direction: AnchorDirection.top,
        offset: const Offset(0.5, 0), // 相对位置
      ),
      AnchorModel(
        id: '${id}_right',
        direction: AnchorDirection.right,
        offset: const Offset(1, 0.5),
      ),
      AnchorModel(
        id: '${id}_bottom',
        direction: AnchorDirection.bottom,
        offset: const Offset(0.5, 1),
      ),
      AnchorModel(
        id: '${id}_left',
        direction: AnchorDirection.left,
        offset: const Offset(0, 0.5),
      ),
    ]);

    for (final anchor in _anchors) {
      anchor._node = this;
    }
    _updateAnchorsPosition();
  }

  /// 更新锚点绝对位置
  void _updateAnchorsPosition() {
    for (final anchor in _anchors) {
      anchor._updateAbsolutePosition();
    }
  }

  /// 添加自定义锚点
  void addAnchor(AnchorModel anchor) {
    anchor._node = this;
    _anchors.add(anchor);
    anchor._updateAbsolutePosition();
    notifyListeners();
  }

  /// 根据方向获取锚点
  AnchorModel? getAnchor(AnchorDirection direction) {
    for (final anchor in _anchors) {
      if (anchor.direction == direction) {
        return anchor;
      }
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════
  // 几何测试
  // ═══════════════════════════════════════════════════════════════════

  /// 检查点是否在节点内
  bool containsPoint(Offset point) {
    return bounds.contains(point);
  }

  // ═══════════════════════════════════════════════════════════════════
  // 数据序列化
  // ═══════════════════════════════════════════════════════════════════

  /// 转换为 NodeData
  NodeData toNodeData() {
    return NodeData(
      id: id,
      type: type,
      x: x,
      y: y,
      width: width,
      height: height,
      text: text.value,
      properties: Map.from(properties),
    );
  }
}
```

---

## 四、TransformModel - 视口变换模型

```dart
/// 视口变换模型
///
/// 管理画布的缩放和平移状态。
class TransformModel with ChangeNotifier {
  // ═══════════════════════════════════════════════════════════════════
  // 核心属性
  // ═══════════════════════════════════════════════════════════════════

  /// 变换矩阵
  Matrix4 _transform = Matrix4.identity();

  /// 最小缩放
  final double minScale;

  /// 最大缩放
  final double maxScale;

  // ═══════════════════════════════════════════════════════════════════
  // 属性访问器
  // ═══════════════════════════════════════════════════════════════════

  Matrix4 get transform => _transform.clone();

  /// 当前缩放比例
  double get scale => _transform.getMaxScaleOnAxis();

  /// 平移偏移
  Offset get offset => Offset(_transform[12], _transform[13]);

  // ═══════════════════════════════════════════════════════════════════
  // 构造函数
  // ═══════════════════════════════════════════════════════════════════

  TransformModel({
    this.minScale = 0.1,
    this.maxScale = 5.0,
  });

  // ═══════════════════════════════════════════════════════════════════
  // 坐标变换
  // ═══════════════════════════════════════════════════════════════════

  /// 屏幕坐标 → 画布坐标
  Offset toScenePoint(Offset screenPoint) {
    final inverse = Matrix4.tryInvert(_transform) ?? Matrix4.identity();
    return MatrixUtils.transformPoint(inverse, screenPoint);
  }

  /// 画布坐标 → 屏幕坐标
  Offset toScreenPoint(Offset scenePoint) {
    return MatrixUtils.transformPoint(_transform, scenePoint);
  }

  // ═══════════════════════════════════════════════════════════════════
  // 变换操作
  // ═══════════════════════════════════════════════════════════════════

  /// 设置缩放（以画布中心为基准）
  void setScale(double newScale) {
    newScale = newScale.clamp(minScale, maxScale);
    _transform = Matrix4.identity()..scale(newScale);
    notifyListeners();
  }

  /// 缩放（以指定点为基准）
  void zoom(double delta, Offset focalPoint) {
    final newScale = (scale * delta).clamp(minScale, maxScale);
    final ratio = newScale / scale;

    // 计算新的变换矩阵
    // 1. 先平移到焦点
    // 2. 缩放
    // 3. 平移回去
    final matrix = Matrix4.identity()
      ..translate(focalPoint.dx, focalPoint.dy)
      ..scale(ratio)
      ..translate(-focalPoint.dx, -focalPoint.dy);

    _transform = matrix * _transform;
    notifyListeners();
  }

  /// 平移
  void pan(Offset delta) {
    _transform.translate(delta.dx, delta.dy);
    notifyListeners();
  }

  /// 设置平移
  void setOffset(Offset newOffset) {
    _transform[12] = newOffset.dx;
    _transform[13] = newOffset.dy;
    notifyListeners();
  }

  /// 重置变换
  void reset() {
    _transform = Matrix4.identity();
    notifyListeners();
  }

  /// 设置变换矩阵
  void setTransform(Matrix4 matrix) {
    _transform = matrix;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  // 高级操作
  // ═══════════════════════════════════════════════════════════════════

  /// 缩放到适应所有节点
  void fitToContent(List<NodeModel> nodes, Size viewSize, {double padding = 50}) {
    if (nodes.isEmpty) return;

    // 计算内容边界
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final node in nodes) {
      minX = math.min(minX, node.x);
      minY = math.min(minY, node.y);
      maxX = math.max(maxX, node.x + node.width);
      maxY = math.max(maxY, node.y + node.height);
    }

    final contentWidth = maxX - minX + padding * 2;
    final contentHeight = maxY - minY + padding * 2;

    // 计算缩放比例
    final scaleX = viewSize.width / contentWidth;
    final scaleY = viewSize.height / contentHeight;
    final newScale = math.min(scaleX, scaleY).clamp(minScale, maxScale);

    // 计算平移位置（居中）
    final centerX = (minX + maxX) / 2;
    final centerY = (minY + maxY) / 2;
    final offsetX = viewSize.width / 2 - centerX * newScale;
    final offsetY = viewSize.height / 2 - centerY * newScale;

    _transform = Matrix4.identity()
      ..translate(offsetX, offsetY)
      ..scale(newScale);

    notifyListeners();
  }
}
```

---

## 五、SelectionModel - 选择状态模型

```dart
/// 选择状态模型
class SelectionModel with ChangeNotifier {
  // ═══════════════════════════════════════════════════════════════════
  // 核心属性
  // ═══════════════════════════════════════════════════════════════════

  /// 选中的节点 ID 集合
  final Set<String> _selectedNodeIds = {};

  /// 选中的边 ID 集合
  final Set<String> _selectedEdgeIds = {};

  /// 是否正在框选
  bool _isSelecting = false;

  /// 框选矩形（屏幕坐标）
  Rect? _selectionRect;

  // ═══════════════════════════════════════════════════════════════════
  // 属性访问器
  // ═══════════════════════════════════════════════════════════════════

  Set<String> get selectedNodeIds => Set.unmodifiable(_selectedNodeIds);
  Set<String> get selectedEdgeIds => Set.unmodifiable(_selectedEdgeIds);
  bool get isSelecting => _isSelecting;
  Rect? get selectionRect => _selectionRect;

  bool get hasSelection => _selectedNodeIds.isNotEmpty || _selectedEdgeIds.isNotEmpty;
  int get selectedCount => _selectedNodeIds.length + _selectedEdgeIds.length;

  // ═══════════════════════════════════════════════════════════════════
  // 选择操作
  // ═══════════════════════════════════════════════════════════════════

  /// 选中单个节点
  void selectNode(String nodeId, {bool addToSelection = false}) {
    if (!addToSelection) {
      _selectedNodeIds.clear();
      _selectedEdgeIds.clear();
    }

    if (_selectedNodeIds.contains(nodeId)) {
      _selectedNodeIds.remove(nodeId);
    } else {
      _selectedNodeIds.add(nodeId);
    }

    notifyListeners();
  }

  /// 选中多个节点
  void selectNodes(Set<String> nodeIds, {bool replace = true}) {
    if (replace) {
      _selectedNodeIds.clear();
      _selectedEdgeIds.clear();
    }
    _selectedNodeIds.addAll(nodeIds);
    notifyListeners();
  }

  /// 选中边
  void selectEdge(String edgeId, {bool addToSelection = false}) {
    if (!addToSelection) {
      _selectedNodeIds.clear();
      _selectedEdgeIds.clear();
    }
    _selectedEdgeIds.add(edgeId);
    notifyListeners();
  }

  /// 取消选中
  void deselect(String id) {
    _selectedNodeIds.remove(id);
    _selectedEdgeIds.remove(id);
    notifyListeners();
  }

  /// 清空选择
  void clear() {
    _selectedNodeIds.clear();
    _selectedEdgeIds.clear();
    _isSelecting = false;
    _selectionRect = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  // 框选操作
  // ═══════════════════════════════════════════════════════════════════

  /// 开始框选
  void startSelection(Offset startPoint) {
    _isSelecting = true;
    _selectionRect = Rect.fromLTWH(startPoint.dx, startPoint.dy, 0, 0);
    notifyListeners();
  }

  /// 更新框选
  void updateSelection(Offset currentPoint) {
    if (!_isSelecting || _selectionRect == null) return;

    final start = _selectionRect!.topLeft;
    _selectionRect = Rect.fromPoints(start, currentPoint);
    notifyListeners();
  }

  /// 结束框选
  void endSelection() {
    _isSelecting = false;
    _selectionRect = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  // 查询方法
  // ═══════════════════════════════════════════════════════════════════

  bool isNodeSelected(String nodeId) => _selectedNodeIds.contains(nodeId);
  bool isEdgeSelected(String edgeId) => _selectedEdgeIds.contains(edgeId);
}
```

---

## 六、数据类型定义

```dart
/// 节点配置（创建节点时使用）
class NodeConfig {
  final String id;
  final String type;
  final double x;
  final double y;
  final double? width;
  final double? height;
  final String? text;
  final Map<String, dynamic> properties;

  const NodeConfig({
    required this.id,
    required this.type,
    this.x = 0,
    this.y = 0,
    this.width,
    this.height,
    this.text,
    this.properties = const {},
  });

  factory NodeConfig.fromNodeData(NodeData data) {
    return NodeConfig(
      id: data.id,
      type: data.type,
      x: data.x ?? 0,
      y: data.y ?? 0,
      width: data.width,
      height: data.height,
      text: data.text,
      properties: Map<String, dynamic>.from(data.properties ?? {}),
    );
  }
}

/// 节点数据（序列化格式）
class NodeData {
  final String id;
  final String type;
  final double? x;
  final double? y;
  final double? width;
  final double? height;
  final String? text;
  final Map<String, dynamic>? properties;

  const NodeData({
    required this.id,
    required this.type,
    this.x,
    this.y,
    this.width,
    this.height,
    this.text,
    this.properties,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'text': text,
      'properties': properties,
    };
  }
}

/// 图数据
class GraphData {
  final List<NodeData> nodes;
  final List<EdgeData> edges;

  const GraphData({
    this.nodes = const [],
    this.edges = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'nodes': nodes.map((n) => n.toJson()).toList(),
      'edges': edges.map((e) => e.toJson()).toList(),
    };
  }
}
```

---

*文档版本: 1.0*
*最后更新: 2025-06-26*
