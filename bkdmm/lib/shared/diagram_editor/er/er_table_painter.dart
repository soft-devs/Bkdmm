import 'package:flutter/rendering.dart';
import '../core/diagram_node.dart';
import '../core/diagram_state.dart';

/// ER 表绘制器
///
/// 负责绘制 ER 图中的表节点，支持：
/// - 表头绘制（带图标和标题）
/// - 字段行绘制（主键标识、字段名、类型）
/// - 选中、悬停、高亮等状态视觉反馈
/// - 字段级锚点绘制
class ERTablePainter extends CustomPainter {
  /// 表 ID
  final String tableId;

  /// 表标题（英文）
  final String title;

  /// 表中文名
  final String chnname;

  /// 字段列表
  final List<ERFieldData> fields;

  /// 节点位置（场景坐标）
  final Offset position;

  /// 节点状态
  final NodeState state;

  /// 视口状态（用于坐标变换）
  final ViewportState? viewport;

  /// 绘制配置
  final ERTablePainterConfig config;

  /// 是否暗色模式
  final bool isDarkMode;

  ERTablePainter({
    required this.tableId,
    required this.title,
    required this.chnname,
    required this.fields,
    required this.position,
    this.state = const NodeState(),
    this.viewport,
    this.config = const ERTablePainterConfig(),
    this.isDarkMode = false,
  });

  /// 计算节点尺寸
  Size get size => ERTablePainterConfig.calculateTableSize(fields.length);

  @override
  void paint(Canvas canvas, Size canvasSize) {
    // 应用视口变换
    if (viewport != null) {
      canvas.save();
      canvas.translate(viewport!.panOffset.dx, viewport!.panOffset.dy);
      canvas.scale(viewport!.zoom, viewport!.zoom);
    }

    // 绘制节点
    _drawTable(canvas);

    // 绘制锚点（如果配置启用）
    if (config.showAnchors) {
      _drawAnchors(canvas);
    }

    if (viewport != null) {
      canvas.restore();
    }
  }

  /// 绘制表节点主体
  void _drawTable(Canvas canvas) {
    final rect = Rect.fromLTWH(
      position.dx,
      position.dy,
      size.width,
      size.height,
    );

    // 绘制阴影
    if (config.showShadow) {
      _drawShadow(canvas, rect);
    }

    // 绘制背景
    _drawBackground(canvas, rect);

    // 绘制表头
    _drawHeader(canvas, rect);

    // 绘制字段行
    _drawFieldRows(canvas, rect);

    // 绘制边框
    _drawBorder(canvas, rect);

    // 绘制选中指示器
    if (state.isSelected) {
      _drawSelectionIndicator(canvas, rect);
    }

    // 绘制悬停指示器
    if (state.isHovered && !state.isSelected) {
      _drawHoverIndicator(canvas, rect);
    }

    // 绘制高亮指示器
    if (state.isHighlighted) {
      _drawHighlightIndicator(canvas, rect);
    }

    // 绘制拖拽指示器
    if (state.isDragging) {
      _drawDragIndicator(canvas, rect);
    }
  }

  /// 绘制阴影
  void _drawShadow(Canvas canvas, Rect rect) {
    final shadowPaint = Paint()
      ..color = config.shadowColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.shadowBlur);

