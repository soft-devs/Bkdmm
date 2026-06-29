/// 图表上下文
///
/// 提供事件处理所需的上下文信息，包括：
/// - 图表状态
/// - 坐标转换
/// - 命中测试结果
library;

import 'dart:ui';
import 'package:flutter/material.dart' show Matrix4, MatrixUtils;
import '../core/diagram_node.dart';
import '../core/diagram_edge.dart';
import '../core/diagram_state.dart' hide InteractionMode;
import '../integration/er_interaction_manager.dart' show InteractionMode;

/// 图表上下文
///
/// 包含处理事件所需的全部信息
class DiagramContext {
  /// 图表 ID
  final String diagramId;

  /// 图表类型
  final String diagramType;

  /// 当前图表状态
  final DiagramState state;

  /// 变换矩阵（用于坐标转换）
  final Matrix4 transform;

  /// 当前交互模式
  final InteractionMode interactionMode;

  /// 是否为暗色模式
  final bool isDarkMode;

  /// 命中测试结果
  final HitTestResult hitTestResult;

  const DiagramContext({
    required this.diagramId,
    required this.diagramType,
    required this.state,
    required this.transform,
    this.interactionMode = InteractionMode.edit,
    this.isDarkMode = false,
    this.hitTestResult = const HitTestResult.empty(),
  });

  // ═══════════════════════════════════════════════════════════════════
  // 坐标转换
  // ═══════════════════════════════════════════════════════════════════

  /// 屏幕坐标转场景坐标
  Offset toScene(Offset screen) {
    final inverse = Matrix4.tryInvert(transform) ?? Matrix4.identity();
    return MatrixUtils.transformPoint(inverse, screen);
  }

  /// 场景坐标转屏幕坐标
  Offset toScreen(Offset scene) {
    return MatrixUtils.transformPoint(transform, scene);
  }

  /// 获取当前缩放比例
  double get zoom => transform.getMaxScaleOnAxis();

  // ═══════════════════════════════════════════════════════════════════
  // 命中测试辅助方法
  // ═══════════════════════════════════════════════════════════════════

  /// 是否命中节点
  bool get isOnNode => hitTestResult.isOnNode;

  /// 是否命中锚点
  bool get isOnAnchor => hitTestResult.isOnAnchor;

  /// 是否命中边
  bool get isOnEdge => hitTestResult.isOnEdge;

  /// 是否命中空白区域
  bool get isOnCanvas => hitTestResult.isOnCanvas;

  /// 获取命中的节点 ID
  String? get hitNodeId => hitTestResult.nodeId;

  /// 获取命中的锚点
  AnchorPoint? get hitAnchor => hitTestResult.anchor;

  /// 获取命中的边 ID
  String? get hitEdgeId => hitTestResult.edgeId;

  // ═══════════════════════════════════════════════════════════════════
  // 状态辅助方法
  // ═══════════════════════════════════════════════════════════════════

  /// 获取选中节点数量
  int get selectedNodeCount => state.selection.selectedNodeIds.length;

  /// 是否有选中节点
  bool get hasSelection => state.selection.hasSelection;

  /// 是否有多选
  bool get hasMultiSelection => state.selection.hasMultiSelection;

  /// 是否正在拖拽
  bool get isDragging => state.interaction.isDragging;

  /// 是否正在连线
  bool get isConnecting => state.interaction.isConnecting;

  /// 是否处于空闲状态
  bool get isIdle => state.interaction.isIdle;

  /// 是否处于编辑模式
  bool get isEditMode => interactionMode == InteractionMode.edit;

  /// 是否处于预览模式
  bool get isPreviewMode => interactionMode == InteractionMode.move;

  // ═══════════════════════════════════════════════════════════════════
  // 复制方法
  // ═══════════════════════════════════════════════════════════════════

  DiagramContext copyWith({
    String? diagramId,
    String? diagramType,
    DiagramState? state,
    Matrix4? transform,
    InteractionMode? interactionMode,
    bool? isDarkMode,
    HitTestResult? hitTestResult,
  }) {
    return DiagramContext(
      diagramId: diagramId ?? this.diagramId,
      diagramType: diagramType ?? this.diagramType,
      state: state ?? this.state,
      transform: transform ?? this.transform,
      interactionMode: interactionMode ?? this.interactionMode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      hitTestResult: hitTestResult ?? this.hitTestResult,
    );
  }
}

/// 命中测试结果
///
/// 记录在特定位置的命中测试信息
class HitTestResult {
  /// 命中的节点 ID
  final String? nodeId;

  /// 命中的节点
  final DiagramNode? node;

  /// 命中的锚点
  final AnchorPoint? anchor;

  /// 命中的边 ID
  final String? edgeId;

  /// 命中的边
  final DiagramEdge? edge;

  /// 命中位置（场景坐标）
  final Offset hitPosition;

  /// 命中类型
  final HitTestType type;

  const HitTestResult({
    this.nodeId,
    this.node,
    this.anchor,
    this.edgeId,
    this.edge,
    required this.hitPosition,
    this.type = HitTestType.canvas,
  });

  /// 空命中结果
  const HitTestResult.empty()
      : nodeId = null,
        node = null,
        anchor = null,
        edgeId = null,
        edge = null,
        hitPosition = Offset.zero,
        type = HitTestType.canvas;

  /// 创建节点命中结果
  factory HitTestResult.node(
    DiagramNode node,
    Offset position,
  ) {
    return HitTestResult(
      nodeId: node.id,
      node: node,
      hitPosition: position,
      type: HitTestType.node,
    );
  }

  /// 创建锚点命中结果
  factory HitTestResult.anchor(
    AnchorPoint anchor,
    Offset position,
  ) {
    return HitTestResult(
      nodeId: anchor.node.id,
      node: anchor.node,
      anchor: anchor,
      hitPosition: position,
      type: HitTestType.anchor,
    );
  }

  /// 创建边命中结果
  factory HitTestResult.edge(
    DiagramEdge edge,
    Offset position,
  ) {
    return HitTestResult(
      edgeId: edge.id,
      edge: edge,
      hitPosition: position,
      type: HitTestType.edge,
    );
  }

  /// 创建画布命中结果
  factory HitTestResult.canvas(Offset position) {
    return HitTestResult(
      hitPosition: position,
      type: HitTestType.canvas,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 属性检查
  // ═══════════════════════════════════════════════════════════════════

  bool get isOnNode => type == HitTestType.node;
  bool get isOnAnchor => type == HitTestType.anchor;
  bool get isOnEdge => type == HitTestType.edge;
  bool get isOnCanvas => type == HitTestType.canvas;

  /// 是否命中任何元素
  bool get hasHit => type != HitTestType.canvas;
}

/// 命中测试类型
enum HitTestType {
  /// 命中节点
  node,

  /// 命中锚点
  anchor,

  /// 命中边
  edge,

  /// 命中空白画布
  canvas,
}