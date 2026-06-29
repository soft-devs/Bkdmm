# 事件系统设计

基于 LogicFlow 的事件发射器模式设计统一的事件系统。

---

## 一、事件系统架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           EventCenter (事件中心)                         │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                        内部事件映射表                              │   │
│   │                                                                   │   │
│   │   'node:click'        → [Handler1, Handler2, ...]               │   │
│   │   'node:drag'         → [Handler3, ...]                         │   │
│   │   'edge:add'          → [Handler4, Handler5, ...]               │   │
│   │   'canvas:click'      → [Handler6, ...]                         │   │
│   │   '*'                 → [WildcardHandler]                       │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│   方法:                                                                  │
│   - on(event, callback, once?)   // 监听事件                           │
│   - once(event, callback)        // 监听一次                           │
│   - emit(event, args)            // 触发事件                           │
│   - off(event, callback?)        // 取消监听                           │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
                    ▼               ▼               ▼
            ┌───────────┐   ┌───────────┐   ┌───────────┐
            │  Widget   │   │  Behavior │   │  Plugin   │
            │  监听渲染  │   │  监听交互  │   │  监听扩展  │
            └───────────┘   └───────────┘   └───────────┘
```

---

## 二、EventCenter 实现

```dart
/// 事件回调类型
typedef EventCallback<T> = void Function(T args);

/// 事件处理器
class _EventHandler {
  final EventCallback callback;
  final bool once;

  _EventHandler({required this.callback, this.once = false});

  void call(dynamic args) {
    callback(args);
  }
}

/// 事件中心 - 统一管理所有事件
///
/// 参考 LogicFlow 的 EventEmitter 实现。
class EventCenter {
  /// 事件处理器映射表
  final Map<String, List<_EventHandler>> _handlers = {};

  /// 通配符事件处理器
  final List<_EventHandler> _wildcardHandlers = [];

  /// 监听事件
  ///
  /// [eventType] 事件类型
  /// [callback] 回调函数
  /// [once] 是否只监听一次
  void on<T>(
    String eventType,
    EventCallback<T> callback, {
    bool once = false,
  }) {
    // 支持逗号分隔的多个事件类型
    eventType.split(',').forEach((type) {
      type = type.trim();
      if (type.isEmpty) return;

      final handler = _EventHandler(callback: callback, once: once);

      if (type == '*') {
        _wildcardHandlers.add(handler);
      } else {
        _handlers.putIfAbsent(type, () => []);
        _handlers[type]!.add(handler);
      }
    });
  }

  /// 监听一次
  void once<T>(String eventType, EventCallback<T> callback) {
    on(eventType, callback, once: true);
  }

  /// 触发事件
  void emit<T>(String eventType, T args) {
    // 支持逗号分隔的多个事件类型
    eventType.split(',').forEach((type) {
      type = type.trim();
      if (type.isEmpty) return;

      // 触发特定事件处理器
      final handlers = _handlers[type];
      if (handlers != null) {
        _callHandlers(handlers, args);
      }

      // 触发通配符处理器
      if (_wildcardHandlers.isNotEmpty) {
        _callHandlers(_wildcardHandlers, args);
      }
    });
  }

  /// 调用处理器列表
  void _callHandlers(List<_EventHandler> handlers, dynamic args) {
    // 从后向前遍历，避免删除元素时索引错乱
    for (var i = handlers.length - 1; i >= 0; i--) {
      final handler = handlers[i];
      try {
        handler.call(args);
      } catch (e, stackTrace) {
        // 错误处理：打印日志但不中断其他处理器
        debugPrint('EventCenter: Error in handler: $e');
        debugPrint(stackTrace.toString());
      }

      // 移除 once 处理器
      if (handler.once) {
        handlers.removeAt(i);
      }
    }

    // 如果事件处理器列表为空，移除该事件类型
    if (handlers.isEmpty) {
      // 找到对应的 key 并移除
      _handlers.entries
          .where((entry) => entry.value == handlers)
          .map((entry) => entry.key)
          .toList()
          .forEach(_handlers.remove);
    }
  }

  /// 取消监听
  ///
  /// - [eventType] 为空时，清除所有事件监听器
  /// - [callback] 为空时，清除该事件类型的所有监听器
  /// - [callback] 不为空时，只移除匹配的监听器
  void off<T>(String eventType, [EventCallback<T>? callback]) {
    // eventType 为空，清除所有
    if (eventType.isEmpty) {
      _handlers.clear();
      _wildcardHandlers.clear();
      return;
    }

    eventType.split(',').forEach((type) {
      type = type.trim();
      if (type.isEmpty) return;

      if (type == '*') {
        if (callback == null) {
          _wildcardHandlers.clear();
        } else {
          _wildcardHandlers.removeWhere((h) => h.callback == callback);
        }
        return;
      }

      final handlers = _handlers[type];
      if (handlers == null) return;

      if (callback == null) {
        _handlers.remove(type);
      } else {
        handlers.removeWhere((h) => h.callback == callback);
        if (handlers.isEmpty) {
          _handlers.remove(type);
        }
      }
    });
  }

