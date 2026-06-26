# 图编辑器重构方案 v2.0

基于 LogicFlow 成熟架构重新设计 Bkdmm 图编辑器。

---

## 一、架构对比

### 1.1 V1 架构问题

| 问题 | 描述 |
|------|------|
| 事件处理分散 | ~400 行事件代码分散在画布、节点、锚点三个 Widget |
| Widget 耦合 | ER 特定逻辑与通用画布逻辑混合 |
| 状态管理混乱 | UI 状态与数据状态未分离 |
| 无扩展机制 | 添加新图表类型需要大量修改 |

### 1.2 LogicFlow 架构优点

| 特性 | 说明 |
|------|------|
| Model-View 分离 | 数据模型与渲染视图完全分离 |
| 事件中心 | 统一的事件发射器管理所有事件 |
| 插件系统 | 通过注册机制扩展节点/边类型 |
| 响应式状态 | MobX 提供细粒度响应式更新 |

---

## 二、新架构设计

### 2.1 核心架构图

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           DiagramEditor (入口)                           │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                        GraphModel (数据模型)                      │   │
│  │  ├── nodes: Map<String, NodeModel>                               │   │
│  │  ├── edges: Map<String, EdgeModel>                               │   │
│  │  ├── transformModel: TransformModel (视口变换)                   │   │
│  │  ├── selectionModel: SelectionModel (选择状态)                   │   │
│  │  └── editConfigModel: EditConfigModel (编辑配置)                 │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                     │
│                                    │ 响应式更新                           │
│                                    ▼                                     │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                        GraphView (渲染视图)                        │   │
│  │  ├── CanvasOverlay (画布层 - 节点和边)                            │   │
│  │  ├── ModificationOverlay (交互层 - 框选、连线预览)                │   │
│  │  ├── ToolOverlay (工具层 - 工具栏)                                │   │
│  │  ├── GridOverlay (网格层)                                        │   │
│  │  └── BackgroundOverlay (背景层)                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                     │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                     EventCenter (事件中心)                        │   │
│  │  ├── on(event, callback)                                         │   │
│  │  ├── emit(event, args)                                           │   │
│  │  └── off(event, callback)                                        │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                     HistoryController (历史记录)                   │   │
│  │  ├── undo() / redo()                                             │   │
│  │  └── execute(command)                                            │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 文件结构

```
lib/shared/diagram_editor/
├── src/
│   ├── DiagramEditor.dart           # 主入口类
│   │
│   ├── model/                        # 数据模型层
│   │   ├── GraphModel.dart           # 图数据模型
│   │   ├── NodeModel.dart            # 节点模型基类
│   │   ├── EdgeModel.dart            # 边模型基类
│   │   ├── TransformModel.dart       # 视口变换模型
│   │   ├── SelectionModel.dart       # 选择状态模型
│   │   └── EditConfigModel.dart      # 编辑配置模型
│   │
│   ├── view/                         # 渲染视图层
│   │   ├── GraphView.dart            # 主视图
│   │   ├── CanvasOverlay.dart        # 画布层
│   │   ├── ModificationOverlay.dart  # 交互层
│   │   ├── ToolOverlay.dart          # 工具层
│   │   ├── overlay/
│   │   │   ├── GridOverlay.dart      # 网格
│   │   │   └── BackgroundOverlay.dart # 背景
│   │   ├── node/
│   │   │   ├── BaseNode.dart         # 节点渲染基类
│   │   │   └── NodeRegistry.dart     # 节点注册表
│   │   └── edge/
│   │       ├── BaseEdge.dart         # 边渲染基类
│   │       └── EdgeRegistry.dart     # 边注册表
│   │
│   ├── event/                        # 事件系统
│   │   ├── EventCenter.dart          # 事件发射器
│   │   ├── EventTypes.dart           # 事件类型定义
│   │   └── EventArgs.dart            # 事件参数定义
│   │
│   ├── history/                      # 历史记录
│   │   ├── HistoryController.dart    # 历史控制器
│   │   └── commands/                 # 命令实现
│   │       ├── MoveNodeCommand.dart
│   │       ├── AddEdgeCommand.dart
│   │       └── DeleteElementsCommand.dart
│   │
│   ├── behavior/                     # 交互行为
│   │   ├── DragBehavior.dart         # 拖动行为
│   │   ├── SelectionBehavior.dart    # 选择行为
│   │   ├── ConnectionBehavior.dart   # 连线行为
│   │   └── PanZoomBehavior.dart      # 平移缩放行为
│   │
│   ├── util/                         # 工具函数
│   │   ├── geometry.dart             # 几何计算
│   │   ├── matrix.dart               # 矩阵变换
│   │   └── uuid.dart                 # ID 生成
│   │
│   └── constant/                     # 常量定义
│       ├── ElementType.dart          # 元素类型
│       ├── EventType.dart            # 事件类型
│       └── ModelType.dart            # 模型类型
│
├── diagram_editor.dart               # 导出文件
└── README.md
```