    final shadowRect = rect.shift(config.shadowOffset);
    canvas.drawRRect(
      RRect.fromRectAndRadius(shadowRect, config.cornerRadius),
      shadowPaint,
    );
  }

  /// 绘制背景
  void _drawBackground(Canvas canvas, Rect rect) {
    final bgColor = _getBackgroundColor();
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, config.cornerRadius),
      bgPaint,
    );
  }

  /// 绘制表头
  void _drawHeader(Canvas canvas, Rect rect) {
    final headerRect = Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width,
      ERTablePainterConfig.headerHeight,
    );

    // 表头背景
    final headerBgPaint = Paint()
      ..color = _getHeaderBackgroundColor()
      ..style = PaintingStyle.fill;

    // 绘制表头圆角矩形（仅上部分有圆角）
    final headerRRect = RRect.fromRectAndCorners(
      headerRect,
      topLeft: config.cornerRadius,
      topRight: config.cornerRadius,
      bottomLeft: Radius.zero,
      bottomRight: Radius.zero,
    );
    canvas.drawRRect(headerRRect, headerBgPaint);

    // 绘制表图标
    _drawHeaderIcon(canvas, headerRect);

    // 绘制表标题
    _drawHeaderTitle(canvas, headerRect);

    // 绘制表中文名
    if (chnname.isNotEmpty) {
      _drawHeaderChnName(canvas, headerRect);
    }
  }

  /// 绘制表图标
  void _drawHeaderIcon(Canvas canvas, Rect headerRect) {
    final iconColor = config.headerIconColor;
    final iconPaint = Paint()
      ..color = iconColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final iconSize = config.headerIconSize;
    final iconX = headerRect.left + config.headerPadding;
    final iconY = headerRect.center.dy;

    // 绘制表格图标（简化版）
    final iconPath = Path();
    // 外框
    iconPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(iconX, iconY), width: iconSize, height: iconSize),
      Radius.circular(2),
    ));
    // 中间横线
    canvas.drawLine(
      Offset(iconX - iconSize / 2, iconY),
      Offset(iconX + iconSize / 2, iconY),
      iconPaint,
    );
    // 中间竖线
    canvas.drawLine(
      Offset(iconX, iconY - iconSize / 2),
      Offset(iconX, iconY + iconSize / 2),
      iconPaint,
    );

    canvas.drawPath(iconPath, iconPaint);
  }

  /// 绘制表标题（英文）
  void _drawHeaderTitle(Canvas canvas, Rect headerRect) {
    if (title.isEmpty) return;

    final titleStyle = TextStyle(
      color: config.headerTitleColor,
      fontSize: config.headerTitleFontSize,
      fontWeight: config.headerTitleFontWeight,
      fontFamily: config.fontFamily,
    );

    final textSpan = TextSpan(
      text: title,
      style: titleStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final iconOffset = config.headerIconSize + 8.0;
    final titleOffset = Offset(
      headerRect.left + config.headerPadding + iconOffset,
      headerRect.center.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, titleOffset);
  }

  /// 绘制表中文名
  void _drawHeaderChnName(Canvas canvas, Rect headerRect) {
    final chnNameStyle = TextStyle(
      color: config.headerChnNameColor,
      fontSize: config.headerChnNameFontSize,
      fontWeight: FontWeight.normal,
      fontFamily: config.fontFamily,
    );

    final textSpan = TextSpan(
      text: chnname,
      style: chnNameStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.right,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: headerRect.width - config.headerPadding * 2);

    final titleWidth = _estimateTextWidth(title, config.headerTitleFontSize);
    final iconOffset = config.headerIconSize + 8.0;
    final maxChnWidth = headerRect.width - config.headerPadding * 2 - iconOffset - titleWidth - 8;

    if (textPainter.width > maxChnWidth) {
      // 重新布局以适应宽度
      textPainter.layout(maxWidth: maxChnWidth);
    }

    final chnOffset = Offset(
      headerRect.right - config.headerPadding - textPainter.width,
      headerRect.center.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, chnOffset);
  }

  /// 绘制字段行
  void _drawFieldRows(Canvas canvas, Rect rect) {
    for (int i = 0; i < fields.length; i++) {
      _drawFieldRow(canvas, rect, i, fields[i]);
    }
  }

  /// 绘制单个字段行
  void _drawFieldRow(Canvas canvas, Rect rect, int index, ERFieldData field) {
    final rowY = rect.top + ERTablePainterConfig.headerHeight + (index * ERTablePainterConfig.fieldRowHeight);
    final rowRect = Rect.fromLTWH(
      rect.left,
      rowY,
      rect.width,
      ERTablePainterConfig.fieldRowHeight,
    );

    // 偶数行背景（仅在亮色模式下）
    if (index % 2 == 1 && !isDarkMode && config.showAlternateRowBackground) {
      final rowBgPaint = Paint()
        ..color = config.alternateRowBackgroundColor
        ..style = PaintingStyle.fill;
      canvas.drawRect(rowRect, rowBgPaint);
    }

    // 绘制主键图标
    if (field.isPrimaryKey) {
      _drawPrimaryKeyIcon(canvas, rowRect);
    }

    // 绘制字段名
    _drawFieldName(canvas, rowRect, field);

    // 绘制字段类型
    _drawFieldType(canvas, rowRect, field);
  }

  /// 绘制主键图标
  void _drawPrimaryKeyIcon(Canvas canvas, Rect rowRect) {
    final iconColor = config.primaryKeyIconColor;
    final iconPaint = Paint()
      ..color = iconColor
      ..style = PaintingStyle.fill;

    final iconSize = config.primaryKeyIconSize;
    final iconX = rowRect.left + config.fieldPadding;
    final iconY = rowRect.center.dy;

    // 绘制钥匙图标（简化版钻石形状）
    final keyPath = Path();
    final halfSize = iconSize / 2;

    // 钻石形状
    keyPath.moveTo(iconX, iconY - halfSize);
    keyPath.lineTo(iconX + halfSize, iconY);
    keyPath.lineTo(iconX, iconY + halfSize);
    keyPath.lineTo(iconX - halfSize, iconY);
    keyPath.close();

    canvas.drawPath(keyPath, iconPaint);

    // 钥匙柄（小圆）
    canvas.drawCircle(
      Offset(iconX - halfSize * 0.3, iconY),
      halfSize * 0.25,
      iconPaint,
    );
  }

  /// 绘制字段名
  void _drawFieldName(Canvas canvas, Rect rowRect, ERFieldData field) {
    final fieldNameStyle = TextStyle(
      color: _getFieldNameColor(field.isPrimaryKey),
      fontSize: config.fieldNameFontSize,
      fontWeight: field.isPrimaryKey ? FontWeight.w600 : FontWeight.normal,
      fontFamily: config.fontFamily,
    );

    final textSpan = TextSpan(
      text: field.name,
      style: fieldNameStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: rowRect.width - config.fieldPadding * 2 - config.primaryKeyIconSize);

    final pkIconOffset = field.isPrimaryKey ? config.primaryKeyIconSize + 4.0 : 0.0;
    final nameOffset = Offset(
      rowRect.left + config.fieldPadding + pkIconOffset,
      rowRect.center.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, nameOffset);
  }

  /// 绘制字段类型
  void _drawFieldType(Canvas canvas, Rect rowRect, ERFieldData field) {
    final typeText = _formatFieldType(field);

    final typeStyle = TextStyle(
      color: config.fieldTypeColor,
      fontSize: config.fieldTypeFontSize,
      fontWeight: FontWeight.normal,
      fontFamily: config.fontFamily,
    );

    final textSpan = TextSpan(
      text: typeText,
      style: typeStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.right,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final typeOffset = Offset(
      rowRect.right - config.fieldPadding - textPainter.width,
      rowRect.center.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, typeOffset);
  }

  /// 绘制边框
  void _drawBorder(Canvas canvas, Rect rect) {
    final borderColor = _getBorderColor();
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _getBorderWidth();

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, config.cornerRadius),
      borderPaint,
    );
  }

  /// 绘制选中指示器
  void _drawSelectionIndicator(Canvas canvas, Rect rect) {
    final indicatorPaint = Paint()
      ..color = config.selectionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.selectionStrokeWidth;

    // 绘制选中边框
    final selectionRect = rect.inflate(config.selectionPadding);
    canvas.drawRRect(
      RRect.fromRectAndRadius(selectionRect, config.cornerRadius),
      indicatorPaint,
    );

    // 绘制选中角标
    if (config.showSelectionHandles) {
      _drawSelectionHandles(canvas, selectionRect);
    }
  }

  /// 绘制选中角标
  void _drawSelectionHandles(Canvas canvas, Rect rect) {
    final handleSize = config.selectionHandleSize;
    final handlePaint = Paint()
      ..color = config.selectionColor
      ..style = PaintingStyle.fill;

    // 四个角的把手位置
    final handles = [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ];

    for (final handle in handles) {
      canvas.drawRect(
        Rect.fromCenter(center: handle, width: handleSize, height: handleSize),
        handlePaint,
      );
    }
  }

  /// 绘制悬停指示器
  void _drawHoverIndicator(Canvas canvas, Rect rect) {
    final hoverPaint = Paint()
      ..color = config.hoverColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.hoverStrokeWidth;

    final hoverRect = rect.inflate(config.hoverPadding);
    canvas.drawRRect(
      RRect.fromRectAndRadius(hoverRect, config.cornerRadius),
      hoverPaint,
    );
  }

  /// 绘制高亮指示器
  void _drawHighlightIndicator(Canvas canvas, Rect rect) {
    final highlightPaint = Paint()
      ..color = config.highlightColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.highlightStrokeWidth;

    final highlightRect = rect.inflate(config.highlightPadding);
    canvas.drawRRect(
      RRect.fromRectAndRadius(highlightRect, config.cornerRadius),
      highlightPaint,
    );
  }

  /// 绘制拖拽指示器
  void _drawDragIndicator(Canvas canvas, Rect rect) {
    // 拖拽时绘制半透明原位置指示
    final dragPaint = Paint()
      ..color = config.dragColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, config.cornerRadius),
      dragPaint,
    );
  }

  /// 绘制锚点
  void _drawAnchors(Canvas canvas) {
    for (int i = 0; i < fields.length; i++) {
      final field = fields[i];

      // 左锚点
      final leftAnchorPos = Offset(
        position.dx,
        position.dy + ERTablePainterConfig.headerHeight + (i * ERTablePainterConfig.fieldRowHeight) + ERTablePainterConfig.fieldRowHeight / 2,
      );
      _drawAnchor(canvas, leftAnchorPos, field.isPrimaryKey, AnchorDirection.left);

      // 右锚点
      final rightAnchorPos = Offset(
        position.dx + size.width,
        position.dy + ERTablePainterConfig.headerHeight + (i * ERTablePainterConfig.fieldRowHeight) + ERTablePainterConfig.fieldRowHeight / 2,
      );
      _drawAnchor(canvas, rightAnchorPos, field.isPrimaryKey, AnchorDirection.right);
    }
  }

  /// 绘制单个锚点
  void _drawAnchor(Canvas canvas, Offset position, bool isPrimaryKey, AnchorDirection direction) {
    final anchorColor = _getAnchorColor(isPrimaryKey);
    final anchorPaint = Paint()
      ..color = anchorColor
      ..style = PaintingStyle.fill;

    final anchorBorderPaint = Paint()
      ..color = config.anchorBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.anchorBorderWidth;

    final anchorRect = Rect.fromCenter(
      center: position,
      width: config.anchorSize,
      height: config.anchorSize,
    );

    // 根据锚点形状绘制
    if (config.anchorShape == ERAnchorShape.circle) {
      canvas.drawCircle(position, config.anchorSize / 2, anchorPaint);
      canvas.drawCircle(position, config.anchorSize / 2, anchorBorderPaint);
    } else {
      canvas.drawRect(anchorRect, anchorPaint);
      canvas.drawRect(anchorRect, anchorBorderPaint);
    }
  }

  /// 获取背景颜色
  Color _getBackgroundColor() {
    if (state.isDragging) {
      return _getBaseBackgroundColor().withValues(alpha: config.dragOpacity);
    }
    if (state.isSelected) {
      return isDarkMode ? config.selectedBackgroundColorDark : config.selectedBackgroundColor;
    }
    if (state.isHovered) {
      return isDarkMode ? config.hoverBackgroundColorDark : config.hoverBackgroundColor;
    }
    if (state.isHighlighted) {
      return isDarkMode ? config.highlightBackgroundColorDark : config.highlightBackgroundColor;
    }
    return _getBaseBackgroundColor();
  }

  /// 获取基础背景颜色
  Color _getBaseBackgroundColor() {
    return isDarkMode ? config.backgroundColorDark : config.backgroundColor;
  }

  /// 获取表头背景颜色
  Color _getHeaderBackgroundColor() {
    return isDarkMode ? config.headerBackgroundColorDark : config.headerBackgroundColor;
  }

  /// 获取边框颜色
  Color _getBorderColor() {
    if (state.isSelected) {
      return config.selectionColor;
    }
    if (state.isHovered) {
      return isDarkMode ? config.hoverBorderColorDark : config.hoverBorderColor;
    }
    if (state.isHighlighted) {
      return config.highlightColor;
    }
    return isDarkMode ? config.borderColorDark : config.borderColor;
  }

  /// 获取边框宽度
  double _getBorderWidth() {
    if (state.isSelected) {
      return config.selectionStrokeWidth;
    }
    if (state.isHovered) {
      return config.hoverStrokeWidth;
    }
    return config.borderWidth;
  }

  /// 获取字段名颜色
  Color _getFieldNameColor(bool isPrimaryKey) {
    if (isPrimaryKey) {
      return isDarkMode ? config.primaryKeyFieldNameColorDark : config.primaryKeyFieldNameColor;
    }
    return isDarkMode ? config.fieldNameColorDark : config.fieldNameColor;
  }

  /// 获取锚点颜色
  Color _getAnchorColor(bool isPrimaryKey) {
    return isPrimaryKey ? config.primaryKeyAnchorColor : config.normalAnchorColor;
  }

  /// 格式化字段类型
  String _formatFieldType(ERFieldData field) {
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

  /// 估算文本宽度
  double _estimateTextWidth(String text, double fontSize) {
    // 简单估算：假设平均字符宽度为 fontSize * 0.6
    return text.length * fontSize * 0.6;
  }

  @override
  bool shouldRepaint(covariant ERTablePainter oldDelegate) {
    return tableId != oldDelegate.tableId ||
        title != oldDelegate.title ||
        chnname != oldDelegate.chnname ||
        _fieldsChanged(fields, oldDelegate.fields) ||
        position != oldDelegate.position ||
        state != oldDelegate.state ||
        viewport != oldDelegate.viewport ||
        config != oldDelegate.config ||
        isDarkMode != oldDelegate.isDarkMode;
  }

  /// 检查字段列表是否变化
  bool _fieldsChanged(List<ERFieldData> a, List<ERFieldData> b) {
    if (a.length != b.length) return true;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return true;
    }
    return false;
  }

  @override
  bool? hitTest(Offset position) {
    // 将屏幕坐标转换为节点本地坐标
    final localPosition = viewport != null
        ? Offset(
            (position.dx - viewport!.panOffset.dx) / viewport!.zoom,
            (position.dy - viewport!.panOffset.dy) / viewport!.zoom,
          )
        : position;

    // 检测是否在节点边界内
    final rect = Rect.fromLTWH(
      this.position.dx,
      this.position.dy,
      size.width,
      size.height,
    );
    return rect.contains(localPosition);
  }

  /// 获取字段锚点位置
  ///
  /// [fieldIndex] 字段索引
  /// [direction] 锚点方向
  Offset getFieldAnchorPosition(int fieldIndex, AnchorDirection direction) {
    final rowY = position.dy + ERTablePainterConfig.headerHeight + (fieldIndex * ERTablePainterConfig.fieldRowHeight) + ERTablePainterConfig.fieldRowHeight / 2;

    switch (direction) {
      case AnchorDirection.left:
        return Offset(position.dx, rowY);
      case AnchorDirection.right:
        return Offset(position.dx + size.width, rowY);
      case AnchorDirection.top:
        return Offset(position.dx + size.width / 2, position.dy);
      case AnchorDirection.bottom:
        return Offset(position.dx + size.width / 2, position.dy + size.height);
    }
  }

  /// 获取所有字段锚点
  List<AnchorPoint> getFieldAnchors(DiagramNode node) {
    final anchors = <AnchorPoint>[];

    for (int i = 0; i < fields.length; i++) {
      final field = fields[i];

      // 左锚点
      anchors.add(AnchorPoint.fieldAnchor(
        node: node,
        fieldIndex: i,
        direction: AnchorDirection.left,
        position: getFieldAnchorPosition(i, AnchorDirection.left),
        fieldData: field,
      ));

      // 右锚点
      anchors.add(AnchorPoint.fieldAnchor(
        node: node,
        fieldIndex: i,
        direction: AnchorDirection.right,
        position: getFieldAnchorPosition(i, AnchorDirection.right),
        fieldData: field,
      ));
    }

    return anchors;
  }
}