  /// 获取所有事件（用于调试）
  Map<String, List<_EventHandler>> getEvents() {
    return Map.unmodifiable(_handlers);
  }

  /// 销毁
  void destroy() {
    _handlers.clear();
    _wildcardHandlers.clear();
  }
}
```

---

## 三、事件类型定义

```dart
/// 事件类型常量
///
/// 参考 LogicFlow 的 EventType 设计。
abstract class EventType {
  // ═══════════════════════════════════════════════════════════════════
  // 节点事件
  // ═══════════════════════════════════════════════════════════════════

  /// 节点添加
  static const nodeAdd = 'node:add';

  /// 节点删除
  static const nodeDelete = 'node:delete';

  /// 节点点击
  static const nodeClick = 'node:click';

  /// 节点双击
  static const nodeDoubleClick = 'node:doubleClick';

  /// 节点悬停进入
  static const nodeMouseEnter = 'node:mouseenter';

  /// 节点悬停离开
  static const nodeMouseLeave = 'node:mouseleave';

  /// 节点拖动开始
  static const nodeDragStart = 'node:dragstart';

  /// 节点拖动中
  static const nodeDrag = 'node:drag';

  /// 节点拖动结束
  static const nodeDragEnd = 'node:dragend';

  /// 节点选中
  static const nodeSelected = 'node:selected';

  /// 节点取消选中
  static const nodeUnselected = 'node:unselected';

  // ═══════════════════════════════════════════════════════════════════
  // 边事件
  // ═══════════════════════════════════════════════════════════════════

  /// 边添加
  static const edgeAdd = 'edge:add';

  /// 边删除
  static const edgeDelete = 'edge:delete';

  /// 边点击
  static const edgeClick = 'edge:click';

  /// 边双击
  static const edgeDoubleClick = 'edge:doubleClick';

  /// 边悬停进入
  static const edgeMouseEnter = 'edge:mouseenter';

  /// 边悬停离开
  static const edgeMouseLeave = 'edge:mouseleave';

  // ═══════════════════════════════════════════════════════════════════
  // 锚点事件
  // ═══════════════════════════════════════════════════════════════════

  /// 锚点点击
  static const anchorClick = 'anchor:click';

  /// 锚点悬停进入
  static const anchorMouseEnter = 'anchor:mouseenter';

  /// 锚点悬停离开
  static const anchorMouseLeave = 'anchor:mouseleave';

  // ═══════════════════════════════════════════════════════════════════
  // 画布事件
  // ═══════════════════════════════════════════════════════════════════

  /// 画布点击
  static const canvasClick = 'canvas:click';

  /// 画布双击
  static const canvasDoubleClick = 'canvas:doubleClick';

  /// 画布拖动开始
  static const canvasDragStart = 'canvas:dragstart';

  /// 画布拖动中
  static const canvasDrag = 'canvas:drag';

  /// 画布拖动结束
  static const canvasDragEnd = 'canvas:dragend';

  /// 框选开始
  static const selectionStart = 'selection:start';

  /// 框选中
  static const selectionUpdate = 'selection:update';

  /// 框选结束
  static const selectionEnd = 'selection:end';

  // ═══════════════════════════════════════════════════════════════════
  // 连线事件
  // ═══════════════════════════════════════════════════════════════════

  /// 连线开始
  static const connectionStart = 'connection:start';

  /// 连线预览更新
  static const connectionUpdate = 'connection:update';

  /// 连线完成
  static const connectionComplete = 'connection:complete';

  /// 连线取消
  static const connectionCancel = 'connection:cancel';

  // ═══════════════════════════════════════════════════════════════════
  // 视口事件
  // ═══════════════════════════════════════════════════════════════════

  /// 缩放变化
  static const transformZoom = 'transform:zoom';

  /// 平移变化
  static const transformPan = 'transform:pan';

  /// 重置变换
  static const transformReset = 'transform:reset';

  // ═══════════════════════════════════════════════════════════════════
  // 图事件
  // ═══════════════════════════════════════════════════════════════════

  /// 图数据更新
  static const graphUpdated = 'graph:updated';

  /// 图数据加载
  static const graphLoaded = 'graph:loaded';

