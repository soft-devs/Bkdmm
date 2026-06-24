import 'view_config.dart';

/// 布局状态
class LayoutState {
  // ========== 左侧视图 ==========
  /// 当前激活的左侧视图ID
  final String? activeLeftView;

  /// 左侧视图可见性映射
  final Map<String, bool> leftViewVisibility;

  /// 左侧视图宽度
  final double leftViewWidth;

  // ========== 右侧视图 ==========
  /// 右侧视图是否可见
  final bool rightViewVisible;

  /// 右侧视图宽度
  final double rightViewWidth;

  // ========== 底部视图 ==========
  /// 当前激活的底部视图ID
  final String? activeBottomView;

  /// 底部视图可见性映射
  final Map<String, bool> bottomViewVisibility;

  /// 底部视图高度
  final double bottomViewHeight;

  // ========== 图标栏 ==========
  /// 图标栏宽度
  final double iconBarWidth;

  // ========== 视图配置 ==========
  /// 左侧视图配置列表
  final List<ViewConfig> leftViewConfigs;

  /// 底部视图配置列表
  final List<ViewConfig> bottomViewConfigs;

  const LayoutState({
    this.activeLeftView,
    this.leftViewVisibility = const {},
    this.leftViewWidth = 260,
    this.rightViewVisible = true,
    this.rightViewWidth = 280,
    this.activeBottomView,
    this.bottomViewVisibility = const {},
    this.bottomViewHeight = 200,
    this.iconBarWidth = 48,
    this.leftViewConfigs = const [],
    this.bottomViewConfigs = const [],
  });

  /// 检查左侧视图是否可见
  bool isLeftViewVisible(String viewId) {
    return activeLeftView == viewId && (leftViewVisibility[viewId] ?? false);
  }

  /// 检查底部视图是否可见
  bool isBottomViewVisible(String viewId) {
    return activeBottomView == viewId && (bottomViewVisibility[viewId] ?? false);
  }

  /// 检查是否有任何视图打开
  bool hasAnyViewOpen() {
    return activeLeftView != null ||
        rightViewVisible ||
        activeBottomView != null;
  }

  LayoutState copyWith({
    String? activeLeftView,
    Map<String, bool>? leftViewVisibility,
    double? leftViewWidth,
    bool? rightViewVisible,
    double? rightViewWidth,
    String? activeBottomView,
    Map<String, bool>? bottomViewVisibility,
    double? bottomViewHeight,
    double? iconBarWidth,
    List<ViewConfig>? leftViewConfigs,
    List<ViewConfig>? bottomViewConfigs,
    bool clearActiveLeftView = false,
    bool clearActiveBottomView = false,
  }) {
    return LayoutState(
      activeLeftView: clearActiveLeftView ? null : (activeLeftView ?? this.activeLeftView),
      leftViewVisibility: leftViewVisibility ?? this.leftViewVisibility,
      leftViewWidth: leftViewWidth ?? this.leftViewWidth,
      rightViewVisible: rightViewVisible ?? this.rightViewVisible,
      rightViewWidth: rightViewWidth ?? this.rightViewWidth,
      activeBottomView: clearActiveBottomView ? null : (activeBottomView ?? this.activeBottomView),
      bottomViewVisibility: bottomViewVisibility ?? this.bottomViewVisibility,
      bottomViewHeight: bottomViewHeight ?? this.bottomViewHeight,
      iconBarWidth: iconBarWidth ?? this.iconBarWidth,
      leftViewConfigs: leftViewConfigs ?? this.leftViewConfigs,
      bottomViewConfigs: bottomViewConfigs ?? this.bottomViewConfigs,
    );
  }
}