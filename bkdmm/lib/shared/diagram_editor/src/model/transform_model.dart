/// 视口变换模型
///
/// 提供视口的缩放、平移和坐标转换功能。
/// 支持手势交互（双指缩放、双指平移、滚轮缩放）和动画过渡。
library;

import 'dart:ui';
import 'package:flutter/material.dart' show Matrix4;

/// 视口变换模型
///
/// 管理视口的变换状态，包括缩放和平移。
/// 所有坐标转换都通过变换矩阵进行计算。
///
/// ## 坐标系统
///
/// - **场景坐标 (Scene)**: 图表内容的逻辑坐标，节点位置使用此坐标
/// - **屏幕坐标 (Screen)**: 视口/Widget 的像素坐标，事件位置使用此坐标
///
/// ## 变换公式
///
/// ```
/// screen = scene * zoom + panOffset
/// scene = (screen - panOffset) / zoom
/// ```
class TransformModel {
  /// 缩放比例
  final double zoom;

  /// 平移偏移（屏幕坐标）
  final Offset panOffset;

  /// 最小缩放比例
  final double minZoom;

  /// 最大缩放比例
  final double maxZoom;

  /// 创建变换模型
  const TransformModel({
    this.zoom = 1.0,
    this.panOffset = Offset.zero,
    this.minZoom = 0.1,
    this.maxZoom = 5.0,
  });

  /// 默认变换
  static const TransformModel identity = TransformModel();

  /// 是否为默认状态
  bool get isIdentity => zoom == 1.0 && panOffset == Offset.zero;

  // ═══════════════════════════════════════════════════════════════════
  // 坐标转换
  // ═══════════════════════════════════════════════════════════════════

  /// 场景坐标转屏幕坐标
  ///
  /// 将图表内容坐标转换为视口像素坐标。
  /// 用于渲染节点和边的位置。
  Offset toScreen(Offset scene) {
    return Offset(
      scene.dx * zoom + panOffset.dx,
      scene.dy * zoom + panOffset.dy,
    );
  }

  /// 屏幕坐标转场景坐标
  ///
  /// 将视口像素坐标转换为图表内容坐标。
  /// 用于处理用户输入事件（点击、拖拽等）。
  Offset toScene(Offset screen) {
    return Offset(
      (screen.dx - panOffset.dx) / zoom,
      (screen.dy - panOffset.dy) / zoom,
    );
  }

  /// 场景尺寸转屏幕尺寸
  ///
  /// 仅缩放尺寸，不涉及平移。
  Size scaleSize(Size size) {
    return Size(size.width * zoom, size.height * zoom);
  }

  /// 场景距离转屏幕距离
  ///
  /// 仅缩放距离，不涉及平移。
  double scaleDistance(double distance) {
    return distance * zoom;
  }

  /// 屏幕距离转场景距离
  double unscaleDistance(double distance) {
    return distance / zoom;
  }

  /// 场景矩形转屏幕矩形
  Rect toScreenRect(Rect sceneRect) {
    final topLeft = toScreen(sceneRect.topLeft);
    final bottomRight = toScreen(sceneRect.bottomRight);
    return Rect.fromPoints(topLeft, bottomRight);
  }

  /// 屏幕矩形转场景矩形
  Rect toSceneRect(Rect screenRect) {
    final topLeft = toScene(screenRect.topLeft);
    final bottomRight = toScene(screenRect.bottomRight);
    return Rect.fromPoints(topLeft, bottomRight);
  }

  // ═══════════════════════════════════════════════════════════════════
  // 变换操作
  // ═══════════════════════════════════════════════════════════════════