  /// 图清空
  static const graphCleared = 'graph:cleared';

  // ═══════════════════════════════════════════════════════════════════
  // 历史事件
  // ═══════════════════════════════════════════════════════════════════

  /// 撤销
  static const historyUndo = 'history:undo';

  /// 重做
  static const historyRedo = 'history:redo';

  /// 命令执行
  static const historyExecute = 'history:execute';
}
```

---

## 四、事件参数定义

```dart
/// 基础事件参数
abstract class BaseEventArgs {
  /// 时间戳
  final DateTime timestamp;

  BaseEventArgs() : timestamp = DateTime.now();
}

/// 节点事件参数
class NodeEventArgs extends BaseEventArgs {
  /// 节点模型
  final NodeModel node;

  /// 原始指针事件
  final PointerEvent? event;

  /// 额外数据
  final Map<String, dynamic> data;

  NodeEventArgs({
    required this.node,
    this.event,
    this.data = const {},
  });
}

/// 边事件参数
class EdgeEventArgs extends BaseEventArgs {
  /// 边模型
  final EdgeModel edge;

  /// 原始指针事件
  final PointerEvent? event;

  EdgeEventArgs({
    required this.edge,
    this.event,
  });
}

/// 锚点事件参数
class AnchorEventArgs extends BaseEventArgs {
  /// 锚点模型
  final AnchorModel anchor;

  /// 所属节点
  final NodeModel node;

  /// 原始指针事件
  final PointerEvent? event;

  AnchorEventArgs({
    required this.anchor,
    required this.node,
    this.event,
  });
}

/// 画布事件参数
class CanvasEventArgs extends BaseEventArgs {
  /// 点击位置（画布坐标）
  final Offset position;

  /// 屏幕位置
  final Offset? screenPosition;

  /// 原始指针事件
  final PointerEvent? event;

  CanvasEventArgs({
    required this.position,
    this.screenPosition,
    this.event,
  });
}

/// 框选事件参数
class SelectionEventArgs extends BaseEventArgs {
  /// 框选矩形（屏幕坐标）
  final Rect selectionRect;

  /// 选中的节点 ID
  final Set<String> selectedNodeIds;

  /// 选中的边 ID
  final Set<String> selectedEdgeIds;

  SelectionEventArgs({
    required this.selectionRect,
    this.selectedNodeIds = const {},
    this.selectedEdgeIds = const {},
  });
}

/// 连线事件参数
class ConnectionEventArgs extends BaseEventArgs {
  /// 源锚点
  final AnchorModel sourceAnchor;

  /// 源节点
  final NodeModel sourceNode;

  /// 目标锚点（完成时）
  final AnchorModel? targetAnchor;

  /// 目标节点（完成时）
  final NodeModel? targetNode;

  /// 预览终点位置（连线中）
  final Offset? previewEnd;

  ConnectionEventArgs({
    required this.sourceAnchor,
    required this.sourceNode,
    this.targetAnchor,
    this.targetNode,
    this.previewEnd,
  });
}

/// 变换事件参数
class TransformEventArgs extends BaseEventArgs {
  /// 缩放比例
  final double scale;

  /// 平移偏移
  final Offset offset;

  /// 变换前的缩放
  final double? previousScale;

  /// 变换前的偏移
  final Offset? previousOffset;

  TransformEventArgs({
    required this.scale,
    required this.offset,
    this.previousScale,
    this.previousOffset,
  });
}

/// 图事件参数
class GraphEventArgs extends BaseEventArgs {
  /// 图数据
  final GraphData? data;

  /// 变更类型
  final String? changeType;

  GraphEventArgs({this.data, this.changeType});
}

/// 历史事件参数
class HistoryEventArgs extends BaseEventArgs {
  /// 命令
  final DiagramCommand? command;

  /// 是否可以撤销
  final bool canUndo;

  /// 是否可以重做
  final bool canRedo;

  HistoryEventArgs({
    this.command,
    this.canUndo = false,
    this.canRedo = false,
  });
}
```

---

## 五、事件使用示例

### 5.1 监听节点事件

```dart
// 在 Widget 中监听
class ERDiagramCanvas extends StatefulWidget {
  @override
  State<ERDiagramCanvas> createState() => _ERDiagramCanvasState();
}

class _ERDiagramCanvasState extends State<ERDiagramCanvas> {
  late final GraphModel _graphModel;