/// ER 字段数据
///
/// 用于绘制器的字段数据结构
class ERFieldData {
  /// 字段 ID
  final String id;

  /// 字段名
  final String name;

  /// 字段类型
  final String type;

  /// 是否主键
  final bool isPrimaryKey;

  /// 字段长度
  final int? length;

  /// 小数位数
  final int? decimal;

  const ERFieldData({
    required this.id,
    required this.name,
    required this.type,
    this.isPrimaryKey = false,
    this.length,
    this.decimal,
  });

  /// 从 Entity Field 创建
  factory ERFieldData.fromField(Map<String, dynamic> fieldJson) {
    return ERFieldData(
      id: fieldJson['id'] as String? ?? '',
      name: fieldJson['name'] as String? ?? '',
      type: fieldJson['type'] as String? ?? '',
      isPrimaryKey: fieldJson['pk'] as bool? ?? false,
      length: fieldJson['length'] as int?,
      decimal: fieldJson['decimal'] as int?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ERFieldData &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.isPrimaryKey == isPrimaryKey &&
        other.length == length &&
        other.decimal == decimal;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, type, isPrimaryKey, length, decimal);
  }
}

/// ER 表绘制配置
class ERTablePainterConfig {
  /// 默认宽度
  static const double defaultWidth = 200.0;

