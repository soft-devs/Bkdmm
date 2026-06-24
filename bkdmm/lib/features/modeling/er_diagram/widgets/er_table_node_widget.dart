import 'package:flutter/material.dart';
import 'package:graphview/graphview.dart';
import '../../shared/models/models.dart';
import '../../shared/theme/td_theme.dart';
import '../core/field_anchor_registry.dart';

/// ER 图表格节点 Widget
///
/// 使用 Flutter Widget 渲染 ER 图中的表节点
/// 保持与原有 Canvas 渲染器的视觉一致性
class ERTableNodeWidget extends StatelessWidget {
  /// graphview Node 实例
  final Node node;

  /// 实体数据
  final Entity entity;

  /// 是否选中
  final bool isSelected;

  /// 是否悬停
  final bool isHovered;

  /// 是否显示锚点（编辑模式）
  final bool showAnchors;

  /// 是否暗色模式
  final bool isDarkMode;

  /// 锚点点击回调
  final void Function(FieldAnchor)? onAnchorTap;

  /// 节点点击回调
  final VoidCallback? onTap;

  /// 节点双击回调
  final VoidCallback? onDoubleTap;

  /// 布局常量（与 ERNodeRenderer 保持一致）
  static const double defaultWidth = 200.0;
  static const double headerHeight = 40.0;
  static const double fieldRowHeight = 28.0;
  static const double padding = 12.0;
  static const double cornerRadius = 8.0;
  static const double anchorOffset = 8.0;
  static const double fieldAnchorSize = 6.0;

  const ERTableNodeWidget({
    super.key,
    required this.node,
    required this.entity,
    this.isSelected = false,
    this.isHovered = false,
    this.showAnchors = false,
    this.isDarkMode = false,
    this.onAnchorTap,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode || Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cornerRadius),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(isDark),
                    ...entity.fields.asMap().entries.map((entry) =>
                        _buildFieldRow(context, entry.key, entry.value, isDark)),
                  ],
                ),
                // 字段锚点（仅在编辑模式显示）
                if (showAnchors) _buildFieldAnchors(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建表头
  Widget _buildHeader(bool isDark) {
    return Container(
      height: headerHeight,
      decoration: BoxDecoration(
        color: TDAppTheme.getNodeHeaderColor(isDark),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: padding),
        child: Row(
          children: [
            // 表图标
            const Icon(
              Icons.table_rows,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            // 表名
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
            // 中文名
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
  Widget _buildFieldRow(BuildContext context, int index, Field field, bool isDark) {
    return Container(
      height: fieldRowHeight,
      color: index % 2 == 1 && !isDark ? Colors.grey.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: padding),
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

  /// 构建字段锚点层
  Widget _buildFieldAnchors(bool isDark) {
    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < entity.fields.length; i++)
            ..._buildAnchorsForField(i, entity.fields[i], isDark),
        ],
      ),
    );
  }

  /// 构建单个字段的左右锚点
  List<Widget> _buildAnchorsForField(int index, Field field, bool isDark) {
    final nodeId = node.key?.value.toString() ?? '';
    final rowY = headerHeight + (index * fieldRowHeight) + fieldRowHeight / 2;

    return [
      // 左锚点（出边连接点）
      Positioned(
        left: -anchorOffset - fieldAnchorSize / 2,
        top: rowY - fieldAnchorSize / 2,
        child: _buildAnchorWidget(
          FieldAnchor(
            nodeId: nodeId,
            fieldIndex: index,
            position: Offset(node.x - anchorOffset, node.y + rowY),
            direction: FieldAnchorDirection.left,
            field: field,
          ),
          isDark,
        ),
      ),
      // 右锚点（入边连接点）
      Positioned(
        right: -anchorOffset - fieldAnchorSize / 2,
        top: rowY - fieldAnchorSize / 2,
        child: _buildAnchorWidget(
          FieldAnchor(
            nodeId: nodeId,
            fieldIndex: index,
            position: Offset(node.x + defaultWidth + anchorOffset, node.y + rowY),
            direction: FieldAnchorDirection.right,
            field: field,
          ),
          isDark,
        ),
      ),
    ];
  }

  /// 构建单个锚点 Widget
  Widget _buildAnchorWidget(FieldAnchor anchor, bool isDark) {
    final color = TDAppTheme.getAnchorColor(anchor.field.pk);

    return GestureDetector(
      onTap: () => onAnchorTap?.call(anchor),
      child: MouseRegion(
        cursor: SystemMouseCursors.crosshair,
        child: Container(
          width: fieldAnchorSize,
          height: fieldAnchorSize,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: 1.5,
            ),
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(4, 4),
              painter: _AnchorDirectionPainter(
                direction: anchor.direction,
                color: color,
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

/// 锚点方向指示器
class _AnchorDirectionPainter extends CustomPainter {
  final FieldAnchorDirection direction;
  final Color color;

  _AnchorDirectionPainter({
    required this.direction,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);

    if (direction == FieldAnchorDirection.left) {
      // 左锚点：箭头向左（出边）
      canvas.drawLine(
        Offset(center.dx + 1, center.dy),
        Offset(center.dx - 1, center.dy),
        paint,
      );
    } else {
      // 右锚点：箭头向右（入边）
      canvas.drawLine(
        Offset(center.dx - 1, center.dy),
        Offset(center.dx + 1, center.dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AnchorDirectionPainter oldDelegate) {
    return direction != oldDelegate.direction || color != oldDelegate.color;
  }
}