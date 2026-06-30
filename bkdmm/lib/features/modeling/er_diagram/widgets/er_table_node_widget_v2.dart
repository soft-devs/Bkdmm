import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/diagram_editor/diagram_editor.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/theme/td_theme.dart';
import '../../../../utils/logging/logging_service.dart';
import '../models/er_diagram_ui_state.dart';
import 'er_field_anchor_widget.dart';

/// ER 表格节点 Widget V2
///
/// 用于 diagram_editor 框架的节点渲染。
/// 支持作为 nodeBuilder 使用。
class ERTableNodeWidgetV2 extends StatefulWidget {
  /// 实体数据
  final Entity entity;

  /// 是否选中
  final bool isSelected;

  /// 是否悬停
  final bool isHovered;

  /// 是否拖拽中
  final bool isDragging;

  /// 当前交互模式
  final ERInteractionMode interactionMode;

  /// 是否暗色模式
  final bool isDarkMode;

  /// 锚点点击回调
  final void Function(ERFieldAnchor anchor)? onAnchorTap;

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

  const ERTableNodeWidgetV2({
    super.key,
    required this.entity,
    this.isSelected = false,
    this.isHovered = false,
    this.isDragging = false,
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

  /// nodeBuilder 静态方法
  ///
  /// 用于 GraphView 的节点构建回调。
  static Widget builder(
    DiagramNode node,
    NodeState nodeState, {
    void Function(ERFieldAnchor anchor)? onAnchorTap,
    void Function(bool isCtrlPressed)? onTap,
    VoidCallback? onDoubleTap,
    void Function(DragStartDetails)? onDragStart,
    void Function(DragUpdateDetails)? onDragUpdate,
    VoidCallback? onDragEnd,
    bool isDarkMode = false,
    ERInteractionMode interactionMode = ERInteractionMode.edit,
  }) {
    if (node is! ERTableNodeModel) {
      return const SizedBox.shrink();
    }

    final erNode = node;

    return ERTableNodeWidgetV2(
      entity: erNode.entity,
      isSelected: nodeState.isSelected,
      isHovered: nodeState.isHovered,
      isDragging: nodeState.isDragging,
      interactionMode: interactionMode,
      isDarkMode: isDarkMode,
      onAnchorTap: onAnchorTap,
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
    );
  }

  @override
  State<ERTableNodeWidgetV2> createState() => _ERTableNodeWidgetV2State();
}

class _ERTableNodeWidgetV2State extends State<ERTableNodeWidgetV2> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode || Theme.of(context).brightness == Brightness.dark;

    Widget content = _buildNodeBody(isDark);

    content = Listener(
      onPointerDown: (event) {
        logging.d('[ERTableNodeV2] Listener onPointerDown: ${widget.entity.title}', tag: 'ERCanvas');
      },
      behavior: HitTestBehavior.opaque,
      child: content,
    );

    if (widget.isEditMode && widget.onDragStart != null) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        onDoubleTap: widget.onDoubleTap,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: content,
      );
    } else {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: widget.onDoubleTap,
        child: content,
      );
    }

    return content;
  }

  void _onTap() {
    logging.d('[ERTableNodeV2] onTap: ${widget.entity.title}', tag: 'ERCanvas');
    final isCtrlPressed = HardwareKeyboard.instance.logicalKeysPressed
        .contains(LogicalKeyboardKey.controlLeft) ||
        HardwareKeyboard.instance.logicalKeysPressed
        .contains(LogicalKeyboardKey.controlRight);
    widget.onTap?.call(isCtrlPressed);
  }

  void _onPanStart(DragStartDetails details) {
    logging.d('[ERTableNodeV2] onPanStart: ${widget.entity.title}', tag: 'ERCanvas');
    _isDragging = true;
    widget.onDragStart?.call(details);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    widget.onDragUpdate?.call(details);
  }

  void _onPanEnd(DragEndDetails details) {
    logging.d('[ERTableNodeV2] onPanEnd: ${widget.entity.title}', tag: 'ERCanvas');
    _isDragging = false;
    widget.onDragEnd?.call();
  }

  Widget _buildNodeBody(bool isDark) {
    return MouseRegion(
      cursor: widget.isEditMode
          ? (widget.isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab)
          : MouseCursor.defer,
      child: Container(
        width: ERTableNodeWidgetV2.defaultWidth,
        decoration: BoxDecoration(
          color: TDAppTheme.getNodeBgColor(isDark, widget.isSelected),
          borderRadius: BorderRadius.circular(ERTableNodeWidgetV2.cornerRadius),
          border: widget.isSelected
              ? Border.all(
                  color: TDAppTheme.getSelectionBorderColor(isDark),
                  width: 2,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDragging ? 0.25 : 0.15),
              blurRadius: widget.isDragging ? 10 : 6,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(ERTableNodeWidgetV2.cornerRadius),
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
            if (widget.isEditMode) _buildAnchorLayer(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      height: ERTableNodeWidgetV2.headerHeight,
      decoration: BoxDecoration(
        color: TDAppTheme.getNodeHeaderColor(isDark),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(ERTableNodeWidgetV2.cornerRadius),
          topRight: Radius.circular(ERTableNodeWidgetV2.cornerRadius),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.table_rows, size: 16, color: Colors.white),
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

  Widget _buildFieldRow(int index, Field field, bool isDark) {
    return Container(
      height: ERTableNodeWidgetV2.fieldRowHeight,
      color: index % 2 == 1 && !isDark ? Colors.grey.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            if (field.pk)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.vpn_key, size: 14, color: Colors.amber.shade600),
              ),
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

  Widget _buildAnchorLayer(bool isDark) {
    final primaryKeyFlags = widget.entity.fields.map((f) => f.pk).toList();

    return ERFieldAnchorLayer(
      entityId: widget.entity.id,
      fieldCount: widget.entity.fields.length,
      primaryKeyFlags: primaryKeyFlags,
      headerHeight: ERTableNodeWidgetV2.headerHeight,
      fieldRowHeight: ERTableNodeWidgetV2.fieldRowHeight,
      onAnchorTap: widget.onAnchorTap,
    );
  }

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