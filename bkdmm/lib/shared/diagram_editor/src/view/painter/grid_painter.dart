/// 网格绘制器
///
/// 提供图表编辑器的网格背景绘制功能：
/// - 支持多种网格类型（点、线、交叉）
/// - 支持动态缩放和平移
/// - 支持自适应网格密度
library;

import 'package:flutter/material.dart';
import '../../model/transform_model.dart';

/// 网格类型
enum GridType {
  /// 点网格 - 以点阵形式显示
  dots,

  /// 线网格 - 以网格线形式显示
  lines,

  /// 交叉网格 - 以十字交叉形式显示
  cross,

  /// 无网格
  none,
}

/// 网格配置
class GridConfig {
  /// 网格类型
  final GridType type;

  /// 主网格间距（场景坐标）
  final double majorSpacing;

  /// 次网格间距（场景坐标），0 表示不显示次网格
  final double minorSpacing;

  /// 主网格颜色
  final Color majorColor;

  /// 次网格颜色
  final Color minorColor;

  /// 点大小（仅用于 [GridType.dots] 和 [GridType.cross]）
  final double dotSize;

  /// 是否在缩放时自适应网格密度
  final bool adaptive;

  /// 自适应缩放阈值
  ///
  /// 当缩放比例低于此值时，会增加网格间距以保持视觉清晰。
  final double adaptiveThreshold;

  const GridConfig({
    this.type = GridType.lines,
    this.majorSpacing = 50.0,
    this.minorSpacing = 10.0,
    this.majorColor = const Color(0xFFE0E0E0),
    this.minorColor = const Color(0xFFF5F5F5),
    this.dotSize = 2.0,
    this.adaptive = true,
    this.adaptiveThreshold = 0.5,
  });

  /// 默认点网格配置
  static const GridConfig dots = GridConfig(
    type: GridType.dots,
    majorSpacing: 20.0,
    minorSpacing: 0.0,
    dotSize: 1.5,
  );

  /// 默认线网格配置
  static const GridConfig lines = GridConfig(
    type: GridType.lines,
    majorSpacing: 50.0,
    minorSpacing: 10.0,
  );

  /// 默认交叉网格配置
  static const GridConfig cross = GridConfig(
    type: GridType.cross,
    majorSpacing: 30.0,
    minorSpacing: 0.0,
    dotSize: 8.0,
  );

  /// 暗色模式点网格
  static GridConfig dotsDark({Color? color}) => GridConfig(
        type: GridType.dots,
        majorSpacing: 20.0,
        minorSpacing: 0.0,
        dotSize: 1.5,
        majorColor: color ?? const Color(0xFF4A5568),
      );

  /// 暗色模式线网格
  static GridConfig linesDark({Color? majorColor, Color? minorColor}) => GridConfig(
        type: GridType.lines,
        majorSpacing: 50.0,
        minorSpacing: 10.0,
        majorColor: majorColor ?? const Color(0xFF374151),
        minorColor: minorColor ?? const Color(0xFF1F2937),
      );

  /// 复制并修改
  GridConfig copyWith({
    GridType? type,
    double? majorSpacing,
    double? minorSpacing,
    Color? majorColor,
    Color? minorColor,
    double? dotSize,
    bool? adaptive,
    double? adaptiveThreshold,
  }) {
    return GridConfig(
      type: type ?? this.type,
      majorSpacing: majorSpacing ?? this.majorSpacing,
      minorSpacing: minorSpacing ?? this.minorSpacing,
      majorColor: majorColor ?? this.majorColor,
      minorColor: minorColor ?? this.minorColor,
      dotSize: dotSize ?? this.dotSize,
      adaptive: adaptive ?? this.adaptive,
      adaptiveThreshold: adaptiveThreshold ?? this.adaptiveThreshold,
    );
  }
}

/// 网格绘制器
///
/// 使用 [CustomPainter] 绘制图表编辑器的网格背景。
/// 支持多种网格类型和自适应缩放。
///
/// ## 使用示例
///
/// ```dart
/// CustomPaint(
///   painter: GridPainter(
///     config: GridConfig.lines,
///     transform: transformModel,
///   ),
///   size: Size.infinite,
/// )
/// ```
class GridPainter extends CustomPainter {
  /// 网格配置
  final GridConfig config;

  /// 视口变换模型
  final TransformModel transform;

  /// 是否为暗色模式
  final bool isDark;