---

## 三、核心类设计

### 3.1 GraphModel - 图数据模型

```dart
/// 图数据模型 - 所有数据的单一来源
class GraphModel with ChangeNotifier {
  /// 节点映射表
  final Map<String, NodeModel> _nodes = {};

  /// 边映射表
  final Map<String, EdgeModel> _edges = {};

  /// 视口变换模型
  final TransformModel transformModel;

  /// 选择状态模型
  final SelectionModel selectionModel;

  /// 编辑配置模型
  final EditConfigModel editConfigModel;

  /// 事件中心
  final EventCenter eventCenter;

  // ═══════════════════════════════════════════════════════════════════
  // 节点操作
  // ═══════════════════════════════════════════════════════════════════

  /// 添加节点
  NodeModel addNode(NodeConfig config) {
    final node = _createNode(config);
    _nodes[node.id] = node;
    eventCenter.emit(EventType.nodeAdd, NodeEventArgs(node: node));
    notifyListeners();
    return node;
  }

  /// 删除节点
  void removeNode(String nodeId) {
    final node = _nodes[nodeId];
    if (node != null) {
      // 先删除关联的边
      _removeEdgesByNode(nodeId);
      _nodes.remove(nodeId);
      eventCenter.emit(EventType.nodeDelete, NodeEventArgs(node: node));
      notifyListeners();
    }
  }

  /// 获取节点
  NodeModel? getNode(String id) => _nodes[id];

  /// 获取所有节点
  List<NodeModel> get nodes => _nodes.values.toList();

  // ═══════════════════════════════════════════════════════════════════
  // 边操作
  // ═══════════════════════════════════════════════════════════════════

  /// 添加边
  EdgeModel addEdge(EdgeConfig config) {
    final edge = _createEdge(config);
    _edges[edge.id] = edge;
    eventCenter.emit(EventType.edgeAdd, EdgeEventArgs(edge: edge));
    notifyListeners();
    return edge;
  }

  /// 删除边
  void removeEdge(String edgeId) {
    final edge = _edges[edgeId];
    if (edge != null) {
      _edges.remove(edgeId);
      eventCenter.emit(EventType.edgeDelete, EdgeEventArgs(edge: edge));
      notifyListeners();
    }
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

  /// 命中测试：获取指定位置的节点
  NodeModel? hitTestNode(Offset scenePoint) {
    // 从上层到下层遍历（后添加的在上层）
    for (final node in nodes.reversed) {
      if (node.containsPoint(scenePoint)) {
        return node;
      }
    }
    return null;
  }

  /// 命中测试：获取指定位置的锚点
  AnchorModel? hitTestAnchor(Offset scenePoint) {
    // 先找到节点，再检查锚点
    for (final node in nodes.reversed) {
      if (node.containsPoint(scenePoint)) {
        for (final anchor in node.anchors) {
          if (anchor.containsPoint(scenePoint)) {
            return anchor;
          }
        }
      }
    }
    return null;
  }

  /// 命中测试：获取指定位置的边
  EdgeModel? hitTestEdge(Offset scenePoint) {
    for (final edge in edges.reversed) {
      if (edge.containsPoint(scenePoint)) {
        return edge;
      }
    }
    return null;
  }
}
```

### 3.2 NodeModel - 节点模型

