/// 平移缩放行为
///
/// 提供可复用的画布平移和缩放交互行为。
/// 支持鼠标滚轮缩放、触摸板双指缩放、拖拽平移等操作。
library;

import 'dart:ui';
import 'behavior.dart' show Behavior, BehaviorEvent, BehaviorContext, BehaviorUpdate;
import 'behavior_registry.dart' show BehaviorPriority;

/// 平移缩放状态
class PanZoomState {
  /// 当前变换模型
  final TransformSnapshot transform;

  /// 是否正在平移
  final bool isPanning;

  /// 平移起始位置（屏幕坐标）
  final Offset? panStartPosition;

  /// 平移开始时的 panOffset
  final Offset? panStartOffset;

  /// 是否正在缩放
  final bool isZooming;

  /// 缩放焦点（屏幕坐标）
  final Offset? zoomFocusPoint;

  const PanZoomState({
    required this.transform,
    this.isPanning = false,
    this.panStartPosition,
    this.panStartOffset,
    this.isZooming = false,
    this.zoomFocusPoint,
  });

  /// 初始状态
  static const initial = PanZoomState(
    transform: TransformSnapshot.initial,
  );

  /// 是否处于活动状态
  bool get isActive => isPanning || isZooming;

  /// 创建副本
  PanZoomState copyWith({
    TransformSnapshot? transform,
    bool? isPanning,
    Offset? panStartPosition,
    Offset? panStartOffset,
    bool? isZooming,
    Offset? zoomFocusPoint,
    bool clearPanStart = false,
    bool clearZoomFocus = false,
  }) {
    return PanZoomState(
      transform: transform ?? this.transform,
      isPanning: isPanning ?? this.isPanning,
      panStartPosition:
          clearPanStart ? null : (panStartPosition ?? this.panStartPosition),
      panStartOffset: clearPanStart ? null : (panStartOffset ?? this.panStartOffset),
      isZooming: isZooming ?? this.isZooming,
      zoomFocusPoint:
          clearZoomFocus ? null : (zoomFocusPoint ?? this.zoomFocusPoint),
    );
  }

  @override
  String toString() =>
      'PanZoomState(zoom: ${transform.zoom.toStringAsFixed(2)}, panning: $isPanning, zooming: $isZooming)';
}

/// 变换快照
///
/// 不可变的变换状态记录，用于状态管理和动画。
class TransformSnapshot {
  /// 缩放比例
  final double zoom;

  /// 平移偏移
  final Offset panOffset;

  /// 最小缩放
  final double minZoom;

  /// 最大缩放
  final double maxZoom;

  const TransformSnapshot({
    this.zoom = 1.0,
    this.panOffset = Offset.zero,
    this.minZoom = 0.1,
    this.maxZoom = 5.0,
  });

  /// 初始状态
  static const initial = TransformSnapshot();

  /// 转换为 TransformModel
  TransformModel toTransformModel() {
    return TransformModel(
      zoom: zoom,
      panOffset: panOffset,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
  }

  /// 从 TransformModel 创建
  factory TransformSnapshot.fromTransformModel(TransformModel model) {
    return TransformSnapshot(
      zoom: model.zoom,
      panOffset: model.panOffset,
      minZoom: model.minZoom,
      maxZoom: model.maxZoom,
    );
  }

  @override
  String toString() =>
      'TransformSnapshot(zoom: ${zoom.toStringAsFixed(2)}, offset: $panOffset)';
}

/// 变换模型（简化版，避免循环依赖）
///
/// 用于实际坐标转换计算。
class TransformModel {
  /// 缩放比例
  final double zoom;

  /// 平移偏移
  final Offset panOffset;

  /// 最小缩放
  final double minZoom;

  /// 最大缩放
  final double maxZoom;

  const TransformModel({
    this.zoom = 1.0,
    this.panOffset = Offset.zero,
    this.minZoom = 0.1,
    this.maxZoom = 5.0,
  });

  /// 场景坐标转屏幕坐标
  Offset toScreen(Offset scene) {
    return Offset(
      scene.dx * zoom + panOffset.dx,
      scene.dy * zoom + panOffset.dy,
    );
  }

  /// 屏幕坐标转场景坐标
  Offset toScene(Offset screen) {
    return Offset(
      (screen.dx - panOffset.dx) / zoom,
      (screen.dy - panOffset.dy) / zoom,
    );
  }

