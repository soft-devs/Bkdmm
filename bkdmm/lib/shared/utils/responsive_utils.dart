/// 响应式设计工具类
///
/// 基于 Material Design 3 断点系统设计，参考：
/// - flutter_adaptive_scaffold 官方包
/// - adaptive_breakpoints 官方包
/// - Material Design 3 规范
///
/// 提供统一的响应式布局解决方案，包括：
/// - 断点系统 (Breakpoint)
/// - 对话框/表单尺寸计算
/// - 字体大小适配
/// - 间距适配
library;

import 'package:flutter/material.dart';

/// Material Design 3 断点常量
///
/// 来源: Material Design 3 规范
/// https://m3.material.io/foundations/layout/understand-layout/breakpoints
class MaterialBreakpoints {
  MaterialBreakpoints._();

  /// 紧凑屏幕断点: 0-600dp
  static const double compactBegin = 0;
  static const double compactEnd = 600;

  /// 中等屏幕断点: 600-840dp
  static const double mediumBegin = 600;
  static const double mediumEnd = 840;

  /// 中大屏幕断点: 840-1200dp
  static const double mediumLargeBegin = 840;
  static const double mediumLargeEnd = 1200;

  /// 大屏幕断点: 1200-1600dp
  static const double largeBegin = 1200;
  static const double largeEnd = 1600;

  /// 超大屏幕断点: 1600dp+
  static const double extraLargeBegin = 1600;
}

/// 屏幕断点定义
///
/// 基于 Material Design 3 规范，与 flutter_adaptive_scaffold 保持一致
///
/// | 断点 | 宽度范围 | 典型设备 |
/// |------|---------|---------|
/// | compact | 0-600dp | 手机竖屏 |
/// | medium | 600-840dp | 平板竖屏、手机横屏 |
/// | mediumLarge | 840-1200dp | 平板横屏 |
/// | large | 1200-1600dp | 桌面显示器 |
/// | extraLarge | 1600dp+ | 大型桌面显示器 |
enum ScreenBreakpoint {
  /// 紧凑屏幕: 0-600dp
  /// 适用于: 手机竖屏、小型平板竖屏
  compact(
    MaterialBreakpoints.compactBegin,
    MaterialBreakpoints.compactEnd,
    4,   // columns
    16,  // margin
    16,  // gutter
    1,   // recommendedPanes
  ),

  /// 中等屏幕: 600-840dp
  /// 适用于: 平板竖屏、手机横屏
  medium(
    MaterialBreakpoints.mediumBegin,
    MaterialBreakpoints.mediumEnd,
    8,   // columns
    24,  // margin
    24,  // gutter
    1,   // recommendedPanes
  ),

  /// 中大屏幕: 840-1200dp
  /// 适用于: 大型平板横屏、小型桌面
  mediumLarge(
    MaterialBreakpoints.mediumLargeBegin,
    MaterialBreakpoints.mediumLargeEnd,
    12,  // columns
    24,  // margin
    24,  // gutter
    2,   // recommendedPanes
  ),

  /// 大屏幕: 1200-1600dp
  /// 适用于: 桌面显示器
  large(
    MaterialBreakpoints.largeBegin,
    MaterialBreakpoints.largeEnd,
    12,  // columns
    24,  // margin
    24,  // gutter
    2,   // recommendedPanes
  ),

  /// 超大屏幕: 1600dp+
  /// 适用于: 大型桌面显示器、宽屏
  extraLarge(
    MaterialBreakpoints.extraLargeBegin,
    double.infinity,
    12,  // columns
    24,  // margin
    24,  // gutter
    3,   // recommendedPanes
  );

  const ScreenBreakpoint(
    this.minWidth,
    this.maxWidth,
    this.columns,
    this.margin,
    this.gutter,
    this.recommendedPanes,
  );

  final double minWidth;
  final double maxWidth;
  final int columns;
  final double margin;
  final double gutter;
  final int recommendedPanes;

  /// 根据宽度判断当前断点
  static ScreenBreakpoint fromWidth(double width) {
    if (width < MaterialBreakpoints.mediumBegin) {
      return ScreenBreakpoint.compact;
    } else if (width < MaterialBreakpoints.mediumLargeBegin) {
      return ScreenBreakpoint.medium;
    } else if (width < MaterialBreakpoints.largeBegin) {
      return ScreenBreakpoint.mediumLarge;
    } else if (width < MaterialBreakpoints.extraLargeBegin) {
      return ScreenBreakpoint.large;
    } else {
      return ScreenBreakpoint.extraLarge;
    }
  }
}

