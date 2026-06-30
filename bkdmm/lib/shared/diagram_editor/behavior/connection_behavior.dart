/// 连线行为
///
/// 提供可复用的连线创建交互行为，支持锚点连接、连线预览、连线验证。
/// 可以附加到任何支持 Behavior 协议的组件上。
library;

import 'package:flutter/material.dart';
import 'behavior.dart';

/// 连线状态
class ConnectionState {
  /// 源锚点 ID
  final String sourceAnchorId;

  /// 源锚点位置（场景坐标）
  final Offset sourcePosition;

  /// 当前鼠标位置（场景坐标）
  final Offset currentPosition;

  /// 源节点 ID
  final String sourceNodeId;

  /// 潜在的目标锚点 ID（鼠标悬停在锚点上时）
  final String? targetAnchorId;

  /// 是否有效连接
  final bool isValidConnection;

  /// 连线预览路径
  final List<Offset>? previewPath;

  const ConnectionState({
    required this.sourceAnchorId,
    required this.sourcePosition,
    required this.currentPosition,
    required this.sourceNodeId,
    this.targetAnchorId,
    this.isValidConnection = false,
    this.previewPath,
  });

  /// 创建副本
  ConnectionState copyWith({
    String? sourceAnchorId,
    Offset? sourcePosition,
    Offset? currentPosition,
    String? sourceNodeId,
    String? targetAnchorId,
    bool? isValidConnection,
    List<Offset>? previewPath,
    bool clearTarget = false,
  }) {
    return ConnectionState(
      sourceAnchorId: sourceAnchorId ?? this.sourceAnchorId,
      sourcePosition: sourcePosition ?? this.sourcePosition,
      currentPosition: currentPosition ?? this.currentPosition,
      sourceNodeId: sourceNodeId ?? this.sourceNodeId,
      targetAnchorId: clearTarget ? null : (targetAnchorId ?? this.targetAnchorId),
      isValidConnection: isValidConnection ?? this.isValidConnection,
      previewPath: previewPath ?? this.previewPath,
    );
  }
}

/// 连线行为更新类型
enum ConnectionUpdateType {
  /// 开始连线
  startConnection,

  /// 更新连线预览
  updatePreview,

  /// 完成连线
  completeConnection,

  /// 取消连线
  cancelConnection,

  /// 高亮目标锚点
  highlightAnchor,
}

/// 连线行为更新
class ConnectionUpdate extends BehaviorUpdate {
  /// 更新类型
  final ConnectionUpdateType connectionType;

  /// 源锚点 ID
  final String? sourceAnchorId;

  /// 源位置
  final Offset? sourcePosition;

  /// 当前位置
  final Offset? currentPosition;

  /// 目标锚点 ID
  final String? targetAnchorId;

  /// 是否有效连接
  final bool isValid;

  /// 预览路径
  final List<Offset>? previewPath;

  /// 边类型
  final String? edgeType;

  ConnectionUpdate({
    required this.connectionType,
    this.sourceAnchorId,
    this.sourcePosition,
    this.currentPosition,
    this.targetAnchorId,
    this.isValid = false,
    this.previewPath,
    this.edgeType,
  }) : super(type: connectionType.name);

  /// 创建开始连线更新
  factory ConnectionUpdate.startConnection(
    String sourceAnchorId,
    Offset sourcePosition,
    String sourceNodeId,
  ) {
    return ConnectionUpdate(
      connectionType: ConnectionUpdateType.startConnection,
      sourceAnchorId: sourceAnchorId,
      sourcePosition: sourcePosition,
      currentPosition: sourcePosition,
    );
  }

  /// 创建更新预览更新
  factory ConnectionUpdate.updatePreview(
    Offset currentPosition, {
    String? targetAnchorId,
    bool isValid = false,
    List<Offset>? previewPath,
  }) {
    return ConnectionUpdate(
      connectionType: ConnectionUpdateType.updatePreview,
      currentPosition: currentPosition,
      targetAnchorId: targetAnchorId,
      isValid: isValid,
      previewPath: previewPath,
    );
  }