  /// 表头高度
  static const double headerHeight = 40.0;

  /// 字段行高度
  static const double fieldRowHeight = 28.0;

  /// 最小高度
  static const double minHeight = 80.0;

  /// 计算表高度
  static double calculateTableHeight(int fieldCount) {
    final height = headerHeight + (fieldCount * fieldRowHeight);
    return height < minHeight ? minHeight : height;
  }

  /// 计算表尺寸
  static Size calculateTableSize(int fieldCount) {
    return Size(defaultWidth, calculateTableHeight(fieldCount));
  }

  // 背景颜色
  final Color backgroundColor;
  final Color backgroundColorDark;
  final Color selectedBackgroundColor;
  final Color selectedBackgroundColorDark;
  final Color hoverBackgroundColor;
  final Color hoverBackgroundColorDark;
  final Color highlightBackgroundColor;
  final Color highlightBackgroundColorDark;

  // 边框
  final Color borderColor;
  final Color borderColorDark;
  final Color hoverBorderColor;
  final Color hoverBorderColorDark;
  final double borderWidth;
  final Radius cornerRadius;

  // 表头
  final Color headerBackgroundColor;
  final Color headerBackgroundColorDark;
  final Color headerIconColor;
  final double headerIconSize;
  final Color headerTitleColor;
  final double headerTitleFontSize;
  final FontWeight headerTitleFontWeight;
  final Color headerChnNameColor;
  final double headerChnNameFontSize;
  final double headerPadding;

