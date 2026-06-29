import 'package:flutter/material.dart';

/// 视图位置
enum ViewPosition {
  /// 左侧视图
  left,

  /// 右侧视图
  right,

  /// 底部视图
  bottom,
}

/// 视图配置
class ViewConfig {
  /// 视图ID
  final String id;

  /// 视图标题
  final String title;

  /// 图标
  final IconData icon;

  /// 快捷键
  final String shortcut;

  /// 视图位置
  final ViewPosition position;

  /// 默认是否可见
  final bool isDefaultVisible;

  /// 默认宽度
  final double defaultWidth;

  /// 默认高度
  final double defaultHeight;

  /// 排序顺序
  final int order;

  const ViewConfig({
    required this.id,
    required this.title,
    required this.icon,
    required this.shortcut,
    required this.position,
    this.isDefaultVisible = true,
    this.defaultWidth = 260,
    this.defaultHeight = 200,
    this.order = 0,
  });
}