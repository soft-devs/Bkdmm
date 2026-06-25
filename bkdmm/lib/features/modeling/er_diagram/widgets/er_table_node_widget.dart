import 'package:flutter/material.dart';
import 'package:graphview/graphview.dart';

import '../../../../shared/models/models.dart';
import '../../../../shared/theme/td_theme.dart';
import '../models/er_diagram_ui_state.dart';

/// ER 表格节点 Widget
///
/// 使用 Flutter Widget 渲染 ER 图中的表节点
class ERTableNodeWidget extends StatelessWidget {
  /// graphview Node 实例
  final Node node;

  /// 实体数据
  final Entity entity;

  /// 图节点数据（位置等）
  final GraphNode graphNode;

  /// 是否选中
  final bool isSelected;

  /// 是否显示锚点（编辑模式）
  final bool showAnchors;

  /// 是否可拖动（编辑模式）
  final bool isDraggable;

  /// 是否暗色模式
  final bool isDarkMode;

  /// 锚点点击回调
  final void Function(ERFieldAnchor)? onAnchorTap;

  /// 节点点击回调
  final VoidCallback? onTap;

  /// 节点双击回调
  final VoidCallback? onDoubleTap;

  /// 节点拖动开始回调
  final void Function(DragStartDetails)? onDragStart;

  /// 节点拖动更新回调
  final void Function(DragUpdateDetails)? onDragUpdate;

  /// 节点拖动结束回调
  final VoidCallback? onDragEnd;

  /// 布局常量
  static const double defaultWidth = 200.0;
  static const double headerHeight = 40.0;
  static const double fieldRowHeight = 28.0;
  static const double cornerRadius = 8.0;
  static const double anchorOffset = 8.0;
  static const double anchorVisualSize = 6.0;
  static const double anchorHitSize = 20.0;

  const ERTableNodeWidget({
    super.key,
    required this.node,
    required this.entity,
    required this.graphNode,
    this.isSelected = false,
    this.showAnchors = false,
    this.isDraggable = false,
    this.isDarkMode = false,
    this.onAnchorTap,
    this.onTap,
    this.onDoubleTap,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode || Theme.of(context).brightness == Brightness.dark;

    // 节点主体
    Widget content = GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: MouseRegion(
        cursor: isDraggable ? SystemMouseCursors.grab : SystemMouseCursors.click,
        child: Container(
          width: defaultWidth,
          decoration: BoxDecoration(
            color: TDAppTheme.getNodeBgColor(isDark, isSelected),
            borderRadius: BorderRadius.circular(cornerRadius),
            border: isSelected
                ? Border.all(
                    color: TDAppTheme.getSelectionBorderColor(isDark),
                    width: 2,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 节点主体
              ClipRRect(
                borderRadius: BorderRadius.circular(cornerRadius),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(isDark),
                    ...entity.fields.asMap().entries.map((entry) =>
                        _buildFieldRow(entry.key, entry.value, isDark)),
                  ],
                ),
              ),
              // 锚点层（编辑模式）
              if (showAnchors) _buildAnchorLayer(isDark),
            ],
          ),
        ),
      ),
    );

    // 如果可拖动，包裹拖动手势
    if (isDraggable && onDragStart != null) {
      content = GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onPanStart: onDragStart,
        onPanUpdate: onDragUpdate,
        onPanEnd: (_) => onDragEnd?.call(),
        child: content,
      );
    }

    return content;
  }

  /// 构建表头
  Widget _buildHeader(bool isDark) {
    return Container(
      height: headerHeight,
      decoration: BoxDecoration(
        color: TDAppTheme.getNodeHeaderColor(isDark),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(cornerRadius),
          topRight: Radius.circular(cornerRadius),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(
              Icons.table_rows,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entity.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (entity.chnname.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  entity.chnname,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建字段行
  Widget _buildFieldRow(int index, Field field, bool isDark) {
    return Container(
      height: fieldRowHeight,
      color: index % 2 == 1 && !isDark ? Colors.grey.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // 主键图标
            if (field.pk)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.vpn_key,
                  size: 14,
                  color: Colors.amber.shade600,
                ),
              ),
            // 字段名
            Expanded(
              child: Text(
                field.name,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontWeight: field.pk ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            // 字段类型
            Text(
              _formatFieldType(field),
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建锚点层
  Widget _buildAnchorLayer(bool isDark) {
    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < entity.fields.length; i++) ...[
            _buildAnchor(i, ERAnchorDirection.left, isDark),
            _buildAnchor(i, ERAnchorDirection.right, isDark),
          ],
        ],
      ),
    );
  }

  /// 构建单个锚点
  Widget _buildAnchor(int fieldIndex, ERAnchorDirection direction, bool isDark) {
    final field = entity.fields[fieldIndex];
    final rowY = headerHeight + (fieldIndex * fieldRowHeight) + fieldRowHeight / 2;

    // 计算锚点位置
    final left = direction == ERAnchorDirection.left
        ? -anchorOffset - anchorHitSize / 2
        : null;
    final right = direction == ERAnchorDirection.right
        ? -anchorOffset - anchorHitSize / 2
        : null;

    final anchor = ERFieldAnchor(
      nodeId: entity.id,
      fieldIndex: fieldIndex,
      direction: direction,
      position: Offset(
        direction == ERAnchorDirection.left
            ? graphNode.x - anchorOffset
            : graphNode.x + defaultWidth + anchorOffset,
        graphNode.y + rowY,
      ),
    );

    final color = field.pk ? Colors.amber.shade600 : Colors.blue.shade500;

    return Positioned(
      left: left,
      right: right,
      top: rowY - anchorHitSize / 2,
      child: Listener(
        onPointerDown: (_) {
          onAnchorTap?.call(anchor);
        },
        behavior: HitTestBehavior.opaque,
        child: MouseRegion(
          cursor: SystemMouseCursors.cell,
          child: SizedBox(
            width: anchorHitSize,
            height: anchorHitSize,
            child: Center(
              child: Container(
                width: anchorVisualSize,
                height: anchorVisualSize,
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

  /// 格式化字段类型
  String _formatFieldType(Field field) {
    var type = field.type;
    if (field.length != null) {
      type += '(${field.length}';
      if (field.decimal != null) {
        type += ',${field.decimal}';
      }
      type += ')';
    }
    return type;
  }

  /// 计算节点高度
  static double calculateNodeHeight(int fieldCount) {
    const minHeight = 80.0;
    final height = headerHeight + (fieldCount * fieldRowHeight);
    return height < minHeight ? minHeight : height;
  }

  /// 计算节点尺寸
  static Size calculateNodeSize(int fieldCount) {
    return Size(defaultWidth, calculateNodeHeight(fieldCount));
  }
}