  /// 创建完成连线更新
  factory ConnectionUpdate.completeConnection(
    String sourceAnchorId,
    String targetAnchorId, {
    String? edgeType,
  }) {
    return ConnectionUpdate(
      connectionType: ConnectionUpdateType.completeConnection,
      sourceAnchorId: sourceAnchorId,
      targetAnchorId: targetAnchorId,
      isValid: true,
      edgeType: edgeType,
    );
  }

  /// 创建取消连线更新
  factory ConnectionUpdate.cancelConnection() {
    return ConnectionUpdate(
      connectionType: ConnectionUpdateType.cancelConnection,
    );
  }

  /// 创建高亮锚点更新
  factory ConnectionUpdate.highlightAnchor(
    String? anchorId, {
    bool isValid = false,
  }) {
    return ConnectionUpdate(
      connectionType: ConnectionUpdateType.highlightAnchor,
      targetAnchorId: anchorId,
      isValid: isValid,
    );
  }
}

/// 连线验证结果
class ConnectionValidationResult {
  /// 是否有效
  final bool isValid;

  /// 错误消息
  final String? errorMessage;

  /// 警告消息
  final String? warningMessage;

  const ConnectionValidationResult({
    required this.isValid,
    this.errorMessage,
    this.warningMessage,
  });

  /// 创建有效结果
  const ConnectionValidationResult.valid()
      : isValid = true,
        errorMessage = null,
        warningMessage = null;

  /// 创建无效结果
  const ConnectionValidationResult.invalid(String message)
      : isValid = false,
        errorMessage = message,
        warningMessage = null;

  /// 创建带警告的有效结果
  const ConnectionValidationResult.withWarning(String warning)
      : isValid = true,
        errorMessage = null,
        warningMessage = warning;
}

/// 连线行为
///
/// 当用户在锚点上按下并拖动时，创建连线。
/// 支持连线验证、预览路径、多种连线样式。
///
/// ## 使用示例
///
/// ```dart
/// final connectionBehavior = ConnectionBehavior(
///   validateConnection: (source, target) {
///     // 自定义验证逻辑
///     return ConnectionValidationResult.valid();
///   },
///   getAnchorPosition: (id) => anchors[id]?.position,
///   getEdgeType: () => 'default',
/// );
///
/// // 添加到行为列表
/// behaviors.add(connectionBehavior);
/// ```
class ConnectionBehavior extends Behavior<ConnectionState> {
  /// 连线验证回调
  final ConnectionValidationResult Function(
          String sourceAnchorId, String targetAnchorId)?
      validateConnection;

  /// 获取锚点位置的回调
  final Offset Function(String anchorId)? getAnchorPosition;

  /// 获取锚点所属节点 ID 的回调
  final String Function(String anchorId)? getAnchorNodeId;

  /// 获取锚点方向的回调
  final AnchorDirection Function(String anchorId)? getAnchorDirection;

  /// 获取默认边类型的回调
  final String Function()? getEdgeType;

  /// 获取可用锚点列表的回调
  final List<String> Function()? getAvailableAnchors;

  /// 检查锚点是否可以连接的回调
  final bool Function(String anchorId, bool asSource)? canAnchorConnect;

  /// 计算预览路径的回调
  final List<Offset> Function(
          Offset start, Offset end, AnchorDirection startDir, AnchorDirection endDir)?
      computePreviewPath;

  /// 连线预览样式
  final EdgePreviewStyle previewStyle;

  /// 是否允许自连接（同一节点的不同锚点）
  final bool allowSelfConnection;

  /// 是否允许重复连接
  final bool allowDuplicateConnection;

  ConnectionBehavior({
    super.priority = 15,
    super.name = 'Connection',
    this.validateConnection,
    this.getAnchorPosition,
    this.getAnchorNodeId,
    this.getAnchorDirection,
    this.getEdgeType,
    this.getAvailableAnchors,
    this.canAnchorConnect,
    this.computePreviewPath,
    this.previewStyle = const EdgePreviewStyle(),
    this.allowSelfConnection = true,
    this.allowDuplicateConnection = false,
  });

  /// 是否正在连线
  bool get isConnecting => state != null;

  /// 当前源锚点 ID
  String? get sourceAnchorId => state?.sourceAnchorId;