```dart
/// 节点模型基类
abstract class NodeModel with ChangeNotifier {
  /// 节点 ID
  final String id;

  /// 节点类型
  final String type;

  /// 位置
  Offset _position;

  /// 尺寸
  Size _size;

  /// 锚点列表
  final List<AnchorModel> _anchors = [];

  /// 是否选中
  bool _isSelected = false;

  /// 是否悬停
  bool _isHovered = false;

  /// 是否显示锚点
  bool _isShowAnchor = false;

  /// 自定义属性
  Map<String, dynamic> properties = {};

  /// 所属图模型
  GraphModel? _graphModel;

  // ═══════════════════════════════════════════════════════════════════
  // 属性访问器
  // ═══════════════════════════════════════════════════════════════════

  Offset get position => _position;
  set position(Offset value) {
    if (_position != value) {
      _position = value;
      notifyListeners();
    }
  }

  double get x => _position.dx;
  double get y => _position.dy;

  Size get size => _size;
  set size(Size value) {
    if (_size != value) {
      _size = value;
      _updateAnchors();
      notifyListeners();
    }
  }

  double get width => _size.width;
  double get height => _size.height;

  bool get isSelected => _isSelected;
  bool get isHovered => _isHovered;
  bool get isShowAnchor => _isShowAnchor;

  List<AnchorModel> get anchors => List.unmodifiable(_anchors);

  // ═══════════════════════════════════════════════════════════════════
  // 状态控制
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
      notifyListeners();
    }
  }

  void setShowAnchor(bool show) {
    if (_isShowAnchor != show) {
      _isShowAnchor = show;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 几何计算
  // ═══════════════════════════════════════════════════════════════════

  /// 获取边界矩形
  Rect get bounds => Rect.fromLTWH(x, y, width, height);

  /// 检查点是否在节点内
  bool containsPoint(Offset point) {
    return bounds.contains(point);
  }

  /// 移动节点
  void move(double deltaX, double deltaY) {
    position = Offset(x + deltaX, y + deltaY);
  }

  // ═══════════════════════════════════════════════════════════════════
  // 锚点管理
  // ═══════════════════════════════════════════════════════════════════

  /// 添加锚点
  void addAnchor(AnchorModel anchor) {
    _anchors.add(anchor);
    anchor._node = this;
  }

  /// 根据方向获取锚点
  AnchorModel? getAnchorByDirection(AnchorDirection direction) {
    for (final anchor in _anchors) {
      if (anchor.direction == direction) {
        return anchor;
      }
    }
    return null;
  }

  /// 更新锚点位置（子类重写）
  void _updateAnchors() {
    // 默认实现：四边中点锚点
    for (final anchor in _anchors) {
      anchor._updatePosition();
    }
  }
}
```

### 3.3 EventCenter - 事件中心

```dart
/// 事件回调类型
typedef EventCallback<T> = void Function(T args);

/// 事件中心 - 统一管理所有事件
class EventCenter {
  final Map<String, List<_EventHandler>> _handlers = {};

  /// 监听事件
  void on<T>(String eventType, EventCallback<T> callback, {bool once = false}) {
    _handlers.putIfAbsent(eventType, () => []);
    _handlers[eventType]!.add(_EventHandler(
      callback: callback,
      once: once,
    ));
  }

  /// 监听一次
  void once<T>(String eventType, EventCallback<T> callback) {
    on(eventType, callback, once: true);
  }

  /// 触发事件
  void emit<T>(String eventType, T args) {
    final handlers = _handlers[eventType];
    if (handlers == null) return;

    // 处理 once 标记
    handlers.removeWhere((handler) {
      handler.call(args);
      return handler.once;
    });
  }

  /// 取消监听
  void off<T>(String eventType, [EventCallback<T>? callback]) {
    if (callback == null) {
      _handlers.remove(eventType);
    } else {
      _handlers[eventType]?.removeWhere((h) => h.callback == callback);
    }
  }

  /// 清除所有事件
  void clear() {
    _handlers.clear();
  }
}

class _EventHandler {
  final EventCallback callback;
  final bool once;

  _EventHandler({required this.callback, this.once = false});

  void call(dynamic args) {
    callback(args);
  }
}
```

### 3.4 GraphView - 主视图