  // 字段行
  final Color fieldNameColor;
  final Color fieldNameColorDark;
  final Color primaryKeyFieldNameColor;
  final Color primaryKeyFieldNameColorDark;
  final double fieldNameFontSize;
  final Color fieldTypeColor;
  final double fieldTypeFontSize;
  final double fieldPadding;
  final bool showAlternateRowBackground;
  final Color alternateRowBackgroundColor;

  // 主键图标
  final Color primaryKeyIconColor;
  final double primaryKeyIconSize;

  // 选中状态
  final Color selectionColor;
  final double selectionStrokeWidth;
  final double selectionPadding;
  final bool showSelectionHandles;
  final double selectionHandleSize;

  // 悬停状态
  final Color hoverColor;
  final double hoverStrokeWidth;
  final double hoverPadding;

  // 高亮状态
  final Color highlightColor;
  final double highlightStrokeWidth;
  final double highlightPadding;

  // 拖拽状态
  final Color dragColor;
  final double dragOpacity;

  // 阴影
  final bool showShadow;
  final Color shadowColor;
  final double shadowBlur;
  final Offset shadowOffset;

  // 锚点
  final bool showAnchors;
  final Color primaryKeyAnchorColor;
  final Color normalAnchorColor;
  final Color anchorBorderColor;
  final double anchorBorderWidth;
  final double anchorSize;
  final ERAnchorShape anchorShape;

  // 字体
  final String? fontFamily;

  const ERTablePainterConfig({
    // 背景颜色
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.backgroundColorDark = const Color(0xFF2D3748),
    this.selectedBackgroundColor = const Color(0xFFE3F2FD),
    this.selectedBackgroundColorDark = const Color(0xFF1E3A5F),
    this.hoverBackgroundColor = const Color(0xFFF5F5F5),
    this.hoverBackgroundColorDark = const Color(0xFF3D4758),
    this.highlightBackgroundColor = const Color(0xFFFFF8E1),
    this.highlightBackgroundColorDark = const Color(0xFF3D3D1F),

    // 边框
    this.borderColor = const Color(0xFFE0E0E0),
    this.borderColorDark = const Color(0xFF4A5568),
    this.hoverBorderColor = const Color(0xFFBDBDBD),
    this.hoverBorderColorDark = const Color(0xFF718096),
    this.borderWidth = 1.0,
    this.cornerRadius = const Radius.circular(8.0),

    // 表头
    this.headerBackgroundColor = const Color(0xFF1976D2),
    this.headerBackgroundColorDark = const Color(0xFF2563EB),
    this.headerIconColor = const Color(0xFFFFFFFF),
    this.headerIconSize = 16.0,
    this.headerTitleColor = const Color(0xFFFFFFFF),
    this.headerTitleFontSize = 14.0,
    this.headerTitleFontWeight = FontWeight.w600,
    this.headerChnNameColor = const Color(0xFFFFFFFF),
    this.headerChnNameFontSize = 10.0,
    this.headerPadding = 12.0,

    // 字段行
    this.fieldNameColor = const Color(0xFF212121),
    this.fieldNameColorDark = const Color(0xFFE2E8F0),
    this.primaryKeyFieldNameColor = const Color(0xFF212121),
    this.primaryKeyFieldNameColorDark = const Color(0xFFE2E8F0),
    this.fieldNameFontSize = 12.0,
    this.fieldTypeColor = const Color(0xFF757575),
    this.fieldTypeFontSize = 10.0,
    this.fieldPadding = 12.0,
    this.showAlternateRowBackground = true,
    this.alternateRowBackgroundColor = const Color(0xFFF5F5F5),

    // 主键图标
    this.primaryKeyIconColor = const Color(0xFFFFB300),
    this.primaryKeyIconSize = 14.0,

    // 选中状态
    this.selectionColor = const Color(0xFF2196F3),
    this.selectionStrokeWidth = 2.0,
    this.selectionPadding = 4.0,
    this.showSelectionHandles = true,
    this.selectionHandleSize = 8.0,

    // 悬停状态
    this.hoverColor = const Color(0xFF2196F3),
    this.hoverStrokeWidth = 1.0,
    this.hoverPadding = 2.0,

    // 高亮状态
    this.highlightColor = const Color(0xFFFFA726),
    this.highlightStrokeWidth = 2.0,
    this.highlightPadding = 4.0,

    // 拖拽状态
    this.dragColor = const Color(0xFF2196F3),
    this.dragOpacity = 0.3,

    // 阴影
    this.showShadow = true,
    this.shadowColor = const Color(0x26000000),
    this.shadowBlur = 6.0,
    this.shadowOffset = const Offset(2, 2),

    // 锚点
    this.showAnchors = false,
    this.primaryKeyAnchorColor = const Color(0xFFFFB300),
    this.normalAnchorColor = const Color(0xFF4CAF50),
    this.anchorBorderColor = const Color(0xFFFFFFFF),
    this.anchorBorderWidth = 2.0,
    this.anchorSize = 10.0,
    this.anchorShape = ERAnchorShape.circle,

    // 字体
    this.fontFamily,
  });