  /// 当前目标锚点 ID
  String? get targetAnchorId => state?.targetAnchorId;

  @override
  bool canHandle(BehaviorEvent event, BehaviorContext context) {
    // 只在编辑模式下处理
    if (!_isEditMode(context)) return false;

    // 处理指针按下：检查是否在锚点上
    if (event is ConnectionPointerDown) {
      return event.isLeftButton && context.isOnAnchor;
    }

    // 处理指针移动：正在连线时
    if (event is ConnectionPointerMove) {
      return isActive && event.isLeftButton;
    }

    // 处理指针抬起：完成或取消连线
    if (event is ConnectionPointerUp) {
      return isActive;
    }

    // 处理取消事件
    if (event is ConnectionCancelEvent) {
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
    if (event is ConnectionPointerDown) {
      return _handlePointerDown(event, context, update);
    }

    if (event is ConnectionPointerMove) {
      return _handlePointerMove(event, context, update);
    }

    if (event is ConnectionPointerUp) {
      return _handlePointerUp(event, context, update);
    }

    if (event is ConnectionCancelEvent) {
      return _handleCancel(event, context, update);
    }

    return false;
  }

  /// 处理指针按下
  bool _handlePointerDown(
    ConnectionPointerDown event,
    BehaviorContext context,
    void Function(BehaviorUpdate update) update,
  ) {
    final anchorId = context.hitId;
    if (anchorId == null) return false;

    // 检查锚点是否可以作为连线起点
    if (canAnchorConnect != null && !canAnchorConnect!(anchorId, true)) {
      return false;
    }

    final anchorPosition = getAnchorPosition?.call(anchorId) ?? event.localPosition;
    final nodeId = getAnchorNodeId?.call(anchorId) ?? _extractNodeId(anchorId);

    // 初始化连线状态
    state = ConnectionState(
      sourceAnchorId: anchorId,
      sourcePosition: anchorPosition,
      currentPosition: event.localPosition,
      sourceNodeId: nodeId,
    );

    // 发送开始连线更新
    update(ConnectionUpdate.startConnection(
      anchorId,
      anchorPosition,
      nodeId,
    ));

    return true;
  }

  /// 处理指针移动
  bool _handlePointerMove(
    ConnectionPointerMove event,
    BehaviorContext context,
    void Function(BehaviorUpdate update) update,
  ) {
    if (state == null) return false;

    // 检查是否悬停在锚点上
    String? targetAnchorId;
    bool isValidConnection = false;
    List<Offset>? previewPath;

    if (context.isOnAnchor) {
      targetAnchorId = context.hitId;

      // 检查是否是有效的目标锚点
      if (targetAnchorId != null && targetAnchorId != state!.sourceAnchorId) {
        isValidConnection = _validateTargetAnchor(targetAnchorId);

        // 计算预览路径
        if (isValidConnection) {
          previewPath = _computePreviewPath(targetAnchorId);
        }
      }
    }

    // 更新状态
    state = state!.copyWith(
      currentPosition: event.localPosition,
      targetAnchorId: targetAnchorId,
      isValidConnection: isValidConnection,
      previewPath: previewPath,
    );

    // 发送更新预览
    update(ConnectionUpdate.updatePreview(
      event.localPosition,
      targetAnchorId: targetAnchorId,
      isValid: isValidConnection,
      previewPath: previewPath,
    ));

    return true;
  }

  /// 处理指针抬起
  bool _handlePointerUp(
    ConnectionPointerUp event,
    BehaviorContext context,
    void Function(BehaviorUpdate update) update,
  ) {
    if (state == null) return false;

    // 检查是否完成连线
    if (context.isOnAnchor && state!.isValidConnection) {
      final targetAnchorId = context.hitId;
      if (targetAnchorId != null && targetAnchorId != state!.sourceAnchorId) {
        // 完成连线
        final edgeType = getEdgeType?.call() ?? 'default';
        update(ConnectionUpdate.completeConnection(
          state!.sourceAnchorId,
          targetAnchorId,
          edgeType: edgeType,
        ));
      }
    } else {
      // 取消连线
      update(ConnectionUpdate.cancelConnection());
    }

    // 重置状态
    reset();

    return true;
  }

  /// 处理取消事件
  bool _handleCancel(
    ConnectionCancelEvent event,
    BehaviorContext context,
    void Function(BehaviorUpdate update) update,
  ) {
    if (state == null) return false;

    update(ConnectionUpdate.cancelConnection());
    reset();

    return true;
  }

  /// 验证目标锚点是否有效
  bool _validateTargetAnchor(String targetAnchorId) {
    // 检查是否是同一个锚点
    if (targetAnchorId == state!.sourceAnchorId) {
      return false;
    }

    final targetNodeId = getAnchorNodeId?.call(targetAnchorId) ??
        _extractNodeId(targetAnchorId);

    // 检查自连接
    if (!allowSelfConnection && targetNodeId == state!.sourceNodeId) {
      return false;
    }

    // 检查锚点是否可以作为目标
    if (canAnchorConnect != null && !canAnchorConnect!(targetAnchorId, false)) {
      return false;
    }

    // 执行自定义验证
    if (validateConnection != null) {
      final result = validateConnection!(state!.sourceAnchorId, targetAnchorId);
      return result.isValid;
    }

    return true;
  }

  /// 计算预览路径
  List<Offset>? _computePreviewPath(String targetAnchorId) {
    final sourcePos = state!.sourcePosition;
    final targetPos = getAnchorPosition?.call(targetAnchorId);

    if (targetPos == null) return null;

    // 使用自定义路径计算
    if (computePreviewPath != null) {
      final sourceDir = getAnchorDirection?.call(state!.sourceAnchorId) ??
          AnchorDirection.right;
      final targetDir =
          getAnchorDirection?.call(targetAnchorId) ?? AnchorDirection.left;
      return computePreviewPath!(sourcePos, targetPos, sourceDir, targetDir);
    }

    // 默认返回直线路径
    return [sourcePos, targetPos];
  }

  /// 从锚点 ID 提取节点 ID
  String _extractNodeId(String anchorId) {
    return anchorId.split(':').first;
  }

  /// 判断是否为编辑模式
  bool _isEditMode(BehaviorContext context) {
    // 检查上下文是否有 isEditMode 属性
    // 默认为编辑模式
    return true;
  }

  @override
  MouseCursor? getCursor(BehaviorContext context) {
    if (!context.isOnAnchor || !_isEditMode(context)) return null;

    if (isConnecting) {
      // 正在连线时
      if (context.isOnAnchor && state?.isValidConnection == true) {
        return SystemMouseCursors.click;
      }
      return SystemMouseCursors.cell;
    }

    // 悬停在锚点上
    return SystemMouseCursors.click;
  }

  @override
  void reset() {
    state = null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 事件类型定义
// ═══════════════════════════════════════════════════════════════════════════════

/// 连线指针按下事件
class ConnectionPointerDown extends BehaviorEvent {
  /// 本地坐标
  final Offset localPosition;

  /// 全局坐标
  final Offset position;

  /// 按下的按钮
  final int buttons;

  const ConnectionPointerDown({
    required this.localPosition,
    required this.position,
    required this.buttons,
    required super.timestamp,
    super.deviceKind,
    this.isCtrlPressed = false,
    this.isShiftPressed = false,
    this.isAltPressed = false,
  });

  /// 是否左键按下
  bool get isLeftButton => buttons & kPrimaryMouseButton != 0;

  /// 是否右键按下
  bool get isRightButton => buttons & kSecondaryMouseButton != 0;

  /// 是否中键按下
  bool get isMiddleButton => buttons & kTertiaryMouseButton != 0;

  /// 是否按下 Ctrl
  final bool isCtrlPressed;

  /// 是否按下 Shift
  final bool isShiftPressed;

  /// 是否按下 Alt
  final bool isAltPressed;
}

/// 连线指针移动事件
class ConnectionPointerMove extends BehaviorEvent {
  /// 本地坐标
  final Offset localPosition;

  /// 全局坐标
  final Offset position;

  /// 移动增量
  final Offset delta;

  /// 当前按下的按钮
  final int buttons;

  const ConnectionPointerMove({
    required this.localPosition,
    required this.position,
    required this.delta,
    required this.buttons,
    required super.timestamp,
    super.deviceKind,
  });

  /// 是否左键按下
  bool get isLeftButton => buttons & kPrimaryMouseButton != 0;

  /// 是否右键按下
  bool get isRightButton => buttons & kSecondaryMouseButton != 0;
}

/// 连线指针抬起事件
class ConnectionPointerUp extends BehaviorEvent {
  /// 本地坐标
  final Offset localPosition;

  /// 全局坐标
  final Offset position;

  const ConnectionPointerUp({
    required this.localPosition,
    required this.position,
    required super.timestamp,
    super.deviceKind,
  });
}

/// 连线取消事件
class ConnectionCancelEvent extends BehaviorEvent {
  const ConnectionCancelEvent({
    required super.timestamp,
    super.deviceKind,
  });
}

/// 鼠标按钮常量
const int kPrimaryMouseButton = 1;
const int kSecondaryMouseButton = 2;
const int kTertiaryMouseButton = 4;

// ═══════════════════════════════════════════════════════════════════════════════
// 辅助类型
// ═══════════════════════════════════════════════════════════════════════════════

/// 锚点方向（从 diagram_node.dart 复制以避免循环依赖）
enum AnchorDirection {
  left,
  right,
  top,
  bottom,
}

/// 边预览样式
class EdgePreviewStyle {
  /// 预览线条颜色
  final Color color;

  /// 预览线条宽度
  final double width;

  /// 无效连接时的颜色
  final Color invalidColor;

  /// 预览线条类型
  final EdgePreviewLineType lineType;

  /// 是否显示端点标记
  final bool showEndMarkers;

  /// 端点标记大小
  final double endMarkerSize;

  const EdgePreviewStyle({
    this.color = const Color(0xFF2196F3),
    this.width = 2.0,
    this.invalidColor = const Color(0xFFE53935),
    this.lineType = EdgePreviewLineType.straight,
    this.showEndMarkers = true,
    this.endMarkerSize = 6.0,
  });

  /// 获取实际颜色（根据是否有效）
  Color getColor(bool isValid) => isValid ? color : invalidColor;
}

/// 预览线条类型
enum EdgePreviewLineType {
  /// 直线
  straight,

  /// 曲线
  curved,

  /// 正交线
  orthogonal,
}

/// 连线创建选项
class ConnectionOptions {
  /// 边类型
  final String edgeType;

  /// 边标签
  final String? label;

  /// 源端标记
  final EdgeMarkerOptions? sourceMarker;

  /// 目标端标记
  final EdgeMarkerOptions? targetMarker;

  /// 自定义样式
  final EdgeStyleOptions? style;

  const ConnectionOptions({
    this.edgeType = 'default',
    this.label,
    this.sourceMarker,
    this.targetMarker,
    this.style,
  });
}

/// 边标记选项
class EdgeMarkerOptions {
  /// 标记类型
  final String type;

  /// 标记文本
  final String? text;

  /// 标记颜色
  final Color? color;

  const EdgeMarkerOptions({
    required this.type,
    this.text,
    this.color,
  });

  /// 创建箭头标记
  const EdgeMarkerOptions.arrow({this.color}) : type = 'arrow', text = null;

  /// 创建圆点标记
  const EdgeMarkerOptions.circle({this.color}) : type = 'circle', text = null;

  /// 创建菱形标记
  const EdgeMarkerOptions.diamond({this.color}) : type = 'diamond', text = null;

  /// 创建 "1" 标记（一对一时使用）
  const EdgeMarkerOptions.one({this.color}) : type = 'one', text = '1';

  /// 创建 "N" 标记（一对多时使用）
  const EdgeMarkerOptions.many({this.color}) : type = 'many', text = 'N';
}

/// 边样式选项
class EdgeStyleOptions {
  /// 线条颜色
  final Color? color;

  /// 线条宽度
  final double? width;

  /// 线条类型
  final EdgeLineStyle? lineStyle;

  /// 曲线弯曲程度
  final double? curveFactor;

  const EdgeStyleOptions({
    this.color,
    this.width,
    this.lineStyle,
    this.curveFactor,
  });
}

/// 边线条样式
enum EdgeLineStyle {
  solid,
  dashed,
  dotted,
}