/// 对话框尺寸预设
///
/// 根据 Material Design 3 规范和桌面应用最佳实践设计
///
/// 尺寸计算公式:
/// ```
/// dialogWidth = (screenWidth × screenRatio).clamp(baseWidth, baseWidth × maxScale)
/// ```
enum DialogSizePreset {
  /// 小对话框: 用于简单确认、选择操作
  /// 基础宽度: 320px (接近 Material Design 小卡片尺寸)
  small(320, null, 0.85, 1.3),

  /// 中对话框: 用于表单录入、数据编辑
  /// 基础宽度: 480px (4列网格约 4×80+间距)
  medium(480, null, 0.85, 1.3),

  /// 大对话框: 用于复杂表单、多步骤操作
  /// 基础宽度: 600px (中等断点起始值)
  large(600, null, 0.80, 1.3),

  /// 超大对话框: 用于设置面板、多栏布局
  /// 基础宽度: 720px
  extraLarge(720, null, 0.75, 1.25),

  /// 表单对话框: 用于数据录入表单
  /// 基础宽度: 520px (适合标准表单)
  form(520, null, 0.85, 1.3),

  /// 设置对话框: 用于设置面板
  /// 基础宽度: 720px, 基础高度: 480px
  settings(720, 480, 0.75, 1.25),

  /// 项目对话框: 用于创建/打开项目
  /// 基础宽度: 640px, 基础高度: 420px
  project(640, 420, 0.80, 1.3);

  const DialogSizePreset(
    this.baseWidth,
    this.baseHeight,
    this.screenRatio,
    this.maxScale,
  );

  /// 基础宽度
  final double baseWidth;

  /// 基础高度 (null 表示自适应内容)
  final double? baseHeight;

  /// 屏幕占比系数 (对话框占屏幕宽度的比例)
  final double screenRatio;

  /// 最大放大倍数 (基础宽度的最大倍数)
  final double maxScale;
}

/// 响应式工具类
///
/// 提供响应式设计的各种计算方法
///
/// ## 使用示例
///
/// ```dart
/// // 获取对话框宽度
/// final dialogWidth = ResponsiveUtils.getDialogWidth(context, DialogSizePreset.form);
///
/// // 获取当前断点
/// final breakpoint = ResponsiveUtils.getBreakpoint(context);
///
/// // 获取表单字段间距
/// final spacing = ResponsiveUtils.getFormFieldSpacing(context);
/// ```
class ResponsiveUtils {
  ResponsiveUtils._();

  /// 获取当前断点
  static ScreenBreakpoint getBreakpoint(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return ScreenBreakpoint.fromWidth(width);
  }

  /// 获取屏幕宽度
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  /// 获取屏幕高度
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  /// 判断是否为紧凑屏幕 (< 600dp)
  static bool isCompact(BuildContext context) {
    return getBreakpoint(context) == ScreenBreakpoint.compact;
  }

  /// 判断是否为中等屏幕 (600-840dp)
  static bool isMedium(BuildContext context) {
    return getBreakpoint(context) == ScreenBreakpoint.medium;
  }

  /// 判断是否为中到大屏幕 (>= 840dp)
  static bool isMediumLargeOrLarger(BuildContext context) {
    final breakpoint = getBreakpoint(context);
    return breakpoint == ScreenBreakpoint.mediumLarge ||
           breakpoint == ScreenBreakpoint.large ||
           breakpoint == ScreenBreakpoint.extraLarge;
  }

  /// 判断是否为大屏幕 (>= 1200dp)
  static bool isLargeOrLarger(BuildContext context) {
    final breakpoint = getBreakpoint(context);
    return breakpoint == ScreenBreakpoint.large ||
           breakpoint == ScreenBreakpoint.extraLarge;
  }

