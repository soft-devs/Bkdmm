# 图编辑器核心架构思想

从 LogicFlow 项目提取的核心架构思想，适配 Flutter 实现。

---

## 一、核心设计理念

### 1.1 Model-View 完全分离

**核心思想**：数据模型是单一数据源，视图只是数据的渲染表现。

```
┌─────────────────────────────────────────────────────────────┐
│                    Model (数据层)                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ GraphModel                                          │   │
│  │  - nodes: List<NodeModel>      // 所有节点数据      │   │
│  │  - edges: List<EdgeModel>      // 所有边数据        │   │
│  │  - transformModel              // 视口变换状态      │   │
│  │  - selectionModel              // 选择状态          │   │
│  │  - editConfigModel             // 编辑配置          │   │
│  │                                                      │   │
│  │  所有数据变更都通过 Model 方法进行                   │   │
│  │  Model 变更后通知 View 重绘                         │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                                 │
│                           │ notifyListeners()               │
│                           ▼                                 │
┌─────────────────────────────────────────────────────────────┐
│                    View (渲染层)                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ GraphView                                           │   │
│  │  - 读取 Model 数据进行渲染                          │   │
│  │  - 不直接修改数据                                   │   │
│  │  - 用户操作转换为事件，发送给 Controller            │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

**LogicFlow 实现方式**：
- 使用 MobX 的 `@observable` 让数据可观察
- View 使用 `@observer` 自动响应数据变化

**Flutter 适配方式**：
- Model 使用 `ChangeNotifier` (或 Riverpod 的 `StateNotifier`)
- View 使用 `ListenableBuilder` / `Consumer` / `watch` 响应变化

### 1.2 事件中心统一管理

**核心思想**：所有交互事件通过统一的事件中心分发，避免 Widget 回调链耦合。

```
┌─────────────────────────────────────────────────────────────┐
│                    EventCenter                               │
│                                                              │
│  _handlers: Map<String, List<EventHandler>>                 │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐ │
│  │ 'node:click'     → [handler1, handler2, ...]          │ │
│  │ 'node:drag'      → [handler3, ...]                    │ │
│  │ 'edge:add'       → [handler4, ...]                    │ │
│  │ '*'              → [wildcardHandler]  // 监听所有     │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                              │
│  方法：                                                      │
│  - on(event, callback)      // 监听事件                     │
│  - once(event, callback)    // 监听一次                     │
│  - emit(event, args)        // 触发事件                     │
│  - off(event, callback?)    // 取消监听                     │
└─────────────────────────────────────────────────────────────┘
         │
         │ emit('node:click', NodeEventArgs)
         ▼
┌────────────────┐  ┌────────────────┐  ┌────────────────┐
│   Widget A     │  │   Behavior B   │  │   Plugin C     │
│   监听渲染     │  │   监听交互     │  │   监听扩展     │
└────────────────┘  └────────────────┘  └────────────────┘
```

**LogicFlow 实现方式**：
- `EventEmitter` 类，支持逗号分隔多事件、通配符监听
- 事件触发时，按注册顺序调用所有 handler

**Flutter 适配方式**：
- Dart 的 `Stream` / `StreamController` 可实现类似功能
- 或自定义 `EventCenter` 类，保持与 LogicFlow 一致的 API

---

## 二、关键组件设计

### 2.1 GraphModel - 图数据模型

**核心职责**：
- 管理所有节点和边的数据
- 提供坐标转换方法（屏幕坐标 ↔ 画布坐标）
- 提供命中测试方法（点击位置判断落在哪个元素上）
- 触发数据变更事件

**LogicFlow 关键实现** (GraphModel.ts):

```typescript
// 响应式数据
@observable nodes: BaseNodeModel[] = []
@observable edges: BaseEdgeModel[] = []
@observable transformModel: TransformModel
@observable editConfigModel: EditConfigModel

// 坐标转换：屏幕坐标 → 画布坐标
HtmlPointToCanvasPoint(point: [x, y]): [x, y] {
  return [
    (x - TRANSLATE_X) / SCALE_X,
    (y - TRANSLATE_Y) / SCALE_Y,
  ]
}

// 坐标转换：画布坐标 → 屏幕坐标
CanvasPointToHtmlPoint(point: [x, y]): [x, y] {
  return [
    x * SCALE_X + TRANSLATE_X,
    y * SCALE_Y + TRANSLATE_Y,
  ]
}