```dart
/// 主视图 - 组合所有渲染层
class GraphView extends StatelessWidget {
  final GraphModel graphModel;

  const GraphView({
    super.key,
    required this.graphModel,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: graphModel,
      builder: (context, child) {
        return Stack(
          children: [
            // 1. 背景层
            BackgroundOverlay(graphModel: graphModel),

            // 2. 网格层
            GridOverlay(graphModel: graphModel),

            // 3. 画布层（节点和边）
            CanvasOverlay(graphModel: graphModel),

            // 4. 交互层（框选、连线预览）
            ModificationOverlay(graphModel: graphModel),

            // 5. 工具层
            ToolOverlay(graphModel: graphModel),
          ],
        );
      },
    );
  }
}
```

### 3.5 CanvasOverlay - 画布层

```dart
/// 画布层 - 渲染节点和边
class CanvasOverlay extends StatelessWidget {
  final GraphModel graphModel;

  const CanvasOverlay({
    super.key,
    required this.graphModel,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) => _handlePointerDown(event),
      onPointerMove: (event) => _handlePointerMove(event),
      onPointerUp: (event) => _handlePointerUp(event),
      child: CustomPaint(
        painter: _EdgePainter(graphModel),
        child: Stack(
          clipBehavior: Clip.none,
          children: graphModel.nodes.map((node) {
            return Positioned(
              left: node.x,
              top: node.y,
              child: _buildNodeWidget(node),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNodeWidget(NodeModel node) {
    // 从注册表获取对应的视图组件
    final viewBuilder = NodeRegistry.getBuilder(node.type);
    return viewBuilder(node, graphModel);
  }

  void _handlePointerDown(PointerDownEvent event) {
    // 转换坐标
    final scenePoint = graphModel.toScenePoint(event.localPosition);

    // 命中测试
    final hitNode = graphModel.hitTestNode(scenePoint);
    final hitAnchor = graphModel.hitTestAnchor(scenePoint);

    if (hitAnchor != null) {
      // 锚点点击事件
      graphModel.eventCenter.emit(
        EventType.anchorClick,
        AnchorEventArgs(anchor: hitAnchor, event: event),
      );
    } else if (hitNode != null) {
      // 节点点击事件
      graphModel.eventCenter.emit(
        EventType.nodeClick,
        NodeEventArgs(node: hitNode, event: event),
      );
    } else {
      // 画布点击事件
      graphModel.eventCenter.emit(
        EventType.canvasClick,
        CanvasEventArgs(position: scenePoint, event: event),
      );
    }
  }
}
```

---

## 四、交互行为设计

### 4.1 行为注册机制

```dart
/// 交互行为基类
abstract class DiagramBehavior {
  /// 行为名称
  String get name;

  /// 行为优先级（数值越小优先级越高）
  int get priority;

  /// 是否可以处理该事件
  bool canHandle(DiagramEvent event, GraphModel graphModel);

  /// 处理事件
  void handle(DiagramEvent event, GraphModel graphModel);

  /// 重置状态
  void reset();
}

/// 行为管理器
class BehaviorManager {
  final List<DiagramBehavior> _behaviors = [];

  /// 注册行为
  void register(DiagramBehavior behavior) {
    _behaviors.add(behavior);
    _behaviors.sort((a, b) => a.priority.compareTo(b.priority));
  }

  /// 分发事件
  void dispatch(DiagramEvent event, GraphModel graphModel) {
    for (final behavior in _behaviors) {
      if (behavior.canHandle(event, graphModel)) {
        behavior.handle(event, graphModel);
        break; // 只由第一个匹配的行为处理
      }
    }
  }

  /// 重置所有行为
  void resetAll() {
    for (final behavior in _behaviors) {
      behavior.reset();
    }
  }
}
```

### 4.2 内置行为

| 行为 | 优先级 | 说明 |
|------|:------:|------|
| AnchorClickBehavior | 10 | 锚点点击（开始/结束连线） |
| NodeDragBehavior | 20 | 节点拖动 |
| ConnectionBehavior | 30 | 连线创建 |
| SelectionBehavior | 50 | 框选 |
| CanvasPanBehavior | 100 | 画布平移（最低优先级） |

---

## 五、ER 图实现

### 5.1 ER 节点模型

