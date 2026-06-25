import 'package:flutter/material.dart';

import '../models/er_diagram_ui_state.dart';

/// ER 图字段锚点组件
///
/// 显示在表节点字段的左右两侧，用于创建实体关系连线。
/// 仅在编辑模式下显示。
class ERFieldAnchorWidget extends StatelessWidget {
  /// 锚点方向
  final ERAnchorDirection direction;

  /// 字段索引
  final int fieldIndex;

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
    required this.direction,
    required this.fieldIndex,
    this.isPrimaryKey = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPrimaryKey ? Colors.amber.shade600 : Colors.blue.shade500;

    return Listener(
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
    );
  }
}

/// 锚点层组件
///
/// 管理单个表节点的所有字段锚点。
/// 锚点使用相对定位，跟随节点移动。
class ERFieldAnchorLayer extends StatelessWidget {
  /// 实体 ID
  final String entityId;

  /// 字段数量
  final int fieldCount;

  /// 字段主键标记列表
  final List<bool> primaryKeyFlags;

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
    // 计算锚点相对于节点顶部的 Y 偏移
    final rowY = headerHeight + (fieldIndex * fieldRowHeight) + fieldRowHeight / 2;
    final isPrimaryKey = fieldIndex < primaryKeyFlags.length && primaryKeyFlags[fieldIndex];
    final color = isPrimaryKey ? Colors.amber.shade600 : Colors.blue.shade500;

    return Positioned(
      left: direction == ERAnchorDirection.left
          ? -ERFieldAnchorWidget.anchorOffset - ERFieldAnchorWidget.hitSize / 2
          : null,
      right: direction == ERAnchorDirection.right
          ? -ERFieldAnchorWidget.anchorOffset - ERFieldAnchorWidget.hitSize / 2
          : null,
      top: rowY - ERFieldAnchorWidget.hitSize / 2,
      width: ERFieldAnchorWidget.hitSize,
      height: ERFieldAnchorWidget.hitSize,
      child: Listener(
        behavior: HitTestBehavior.opaque, // 拦截事件，不传递给父级
        onPointerDown: (_) {
          // 创建锚点数据
          final anchor = ERFieldAnchor(
            nodeId: entityId,
            fieldIndex: fieldIndex,
            direction: direction,
            position: Offset.zero, // 实际位置在画布中计算
          );
          onAnchorTap?.call(anchor);
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.cell,
          child: Center(
            child: Container(
              width: ERFieldAnchorWidget.visualSize,
              height: ERFieldAnchorWidget.visualSize,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