// 添加节点：触发事件
@action addNode(nodeConfig) {
  const nodeModel = this.getModelAfterSnapToGrid(nodeConfig)
  this.nodes.push(nodeModel)
  this.eventCenter.emit(EventType.NODE_ADD, { data: nodeModel.getData() })
  return nodeModel
}
```

**Flutter 适配**：

```dart
class GraphModel extends ChangeNotifier {
  final List<NodeModel> _nodes = [];
  final List<EdgeModel> _edges = [];
  final TransformModel transformModel = TransformModel();
  final EventCenter eventCenter = EventCenter();

  List<NodeModel> get nodes => List.unmodifiable(_nodes);
  List<EdgeModel> get edges => List.unmodifiable(_edges);

  // 坐标转换
  Offset toCanvasPoint(Offset screenPoint) {
    final t = transformModel;
    return Offset(
      (screenPoint.dx - t.translateX) / t.scaleX,
      (screenPoint.dy - t.translateY) / t.scaleY,
    );
  }

  Offset toScreenPoint(Offset canvasPoint) {
    final t = transformModel;
    return Offset(
      canvasPoint.dx * t.scaleX + t.translateX,
      canvasPoint.dy * t.scaleY + t.translateY,
    );
  }

  // 添加节点
  void addNode(NodeConfig config) {
    final nodeModel = createNodeModel(config);
    _nodes.add(nodeModel);
    eventCenter.emit(EventType.nodeAdd, NodeEventArgs(node: nodeModel));
    notifyListeners();
  }
}
```

### 2.2 TransformModel - 视口变换模型

**核心思想**：不使用 Flutter 的 InteractiveViewer，手动管理缩放和平移。

**为什么不用 InteractiveViewer**：
- InteractiveViewer 会拦截所有手势事件
- 无法精细控制事件分发优先级
- 无法实现自定义的缩放/平移逻辑

**LogicFlow 实现** (TransformModel.ts):

```typescript
@observable SCALE_X = 1       // X轴缩放
@observable SCALE_Y = 1       // Y轴缩放
@observable TRANSLATE_X = 0   // X轴偏移
@observable TRANSLATE_Y = 0   // Y轴偏移

// 缩放：以指定点为中心
@action zoom(zoomSize, point?: [x, y]) {
  let newScale = this.SCALE_X + (zoomSize ? ZOOM_SIZE : -ZOOM_SIZE)
  if (newScale < MINI_SCALE_SIZE || newScale > MAX_SCALE_SIZE) return

  if (point) {
    // 保持 focalPoint 在屏幕上的位置不变
    this.TRANSLATE_X -= (newScale - this.SCALE_X) * point[0]
    this.TRANSLATE_Y -= (newScale - this.SCALE_Y) * point[1]
  }

  this.SCALE_X = newScale
  this.SCALE_Y = newScale
  this.emitGraphTransform('zoom')
}

// 平移
@action translate(x, y) {
  this.TRANSLATE_X += x
  this.TRANSLATE_Y += y
  this.emitGraphTransform('translate')
}
```

**Flutter 适配**：

```dart
class TransformModel extends ChangeNotifier {
  double scaleX = 1.0;
  double scaleY = 1.0;
  double translateX = 0.0;
  double translateY = 0.0;

  static const double zoomStep = 0.1;
  static const double minScale = 0.2;
  static const double maxScale = 16.0;

  // 缩放：以 focalPoint 为中心
  void zoom(bool zoomIn, Offset? focalPoint) {
    final delta = zoomIn ? zoomStep : -zoomStep;
    final newScale = scaleX + delta;

    if (newScale < minScale || newScale > maxScale) return;

    if (focalPoint != null) {
      // focalPoint 在屏幕上的位置保持不变
      translateX -= (newScale - scaleX) * focalPoint.dx;
      translateY -= (newScale - scaleY) * focalPoint.dy;
    }

    scaleX = newScale;
    scaleY = newScale;
    notifyListeners();
  }

  // 平移
  void pan(Offset delta) {
    translateX += delta.dx;
    translateY += delta.dy;
    notifyListeners();
  }