```dart
/// ER 表节点模型
class ERTableNodeModel extends NodeModel {
  /// 实体数据
  final Entity entity;

  /// 字段锚点
  final Map<int, ERFieldAnchor> _fieldAnchors = {};

  ERTableNodeModel({
    required String id,
    required this.entity,
    required Offset position,
  }) : super(id: id, type: 'er-table', position: position) {
    _initFieldAnchors();
  }

  void _initFieldAnchors() {
    for (var i = 0; i < entity.fields.length; i++) {
      _fieldAnchors[i] = ERFieldAnchor(
        fieldIndex: i,
        direction: AnchorDirection.left, // 默认左边
        isPrimaryKey: entity.fields[i].pk,
      );
    }
  }

  /// 计算节点高度
  double calculateHeight() {
    return ERTableNodeWidget.headerHeight +
        (entity.fields.length * ERTableNodeWidget.fieldRowHeight);
  }
}
```

### 5.2 ER 节点视图

```dart
/// ER 表节点视图
class ERTableNodeWidget extends StatelessWidget {
  final ERTableNodeModel model;
  final GraphModel graphModel;

  static const double defaultWidth = 200.0;
  static const double headerHeight = 40.0;
  static const double fieldRowHeight = 28.0;

  const ERTableNodeWidget({
    super.key,
    required this.model,
    required this.graphModel,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: model,
      builder: (context, child) {
        return MouseRegion(
          cursor: graphModel.editConfigModel.isEditable
              ? SystemMouseCursors.grab
              : MouseCursor.defer,
          child: Container(
            width: defaultWidth,
            decoration: _buildDecoration(context),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildContent(context),
                if (graphModel.editConfigModel.isEditable)
                  _buildAnchorLayer(context),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

### 5.3 ER 图注册

```dart
/// 注册 ER 图节点和边
void registerERDiagram(DiagramEditor editor) {
  // 注册节点
  editor.registerNode(
    type: 'er-table',
    model: ERTableNodeModel.new,
    view: (model, graphModel) => ERTableNodeWidget(
      model: model as ERTableNodeModel,
      graphModel: graphModel,
    ),
  );

  // 注册边
  editor.registerEdge(
    type: 'er-relation',
    model: ERRelationEdgeModel.new,
    view: (model, graphModel) => ERRelationEdgeWidget(
      model: model as ERRelationEdgeModel,
      graphModel: graphModel,
    ),
  );
}
```

---

## 六、迁移计划

### Phase 1: 核心框架 (3-4 天)

| 任务 | 文件 | 说明 |
|------|------|------|
| 事件中心 | `EventCenter.dart` | 统一事件管理 |
| 数据模型基类 | `GraphModel.dart`, `NodeModel.dart`, `EdgeModel.dart` | 响应式数据模型 |
| 视口变换 | `TransformModel.dart` | 缩放和平移 |
| 选择状态 | `SelectionModel.dart` | 选择管理 |
| 编辑配置 | `EditConfigModel.dart` | 模式配置 |

### Phase 2: 渲染层 (2-3 天)

| 任务 | 文件 | 说明 |
|------|------|------|
| 主视图 | `GraphView.dart` | 组合渲染层 |
| 画布层 | `CanvasOverlay.dart` | 节点和边渲染 |
| 交互层 | `ModificationOverlay.dart` | 框选、连线预览 |
| 网格层 | `GridOverlay.dart` | 无限网格 |
| 节点注册 | `NodeRegistry.dart` | 节点类型注册 |

### Phase 3: 交互行为 (2-3 天)

| 任务 | 文件 | 说明 |
|------|------|------|
| 行为管理 | `BehaviorManager.dart` | 行为分发 |
| 节点拖动 | `NodeDragBehavior.dart` | 拖动移动 |
| 框选 | `SelectionBehavior.dart` | 框选多选 |
| 连线 | `ConnectionBehavior.dart` | 创建连线 |
| 平移缩放 | `PanZoomBehavior.dart` | 画布操作 |

### Phase 4: ER 图迁移 (2-3 天)

| 任务 | 说明 |
|------|------|
| ER 节点模型 | 实现 `ERTableNodeModel` |
| ER 节点视图 | 实现 `ERTableNodeWidget` |
| ER 边模型 | 实现 `ERRelationEdgeModel` |
| ER 边视图 | 实现 `ERRelationEdgeWidget` |
| 集成测试 | 验证所有功能 |

### Phase 5: 清理和扩展 (1-2 天)

| 任务 | 说明 |
|------|------|
| 删除旧代码 | 移除 V1 实现 |
| 文档更新 | API 文档 |
| 扩展准备 | 为流程图预留接口 |

---

## 七、关键设计决策

### 7.1 为什么不用 InteractiveViewer？

**问题**：InteractiveViewer 会拦截所有手势事件，导致子组件无法正确接收事件。

**解决方案**：完全手动处理视口变换：

```dart
class TransformModel with ChangeNotifier {
  Matrix4 _transform = Matrix4.identity();