  /// 创建暗色主题配置
  factory ERTablePainterConfig.dark() {
    return const ERTablePainterConfig(
      backgroundColor: Color(0xFF2D3748),
      backgroundColorDark: Color(0xFF1A202C),
      selectedBackgroundColor: Color(0xFF1E3A5F),
      selectedBackgroundColorDark: Color(0xFF1E3A5F),
      hoverBackgroundColor: Color(0xFF3D4758),
      hoverBackgroundColorDark: Color(0xFF4A5568),
      highlightBackgroundColor: Color(0xFF3D3D1F),
      highlightBackgroundColorDark: Color(0xFF3D3D1F),
      borderColor: Color(0xFF4A5568),
      borderColorDark: Color(0xFF2D3748),
      hoverBorderColor: Color(0xFF718096),
      hoverBorderColorDark: Color(0xFF718096),
      headerBackgroundColor: Color(0xFF2563EB),
      headerBackgroundColorDark: Color(0xFF1D4ED8),
      headerTitleColor: Color(0xFFE2E8F0),
      headerChnNameColor: Color(0xFF94A3B8),
      fieldNameColor: Color(0xFFE2E8F0),
      fieldNameColorDark: Color(0xFFCBD5E1),
      primaryKeyFieldNameColor: Color(0xFFE2E8F0),
      primaryKeyFieldNameColorDark: Color(0xFFCBD5E1),
      fieldTypeColor: Color(0xFF94A3B8),
      alternateRowBackgroundColor: Color(0xFF374151),
      selectionColor: Color(0xFF63B3ED),
      hoverColor: Color(0xFF63B3ED),
      highlightColor: Color(0xFFF6AD55),
      dragColor: Color(0xFF63B3ED),
      shadowColor: Color(0x3F000000),
      primaryKeyAnchorColor: Color(0xFFFFB300),
      normalAnchorColor: Color(0xFF4CAF50),
      anchorBorderColor: Color(0xFF2D3748),
    );
  }

