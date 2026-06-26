import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphview/graphview.dart';

import '../../../../shared/models/models.dart';
import '../../../../shared/theme/td_theme.dart';
import '../../../../utils/logging/logging_service.dart';
import '../models/er_diagram_ui_state.dart';
import 'er_field_anchor_widget.dart';

/// ER 表格节点 Widget
///
/// 使用 Flutter Widget 渲染 ER 图中的表节点。
/// 根据交互模式响应不同的事件。
class ERTableNodeWidget extends StatefulWidget {
  /// graphview Node 实例
  final Node node;

  /// 实体数据
  final Entity entity;

  /// 图节点数据（位置等）
  final GraphNode graphNode;

  /// 是否选中
  final bool isSelected;

  /// 当前交互模式
  final ERInteractionMode interactionMode;

  /// 是否暗色模式
  final bool isDarkMode;

  /// 锚点点击回调
  final void Function(ERFieldAnchor anchor, GraphNode graphNode)? onAnchorTap;

  /// 节点点击回调（编辑模式），参数为是否按下 Ctrl 键
  final void Function(bool isCtrlPressed)? onTap;

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

  const ERTableNodeWidget({
    super.key,
    required this.node,
    required this.entity,
    required this.graphNode,
    this.isSelected = false,
    this.interactionMode = ERInteractionMode.preview,
    this.isDarkMode = false,
    this.onAnchorTap,
    this.onTap,
    this.onDoubleTap,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
  });

  /// 是否是编辑模式
  bool get isEditMode => interactionMode == ERInteractionMode.edit;

  /// 是否是预览模式
  bool get isPreviewMode => interactionMode == ERInteractionMode.preview;

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

  @override
  State<ERTableNodeWidget> createState() => _ERTableNodeWidgetState();
}

class _ERTableNodeWidgetState extends State<ERTableNodeWidget> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode || Theme.of(context).brightness == Brightness.dark;

    // 节点主体
    Widget content = _buildNodeBody(isDark);

    // 编辑模式：可拖动和点击
    if (widget.isEditMode && widget.onDragStart != null) {
      content = GestureDetector(
        behavior: HitTestBehavior.deferToChild, // 让子组件（锚点）优先处理事件
        onTap: _onTap,
        onDoubleTap: widget.onDoubleTap,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: content,
      );
    } else {
      // 预览模式：仅响应双击
      content = GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onDoubleTap: widget.onDoubleTap,
        child: content,
      );
    }

    return content;
  }

  void _onTap() {
    logging.d('[ERTableNode] onTap: ${widget.entity.title}', tag: 'ERCanvas');
    // 检查是否按下 Ctrl 键
    final isCtrlPressed = HardwareKeyboard.instance.logicalKeysPressed
        .contains(LogicalKeyboardKey.controlLeft) ||
        HardwareKeyboard.instance.logicalKeysPressed
        .contains(LogicalKeyboardKey.controlRight);
    widget.onTap?.call(isCtrlPressed);
  }

  void _onPanStart(DragStartDetails details) {
    logging.d('[ERTableNode] onPanStart: ${widget.entity.title}, position=${details.localPosition}', tag: 'ERCanvas');
    _isDragging = true;
    widget.onDragStart?.call(details);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    widget.onDragUpdate?.call(details);
  }

  void _onPanEnd(DragEndDetails details) {
    logging.d('[ERTableNode] onPanEnd: ${widget.entity.title}', tag: 'ERCanvas');
    _isDragging = false;
    widget.onDragEnd?.call();
  }

  /// 构建节点主体
  Widget _buildNodeBody(bool isDark) {
    return MouseRegion(
      cursor: widget.isEditMode ? SystemMouseCursors.grab : MouseCursor.defer,
      child: Container(
        width: ERTableNodeWidget.defaultWidth,
        decoration: BoxDecoration(
          color: TDAppTheme.getNodeBgColor(isDark, widget.isSelected),
          borderRadius: BorderRadius.circular(ERTableNodeWidget.cornerRadius),
          border: widget.isSelected
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
              borderRadius: BorderRadius.circular(ERTableNodeWidget.cornerRadius),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(isDark),
                  ...widget.entity.fields.asMap().entries.map((entry) =>
                      _buildFieldRow(entry.key, entry.value, isDark)),
                ],
              ),
            ),
            // 锚点层（仅编辑模式）
            if (widget.isEditMode) _buildAnchorLayer(isDark),
          ],
        ),
      ),
    );
  }

  /// 构建表头
  Widget _buildHeader(bool isDark) {
    return Container(
      height: ERTableNodeWidget.headerHeight,
      decoration: BoxDecoration(
        color: TDAppTheme.getNodeHeaderColor(isDark),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(ERTableNodeWidget.cornerRadius),
          topRight: Radius.circular(ERTableNodeWidget.cornerRadius),
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
                widget.entity.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (widget.entity.chnname.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  widget.entity.chnname,
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
      height: ERTableNodeWidget.fieldRowHeight,
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
    final primaryKeyFlags = widget.entity.fields.map((f) => f.pk).toList();

    return ERFieldAnchorLayer(
      entityId: widget.entity.id,
      fieldCount: widget.entity.fields.length,
      primaryKeyFlags: primaryKeyFlags,
      headerHeight: ERTableNodeWidget.headerHeight,
      fieldRowHeight: ERTableNodeWidget.fieldRowHeight,
      onAnchorTap: widget.onAnchorTap != null
          ? (anchor) => widget.onAnchorTap!(anchor, widget.graphNode)
          : null,
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
}
