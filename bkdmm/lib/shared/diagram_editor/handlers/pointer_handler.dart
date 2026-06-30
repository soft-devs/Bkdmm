/// 指针事件处理器 - 事件入口
///
/// 作为所有指针事件的入口点，负责：
/// 1. 接收 Flutter Listener 的原始指针事件
/// 2. 坐标转换（屏幕坐标 -> 场景坐标）
/// 3. 命中测试（确定点击位置的对象）
/// 4. 构建 DiagramContext 并分发事件
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../handlers/diagram_event.dart';
import '../handlers/diagram_context.dart' hide HitTestResult;
import '../handlers/diagram_context.dart' as diag_context show HitTestResult;
import '../handlers/handler_registry.dart';
import '../handlers/diagram_handler.dart';
import '../spatial/simple_index.dart';
import '../core/diagram_state.dart' hide InteractionMode;
import '../core/diagram_node.dart';
import '../core/diagram_edge.dart';
import '../integration/er_interaction_manager.dart' show InteractionMode;
import '../model/transform_model.dart';

/// 指针事件处理器
///
/// 管理指针事件的接收、转换和分发流程。
/// 作为图表交互的入口点，协调 Listener、坐标系统和处理器注册表。
///
/// ## 事件流程
///
/// ```
/// Listener (原始事件)
///     ↓
/// PointerHandler.handlePointerXxx()
///     ↓
/// 1. 坐标转换: screen → scene
/// 2. 命中测试: 确定 HitTestResult
/// 3. 构建 DiagramContext
///     ↓
/// HandlerRegistry.dispatch()
///     ↓
/// 各 Handler 处理事件
/// ```
class PointerHandler {
  /// 处理器注册表
  final HandlerRegistry registry;

  /// 空间索引（用于命中测试）
  final DiagramSpatialIndex spatialIndex;

  /// 变换模型（用于坐标转换）
  TransformModel _transform;

  /// 当前交互模式
  InteractionMode _interactionMode;

  /// 是否为暗色模式
  bool _isDarkMode;

  /// 图表 ID
  final String diagramId;

  /// 图表类型
  final String diagramType;

  /// 状态更新回调
  final void Function(HandlerUpdate update)? onStateUpdate;

  /// 创建指针处理器
  PointerHandler({
    required this.registry,
    required this.spatialIndex,
    required this.diagramId,
    required this.diagramType,
    TransformModel transform = TransformModel.identity,
    InteractionMode interactionMode = InteractionMode.edit,
    bool isDarkMode = false,
    this.onStateUpdate,
  })  : _transform = transform,
        _interactionMode = interactionMode,
        _isDarkMode = isDarkMode;

  // ═══════════════════════════════════════════════════════════════════
  // 配置更新
  // ═══════════════════════════════════════════════════════════════════

  /// 更新变换模型
  void updateTransform(TransformModel transform) {
    _transform = transform;
  }

  /// 更新交互模式
  void updateInteractionMode(InteractionMode mode) {
    _interactionMode = mode;
  }

  /// 更新暗色模式
  void updateDarkMode(bool isDark) {
    _isDarkMode = isDark;
  }