  /// 计算对话框宽度
  ///
  /// [context] - BuildContext
  /// [preset] - 尺寸预设
  /// [customBaseWidth] - 自定义基础宽度 (覆盖预设)
  /// [customScreenRatio] - 自定义屏幕占比 (覆盖预设)
  /// [customMaxScale] - 自定义最大放大倍数 (覆盖预设)
  ///
  /// 返回计算后的对话框宽度
  static double getDialogWidth(
    BuildContext context,
    DialogSizePreset preset, {
    double? customBaseWidth,
    double? customScreenRatio,
    double? customMaxScale,
  }) {
    final screenWidth = getScreenWidth(context);
    final baseWidth = customBaseWidth ?? preset.baseWidth;
    final screenRatio = customScreenRatio ?? preset.screenRatio;
    final maxScale = customMaxScale ?? preset.maxScale;

    final minWidth = baseWidth;
    final maxWidth = baseWidth * maxScale;

    return (screenWidth * screenRatio).clamp(minWidth, maxWidth);
  }

  /// 计算对话框高度
  ///
  /// [context] - BuildContext
  /// [preset] - 尺寸预设
  /// [customBaseHeight] - 自定义基础高度 (覆盖预设)
  /// [customScreenRatio] - 自定义屏幕占比 (覆盖预设)
  /// [customMaxScale] - 自定义最大放大倍数 (覆盖预设)
  ///
  /// 返回计算后的对话框高度，如果预设无基础高度则返回 null
  static double? getDialogHeight(
    BuildContext context,
    DialogSizePreset preset, {
    double? customBaseHeight,
    double? customScreenRatio,
    double? customMaxScale,
  }) {
    final baseHeight = customBaseHeight ?? preset.baseHeight;
    if (baseHeight == null) return null;

    final screenHeight = getScreenHeight(context);
    final screenRatio = customScreenRatio ?? preset.screenRatio;
    final maxScale = customMaxScale ?? preset.maxScale;

    final minHeight = baseHeight;
    final maxHeight = baseHeight * maxScale;

    return (screenHeight * screenRatio).clamp(minHeight, maxHeight);
  }

  /// 计算对话框尺寸 (宽度和高度)
  static Size getDialogSize(
    BuildContext context,
    DialogSizePreset preset, {
    double? customBaseWidth,
    double? customBaseHeight,
    double? customScreenRatio,
    double? customMaxScale,
  }) {
    final width = getDialogWidth(
      context,
      preset,
      customBaseWidth: customBaseWidth,
      customScreenRatio: customScreenRatio,
      customMaxScale: customMaxScale,
    );
    final height = getDialogHeight(
      context,
      preset,
      customBaseHeight: customBaseHeight,
      customScreenRatio: customScreenRatio,
      customMaxScale: customMaxScale,
    );
    return Size(width, height ?? double.infinity);
  }

  /// 获取响应式间距
  ///
  /// 根据屏幕断点返回不同的间距值
  static double getSpacing(BuildContext context, {
    double compact = 8.0,
    double medium = 12.0,
    double mediumLarge = 16.0,
    double large = 20.0,
    double extraLarge = 24.0,
  }) {
    final breakpoint = getBreakpoint(context);
    switch (breakpoint) {
      case ScreenBreakpoint.compact:
        return compact;
      case ScreenBreakpoint.medium:
        return medium;
      case ScreenBreakpoint.mediumLarge:
        return mediumLarge;
      case ScreenBreakpoint.large:
        return large;
      case ScreenBreakpoint.extraLarge:
        return extraLarge;
    }
  }

  /// 获取标准表单字段间距
  ///
  /// 统一使用 16px，符合 Material Design 3 表单设计规范
  static double getFormFieldSpacing(BuildContext context) {
    return 16.0;
  }

  /// 获取响应式字体大小
  ///
  /// 根据屏幕断点返回不同的字体大小
  static double getFontSize(BuildContext context, {
    double compact = 12.0,
    double medium = 14.0,
    double mediumLarge = 14.0,
    double large = 16.0,
    double extraLarge = 16.0,
  }) {
    final breakpoint = getBreakpoint(context);
    switch (breakpoint) {
      case ScreenBreakpoint.compact:
        return compact;
      case ScreenBreakpoint.medium:
        return medium;
      case ScreenBreakpoint.mediumLarge:
        return mediumLarge;
      case ScreenBreakpoint.large:
        return large;
      case ScreenBreakpoint.extraLarge:
        return extraLarge;
    }
  }