  // 获取变换矩阵（用于 CustomPaint）
  Matrix4 get matrix => Matrix4.identity()
    .translate(translateX, translateY)
    .scale(scaleX, scaleY);
}
```

### 2.3 NodeModel - 节点数据模型

**核心思想**：节点包含位置、尺寸、状态，以及自定义属性。

**LogicFlow 关键属性** (BaseNodeModel.ts):

```typescript
@observable x = 0          // X坐标（画布坐标系）
@observable y = 0          // Y坐标
@observable _width = 100   // 宽度
@observable _height = 80   // 高度

// 状态属性
@observable isSelected = false
@observable isHovered = false
@observable isDragging = false
@observable isShowAnchor = false

// 自定义属性
@observable properties: P

// 锚点配置（相对于节点中心的偏移）
@observable anchorsOffset: [offsetX, offsetY][] = []

// 移动节点
@action move(deltaX, deltaY) {
  if (!this.isAllowMoveNode(deltaX, deltaY)) return false
  this.x += deltaX
  this.y += deltaY
  return true
}

// 获取锚点位置
get anchors(): AnchorConfig[] {
  return this.anchorsOffset.map(([ox, oy], idx) => ({
    id: `${this.id}_${idx}`,
    x: this.x + ox,
    y: this.y + oy,
  }))
}
```

**Flutter 适配**：

```dart
class NodeModel extends ChangeNotifier {
  String id;
  String type;
  double x, y;
  double width, height;

  // 状态
  bool isSelected = false;
  bool isHovered = false;
  bool isDragging = false;
  bool isShowAnchor = false;

  // 自定义属性
  Map<String, dynamic> properties = {};

  // 锚点偏移（相对于节点中心）
  List<Offset> anchorsOffset = [];

  // 移动节点
  void move(double deltaX, double deltaY) {
    x += deltaX;
    y += deltaY;
    notifyListeners();
  }

  // 获取锚点绝对位置
  List<AnchorModel> get anchors {
    return anchorsOffset.asMap().entries.map((entry) {
      return AnchorModel(
        id: '${id}_${entry.key}',
        x: x + entry.value.dx,
        y: y + entry.value.dy,
      );
    }).toList();
  }
}
```

---

## 三、渲染分层架构

**核心思想**：画布按功能分层，每层独立渲染，减少重绘范围。

```
┌─────────────────────────────────────────────────────────────┐
│                      Graph (容器)                            │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ CanvasOverlay (画布层 - SVG/CustomPaint)            │   │
│  │  - 渲染所有节点和边                                  │   │
│  │  - 应用 transformModel 的变换                       │   │
│  │  - 最底层                                            │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ModificationOverlay (交互层)                         │   │
│  │  - 框选矩形                                          │   │
│  │  - 连线预览                                          │   │
│  │  - 节点选中轮廓                                      │   │
│  │  - 不跟随 transform（屏幕坐标系）                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ToolOverlay (工具层)                                 │   │
│  │  - 工具栏                                            │   │
│  │  - 缩放控制                                          │   │
│  │  - 位置信息                                          │   │
│  │  - 固定位置，不跟随任何变换                         │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ GridOverlay / BackgroundOverlay                      │   │
│  │  - 网格线                                            │   │
│  │  - 背景图                                            │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

**LogicFlow 实现** (Graph.tsx):

```tsx
<div className="lf-graph">
  {/* 元素层 - 应用 transform */}
  <CanvasOverlay graphModel={graphModel}>
    <g className="lf-base" transform={transformModel.getTransformStyle()}>
      {nodes.map(n => this.getComponent(n))}
      {edges.map(e => this.getComponent(e))}
    </g>
  </CanvasOverlay>

  {/* 交互层 - 不应用 transform */}
  <ModificationOverlay graphModel={graphModel}>
    <OutlineOverlay />      {/* 选中轮廓 */}
    <SnaplineOverlay />     {/* 对齐线 */}
  </ModificationOverlay>

  {/* 工具层 */}
  <ToolOverlay graphModel={graphModel} />

  {/* 背景/网格 */}
  <Grid graphModel={graphModel} />
</div>
```

**Flutter 适配**：

```dart
Widget build(BuildContext context) {
  return Stack(
    children: [
      // 1. 网格层
      GridOverlay(model: graphModel),

      // 2. 画布层 - 应用 transform
      Transform(
        transform: graphModel.transformModel.matrix,
        child: CustomPaint(
          painter: CanvasPainter(
            nodes: graphModel.nodes,
            edges: graphModel.edges,
          ),
        ),
      ),

      // 3. 交互层 - 不应用 transform（屏幕坐标）
      ModificationOverlay(model: graphModel),

      // 4. 工具层 - 固定位置
      Positioned(
        right: 16,
        bottom: 16,
        child: ToolBar(model: graphModel),
      ),
    ],
  );
}
```

