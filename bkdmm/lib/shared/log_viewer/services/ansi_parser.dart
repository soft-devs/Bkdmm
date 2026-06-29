/// ANSI 转义序列解析器
///
/// 参考 xterm.dart 的无状态设计原则：
/// - 解析过程中不创建中间对象
/// - 相同输入产生相同输出（确定性）
library;

import 'package:flutter/material.dart';

/// ANSI 转义序列解析器
///
/// 支持基础 ANSI 颜色码：
/// - 0: 重置
/// - 1: 粗体
/// - 30-37: 前景色
/// - 40-47: 背景色
class AnsiParser {
  AnsiParser._();

  /// ANSI 转义序列正则表达式
  /// 匹配格式: \x1B[<params>m
  static final RegExp _ansiPattern = RegExp(r'\x1B\[([0-9;]*)m');

  /// ANSI 颜色码映射表
  static const Map<int, Color> _foregroundColors = {
    30: Color(0xFF000000), // 黑色
    31: Color(0xFFCD0000), // 红色
    32: Color(0xFF00CD00), // 绿色
    33: Color(0xFFCDCD00), // 黄色
    34: Color(0xFF0000EE), // 蓝色
    35: Color(0xFFCD00CD), // 紫色
    36: Color(0xFF00CDCD), // 青色
    37: Color(0xFFE5E5E5), // 白色
  };

  /// 高亮 ANSI 颜色码映射表
  static const Map<int, Color> _brightForegroundColors = {
    90: Color(0xFF7F7F7F), // 亮黑（灰色）
    91: Color(0xFFFF0000), // 亮红
    92: Color(0xFF00FF00), // 亮绿
    93: Color(0xFFFFFF00), // 亮黄
    94: Color(0xFF5C5CFF), // 亮蓝
    95: Color(0xFFFF00FF), // 亮紫
    96: Color(0xFF00FFFF), // 亮青
    97: Color(0xFFFFFFFF), // 亮白
  };

  /// 解析带 ANSI 颜色码的文本为 TextSpan 列表
  ///
  /// [text] 包含 ANSI 转义序列的原始文本
  /// [baseStyle] 基础文本样式
  ///
  /// 返回 TextSpan 列表，可直接用于 SelectableText.rich
  static List<TextSpan> parse(String text, {TextStyle? baseStyle}) {
    if (text.isEmpty) return [];

    final spans = <TextSpan>[];
    final base = baseStyle ?? const TextStyle(fontFamily: 'RobotoMono', fontSize: 13);

    // 当前样式状态
    Color? currentColor;
    FontWeight currentWeight = FontWeight.normal;

    var lastEnd = 0;

    for (final match in _ansiPattern.allMatches(text)) {
      // 添加前段普通文本
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: _buildStyle(base, currentColor, currentWeight),
        ));
      }

      // 解析 ANSI 参数
      final paramsStr = match.group(1);
      if (paramsStr != null && paramsStr.isNotEmpty) {
        final params = paramsStr.split(';').map((s) => int.tryParse(s)).whereType<int>().toList();

        // 处理参数
        for (final param in params) {
          if (param == 0) {
            // 重置所有样式
            currentColor = null;
            currentWeight = FontWeight.normal;
          } else if (param == 1) {
            // 粗体
            currentWeight = FontWeight.bold;
          } else if (param == 22) {
            // 取消粗体
            currentWeight = FontWeight.normal;
          } else if (_foregroundColors.containsKey(param)) {
            // 标准前景色
            currentColor = _foregroundColors[param];
          } else if (_brightForegroundColors.containsKey(param)) {
            // 高亮前景色
            currentColor = _brightForegroundColors[param];
          } else if (param == 39) {
            // 默认前景色
            currentColor = null;
          }
        }
      }

      lastEnd = match.end;
    }

    // 添加剩余文本
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: _buildStyle(base, currentColor, currentWeight),
      ));
    }

    return spans;
  }

  /// 构建文本样式
  static TextStyle _buildStyle(TextStyle base, Color? color, FontWeight weight) {
    return base.copyWith(
      color: color,
      fontWeight: weight,
    );
  }

  /// 去除 ANSI 转义序列，返回纯文本
  ///
  /// [text] 包含 ANSI 转义序列的原始文本
  /// 返回去除所有 ANSI 码后的纯文本
  static String strip(String text) {
    return text.replaceAll(_ansiPattern, '');
  }

  /// 检查文本是否包含 ANSI 转义序列
  static bool hasAnsi(String text) {
    return _ansiPattern.hasMatch(text);
  }

  /// 创建带 ANSI 颜色的文本
  ///
  /// 用于生成测试数据或自定义日志输出
  static String colorize(String text, int colorCode) {
    return '\x1B[${colorCode}m$text\x1B[0m';
  }

  /// 创建带样式的 ANSI 文本
  ///
  /// [text] 文本内容
  /// [colorCode] 颜色码 (30-37, 90-97)
  /// [bold] 是否粗体
  static String style(String text, {int? colorCode, bool bold = false}) {
    final codes = <int>[];
    if (bold) codes.add(1);
    if (colorCode != null) codes.add(colorCode);

    if (codes.isEmpty) return text;

    final prefix = codes.join(';');
    return '\x1B[${prefix}m$text\x1B[0m';
  }
}

/// ANSI 颜色码常量
///
/// 方便使用的预定义颜色码
class AnsiColors {
  AnsiColors._();

  // 标准颜色
  static const int black = 30;
  static const int red = 31;
  static const int green = 32;
  static const int yellow = 33;
  static const int blue = 34;
  static const int magenta = 35;
  static const int cyan = 36;
  static const int white = 37;

  // 高亮颜色
  static const int brightBlack = 90;
  static const int brightRed = 91;
  static const int brightGreen = 92;
  static const int brightYellow = 93;
  static const int brightBlue = 94;
  static const int brightMagenta = 95;
  static const int brightCyan = 96;
  static const int brightWhite = 97;

  // 样式
  static const int reset = 0;
  static const int bold = 1;
  static const int dim = 2;
  static const int italic = 3;
  static const int underline = 4;
  static const int blink = 5;
  static const int reverse = 7;
  static const int hidden = 8;

  // 取消样式
  static const int boldOff = 22;
  static const int italicOff = 23;
  static const int underlineOff = 24;
  static const int blinkOff = 25;
  static const int defaultColor = 39;
  static const int defaultBackground = 49;
}