  /// 平移视口
  ///
  /// [delta] 为屏幕坐标的偏移量。
  TransformModel pan(Offset delta) {
    return TransformModel(
      zoom: zoom,
      panOffset: panOffset + delta,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
  }

  /// 设置平移偏移
  TransformModel withPanOffset(Offset offset) {
    return TransformModel(
      zoom: zoom,
      panOffset: offset,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
  }

  /// 缩放到指定比例
  ///
  /// [newZoom] 目标缩放比例（会自动 clamp 到 [minZoom] 和 [maxZoom] 之间）
  /// [center] 缩放中心点（屏幕坐标）
  ///
  /// 缩放时会调整 panOffset 以保持 [center] 点在屏幕上的位置不变。
  TransformModel zoomTo(double newZoom, Offset center) {
    final clampedZoom = newZoom.clamp(minZoom, maxZoom);
    if (clampedZoom == zoom) return this;

    // 计算缩放因子
    final factor = clampedZoom / zoom;

    // 调整 panOffset 使中心点保持不变
    // 新的 panOffset = center - (center - panOffset) * factor
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

  /// 以指定比例缩放（以视口中心为中心）
  TransformModel zoomBy(double factor, Size viewportSize) {
    final center = Offset(viewportSize.width / 2, viewportSize.height / 2);
    return zoomTo(zoom * factor, center);
  }

  /// 设置缩放比例（以视口中心为中心）
  TransformModel withZoom(double newZoom, Size viewportSize) {
    final center = Offset(viewportSize.width / 2, viewportSize.height / 2);
    return zoomTo(newZoom, center);
  }

  /// 设置缩放范围
  TransformModel withZoomRange(double min, double max) {
    return TransformModel(
      zoom: zoom.clamp(min, max),
      panOffset: panOffset,
      minZoom: min,
      maxZoom: max,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 视图适配
  // ═══════════════════════════════════════════════════════════════════

  /// 适配内容到视口
  ///
  /// [contentBounds] 内容边界（场景坐标）
  /// [viewportSize] 视口尺寸
  /// [padding] 内边距
  TransformModel fitContent(
    Rect contentBounds,
    Size viewportSize, {
    double padding = 50.0,
  }) {
    if (contentBounds == Rect.zero || viewportSize == Size.zero) {
      return TransformModel(minZoom: minZoom, maxZoom: maxZoom);
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

    return TransformModel(
      zoom: scale,
      panOffset: Offset(offsetX, offsetY),
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
  }

  /// 将指定场景点移动到视口中心
  ///
  /// [scenePoint] 场景坐标点
  /// [viewportSize] 视口尺寸
  TransformModel centerOn(Offset scenePoint, Size viewportSize) {
    return TransformModel(
      zoom: zoom,
      panOffset: Offset(
        viewportSize.width / 2 - scenePoint.dx * zoom,
        viewportSize.height / 2 - scenePoint.dy * zoom,
      ),
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
  }

  /// 重置为默认状态
  TransformModel reset() {
    return TransformModel(minZoom: minZoom, maxZoom: maxZoom);
  }

  // ═══════════════════════════════════════════════════════════════════
  // 矩阵转换
  // ═══════════════════════════════════════════════════════════════════

  /// 转换为 Flutter Matrix4
  ///
  /// 用于 [Transform] widget 或 [InteractiveViewer]。
  Matrix4 toMatrix4() {
    return Matrix4.identity()
      ..translate(panOffset.dx, panOffset.dy)
      ..scale(zoom, zoom);
  }

  /// 从 Flutter Matrix4 创建
  factory TransformModel.fromMatrix4(
    Matrix4 matrix, {
    double minZoom = 0.1,
    double maxZoom = 5.0,
  }) {
    // 从矩阵中提取缩放和平移
    final zoom = matrix.getMaxScaleOnAxis();
    final translation = matrix.getTranslation();
    return TransformModel(
      zoom: zoom.clamp(minZoom, maxZoom),
      panOffset: Offset(translation.x, translation.y),
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
  }

  /// 从 ViewportState 创建（兼容现有代码）
  factory TransformModel.fromViewportState(
    dynamic viewportState, {
    double minZoom = 0.1,
    double maxZoom = 5.0,
  }) {
    // 通过动态类型访问，避免直接依赖
    return TransformModel(
      zoom: (viewportState.zoom as num?)?.toDouble() ?? 1.0,
      panOffset: viewportState.panOffset as Offset? ?? Offset.zero,
      minZoom: (viewportState.minZoom as num?)?.toDouble() ?? minZoom,
      maxZoom: (viewportState.maxZoom as num?)?.toDouble() ?? maxZoom,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 插值（用于动画）
  // ═══════════════════════════════════════════════════════════════════

  /// 线性插值
  ///
  /// 用于平滑过渡动画。
  static TransformModel lerp(
    TransformModel a,
    TransformModel b,
    double t,
  ) {
    if (t <= 0) return a;
    if (t >= 1) return b;

    return TransformModel(
      zoom: a.zoom + (b.zoom - a.zoom) * t,
      panOffset: Offset(
        a.panOffset.dx + (b.panOffset.dx - a.panOffset.dx) * t,
        a.panOffset.dy + (b.panOffset.dy - a.panOffset.dy) * t,
      ),
      minZoom: a.minZoom,
      maxZoom: a.maxZoom,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 复制和比较
  // ═══════════════════════════════════════════════════════════════════

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransformModel &&
        other.zoom == zoom &&
        other.panOffset == panOffset &&
        other.minZoom == minZoom &&
        other.maxZoom == maxZoom;
  }

  @override
  int get hashCode => Object.hash(zoom, panOffset, minZoom, maxZoom);

  @override
  String toString() {
    return 'TransformModel(zoom: ${zoom.toStringAsFixed(2)}, panOffset: $panOffset)';
  }
}

/// 变换约束
///
/// 定义变换的限制条件。
class TransformConstraints {
  /// 最小缩放
  final double minZoom;

  /// 最大缩放
  final double maxZoom;

  /// 平移边界（场景坐标），null 表示无限制
  final Rect? panBounds;

  const TransformConstraints({
    this.minZoom = 0.1,
    this.maxZoom = 5.0,
    this.panBounds,
  });

  /// 无约束
  static const TransformConstraints unconstrained = TransformConstraints();

  /// 默认约束
  static const TransformConstraints defaults = TransformConstraints();

  /// 约束变换模型
  TransformModel constrain(TransformModel transform) {
    var result = transform.copyWith(
      minZoom: minZoom,
      maxZoom: maxZoom,
    );

    // 约束缩放
    result = result.copyWith(zoom: transform.zoom.clamp(minZoom, maxZoom));

    // 约束平移
    if (panBounds != null) {
      final sceneTopLeft = result.toScene(Offset.zero);

      final clampedTopLeft = Offset(
        sceneTopLeft.dx.clamp(panBounds!.left, panBounds!.right),
        sceneTopLeft.dy.clamp(panBounds!.top, panBounds!.bottom),
      );

      final delta = clampedTopLeft - sceneTopLeft;
      result = result.pan(delta * result.zoom);
    }

    return result;
  }
}