---

## 四、命中测试与坐标系统

### 4.1 两套坐标系

```
屏幕坐标系 (Screen/HTML/DOM)
├── 原点：Widget 左上角
├── 单位：像素
├── 用途：接收用户输入（PointerEvent.localPosition）
└── 范围：[0, width] × [0, height]

画布坐标系 (Canvas/Scene)
├── 原点：逻辑中心（可任意）
├── 单位：逻辑单位
├── 用途：存储节点位置、计算布局
└── 范围：无限制（可无限扩展）
```

**转换公式**：

```
screen → canvas:
  canvas_x = (screen_x - TRANSLATE_X) / SCALE_X
  canvas_y = (screen_y - TRANSLATE_Y) / SCALE_Y

canvas → screen:
  screen_x = canvas_x * SCALE_X + TRANSLATE_X
  screen_y = canvas_y * SCALE_Y + TRANSLATE_Y
```

### 4.2 命中测试

**LogicFlow 实现**：

```typescript
// GraphModel.ts
getAreaElement(lt, rb, wholeNode) {
  const areaElements = []
  for (const node of this.nodes) {
    // 获取节点四个角点
    const bboxPoints = [
      { x: node.x - width/2, y: node.y - height/2 },  // 左上
      { x: node.x + width/2, y: node.y - height/2 },  // 右上
      { x: node.x + width/2, y: node.y + height/2 },  // 右下
      { x: node.x - width/2, y: node.y + height/2 },  // 左下
    ]

    // 判断所有角点是否都在选区内
    const allInArea = bboxPoints.every(p => isPointInArea(p, lt, rb))
    if (wholeNode && allInArea) areaElements.push(node)
  }
  return areaElements
}
```

**Flutter 适配**：

```dart
class HitTestResult {
  final NodeModel? node;
  final EdgeModel? edge;
  final AnchorModel? anchor;

  bool get isOnNode => node != null;
  bool get isOnEdge => edge != null;
  bool get isOnAnchor => anchor != null;
}

class GraphModel {
  HitTestResult hitTest(Offset canvasPoint) {
    // 1. 检查锚点（优先级最高）
    for (final node in _nodes) {
      if (!node.isShowAnchor) continue;
      for (final anchor in node.anchors) {
        if (_isPointNearAnchor(canvasPoint, anchor)) {
          return HitTestResult(node: node, anchor: anchor);
        }
      }
    }

    // 2. 检查节点
    for (final node in _nodes) {
      if (_isPointInNode(canvasPoint, node)) {
        return HitTestResult(node: node);
      }
    }

    // 3. 检查边
    for (final edge in _edges) {
      if (_isPointNearEdge(canvasPoint, edge)) {
        return HitTestResult(edge: edge);
      }
    }

    return HitTestResult();
  }

  bool _isPointInNode(Offset point, NodeModel node) {
    return point.dx >= node.x - node.width / 2 &&
           point.dx <= node.x + node.width / 2 &&
           point.dy >= node.y - node.height / 2 &&
           point.dy <= node.y + node.height / 2;
  }
}
```

---

## 五、事件处理流程

### 5.1 事件入口

**LogicFlow**：使用 SVG/HTML 原生事件

```tsx
// CanvasOverlay.tsx
<div
  onMouseDown={this.handleMouseDown}
  onMouseMove={this.handleMouseMove}
  onMouseUp={this.handleMouseUp}
  onWheel={this.handleWheel}
>
  {/* 画布内容 */}
</div>
```

**Flutter**：使用 `Listener` 或 `GestureDetector`

```dart
Listener(
  onPointerDown: (event) => _handlePointerDown(event),
  onPointerMove: (event) => _handlePointerMove(event),
  onPointerUp: (event) => _handlePointerUp(event),
  onPointerSignal: (event) => _handlePointerSignal(event),  // 滚轮
  child: Stack(...),
)
```

### 5.2 事件分发流程

