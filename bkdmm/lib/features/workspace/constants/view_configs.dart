import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../models/view_config.dart';

/// 视图配置常量
class ViewConfigs {
  ViewConfigs._();

  // ========== 左侧视图配置 ==========
  static const List<ViewConfig> leftViews = [
    ViewConfig(
      id: 'module_tree',
      title: '模块树',
      icon: TDIcons.view_module,
      shortcut: 'Alt+1',
      position: ViewPosition.left,
      isDefaultVisible: true,
      defaultWidth: 260,
      order: 1,
    ),
    ViewConfig(
      id: 'datatype',
      title: '数据类型',
      icon: TDIcons.code,
      shortcut: 'Alt+D',
      position: ViewPosition.left,
      isDefaultVisible: false,
      defaultWidth: 260,
      order: 2,
    ),
  ];

  // ========== 底部视图配置 ==========
  static const List<ViewConfig> bottomViews = [
    ViewConfig(
      id: 'console',
      title: '控制台',
      icon: TDIcons.terminal,
      shortcut: 'Alt+C',
      position: ViewPosition.bottom,
      isDefaultVisible: false,
      defaultHeight: 200,
      order: 1,
    ),
    ViewConfig(
      id: 'log',
      title: '日志',
      icon: TDIcons.file,
      shortcut: 'Alt+L',
      position: ViewPosition.bottom,
      isDefaultVisible: false,
      defaultHeight: 200,
      order: 2,
    ),
    ViewConfig(
      id: 'output',
      title: '输出',
      icon: TDIcons.chart,
      shortcut: 'Alt+O',
      position: ViewPosition.bottom,
      isDefaultVisible: false,
      defaultHeight: 200,
      order: 3,
    ),
  ];

  // ========== 默认可见性 ==========
  static Map<String, bool> get defaultLeftVisibility =>
      {for (var v in leftViews) v.id: v.isDefaultVisible};

  static Map<String, bool> get defaultBottomVisibility =>
      {for (var v in bottomViews) v.id: v.isDefaultVisible};

  // ========== 快捷键映射 ==========
  static const Map<String, String> shortcutToViewId = {
    'Alt+1': 'module_tree',
    'Alt+D': 'datatype',
    'Alt+P': 'properties',
    'Alt+C': 'console',
    'Alt+L': 'log',
    'Alt+O': 'output',
  };

  /// 根据ID获取视图配置
  static ViewConfig? getLeftViewById(String id) {
    try {
      return leftViews.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 根据ID获取底部视图配置
  static ViewConfig? getBottomViewById(String id) {
    try {
      return bottomViews.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }
}