  /// 背景色
  final Color? backgroundColor;

  /// 缓存的主网格画笔
  Paint? _majorPaint;

  /// 缓存的次网格画笔
  Paint? _minorPaint;

  GridPainter({
    required this.config,
    required this.transform,
    this.isDark = false,
    this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (config.type == GridType.none) {
      // 仅绘制背景
      if (backgroundColor != null) {
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Paint()..color = backgroundColor!,
        );
      }
      return;
    }

    // 绘制背景
    if (backgroundColor != null) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = backgroundColor!,
      );
    }

    // 计算自适应间距
    final spacing = _calculateAdaptiveSpacing();

    // 绘制次网格
    if (config.minorSpacing > 0 && spacing.minorSpacing > 0) {
      _drawGrid(
        canvas,
        size,
        spacing.minorSpacing,
        _getMinorPaint(),
      );
    }

    // 绘制主网格
    _drawGrid(
      canvas,
      size,
      spacing.majorSpacing,
      _getMajorPaint(),
    );
  }

  /// 计算自适应网格间距
  _GridSpacing _calculateAdaptiveSpacing() {
    var majorSpacing = config.majorSpacing;
    var minorSpacing = config.minorSpacing;

    if (config.adaptive && transform.zoom < config.adaptiveThreshold) {
      // 缩放较小时，增加网格间距以保持视觉清晰
      final factor = config.adaptiveThreshold / transform.zoom;
      majorSpacing *= factor;
      if (minorSpacing > 0) {
        minorSpacing *= factor;
      }
    }

    return _GridSpacing(
      majorSpacing: majorSpacing,
      minorSpacing: minorSpacing,
    );
  }

  /// 绘制网格
  void _drawGrid(Canvas canvas, Size size, double spacing, Paint paint) {
    if (spacing <= 0) return;

    // 计算可见区域的场景坐标范围
    final visibleSceneRect = transform.toSceneRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    // 计算网格起始点（对齐到网格）
    final startX = (visibleSceneRect.left / spacing).floor() * spacing;
    final startY = (visibleSceneRect.top / spacing).floor() * spacing;
    final endX = visibleSceneRect.right;
    final endY = visibleSceneRect.bottom;

    switch (config.type) {
      case GridType.dots:
        _drawDots(canvas, startX, startY, endX, endY, spacing, paint);
        break;
      case GridType.lines:
        _drawLines(canvas, size, startX, startY, endX, endY, spacing, paint);
        break;
      case GridType.cross:
        _drawCross(canvas, startX, startY, endX, endY, spacing, paint);
        break;
      case GridType.none:
        break;
    }
  }

  /// 绘制点网格
  void _drawDots(
    Canvas canvas,
    double startX,
    double startY,
    double endX,
    double endY,
    double spacing,
    Paint paint,
  ) {
    final dotRadius = config.dotSize / 2;

    for (var x = startX; x <= endX; x += spacing) {
      for (var y = startY; y <= endY; y += spacing) {
        final screenPos = transform.toScreen(Offset(x, y));
        canvas.drawCircle(screenPos, dotRadius, paint);
      }
    }
  }

  /// 绘制线网格
  void _drawLines(
    Canvas canvas,
    Size size,
    double startX,
    double startY,
    double endX,
    double endY,
    double spacing,
    Paint paint,
  ) {
    // 绘制垂直线
    for (var x = startX; x <= endX; x += spacing) {
      final screenX = transform.toScreen(Offset(x, 0)).dx;
      canvas.drawLine(
        Offset(screenX, 0),
        Offset(screenX, size.height),
        paint,
      );
    }

    // 绘制水平线
    for (var y = startY; y <= endY; y += spacing) {
      final screenY = transform.toScreen(Offset(0, y)).dy;
      canvas.drawLine(
        Offset(0, screenY),
        Offset(size.width, screenY),
        paint,
      );
    }
  }

  /// 绘制交叉网格
  void _drawCross(
    Canvas canvas,
    double startX,
    double startY,
    double endX,
    double endY,
    double spacing,
    Paint paint,
  ) {
    final crossSize = config.dotSize;

    for (var x = startX; x <= endX; x += spacing) {
      for (var y = startY; y <= endY; y += spacing) {
        final screenPos = transform.toScreen(Offset(x, y));

        // 绘制十字交叉
        canvas.drawLine(
          Offset(screenPos.dx - crossSize / 2, screenPos.dy),
          Offset(screenPos.dx + crossSize / 2, screenPos.dy),
          paint,
        );
        canvas.drawLine(
          Offset(screenPos.dx, screenPos.dy - crossSize / 2),
          Offset(screenPos.dx, screenPos.dy + crossSize / 2),
          paint,
        );
      }
    }
  }

  /// 获取主网格画笔
  Paint _getMajorPaint() {
    return _majorPaint ??= Paint()
      ..color = config.majorColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;
  }

  /// 获取次网格画笔
  Paint _getMinorPaint() {
    return _minorPaint ??= Paint()
      ..color = config.minorColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.fill;
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return config != oldDelegate.config ||
        transform != oldDelegate.transform ||
        isDark != oldDelegate.isDark ||
        backgroundColor != oldDelegate.backgroundColor;
  }

  @override
  bool? hitTest(Offset position) => false;
}

