import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/layout_state.dart';
import '../constants/view_configs.dart';

/// 布局状态 Provider
final layoutProvider = StateNotifierProvider<LayoutNotifier, LayoutState>(
  (ref) => LayoutNotifier(),
);

/// 布局状态管理器
class LayoutNotifier extends StateNotifier<LayoutState> {
  LayoutNotifier()
      : super(LayoutState(
          leftViewConfigs: ViewConfigs.leftViews,
          bottomViewConfigs: ViewConfigs.bottomViews,
          leftViewVisibility: ViewConfigs.defaultLeftVisibility,
          bottomViewVisibility: ViewConfigs.defaultBottomVisibility,
          activeLeftView: 'module_tree', // 默认激活模块树
        ));

  // ========== 左侧视图操作 ==========

  /// 显示左侧视图
  void showLeftView(String viewId) {
    state = state.copyWith(
      activeLeftView: viewId,
      leftViewVisibility: {
        ...state.leftViewVisibility,
        viewId: true,
      },
    );
  }

  /// 隐藏左侧视图
  void hideLeftView() {
    state = state.copyWith(clearActiveLeftView: true);
  }

  /// 切换左侧视图
  void toggleLeftView(String viewId) {
    if (state.activeLeftView == viewId) {
      hideLeftView();
    } else {
      showLeftView(viewId);
    }
  }

  /// 设置左侧视图宽度
  void setLeftViewWidth(double width) {
    state = state.copyWith(leftViewWidth: width.clamp(200.0, 400.0));
  }

  // ========== 右侧视图操作 ==========

  /// 显示右侧视图
  void showRightView() {
    state = state.copyWith(rightViewVisible: true);
  }

  /// 隐藏右侧视图
  void hideRightView() {
    state = state.copyWith(rightViewVisible: false);
  }

  /// 切换右侧视图
  void toggleRightView() {
    state = state.copyWith(rightViewVisible: !state.rightViewVisible);
  }

  /// 设置右侧视图宽度
  void setRightViewWidth(double width) {
    state = state.copyWith(rightViewWidth: width.clamp(200.0, 400.0));
  }

  // ========== 底部视图操作 ==========

  /// 显示底部视图
  void showBottomView(String viewId) {
    state = state.copyWith(
      activeBottomView: viewId,
      bottomViewVisibility: {
        ...state.bottomViewVisibility,
        viewId: true,
      },
    );
  }

  /// 隐藏底部视图
  void hideBottomView() {
    state = state.copyWith(clearActiveBottomView: true);
  }

  /// 切换底部视图
  void toggleBottomView(String viewId) {
    if (state.activeBottomView == viewId) {
      hideBottomView();
    } else {
      showBottomView(viewId);
    }
  }

  /// 设置底部视图高度
  void setBottomViewHeight(double height) {
    state = state.copyWith(bottomViewHeight: height.clamp(100.0, 400.0));
  }

  // ========== 全局操作 ==========

  /// 隐藏所有视图
  void hideAllViews() {
    state = state.copyWith(
      clearActiveLeftView: true,
      rightViewVisible: false,
      clearActiveBottomView: true,
    );
  }

  /// 恢复默认布局
  void restoreDefaultLayout() {
    state = LayoutState(
      leftViewConfigs: ViewConfigs.leftViews,
      bottomViewConfigs: ViewConfigs.bottomViews,
      leftViewVisibility: ViewConfigs.defaultLeftVisibility,
      bottomViewVisibility: ViewConfigs.defaultBottomVisibility,
      activeLeftView: 'module_tree',
      rightViewVisible: true,
    );
  }

  // ========== 快捷键处理 ==========

  /// 处理视图快捷键
  bool handleViewShortcut(String shortcut) {
    final viewId = ViewConfigs.shortcutToViewId[shortcut];
    if (viewId == null) return false;

    // 判断是左侧视图还是底部视图
    final leftView = ViewConfigs.getLeftViewById(viewId);
    if (leftView != null) {
      toggleLeftView(viewId);
      return true;
    }

    final bottomView = ViewConfigs.getBottomViewById(viewId);
    if (bottomView != null) {
      toggleBottomView(viewId);
      return true;
    }

    // 特殊处理：属性面板
    if (viewId == 'properties') {
      toggleRightView();
      return true;
    }

    return false;
  }
}