  double get scale => _transform.getMaxScaleOnAxis();
  Offset get offset => Offset(_transform[12], _transform[13]);

  Offset toScenePoint(Offset screenPoint) {
    final inverse = Matrix4.tryInvert(_transform) ?? Matrix4.identity();
    return MatrixUtils.transformPoint(inverse, screenPoint);
  }

  Offset toScreenPoint(Offset scenePoint) {
    return MatrixUtils.transformPoint(_transform, scenePoint);
  }

  void zoom(double delta, Offset focalPoint) {
    // 以 focalPoint 为中心缩放
    final newScale = (scale * delta).clamp(0.1, 5.0);
    // ... 计算新的变换矩阵
    notifyListeners();
  }

  void pan(Offset delta) {
    _transform.translate(delta.dx, delta.dy);
    notifyListeners();
  }
}
```

### 7.2 为什么用 Model-View 分离？

| 好处 | 说明 |
|------|------|
| 状态一致性 | 单一数据源，避免状态不同步 |
| 易于测试 | 可以独立测试 Model 逻辑 |
| 性能优化 | 只有变化的部分重新渲染 |
| 扩展性 | 新图表类型只需实现 Model 和 View |

### 7.3 事件系统设计

参考 LogicFlow 的事件中心设计：

```dart
// 事件类型
abstract class EventType {
  // 节点事件
  static const nodeAdd = 'node:add';
  static const nodeDelete = 'node:delete';
  static const nodeClick = 'node:click';
  static const nodeDoubleClick = 'node:doubleClick';
  static const nodeDragStart = 'node:dragStart';
  static const nodeDrag = 'node:drag';
  static const nodeDragEnd = 'node:dragEnd';

  // 边事件
  static const edgeAdd = 'edge:add';
  static const edgeDelete = 'edge:delete';
  static const edgeClick = 'edge:click';

  // 锚点事件
  static const anchorClick = 'anchor:click';

  // 画布事件
  static const canvasClick = 'canvas:click';
  static const canvasDrag = 'canvas:drag';

  // 图事件
  static const graphUpdated = 'graph:updated';
}
```

---

## 八、性能优化

### 8.1 局部渲染

```dart
class CanvasOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 只渲染可见区域内的节点
    final visibleNodes = graphModel.nodes.where((node) {
      return _isNodeVisible(node, graphModel.transformModel);
    }).toList();

    return Stack(
      children: visibleNodes.map((node) => _buildNode(node)).toList(),
    );
  }

  bool _isNodeVisible(NodeModel node, TransformModel transform) {
    final viewport = transform.viewport;
    final nodeBounds = node.bounds;
    return viewport.overlaps(nodeBounds);
  }
}
```

### 8.2 虚拟化

对于大量节点（100+），使用虚拟列表：

```dart
class VirtualizedCanvas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return VirtualScrollView(
      itemCount: graphModel.nodes.length,
      itemBuilder: (context, index) {
        final node = graphModel.nodes[index];
        return _buildNode(node);
      },
    );
  }
}
```

---

## 九、与 V1 对比

| 方面 | V1 | V2 |
|------|-----|-----|
| **事件处理** | 分散在 Widget 中 | EventCenter 统一管理 |
| **状态管理** | Provider + 混合状态 | ChangeNotifier Model |
| **视口变换** | InteractiveViewer | 手动 TransformModel |
| **节点扩展** | 修改画布代码 | 注册机制 |
| **测试性** | 需要 Widget 测试 | Model 可独立测试 |
| **性能** | 全量渲染 | 局部渲染 + 虚拟化 |

---

*文档版本: 2.0*
*基于 LogicFlow 架构设计*
*最后更新: 2025-06-26*