  /// 从 Matrix4 更新变换
  void updateTransformFromMatrix(Matrix4 matrix) {
    _transform = TransformModel.fromMatrix4(
      matrix,
      minZoom: _transform.minZoom,
      maxZoom: _transform.maxZoom,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 坐标转换
  // ═══════════════════════════════════════════════════════════════════

  /// 屏幕坐标转场景坐标
  Offset screenToScene(Offset screen) {
    return _transform.toScene(screen);
  }

  /// 场景坐标转屏幕坐标
  Offset sceneToScreen(Offset scene) {
    return _transform.toScreen(scene);
  }

  /// 获取当前缩放比例
  double get zoom => _transform.zoom;

  /// 获取当前平移偏移
  Offset get panOffset => _transform.panOffset;

  /// 获取变换矩阵
  Matrix4 get transformMatrix => _transform.toMatrix4();

  // ═══════════════════════════════════════════════════════════════════
  // 命中测试
  // ═══════════════════════════════════════════════════════════════════

  /// 在指定位置执行命中测试
  ///
  /// [screenPosition] 屏幕坐标
  /// 返回命中测试结果
  diag_context.HitTestResult hitTest(Offset screenPosition) {
    final scenePosition = screenToScene(screenPosition);
    final spatialResult = spatialIndex.hitTest(scenePosition);

    return _convertSpatialResult(spatialResult, scenePosition);
  }

  /// 在场景坐标执行命中测试
  diag_context.HitTestResult hitTestScene(Offset scenePosition) {
    final spatialResult = spatialIndex.hitTest(scenePosition);
    return _convertSpatialResult(spatialResult, scenePosition);
  }

  /// 转换空间索引结果到命中测试结果
  diag_context.HitTestResult _convertSpatialResult(
    SpatialHitTestResult spatialResult,
    Offset scenePosition,
  ) {
    switch (spatialResult.type) {
      case SpatialHitTestType.anchor:
        return diag_context.HitTestResult.anchor(
          spatialResult.anchor as AnchorPoint,
          scenePosition,
        );

      case SpatialHitTestType.node:
        return diag_context.HitTestResult.node(
          spatialResult.node as DiagramNode,
          scenePosition,
        );

      case SpatialHitTestType.edge:
        return diag_context.HitTestResult.edge(
          spatialResult.edge as DiagramEdge,
          scenePosition,
        );

      case SpatialHitTestType.canvas:
        return diag_context.HitTestResult.canvas(scenePosition);
    }
  }

  /// 框选测试
  ///
  /// 返回矩形区域内所有节点的 ID
  List<String> hitTestRect(Rect screenRect) {
    final sceneRect = _transform.toSceneRect(screenRect);
    return spatialIndex.queryNodesInRect(sceneRect);
  }

  /// 场景坐标框选测试
  List<String> hitTestSceneRect(Rect sceneRect) {
    return spatialIndex.queryNodesInRect(sceneRect);
  }

  // ═══════════════════════════════════════════════════════════════════
  // 事件处理入口
  // ═══════════════════════════════════════════════════════════════════

  /// 处理指针按下事件
  ///
  /// 从 Flutter PointerDownEvent 转换并分发
  Future<bool> handlePointerDown(
    PointerDownEvent event,
    DiagramState state, {
    bool isCtrlPressed = false,
    bool isShiftPressed = false,
    bool isAltPressed = false,
  }) async {
    // 1. 创建 DiagramEvent
    final diagramEvent = DiagramEvent.fromPointerDown(
      event,
      isCtrlPressed: isCtrlPressed,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );

    // 2. 命中测试
    final hitResult = hitTest(event.localPosition);

    // 3. 构建 Context
    final context = _buildContext(state, hitResult);

    // 4. 分发事件
    return _dispatch(diagramEvent, context);
  }

  /// 处理指针移动事件
  Future<bool> handlePointerMove(
    PointerMoveEvent event,
    DiagramState state, {
    bool isCtrlPressed = false,
    bool isShiftPressed = false,
    bool isAltPressed = false,
  }) async {
    final diagramEvent = DiagramEvent.fromPointerMove(
      event,
      isCtrlPressed: isCtrlPressed,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );

    final hitResult = hitTest(event.localPosition);
    final context = _buildContext(state, hitResult);

    return _dispatch(diagramEvent, context);
  }

  /// 处理指针抬起事件
  Future<bool> handlePointerUp(
    PointerUpEvent event,
    DiagramState state, {
    bool isCtrlPressed = false,
    bool isShiftPressed = false,
    bool isAltPressed = false,
  }) async {
    final diagramEvent = DiagramEvent.fromPointerUp(
      event,
      isCtrlPressed: isCtrlPressed,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );

    final hitResult = hitTest(event.localPosition);
    final context = _buildContext(state, hitResult);

    return _dispatch(diagramEvent, context);
  }

  /// 处理悬停事件
  Future<bool> handlePointerHover(
    PointerHoverEvent event,
    DiagramState state, {
    bool isCtrlPressed = false,
    bool isShiftPressed = false,
    bool isAltPressed = false,
  }) async {
    final diagramEvent = DiagramEvent.fromPointerHover(
      event,
      isCtrlPressed: isCtrlPressed,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );

    final hitResult = hitTest(event.localPosition);
    final context = _buildContext(state, hitResult);

    return _dispatch(diagramEvent, context);
  }

  /// 处理滚轮事件
  Future<bool> handlePointerSignal(
    PointerSignalEvent event,
    DiagramState state, {
    bool isCtrlPressed = false,
    bool isShiftPressed = false,
    bool isAltPressed = false,
  }) async {
    if (event is PointerScrollEvent) {
      final diagramEvent = DiagramScrollEvent(
        localPosition: event.localPosition,
        position: event.position,
        scrollDelta: event.scrollDelta,
        timestamp: event.timeStamp,
        deviceKind: event.kind,
        isCtrlPressed: isCtrlPressed,
        isShiftPressed: isShiftPressed,
        isAltPressed: isAltPressed,
      );

      // 滚轮事件不需要命中测试
      final context = _buildContext(state, const diag_context.HitTestResult.empty());

      return _dispatch(diagramEvent, context);
    }

    return false;
  }

  // ═══════════════════════════════════════════════════════════════════
  // 内部方法
  // ═══════════════════════════════════════════════════════════════════

  /// 构建 DiagramContext
  DiagramContext _buildContext(DiagramState state, diag_context.HitTestResult hitResult) {
    return DiagramContext(
      diagramId: diagramId,
      diagramType: diagramType,
      state: state,
      transform: _transform.toMatrix4(),
      interactionMode: _interactionMode,
      isDarkMode: _isDarkMode,
      hitTestResult: hitResult,
    );
  }

  /// 分发事件到处理器注册表
  Future<bool> _dispatch(DiagramEvent event, DiagramContext context) async {
    if (onStateUpdate != null) {
      return registry.dispatch(event, context, onStateUpdate!);
    } else {
      return registry.dispatch(event, context, (_) {});
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 光标管理
  // ═══════════════════════════════════════════════════════════════════

  /// 获取当前光标样式
  MouseCursor getCursor(DiagramState state) {
    final context = _buildContext(state, const diag_context.HitTestResult.empty());
    return registry.getCursor(context);
  }

  /// 获取指定位置的光标样式
  MouseCursor getCursorAt(Offset screenPosition, DiagramState state) {
    final hitResult = hitTest(screenPosition);
    final context = _buildContext(state, hitResult);
    return registry.getCursor(context);
  }

  // ═══════════════════════════════════════════════════════════════════
  // 状态管理
  // ═══════════════════════════════════════════════════════════════════

  /// 重置所有处理器状态
  void reset() {
    registry.resetAll();
  }

  /// 获取当前活跃处理器
  DiagramEventHandler? get activeHandler => registry.activeHandler;

  /// 是否有活跃处理器
  bool get hasActiveHandler => registry.activeHandler != null;

  /// 获取处理器注册表信息
  String get registryInfo => registry.toString();

  /// 获取空间索引统计
  Map<String, int> get spatialStats => spatialIndex.getStats();

  /// 获取变换信息
  String get transformInfo => _transform.toString();

  /// 获取当前状态摘要
  Map<String, dynamic> get statusSummary => {
        'diagramId': diagramId,
        'diagramType': diagramType,
        'transform': transformInfo,
        'interactionMode': _interactionMode.name,
        'isDarkMode': _isDarkMode,
        'hasActiveHandler': hasActiveHandler,
        'handlers': registry.length,
        'spatialStats': spatialStats,
      };
}

/// 指针处理器配置
///
/// 用于配置 PointerHandler 的初始状态
class PointerHandlerConfig {
  /// 图表 ID
  final String diagramId;

  /// 图表类型
  final String diagramType;

  /// 初始变换
  final TransformModel initialTransform;

  /// 初始交互模式
  final InteractionMode initialInteractionMode;

  /// 是否为暗色模式
  final bool isDarkMode;

  /// 空间索引边界
  final Rect spatialIndexBounds;

  const PointerHandlerConfig({
    required this.diagramId,
    required this.diagramType,
    this.initialTransform = TransformModel.identity,
    this.initialInteractionMode = InteractionMode.edit,
    this.isDarkMode = false,
    this.spatialIndexBounds = const Rect.fromLTWH(0, 0, 50000, 50000),
  });

  /// 创建 ER 图配置
  factory PointerHandlerConfig.erDiagram({
    String diagramId = 'er-default',
    bool isDarkMode = false,
  }) {
    return PointerHandlerConfig(
      diagramId: diagramId,
      diagramType: 'er-diagram',
      initialInteractionMode: InteractionMode.edit,
      isDarkMode: isDarkMode,
    );
  }

  /// 创建流程图配置
  factory PointerHandlerConfig.flowchart({
    String diagramId = 'flowchart-default',
    bool isDarkMode = false,
  }) {
    return PointerHandlerConfig(
      diagramId: diagramId,
      diagramType: 'flowchart',
      initialInteractionMode: InteractionMode.edit,
      isDarkMode: isDarkMode,
    );
  }
}

/// 指针处理器工厂
///
/// 用于创建预配置的 PointerHandler
class PointerHandlerFactory {
  /// 创建默认指针处理器
  static PointerHandler createDefault({
    PointerHandlerConfig config = const PointerHandlerConfig(
      diagramId: 'default',
      diagramType: 'default',
    ),
    void Function(HandlerUpdate)? onStateUpdate,
  }) {
    final registry = HandlerRegistryFactory.createDefault();
    final spatialIndex = DiagramSpatialIndex(bounds: config.spatialIndexBounds);

    return PointerHandler(
      registry: registry,
      spatialIndex: spatialIndex,
      diagramId: config.diagramId,
      diagramType: config.diagramType,
      transform: config.initialTransform,
      interactionMode: config.initialInteractionMode,
      isDarkMode: config.isDarkMode,
      onStateUpdate: onStateUpdate,
    );
  }

  /// 创建 ER 图指针处理器
  static PointerHandler createERDiagram({
    String diagramId = 'er-default',
    bool isDarkMode = false,
    void Function(HandlerUpdate)? onStateUpdate,
    bool enableConnection = true,
    bool enableDrag = true,
    bool enableSelection = true,
    bool enablePan = true,
  }) {
    final registry = HandlerRegistryFactory.createERDiagram(
      enableConnection: enableConnection,
      enableDrag: enableDrag,
      enableSelection: enableSelection,
      enablePan: enablePan,
    );

    final spatialIndex = DiagramSpatialIndex();

    return PointerHandler(
      registry: registry,
      spatialIndex: spatialIndex,
      diagramId: diagramId,
      diagramType: 'er-diagram',
      interactionMode: InteractionMode.edit,
      isDarkMode: isDarkMode,
      onStateUpdate: onStateUpdate,
    );
  }

  /// 从现有组件创建指针处理器
  ///
  /// 用于与现有的 GraphView 等组件集成
  static PointerHandler fromGraphView({
    required String diagramId,
    required String diagramType,
    required TransformationController controller,
    required DiagramState state,
    required HandlerRegistry registry,
    required DiagramSpatialIndex spatialIndex,
    InteractionMode interactionMode = InteractionMode.edit,
    bool isDarkMode = false,
    void Function(HandlerUpdate)? onStateUpdate,
  }) {
    final handler = PointerHandler(
      registry: registry,
      spatialIndex: spatialIndex,
      diagramId: diagramId,
      diagramType: diagramType,
      interactionMode: interactionMode,
      isDarkMode: isDarkMode,
      onStateUpdate: onStateUpdate,
    );

    // 从 TransformationController 初始化变换
    handler.updateTransformFromMatrix(controller.value);

    return handler;
  }
}

/// 指针事件回调包装器
///
/// 提供便捷的回调函数，用于直接连接到 Flutter Listener
class PointerEventCallbacks {
  /// 指针处理器
  final PointerHandler handler;

  /// 图表状态
  final DiagramState state;

  /// 获取修饰键状态的回调
  final ModifierKeysGetter? getModifierKeys;

  /// 创建回调包装器
  PointerEventCallbacks({
    required this.handler,
    required this.state,
    this.getModifierKeys,
  });

  /// 获取修饰键状态
  ModifierKeys _getModifiers() {
    if (getModifierKeys != null) {
      return getModifierKeys!();
    }
    return const ModifierKeys();
  }

  /// 指针按下回调
  void onPointerDown(PointerDownEvent event) {
    final modifiers = _getModifiers();
    handler.handlePointerDown(
      event,
      state,
      isCtrlPressed: modifiers.isCtrlPressed,
      isShiftPressed: modifiers.isShiftPressed,
      isAltPressed: modifiers.isAltPressed,
    );
  }

  /// 指针移动回调
  void onPointerMove(PointerMoveEvent event) {
    final modifiers = _getModifiers();
    handler.handlePointerMove(
      event,
      state,
      isCtrlPressed: modifiers.isCtrlPressed,
      isShiftPressed: modifiers.isShiftPressed,
      isAltPressed: modifiers.isAltPressed,
    );
  }

  /// 指针抬起回调
  void onPointerUp(PointerUpEvent event) {
    final modifiers = _getModifiers();
    handler.handlePointerUp(
      event,
      state,
      isCtrlPressed: modifiers.isCtrlPressed,
      isShiftPressed: modifiers.isShiftPressed,
      isAltPressed: modifiers.isAltPressed,
    );
  }

  /// 悬停回调
  void onPointerHover(PointerHoverEvent event) {
    final modifiers = _getModifiers();
    handler.handlePointerHover(
      event,
      state,
      isCtrlPressed: modifiers.isCtrlPressed,
      isShiftPressed: modifiers.isShiftPressed,
      isAltPressed: modifiers.isAltPressed,
    );
  }

  /// 滚轮回调
  void onPointerSignal(PointerSignalEvent event) {
    final modifiers = _getModifiers();
    handler.handlePointerSignal(
      event,
      state,
      isCtrlPressed: modifiers.isCtrlPressed,
      isShiftPressed: modifiers.isShiftPressed,
      isAltPressed: modifiers.isAltPressed,
    );
  }

  /// 创建 Listener 回调集
  ///
  /// 直接用于 Flutter Listener widget
  ListenerCallbacks createListenerCallbacks() {
    return ListenerCallbacks(
      onPointerDown: onPointerDown,
      onPointerMove: onPointerMove,
      onPointerUp: onPointerUp,
      onPointerHover: onPointerHover,
      onPointerSignal: onPointerSignal,
    );
  }
}

/// 修饰键状态
class ModifierKeys {
  final bool isCtrlPressed;
  final bool isShiftPressed;
  final bool isAltPressed;

  const ModifierKeys({
    this.isCtrlPressed = false,
    this.isShiftPressed = false,
    this.isAltPressed = false,
  });

  /// 从 KeyEvent 获取修饰键状态
  static ModifierKeys fromKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      final key = event.logicalKey;
      return ModifierKeys(
        isCtrlPressed: key == LogicalKeyboardKey.control ||
            key == LogicalKeyboardKey.controlLeft ||
            key == LogicalKeyboardKey.controlRight,
        isShiftPressed: key == LogicalKeyboardKey.shift ||
            key == LogicalKeyboardKey.shiftLeft ||
            key == LogicalKeyboardKey.shiftRight,
        isAltPressed: key == LogicalKeyboardKey.alt ||
            key == LogicalKeyboardKey.altLeft ||
            key == LogicalKeyboardKey.altRight,
      );
    }
    return const ModifierKeys();
  }
}

/// 获取修饰键状态的函数类型
typedef ModifierKeysGetter = ModifierKeys Function();

/// Listener 回调集
///
/// 用于直接传递给 Flutter Listener widget
class ListenerCallbacks {
  final void Function(PointerDownEvent)? onPointerDown;
  final void Function(PointerMoveEvent)? onPointerMove;
  final void Function(PointerUpEvent)? onPointerUp;
  final void Function(PointerHoverEvent)? onPointerHover;
  final void Function(PointerSignalEvent)? onPointerSignal;

  const ListenerCallbacks({
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerHover,
    this.onPointerSignal,
  });
}