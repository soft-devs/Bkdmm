/// 图表编辑器事件类型常量定义
///
/// 定义所有事件类型的字符串常量，用于事件标识、日志记录和调试。
library;

/// 事件类型常量
///
/// 使用字符串常量标识不同类型的事件，便于日志记录和调试。
abstract class DiagramEventTypes {
  DiagramEventTypes._();

  // ========== 指针事件 ==========

  /// 指针按下事件
  static const String pointerDown = 'pointer_down';

  /// 指针移动事件
  static const String pointerMove = 'pointer_move';

  /// 指针抬起事件
  static const String pointerUp = 'pointer_up';

  /// 悬停事件
  static const String hover = 'hover';

  /// 滚轮事件
  static const String scroll = 'scroll';

  // ========== 键盘事件 ==========

  /// 键盘事件
  static const String key = 'key';

  // ========== 手势事件 ==========

  /// 点击事件
  static const String tap = 'tap';

  /// 双击事件
  static const String doubleTap = 'double_tap';

  /// 长按事件
  static const String longPress = 'long_press';

  /// 缩放事件
  static const String scale = 'scale';

  // ========== 交互事件 ==========

  /// 节点选择事件
  static const String nodeSelect = 'node_select';

  /// 节点取消选择事件
  static const String nodeDeselect = 'node_deselect';

  /// 节点拖拽开始事件
  static const String nodeDragStart = 'node_drag_start';

  /// 节点拖拽更新事件
  static const String nodeDragUpdate = 'node_drag_update';

  /// 节点拖拽结束事件
  static const String nodeDragEnd = 'node_drag_end';

  /// 连线开始事件
  static const String connectionStart = 'connection_start';

  /// 连线更新事件
  static const String connectionUpdate = 'connection_update';

  /// 连线完成事件
  static const String connectionComplete = 'connection_complete';

  /// 连线取消事件
  static const String connectionCancel = 'connection_cancel';

  /// 框选开始事件
  static const String boxSelectStart = 'box_select_start';

  /// 框选更新事件
  static const String boxSelectUpdate = 'box_select_update';

  /// 框选完成事件
  static const String boxSelectComplete = 'box_select_complete';

  /// 画布平移事件
  static const String canvasPan = 'canvas_pan';

  /// 画布缩放事件
  static const String canvasZoom = 'canvas_zoom';

  // ========== 所有事件类型列表 ==========

  /// 所有指针事件类型
  static const List<String> pointerEvents = [
    pointerDown,
    pointerMove,
    pointerUp,
    hover,
    scroll,
  ];

  /// 所有手势事件类型
  static const List<String> gestureEvents = [
    tap,
    doubleTap,
    longPress,
    scale,
  ];

  /// 所有交互事件类型
  static const List<String> interactionEvents = [
    nodeSelect,
    nodeDeselect,
    nodeDragStart,
    nodeDragUpdate,
    nodeDragEnd,
    connectionStart,
    connectionUpdate,
    connectionComplete,
    connectionCancel,
    boxSelectStart,
    boxSelectUpdate,
    boxSelectComplete,
    canvasPan,
    canvasZoom,
  ];

  /// 所有事件类型
  static const List<String> all = [
    ...pointerEvents,
    key,
    ...gestureEvents,
    ...interactionEvents,
  ];
}