```
1. 用户操作（点击/拖动）
   ↓
2. Listener 接收 PointerEvent
   ↓
3. 转换坐标：screen → canvas
   canvasPoint = graphModel.toCanvasPoint(event.localPosition)
   ↓
4. 命中测试
   hitResult = graphModel.hitTest(canvasPoint)
   ↓
5. 触发对应事件
   if (hitResult.isOnAnchor) {
     eventCenter.emit('anchor:click', AnchorEventArgs(...))
   } else if (hitResult.isOnNode) {
     eventCenter.emit('node:click', NodeEventArgs(...))
   } else {
     eventCenter.emit('canvas:click', CanvasEventArgs(...))
   }
   ↓
6. Behavior/Widget 响应事件
   eventCenter.on('node:click', (args) => {
     // 处理节点点击
   })
```

---

## 六、注册机制

**核心思想**：节点/边类型通过注册添加，支持自定义渲染和模型。

**LogicFlow 实现**：

```typescript
// 注册自定义节点
lf.register({
  type: 'custom',
  view: CustomNodeView,     // 渲染组件
  model: CustomNodeModel,   // 数据模型
})

// 内部存储
modelMap: Map<string, ModelClass>
viewMap: Map<string, ViewComponent>

// 创建节点时查找
const Model = this.modelMap.get(type)
const nodeModel = new Model(config, this)
```

**Flutter 适配**：

```dart
class DiagramEditor {
  final Map<String, NodeModelFactory> _nodeModelFactories = {};
  final Map<String, NodeWidgetBuilder> _nodeWidgetBuilders = {};

  void registerNode(String type, {
    required NodeModelFactory modelFactory,
    required NodeWidgetBuilder widgetBuilder,
  }) {
    _nodeModelFactories[type] = modelFactory;
    _nodeWidgetBuilders[type] = widgetBuilder;
  }

  NodeModel createNodeModel(NodeConfig config) {
    final factory = _nodeModelFactories[config.type] ?? defaultNodeFactory;
    return factory(config);
  }

  Widget buildNodeWidget(NodeModel model) {
    final builder = _nodeWidgetBuilders[model.type] ?? defaultNodeBuilder;
    return builder(model, graphModel);
  }
}
```

---

## 七、历史记录（撤销/重做）

**核心思想**：每次数据变更记录快照，支持回退和恢复。

**LogicFlow 实现**：

```typescript
// History.ts
class History {
  undos: GraphData[] = []
  redos: GraphData[] = []

  watch(graphModel) {
    graphModel.on('graph:updated', () => {
      const data = graphModel.modelToHistoryData()
      if (data) {
        this.undos.push(data)
        this.redos = []
      }
    })
  }

  undo() {
    const data = this.undos.pop()
    if (data) {
      this.redos.push(graphModel.modelToGraphData())
      graphModel.graphDataToModel(data)
    }
  }

  redo() {
    const data = this.redos.pop()
    if (data) {
      this.undos.push(graphModel.modelToGraphData())
      graphModel.graphDataToModel(data)
    }
  }
}
```

**Flutter 适配**：

```dart
class HistoryController {
  final List<GraphData> _undos = [];
  final List<GraphData> _redos = [];

  void watch(GraphModel graphModel) {
    graphModel.eventCenter.on(EventType.graphUpdated, (args) {
      final data = graphModel.toGraphData();
      _undos.add(data);
      _redos.clear();
    });
  }

  void undo(GraphModel graphModel) {
    if (_undos.isEmpty) return;
    _redos.add(graphModel.toGraphData());
    final data = _undos.removeLast();
    graphModel.loadFromData(data);
  }

  void redo(GraphModel graphModel) {
    if (_redos.isEmpty) return;
    _undos.add(graphModel.toGraphData());
    final data = _redos.removeLast();
    graphModel.loadFromData(data);
  }
}
```

---

## 八、总结：Flutter 实现清单

| LogicFlow 概念 | Flutter 实现方式 |
|----------------|------------------|
| `@observable` + MobX | `ChangeNotifier` 或 Riverpod `StateNotifier` |
| `@observer` + Preact | `ListenableBuilder` / `Consumer` / `watch` |
| `EventEmitter` | 自定义 `EventCenter` 或 `Stream` |
| `TransformModel` (手动变换) | `Transform` widget + 自定义 `TransformModel` |
| SVG 渲染 | `CustomPaint` 或 `SvgPicture` |
| 分层渲染 | `Stack` widget |
| 注册机制 | `Map<String, Factory>` |
| 历史记录 | 快照数组 + 事件监听 |

---

*文档版本: 2.1*
*最后更新: 2026-06-29*