  /// 平移
  TransformModel pan(Offset delta) {
    return TransformModel(
      zoom: zoom,
      panOffset: panOffset + delta,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
  }

  /// 缩放到指定比例
  ///
  /// [newZoom] 目标缩放比例
  /// [center] 缩放中心点（屏幕坐标）
  TransformModel zoomTo(double newZoom, Offset center) {
    final clampedZoom = newZoom.clamp(minZoom, maxZoom);
    if (clampedZoom == zoom) return this;

    final factor = clampedZoom / zoom;

    return TransformModel(
      zoom: clampedZoom,
      panOffset: Offset(
        center.dx - (center.dx - panOffset.dx) * factor,
        center.dy - (center.dy - panOffset.dy) * factor,
      ),
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
  }

  /// 以指定比例缩放
  TransformModel zoomBy(double factor, Offset center) {
    return zoomTo(zoom * factor, center);
  }

  /// 重置
  TransformModel reset() {
    return TransformModel(minZoom: minZoom, maxZoom: maxZoom);
  }

  /// 创建副本
  TransformModel copyWith({
    double? zoom,
    Offset? panOffset,
    double? minZoom,
    double? maxZoom,
  }) {
    return TransformModel(
      zoom: zoom ?? this.zoom,
      panOffset: panOffset ?? this.panOffset,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
    );
  }
}

/// 平移缩放更新类型
enum PanZoomUpdateType {
  /// 开始平移
  startPan,

  /// 更新平移
  updatePan,

  /// 结束平移
  endPan,

  /// 缩放
  zoom,

  /// 重置视图
  reset,

  /// 适配内容
  fitContent,
}

/// 平移缩放更新
class PanZoomUpdate extends BehaviorUpdate {
  /// 更新类型
  final PanZoomUpdateType panZoomType;

  /// 新的变换状态
  final TransformSnapshot? transform;

  /// 平移增量
  final Offset? panDelta;

  /// 缩放因子
  final double? zoomFactor;

  /// 缩放中心
  final Offset? zoomCenter;

  PanZoomUpdate({
    required this.panZoomType,
    this.transform,
    this.panDelta,
    this.zoomFactor,
    this.zoomCenter,
  }) : super(type: panZoomType.name);

  /// 创建开始平移更新
  factory PanZoomUpdate.startPan(Offset position) {
    return PanZoomUpdate(
      panZoomType: PanZoomUpdateType.startPan,
      transform: null,
    );
  }

  /// 创建更新平移更新
  factory PanZoomUpdate.updatePan(Offset delta, TransformSnapshot transform) {
    return PanZoomUpdate(
      panZoomType: PanZoomUpdateType.updatePan,
      panDelta: delta,
      transform: transform,
    );
  }

  /// 创建结束平移更新
  factory PanZoomUpdate.endPan(TransformSnapshot transform) {
    return PanZoomUpdate(
      panZoomType: PanZoomUpdateType.endPan,
      transform: transform,
    );
  }

  /// 创建缩放更新
  factory PanZoomUpdate.zoom(
    double factor,
    Offset center,
    TransformSnapshot transform,
  ) {
    return PanZoomUpdate(
      panZoomType: PanZoomUpdateType.zoom,
      zoomFactor: factor,
      zoomCenter: center,
      transform: transform,
    );
  }

  /// 创建重置更新
  factory PanZoomUpdate.reset(TransformSnapshot transform) {
    return PanZoomUpdate(
      panZoomType: PanZoomUpdateType.reset,
      transform: transform,
    );
  }

  /// 创建适配内容更新
  factory PanZoomUpdate.fitContent(TransformSnapshot transform) {
    return PanZoomUpdate(
      panZoomType: PanZoomUpdateType.fitContent,
      transform: transform,
    );
  }
}

/// 平移缩放行为
///
/// 处理画布的平移和缩放交互：
/// - 鼠标滚轮缩放（以鼠标位置为中心）
/// - 触摸板双指缩放
/// - 空白区域拖拽平移
/// - 中键拖拽平移
///
/// ## 使用示例
///
/// ```dart
/// final panZoomBehavior = PanZoomBehavior(
///   minZoom: 0.1,
///   maxZoom: 5.0,
///   zoomSensitivity: 0.1,
///   onTransformChanged: (transform) {
///     print('Zoom: ${transform.zoom}, Pan: ${transform.panOffset}');
///   },
/// );
///
/// registry.register(panZoomBehavior);
/// ```
class PanZoomBehavior extends Behavior<PanZoomState> {
  /// 最小缩放比例
  final double minZoom;

  /// 最大缩放比例
  final double maxZoom;

  /// 滚轮缩放灵敏度（每刻度缩放比例变化）
  final double zoomSensitivity;

  /// 触摸板缩放灵敏度
  final double touchpadZoomSensitivity;

  /// 是否启用滚轮缩放
  final bool enableWheelZoom;

  /// 是否启用触摸板缩放
  final bool enableTouchpadZoom;

  /// 是否启用拖拽平移
  final bool enableDragPan;

  /// 是否启用中键平移
  final bool enableMiddleButtonPan;

  /// 拖拽平移阈值（像素）
  final double panThreshold;

  /// 缩放到固定比例的快捷键映射
  final Map<String, double> zoomShortcuts;

  /// 回调：变换改变
  final void Function(TransformSnapshot transform)? onTransformChanged;

  PanZoomBehavior({
    super.priority = BehaviorPriority.canvasMin,
    super.name = 'PanZoom',
    this.minZoom = 0.1,
    this.maxZoom = 5.0,
    this.zoomSensitivity = 0.1,
    this.touchpadZoomSensitivity = 0.02,
    this.enableWheelZoom = true,
    this.enableTouchpadZoom = true,
    this.enableDragPan = true,
    this.enableMiddleButtonPan = true,
    this.panThreshold = 3.0,
    this.zoomShortcuts = const {},
    this.onTransformChanged,
  }) {
    state = PanZoomState(
      transform: TransformSnapshot(
        minZoom: minZoom,
        maxZoom: maxZoom,
      ),
    );
  }

  /// 当前缩放比例
  double get zoom => state?.transform.zoom ?? 1.0;

  /// 当前平移偏移
  Offset get panOffset => state?.transform.panOffset ?? Offset.zero;

  /// 是否正在平移
  bool get isPanning => state?.isPanning ?? false;

  /// 是否正在缩放
  bool get isZooming => state?.isZooming ?? false;

  /// 是否处于活动状态
  @override
  bool get isActive => state?.isActive ?? false;

  /// 获取当前变换模型
  TransformModel get transformModel {
    return TransformModel(
      zoom: zoom,
      panOffset: panOffset,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // 行为接口实现
  // ═══════════════════════════════════════════════════════════════════════════════

  @override
  bool canHandle(BehaviorEvent event, BehaviorContext context) {
    // 处理滚轮缩放
    if (event is PanZoomPointerScroll) {
      return enableWheelZoom;
    }

    // 处理触摸板缩放
    if (event is PanZoomScaleStart || event is PanZoomScaleUpdate) {
      return enableTouchpadZoom;
    }

    // 处理中键拖拽平移
    if (event is PanZoomPointerDown) {
      if (event.isMiddleButton && enableMiddleButtonPan) {
        return true;
      }
      // 左键在空白区域按下
      if (event.isLeftButton && enableDragPan && context.isOnCanvas) {
        return true;
      }
    }

    // 处理平移移动
    if (event is PanZoomPointerMove) {
      return isActive && (isPanning || state?.panStartPosition != null);
    }

    // 处理平移结束
    if (event is PanZoomPointerUp) {
      return isActive;
    }

    return false;
  }

  @override
  Future<bool> handle(
    BehaviorEvent event,
    BehaviorContext context,
    void Function(BehaviorUpdate update) update,
  ) async {
    // 滚轮缩放
    if (event is PanZoomPointerScroll) {
      return _handleScroll(event, update);
    }

    // 触摸板缩放开始
    if (event is PanZoomScaleStart) {
      return _handleScaleStart(event, update);
    }

    // 触摸板缩放更新
    if (event is PanZoomScaleUpdate) {
      return _handleScaleUpdate(event, update);
    }

    // 触摸板缩放结束
    if (event is PanZoomScaleEnd) {
      return _handleScaleEnd(event, update);
    }

    // 指针按下（开始平移）
    if (event is PanZoomPointerDown) {
      return _handlePointerDown(event, context, update);
    }

    // 指针移动（更新平移）
    if (event is PanZoomPointerMove) {
      return _handlePointerMove(event, update);
    }

    // 指针抬起（结束平移）
    if (event is PanZoomPointerUp) {
      return _handlePointerUp(event, update);
    }

    return false;
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // 滚轮缩放处理
  // ═══════════════════════════════════════════════════════════════════════════════

  bool _handleScroll(
    PanZoomPointerScroll event,
    void Function(BehaviorUpdate update) update,
  ) {
    // 计算缩放因子
    final delta = event.scrollDelta.dy;
    if (delta == 0) return false;

    // 滚轮向下为负值（缩小），向上为正值（放大）
    final zoomFactor = delta > 0
        ? (1.0 - zoomSensitivity)
        : (1.0 + zoomSensitivity * (delta.abs() / 120));

    // 应用缩放
    final newTransform = transformModel.zoomBy(zoomFactor, event.localPosition);

    // 更新状态
    _updateTransform(newTransform);

    // 发送更新
    update(PanZoomUpdate.zoom(
      zoomFactor,
      event.localPosition,
      state!.transform,
    ));

    return true;
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // 触摸板缩放处理
  // ═══════════════════════════════════════════════════════════════════════════════

  bool _handleScaleStart(
    PanZoomScaleStart event,
    void Function(BehaviorUpdate update) update,
  ) {
    state = state?.copyWith(
      isZooming: true,
      zoomFocusPoint: event.localFocalPoint,
    );

    return true;
  }

  bool _handleScaleUpdate(
    PanZoomScaleUpdate event,
    void Function(BehaviorUpdate update) update,
  ) {
    if (state == null || !state!.isZooming) return false;

    // 应用缩放
    final zoomFactor = event.scale;
    final center = event.localFocalPoint;

    final newTransform = transformModel.zoomTo(
      zoom * zoomFactor / (state!.transform.zoom / zoom * zoom),
      center,
    );

    _updateTransform(newTransform);

    update(PanZoomUpdate.zoom(
      zoomFactor,
      center,
      state!.transform,
    ));

    return true;
  }

  bool _handleScaleEnd(
    PanZoomScaleEnd event,
    void Function(BehaviorUpdate update) update,
  ) {
    state = state?.copyWith(
      isZooming: false,
      clearZoomFocus: true,
    );

    return true;
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // 平移处理
  // ═══════════════════════════════════════════════════════════════════════════════

  bool _handlePointerDown(
    PanZoomPointerDown event,
    BehaviorContext context,
    void Function(BehaviorUpdate update) update,
  ) {
    // 开始平移
    state = state?.copyWith(
      isPanning: true,
      panStartPosition: event.localPosition,
      panStartOffset: panOffset,
    );

    update(PanZoomUpdate.startPan(event.localPosition));

    return true;
  }

  bool _handlePointerMove(
    PanZoomPointerMove event,
    void Function(BehaviorUpdate update) update,
  ) {
    if (state == null || !state!.isPanning) return false;

    // 计算平移增量
    final delta = event.delta;

    // 应用平移
    final newTransform = transformModel.pan(delta);
    _updateTransform(newTransform);

    // 发送更新
    update(PanZoomUpdate.updatePan(delta, state!.transform));

    return true;
  }

  bool _handlePointerUp(
    PanZoomPointerUp event,
    void Function(BehaviorUpdate update) update,
  ) {
    if (state == null) return false;

    // 结束平移
    state = state?.copyWith(
      isPanning: false,
      clearPanStart: true,
    );

    update(PanZoomUpdate.endPan(state!.transform));

    return true;
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // 公共 API
  // ═══════════════════════════════════════════════════════════════════════════════

  /// 缩放到指定比例
  ///
  /// [newZoom] 目标缩放比例
  /// [center] 缩放中心点（屏幕坐标），默认为视口中心
  void zoomTo(double newZoom, {Offset? center}) {
    final effectiveCenter = center ?? Offset.zero;
    final newTransform = transformModel.zoomTo(newZoom, effectiveCenter);
    _updateTransform(newTransform);
    onTransformChanged?.call(state!.transform);
  }

  /// 以指定比例缩放
  ///
  /// [factor] 缩放因子（>1 放大，<1 缩小）
  /// [center] 缩放中心点
  void zoomBy(double factor, {Offset? center}) {
    final effectiveCenter = center ?? Offset.zero;
    final newTransform = transformModel.zoomBy(factor, effectiveCenter);
    _updateTransform(newTransform);
    onTransformChanged?.call(state!.transform);
  }

  /// 平移指定偏移
  void panBy(Offset delta) {
    final newTransform = transformModel.pan(delta);
    _updateTransform(newTransform);
    onTransformChanged?.call(state!.transform);
  }

  /// 设置平移偏移
  void setPanOffset(Offset offset) {
    final newTransform = transformModel.copyWith(panOffset: offset);
    _updateTransform(newTransform);
    onTransformChanged?.call(state!.transform);
  }

  /// 重置视图变换
  void resetView() {
    final newTransform = transformModel.reset();
    _updateTransform(newTransform);
    onTransformChanged?.call(state!.transform);
  }

  /// 适配内容到视口
  ///
  /// [contentBounds] 内容边界（场景坐标）
  /// [viewportSize] 视口尺寸
  /// [padding] 内边距
  void fitContent(
    Rect contentBounds,
    Size viewportSize, {
    double padding = 50.0,
  }) {
    if (contentBounds == Rect.zero || viewportSize == Size.zero) {
      resetView();
      return;
    }

    // 计算包含 padding 的内容尺寸
    final contentWidth = contentBounds.width + padding * 2;
    final contentHeight = contentBounds.height + padding * 2;

    // 计算适配视口所需的缩放比例
    final scaleX = viewportSize.width / contentWidth;
    final scaleY = viewportSize.height / contentHeight;
    final scale = (scaleX < scaleY ? scaleX : scaleY).clamp(minZoom, maxZoom);

    // 计算 panOffset 使内容居中
    final offsetX = (viewportSize.width - contentWidth * scale) / 2 -
        contentBounds.left * scale +
        padding * scale;
    final offsetY = (viewportSize.height - contentHeight * scale) / 2 -
        contentBounds.top * scale +
        padding * scale;

    final newTransform = TransformModel(
      zoom: scale,
      panOffset: Offset(offsetX, offsetY),
      minZoom: minZoom,
      maxZoom: maxZoom,
    );

    _updateTransform(newTransform);
    onTransformChanged?.call(state!.transform);
  }

  /// 将场景点移动到视口中心
  void centerOn(Offset scenePoint, Size viewportSize) {
    final newPanOffset = Offset(
      viewportSize.width / 2 - scenePoint.dx * zoom,
      viewportSize.height / 2 - scenePoint.dy * zoom,
    );

    final newTransform = transformModel.copyWith(panOffset: newPanOffset);
    _updateTransform(newTransform);
    onTransformChanged?.call(state!.transform);
  }

  /// 设置变换状态
  void setTransform(TransformSnapshot transform) {
    state = PanZoomState(
      transform: TransformSnapshot(
        zoom: transform.zoom.clamp(minZoom, maxZoom),
        panOffset: transform.panOffset,
        minZoom: minZoom,
        maxZoom: maxZoom,
      ),
    );
    onTransformChanged?.call(state!.transform);
  }

  @override
  void reset() {
    state = PanZoomState(
      transform: TransformSnapshot(minZoom: minZoom, maxZoom: maxZoom),
    );
  }

  /// 更新变换状态
  void _updateTransform(TransformModel transform) {
    state = state?.copyWith(
      transform: TransformSnapshot(
        zoom: transform.zoom,
        panOffset: transform.panOffset,
        minZoom: transform.minZoom,
        maxZoom: transform.maxZoom,
      ),
    );
  }

  @override
  String toString() =>
      'PanZoomBehavior(zoom: ${zoom.toStringAsFixed(2)}, panning: $isPanning)';
}

// ═══════════════════════════════════════════════════════════════════════════════
// 事件类型定义
// ═══════════════════════════════════════════════════════════════════════════════

/// 滚轮事件
class PanZoomPointerScroll extends BehaviorEvent {
  /// 本地坐标
  final Offset localPosition;

  /// 全局坐标
  final Offset position;

  /// 滚动增量
  final Offset scrollDelta;

  const PanZoomPointerScroll({
    required this.localPosition,
    required this.position,
    required this.scrollDelta,
    required super.timestamp,
    super.deviceKind,
  });
}

/// 指针按下事件
class PanZoomPointerDown extends BehaviorEvent {
  /// 本地坐标
  final Offset localPosition;

  /// 全局坐标
  final Offset position;

  /// 按下的按钮
  final int buttons;

  const PanZoomPointerDown({
    required this.localPosition,
    required this.position,
    required this.buttons,
    required super.timestamp,
    super.deviceKind,
  });

  /// 是否左键按下
  bool get isLeftButton => buttons & kPrimaryMouseButton != 0;

  /// 是否右键按下
  bool get isRightButton => buttons & kSecondaryMouseButton != 0;

  /// 是否中键按下
  bool get isMiddleButton => buttons & kTertiaryMouseButton != 0;
}

/// 指针移动事件
class PanZoomPointerMove extends BehaviorEvent {
  /// 本地坐标
  final Offset localPosition;

  /// 全局坐标
  final Offset position;

  /// 移动增量
  final Offset delta;

  /// 当前按下的按钮
  final int buttons;

  const PanZoomPointerMove({
    required this.localPosition,
    required this.position,
    required this.delta,
    required this.buttons,
    required super.timestamp,
    super.deviceKind,
  });

  /// 是否左键按下
  bool get isLeftButton => buttons & kPrimaryMouseButton != 0;

  /// 是否中键按下
  bool get isMiddleButton => buttons & kTertiaryMouseButton != 0;
}

/// 指针抬起事件
class PanZoomPointerUp extends BehaviorEvent {
  /// 本地坐标
  final Offset localPosition;

  /// 全局坐标
  final Offset position;

  const PanZoomPointerUp({
    required this.localPosition,
    required this.position,
    required super.timestamp,
    super.deviceKind,
  });
}

/// 缩放开始事件（触摸板）
class PanZoomScaleStart extends BehaviorEvent {
  /// 本地焦点
  final Offset localFocalPoint;

  const PanZoomScaleStart({
    required this.localFocalPoint,
    required super.timestamp,
    super.deviceKind,
  });
}

/// 缩放更新事件（触摸板）
class PanZoomScaleUpdate extends BehaviorEvent {
  /// 本地焦点
  final Offset localFocalPoint;

  /// 缩放比例
  final double scale;

  /// 旋转角度
  final double rotation;

  const PanZoomScaleUpdate({
    required this.localFocalPoint,
    required this.scale,
    this.rotation = 0.0,
    required super.timestamp,
    super.deviceKind,
  });
}

/// 缩放结束事件（触摸板）
class PanZoomScaleEnd extends BehaviorEvent {
  /// 速度
  final Offset velocity;

  const PanZoomScaleEnd({
    this.velocity = Offset.zero,
    required super.timestamp,
    super.deviceKind,
  });
}

/// 鼠标按钮常量
const int kPrimaryMouseButton = 1;
const int kSecondaryMouseButton = 2;
const int kTertiaryMouseButton = 4;

/// 平移缩放行为配置
class PanZoomBehaviorConfig {
  /// 最小缩放
  final double minZoom;

  /// 最大缩放
  final double maxZoom;

  /// 滚轮缩放灵敏度
  final double zoomSensitivity;

  /// 是否启用滚轮缩放
  final bool enableWheelZoom;

  /// 是否启用拖拽平移
  final bool enableDragPan;

  /// 是否启用中键平移
  final bool enableMiddleButtonPan;

  const PanZoomBehaviorConfig({
    this.minZoom = 0.1,
    this.maxZoom = 5.0,
    this.zoomSensitivity = 0.1,
    this.enableWheelZoom = true,
    this.enableDragPan = true,
    this.enableMiddleButtonPan = true,
  });

  /// 默认配置
  static const defaultConfig = PanZoomBehaviorConfig();

  /// 只读配置（只允许平移和缩放）
  static const readOnlyConfig = PanZoomBehaviorConfig();

  /// 复制并修改
  PanZoomBehaviorConfig copyWith({
    double? minZoom,
    double? maxZoom,
    double? zoomSensitivity,
    bool? enableWheelZoom,
    bool? enableDragPan,
    bool? enableMiddleButtonPan,
  }) {
    return PanZoomBehaviorConfig(
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      zoomSensitivity: zoomSensitivity ?? this.zoomSensitivity,
      enableWheelZoom: enableWheelZoom ?? this.enableWheelZoom,
      enableDragPan: enableDragPan ?? this.enableDragPan,
      enableMiddleButtonPan: enableMiddleButtonPan ?? this.enableMiddleButtonPan,
    );
  }
}