  /// 复制并修改配置
  ERTablePainterConfig copyWith({
    Color? backgroundColor,
    Color? backgroundColorDark,
    Color? selectedBackgroundColor,
    Color? selectedBackgroundColorDark,
    Color? hoverBackgroundColor,
    Color? hoverBackgroundColorDark,
    Color? highlightBackgroundColor,
    Color? highlightBackgroundColorDark,
    Color? borderColor,
    Color? borderColorDark,
    Color? hoverBorderColor,
    Color? hoverBorderColorDark,
    double? borderWidth,
    Radius? cornerRadius,
    Color? headerBackgroundColor,
    Color? headerBackgroundColorDark,
    Color? headerIconColor,
    double? headerIconSize,
    Color? headerTitleColor,
    double? headerTitleFontSize,
    FontWeight? headerTitleFontWeight,
    Color? headerChnNameColor,
    double? headerChnNameFontSize,
    double? headerPadding,
    Color? fieldNameColor,
    Color? fieldNameColorDark,
    Color? primaryKeyFieldNameColor,
    Color? primaryKeyFieldNameColorDark,
    double? fieldNameFontSize,
    Color? fieldTypeColor,
    double? fieldTypeFontSize,
    double? fieldPadding,
    bool? showAlternateRowBackground,
    Color? alternateRowBackgroundColor,
    Color? primaryKeyIconColor,
    double? primaryKeyIconSize,
    Color? selectionColor,
    double? selectionStrokeWidth,
    double? selectionPadding,
    bool? showSelectionHandles,
    double? selectionHandleSize,
    Color? hoverColor,
    double? hoverStrokeWidth,
    double? hoverPadding,
    Color? highlightColor,
    double? highlightStrokeWidth,
    double? highlightPadding,
    Color? dragColor,
    double? dragOpacity,
    bool? showShadow,
    Color? shadowColor,
    double? shadowBlur,
    Offset? shadowOffset,
    bool? showAnchors,
    Color? primaryKeyAnchorColor,
    Color? normalAnchorColor,
    Color? anchorBorderColor,
    double? anchorBorderWidth,
    double? anchorSize,
    ERAnchorShape? anchorShape,
    String? fontFamily,
  }) {
    return ERTablePainterConfig(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundColorDark: backgroundColorDark ?? this.backgroundColorDark,
      selectedBackgroundColor: selectedBackgroundColor ?? this.selectedBackgroundColor,
      selectedBackgroundColorDark: selectedBackgroundColorDark ?? this.selectedBackgroundColorDark,
      hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
      hoverBackgroundColorDark: hoverBackgroundColorDark ?? this.hoverBackgroundColorDark,
      highlightBackgroundColor: highlightBackgroundColor ?? this.highlightBackgroundColor,
      highlightBackgroundColorDark: highlightBackgroundColorDark ?? this.highlightBackgroundColorDark,
      borderColor: borderColor ?? this.borderColor,
      borderColorDark: borderColorDark ?? this.borderColorDark,
      hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
      hoverBorderColorDark: hoverBorderColorDark ?? this.hoverBorderColorDark,
      borderWidth: borderWidth ?? this.borderWidth,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      headerBackgroundColor: headerBackgroundColor ?? this.headerBackgroundColor,
      headerBackgroundColorDark: headerBackgroundColorDark ?? this.headerBackgroundColorDark,
      headerIconColor: headerIconColor ?? this.headerIconColor,
      headerIconSize: headerIconSize ?? this.headerIconSize,
      headerTitleColor: headerTitleColor ?? this.headerTitleColor,
      headerTitleFontSize: headerTitleFontSize ?? this.headerTitleFontSize,
      headerTitleFontWeight: headerTitleFontWeight ?? this.headerTitleFontWeight,
      headerChnNameColor: headerChnNameColor ?? this.headerChnNameColor,
      headerChnNameFontSize: headerChnNameFontSize ?? this.headerChnNameFontSize,
      headerPadding: headerPadding ?? this.headerPadding,
      fieldNameColor: fieldNameColor ?? this.fieldNameColor,
      fieldNameColorDark: fieldNameColorDark ?? this.fieldNameColorDark,
      primaryKeyFieldNameColor: primaryKeyFieldNameColor ?? this.primaryKeyFieldNameColor,
      primaryKeyFieldNameColorDark: primaryKeyFieldNameColorDark ?? this.primaryKeyFieldNameColorDark,
      fieldNameFontSize: fieldNameFontSize ?? this.fieldNameFontSize,
      fieldTypeColor: fieldTypeColor ?? this.fieldTypeColor,
      fieldTypeFontSize: fieldTypeFontSize ?? this.fieldTypeFontSize,
      fieldPadding: fieldPadding ?? this.fieldPadding,
      showAlternateRowBackground: showAlternateRowBackground ?? this.showAlternateRowBackground,
      alternateRowBackgroundColor: alternateRowBackgroundColor ?? this.alternateRowBackgroundColor,
      primaryKeyIconColor: primaryKeyIconColor ?? this.primaryKeyIconColor,
      primaryKeyIconSize: primaryKeyIconSize ?? this.primaryKeyIconSize,
      selectionColor: selectionColor ?? this.selectionColor,
      selectionStrokeWidth: selectionStrokeWidth ?? this.selectionStrokeWidth,
      selectionPadding: selectionPadding ?? this.selectionPadding,
      showSelectionHandles: showSelectionHandles ?? this.showSelectionHandles,
      selectionHandleSize: selectionHandleSize ?? this.selectionHandleSize,
      hoverColor: hoverColor ?? this.hoverColor,
      hoverStrokeWidth: hoverStrokeWidth ?? this.hoverStrokeWidth,
      hoverPadding: hoverPadding ?? this.hoverPadding,
      highlightColor: highlightColor ?? this.highlightColor,
      highlightStrokeWidth: highlightStrokeWidth ?? this.highlightStrokeWidth,
      highlightPadding: highlightPadding ?? this.highlightPadding,
      dragColor: dragColor ?? this.dragColor,
      dragOpacity: dragOpacity ?? this.dragOpacity,
      showShadow: showShadow ?? this.showShadow,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      shadowOffset: shadowOffset ?? this.shadowOffset,
      showAnchors: showAnchors ?? this.showAnchors,
      primaryKeyAnchorColor: primaryKeyAnchorColor ?? this.primaryKeyAnchorColor,
      normalAnchorColor: normalAnchorColor ?? this.normalAnchorColor,
      anchorBorderColor: anchorBorderColor ?? this.anchorBorderColor,
      anchorBorderWidth: anchorBorderWidth ?? this.anchorBorderWidth,
      anchorSize: anchorSize ?? this.anchorSize,
      anchorShape: anchorShape ?? this.anchorShape,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }
}

/// ER 锚点形状
enum ERAnchorShape {
  /// 圆形
  circle,

  /// 矩形
  rectangle,

  /// 菱形
  diamond,
}

/// ER 表绘制工具函数
class ERTablePainterUtils {
  ERTablePainterUtils._();

  /// 计算表边界矩形
  static Rect calculateBounds(Offset position, int fieldCount) {
    final size = ERTablePainterConfig.calculateTableSize(fieldCount);
    return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
  }

  /// 计算表中心点
  static Offset calculateCenter(Offset position, int fieldCount) {
    final size = ERTablePainterConfig.calculateTableSize(fieldCount);
    return Offset(
      position.dx + size.width / 2,
      position.dy + size.height / 2,
    );
  }