  /// 计算网格列数
  ///
  /// 根据屏幕宽度返回适合的网格列数
  static int getGridCrossAxisCount(BuildContext context, {
    int compact = 2,
    int medium = 3,
    int mediumLarge = 4,
    int large = 5,
    int extraLarge = 6,
  }) {
    final breakpoint = getBreakpoint(context);
    switch (breakpoint) {
      case ScreenBreakpoint.compact:
        return compact;
      case ScreenBreakpoint.medium:
        return medium;
      case ScreenBreakpoint.mediumLarge:
        return mediumLarge;
      case ScreenBreakpoint.large:
        return large;
      case ScreenBreakpoint.extraLarge:
        return extraLarge;
    }
  }

  /// 获取网格最大宽度
  ///
  /// 根据 Material Design 3 规范返回网格的最大宽度
  static double getGridMaxWidth(BuildContext context) {
    final breakpoint = getBreakpoint(context);
    switch (breakpoint) {
      case ScreenBreakpoint.compact:
        return double.infinity;
      case ScreenBreakpoint.medium:
        return 840;
      case ScreenBreakpoint.mediumLarge:
        return 1200;
      case ScreenBreakpoint.large:
      case ScreenBreakpoint.extraLarge:
        return 1600;
    }
  }

  /// 判断是否为桌面平台
  static bool isDesktopPlatform(BuildContext context) {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.macOS ||
           platform == TargetPlatform.windows ||
           platform == TargetPlatform.linux;
  }

  /// 判断是否为移动平台
  static bool isMobilePlatform(BuildContext context) {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.android ||
           platform == TargetPlatform.iOS ||
           platform == TargetPlatform.fuchsia;
  }

  /// 获取最小窗口尺寸
  static Size getMinimumWindowSize() {
    return const Size(800, 600);
  }
}

/// 响应式对话框宽度 Widget
///
/// 简化对话框宽度计算的使用
///
/// ```dart
/// ResponsiveDialogWidth(
///   preset: DialogSizePreset.form,
///   child: YourFormContent(),
/// )
/// ```
class ResponsiveDialogWidth extends StatelessWidget {
  /// 尺寸预设
  final DialogSizePreset preset;

  /// 子 Widget
  final Widget child;

  /// 自定义基础宽度
  final double? customBaseWidth;

  /// 自定义屏幕占比
  final double? customScreenRatio;

  /// 自定义最大放大倍数
  final double? customMaxScale;

  const ResponsiveDialogWidth({
    super.key,
    required this.preset,
    required this.child,
    this.customBaseWidth,
    this.customScreenRatio,
    this.customMaxScale,
  });

  @override
  Widget build(BuildContext context) {
    final width = ResponsiveUtils.getDialogWidth(
      context,
      preset,
      customBaseWidth: customBaseWidth,
      customScreenRatio: customScreenRatio,
      customMaxScale: customMaxScale,
    );
    return SizedBox(width: width, child: child);
  }
}

/// 响应式对话框尺寸 Widget
///
/// 简化对话框尺寸计算的使用
///
/// ```dart
/// ResponsiveDialogSize(
///   preset: DialogSizePreset.settings,
///   child: YourSettingsContent(),
/// )
/// ```
class ResponsiveDialogSize extends StatelessWidget {
  /// 尺寸预设
  final DialogSizePreset preset;

  /// 子 Widget
  final Widget child;

  /// 自定义基础宽度
  final double? customBaseWidth;

  /// 自定义基础高度
  final double? customBaseHeight;

  /// 自定义屏幕占比
  final double? customScreenRatio;

  /// 自定义最大放大倍数
  final double? customMaxScale;

  const ResponsiveDialogSize({
    super.key,
    required this.preset,
    required this.child,
    this.customBaseWidth,
    this.customBaseHeight,
    this.customScreenRatio,
    this.customMaxScale,
  });

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveUtils.getDialogSize(
      context,
      preset,
      customBaseWidth: customBaseWidth,
      customBaseHeight: customBaseHeight,
      customScreenRatio: customScreenRatio,
      customMaxScale: customMaxScale,
    );
    return SizedBox(
      width: size.width,
      height: size.height.isFinite ? size.height : null,
      child: child,
    );
  }
}