/// 网格间距
class _GridSpacing {
  final double majorSpacing;
  final double minorSpacing;

  _GridSpacing({
    required this.majorSpacing,
    required this.minorSpacing,
  });
}

/// 网格绘制器工厂
///
/// 提供便捷的工厂方法创建网格绘制器。
class GridPainterFactory {
  GridPainterFactory._();

  /// 创建点网格绘制器
  static GridPainter dots({
    required TransformModel transform,
    double spacing = 20.0,
    Color? color,
    bool isDark = false,
    Color? backgroundColor,
  }) {
    return GridPainter(
      config: GridConfig(
        type: GridType.dots,
        majorSpacing: spacing,
        majorColor: color ?? (isDark ? const Color(0xFF4A5568) : const Color(0xFFE0E0E0)),
      ),
      transform: transform,
      isDark: isDark,
      backgroundColor: backgroundColor,
    );
  }

  /// 创建线网格绘制器
  static GridPainter lines({
    required TransformModel transform,
    double majorSpacing = 50.0,
    double minorSpacing = 10.0,
    Color? majorColor,
    Color? minorColor,
    bool isDark = false,
    Color? backgroundColor,
  }) {
    return GridPainter(
      config: GridConfig(
        type: GridType.lines,
        majorSpacing: majorSpacing,
        minorSpacing: minorSpacing,
        majorColor: majorColor ?? (isDark ? const Color(0xFF374151) : const Color(0xFFE0E0E0)),
        minorColor: minorColor ?? (isDark ? const Color(0xFF1F2937) : const Color(0xFFF5F5F5)),
      ),
      transform: transform,
      isDark: isDark,
      backgroundColor: backgroundColor,
    );
  }

  /// 创建交叉网格绘制器
  static GridPainter cross({
    required TransformModel transform,
    double spacing = 30.0,
    double crossSize = 8.0,
    Color? color,
    bool isDark = false,
    Color? backgroundColor,
  }) {
    return GridPainter(
      config: GridConfig(
        type: GridType.cross,
        majorSpacing: spacing,
        dotSize: crossSize,
        majorColor: color ?? (isDark ? const Color(0xFF4A5568) : const Color(0xFFE0E0E0)),
      ),
      transform: transform,
      isDark: isDark,
      backgroundColor: backgroundColor,
    );
  }

  /// 创建自适应网格绘制器
  ///
  /// 根据缩放比例自动选择合适的网格密度。
  static GridPainter adaptive({
    required TransformModel transform,
    bool isDark = false,
    Color? backgroundColor,
  }) {
    return GridPainter(
      config: const GridConfig(
        type: GridType.lines,
        majorSpacing: 50.0,
        minorSpacing: 10.0,
        adaptive: true,
        adaptiveThreshold: 0.5,
      ),
      transform: transform,
      isDark: isDark,
      backgroundColor: backgroundColor,
    );
  }
}

/// 网格背景组件
///
/// 封装 [GridPainter] 为 Widget，便于直接使用。
class GridBackground extends StatelessWidget {
  /// 网格配置
  final GridConfig config;

  /// 视口变换模型
  final TransformModel transform;

  /// 是否为暗色模式
  final bool isDark;

  /// 背景色
  final Color? backgroundColor;

  const GridBackground({
    super.key,
    required this.config,
    required this.transform,
    this.isDark = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GridPainter(
        config: config,
        transform: transform,
        isDark: isDark,
        backgroundColor: backgroundColor,
      ),
      size: Size.infinite,
    );
  }
}