  @override
  void initState() {
    super.initState();
    _graphModel = GraphModel();

    // 监听节点点击
    _graphModel.eventCenter.on(EventType.nodeClick, _handleNodeClick);

    // 监听节点双击
    _graphModel.eventCenter.on(EventType.nodeDoubleClick, _handleNodeDoubleClick);

    // 监听节点拖动
    _graphModel.eventCenter.on(EventType.nodeDragEnd, _handleNodeDragEnd);
  }

  void _handleNodeClick(NodeEventArgs args) {
    final node = args.node;
    debugPrint('节点被点击: ${node.id}');

    // 更新选择状态
    _graphModel.selectionModel.selectNode(node.id);
  }

  void _handleNodeDoubleClick(NodeEventArgs args) {
    final node = args.node;
    debugPrint('节点被双击: ${node.id}');

    // 打开编辑弹窗
    _showEditDialog(node);
  }

  void _handleNodeDragEnd(NodeEventArgs args) {
    final node = args.node;
    debugPrint('节点拖动结束: ${node.id}, 新位置: (${node.x}, ${node.y})');

    // 保存到数据源
    _saveNodePosition(node);
  }

  @override
  void dispose() {
    // 取消所有监听
    _graphModel.eventCenter.off(EventType.nodeClick);
    _graphModel.eventCenter.off(EventType.nodeDoubleClick);
    _graphModel.eventCenter.off(EventType.nodeDragEnd);
    super.dispose();
  }
}
```

### 5.2 在行为中触发事件

```dart
/// 节点拖动行为
class NodeDragBehavior extends DiagramBehavior {
  @override
  String get name => 'NodeDrag';

  @override
  int get priority => 20;

  NodeModel? _draggingNode;
  Offset? _startPosition;

  @override
  bool canHandle(DiagramEvent event, GraphModel graphModel) {
    if (!graphModel.editConfigModel.isEditable) return false;

    if (event is PointerDownEvent) {
      final hitResult = graphModel.hitTest(graphModel.toScenePoint(event.localPosition));
      return hitResult.isOnNode;
    }

    return _draggingNode != null && event is PointerMoveEvent || event is PointerUpEvent;
  }

  @override
  void handle(DiagramEvent event, GraphModel graphModel) {
    if (event is PointerDownEvent) {
      _startDrag(event, graphModel);
    } else if (event is PointerMoveEvent) {
      _updateDrag(event, graphModel);
    } else if (event is PointerUpEvent) {
      _endDrag(graphModel);
    }
  }

  void _startDrag(PointerDownEvent event, GraphModel graphModel) {
    final hitResult = graphModel.hitTest(graphModel.toScenePoint(event.localPosition));
    _draggingNode = hitResult.node;
    _startPosition = _draggingNode!.position;

    // 触发拖动开始事件
    graphModel.eventCenter.emit(
      EventType.nodeDragStart,
      NodeEventArgs(node: _draggingNode!, event: event),
    );

    _draggingNode!.setDragging(true);
  }

  void _updateDrag(PointerMoveEvent event, GraphModel graphModel) {
    if (_draggingNode == null) return;

    // 计算新位置
    final scenePos = graphModel.toScenePoint(event.localPosition);
    final startScenePos = graphModel.toScenePoint(_startScreenPosition!);
    final delta = scenePos - startScenePos;

    _draggingNode!.position = _startPosition! + delta;

    // 触发拖动更新事件
    graphModel.eventCenter.emit(
      EventType.nodeDrag,
      NodeEventArgs(node: _draggingNode!, event: event),
    );
  }

  void _endDrag(GraphModel graphModel) {
    if (_draggingNode == null) return;

    _draggingNode!.setDragging(false);

    // 触发拖动结束事件
    graphModel.eventCenter.emit(
      EventType.nodeDragEnd,
      NodeEventArgs(node: _draggingNode!),
    );

    _draggingNode = null;
    _startPosition = null;
  }

  @override
  void reset() {
    _draggingNode = null;
    _startPosition = null;
  }
}
```

### 5.3 通配符监听

```dart
// 监听所有事件（用于调试/日志）
eventCenter.on('*', (args) {
  debugPrint('事件触发: $args');
});

// 或使用通配符监听特定前缀
eventCenter.on('node:*', (args) {
  debugPrint('节点事件触发');
});
```

---

## 六、与 V1 对比

| 方面 | V1 | V2 (EventCenter) |
|------|-----|------------------|
| 事件传递 | Widget 回调链 | 统一事件中心 |
| 解耦程度 | 紧耦合 | 完全解耦 |
| 扩展性 | 修改 Widget | 监听事件 |
| 调试性 | 难以追踪 | 集中日志 |
| 测试性 | 需要 Widget 测试 | 独立单元测试 |

---

*文档版本: 1.1*
*最后更新: 2026-06-29*
