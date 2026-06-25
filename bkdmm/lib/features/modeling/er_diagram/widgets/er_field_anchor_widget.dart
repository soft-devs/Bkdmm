import 'package:flutter/material.dart';

import '../models/er_diagram_ui_state.dart';

/// ER 图字段锚点组件
///
/// 显示在表节点字段的左右两侧，用于创建实体关系连线。
/// 仅在编辑模式下显示。
class ERFieldAnchorWidget extends StatelessWidget {
  /// 锚点数据
  final ERFieldAnchor anchor;

  /// 是否是主键字段（影响颜色）
  final bool isPrimaryKey;

  /// 点击回调
  final VoidCallback? onTap;

  /// 锚点视觉尺寸（实际显示大小）
  static const double visualSize = 6.0;

  /// 锚点点击区域大小（热区）
  static const double hitSize = 20.0;

  /// 锚点距离节点边缘的偏移
  static const double anchorOffset = 8.0;

  const ERFieldAnchorWidget({
    super.key,
    required this.anchor,
    this.isPrimaryKey = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPrimaryKey ? Colors.amber.shade600 : Colors.blue.shade500;

    return Positioned(
      left: anchor.direction == ERAnchorDirection.left
          ? -anchorOffset - hitSize / 2
          : null,
      right: anchor.direction == ERAnchorDirection.right
          ? -anchorOffset - hitSize / 2
          : null,
      top: anchor.position.dy - hitSize / 2,
      child: Listener(
        onPointerDown: (_) {
          onTap?.call();
        },
        behavior: HitTestBehavior.opaque,
        child: MouseRegion(
          cursor: SystemMouseCursors.cell,
          child: SizedBox(
            width: hitSize,
            height: hitSize,
            child: Center(
              child: Container(
                width: visualSize,
                height: visualSize,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 锚点层组件
///
/// 管理单个表节点的所有字段锚点
class ERFieldAnchorLayer extends StatelessWidget {
  /// 实体 ID
  final String entityId;

  /// 字段数量
  final int fieldCount;

  /// 字段主键标记列表
  final List<bool> primaryKeyFlags;

  /// 节点位置
  final Offset nodePosition;

  /// 节点宽度
  final double nodeWidth;

  /// 表头高度
  final double headerHeight;

  /// 字段行高度
  final double fieldRowHeight;

  /// 锚点点击回调
  final void Function(ERFieldAnchor anchor)? onAnchorTap;

  const ERFieldAnchorLayer({
    super.key,
    required this.entityId,
    required this.fieldCount,
    required this.primaryKeyFlags,
    required this.nodePosition,
    required this.nodeWidth,
    this.headerHeight = 40.0,
    this.fieldRowHeight = 28.0,
    this.onAnchorTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < fieldCount; i++) ...[
            _buildAnchor(i, ERAnchorDirection.left),
            _buildAnchor(i, ERAnchorDirection.right),
          ],
        ],
      ),
    );
  }

  Widget _buildAnchor(int fieldIndex, ERAnchorDirection direction) {
    final rowY = headerHeight + (fieldIndex * fieldRowHeight) + fieldRowHeight / 2;

    final anchor = ERFieldAnchor(
      nodeId: entityId,
      fieldIndex: fieldIndex,
      direction: direction,
      position: Offset(
        direction == ERAnchorDirection.left
            ? nodePosition.dx - ERFieldAnchorWidget.anchorOffset
            : nodePosition.dx + nodeWidth + ERFieldAnchorWidget.anchorOffset,
        nodePosition.dy + rowY,
      ),
    );

    return ERFieldAnchorWidget(
      anchor: anchor,
      isPrimaryKey: fieldIndex < primaryKeyFlags.length && primaryKeyFlags[fieldIndex],
      onTap: onAnchorTap != null ? () => onAnchorTap!(anchor) : null,
    );
  }
}