  /// 计算字段锚点位置
  static Offset calculateFieldAnchorPosition(
    Offset tablePosition,
    int fieldCount,
    int fieldIndex,
    AnchorDirection direction,
  ) {
    final size = ERTablePainterConfig.calculateTableSize(fieldCount);
    final rowY = tablePosition.dy +
        ERTablePainterConfig.headerHeight +
        (fieldIndex * ERTablePainterConfig.fieldRowHeight) +
        ERTablePainterConfig.fieldRowHeight / 2;

    switch (direction) {
      case AnchorDirection.left:
        return Offset(tablePosition.dx, rowY);
      case AnchorDirection.right:
        return Offset(tablePosition.dx + size.width, rowY);
      case AnchorDirection.top:
        return Offset(tablePosition.dx + size.width / 2, tablePosition.dy);
      case AnchorDirection.bottom:
        return Offset(tablePosition.dx + size.width / 2, tablePosition.dy + size.height);
    }
  }

  /// 检测点是否在表内
  static bool containsPoint(Offset tablePosition, int fieldCount, Offset point, {double padding = 0.0}) {
    final rect = calculateBounds(tablePosition, fieldCount).inflate(padding);
    return rect.contains(point);
  }

  /// 检测点是否在特定字段行内
  static bool containsPointInFieldRow(
    Offset tablePosition,
    int fieldIndex,
    Offset point,
  ) {
    final size = ERTablePainterConfig.calculateTableSize(0);
    final rowY = tablePosition.dy +
        ERTablePainterConfig.headerHeight +
        (fieldIndex * ERTablePainterConfig.fieldRowHeight);
    final rowRect = Rect.fromLTWH(
      tablePosition.dx,
      rowY,
      size.width,
      ERTablePainterConfig.fieldRowHeight,
    );
    return rowRect.contains(point);
  }

  /// 查找点所在的字段索引
  static int? findFieldIndexAtPoint(Offset tablePosition, int fieldCount, Offset point) {
    for (int i = 0; i < fieldCount; i++) {
      if (containsPointInFieldRow(tablePosition, i, point)) {
        return i;
      }
    }
    return null;
  }

  /// 计算连线与表边界的交点
  static Offset? calculateEdgeIntersection(
    Offset tablePosition,
    int fieldCount,
    Offset externalPoint,
    AnchorDirection preferredDirection,
  ) {
    final rect = calculateBounds(tablePosition, fieldCount);
    final center = calculateCenter(tablePosition, fieldCount);

    // 计算方向向量
    final dx = externalPoint.dx - center.dx;
    final dy = externalPoint.dy - center.dy;

    if (dx == 0 && dy == 0) return null;

    // 根据偏好方向优先计算交点
    if (preferredDirection == AnchorDirection.left || preferredDirection == AnchorDirection.right) {
      // 水平方向优先
      final t = preferredDirection == AnchorDirection.left
          ? (rect.left - center.dx) / dx
          : (rect.right - center.dx) / dx;
      if (t > 0) {
        final y = center.dy + t * dy;
        if (y >= rect.top && y <= rect.bottom) {
          return Offset(
            preferredDirection == AnchorDirection.left ? rect.left : rect.right,
            y,
          );
        }
      }
    } else {
      // 垂直方向优先
      final t = preferredDirection == AnchorDirection.top
          ? (rect.top - center.dy) / dy
          : (rect.bottom - center.dy) / dy;
      if (t > 0) {
        final x = center.dx + t * dx;
        if (x >= rect.left && x <= rect.right) {
          return Offset(
            x,
            preferredDirection == AnchorDirection.top ? rect.top : rect.bottom,
          );
        }
      }
    }

    // 如果偏好方向失败，计算其他方向
    return _calculateIntersectionFallback(rect, center, externalPoint);
  }

  /// 计算交点的备用方法
  static Offset? _calculateIntersectionFallback(Rect rect, Offset center, Offset externalPoint) {
    final dx = externalPoint.dx - center.dx;
    final dy = externalPoint.dy - center.dy;

    double? tMin;
    Offset? intersection;

    // 辅助函数：更新最近交点
    void updateIntersection(double t, Offset point) {
      if (t > 0) {
        if (tMin == null || t < tMin!) {
          tMin = t;
          intersection = point;
        }
      }
    }

    // 检查所有四个边
    // 左边
    if (dx != 0) {
      final t = (rect.left - center.dx) / dx;
      final y = center.dy + t * dy;
      if (y >= rect.top && y <= rect.bottom) {
        updateIntersection(t, Offset(rect.left, y));
      }
    }

    // 右边
    if (dx != 0) {
      final t = (rect.right - center.dx) / dx;
      final y = center.dy + t * dy;
      if (y >= rect.top && y <= rect.bottom) {
        updateIntersection(t, Offset(rect.right, y));
      }
    }

    // 上边
    if (dy != 0) {
      final t = (rect.top - center.dy) / dy;
      final x = center.dx + t * dx;
      if (x >= rect.left && x <= rect.right) {
        updateIntersection(t, Offset(x, rect.top));
      }
    }

    // 下边
    if (dy != 0) {
      final t = (rect.bottom - center.dy) / dy;
      final x = center.dx + t * dx;
      if (x >= rect.left && x <= rect.right) {
        updateIntersection(t, Offset(x, rect.bottom));
      }
    }

    return intersection;
  }

  /// 绘制 ER 表路径（用于遮罩或裁剪）
  static Path createTablePath(Offset position, int fieldCount, Radius cornerRadius) {
    final size = ERTablePainterConfig.calculateTableSize(fieldCount);
    final rect = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
    return Path()..addRRect(RRect.fromRectAndRadius(rect, cornerRadius));
  }
}