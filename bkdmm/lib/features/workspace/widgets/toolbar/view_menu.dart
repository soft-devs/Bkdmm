import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:bkdmm/shared/widgets/td_popup_menu.dart';
import '../../providers/layout_provider.dart';
import '../../models/layout_state.dart';

/// 视图管理菜单按钮
class ViewMenuButton extends ConsumerWidget {
  const ViewMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tdTheme = TDTheme.of(context);
    final layoutState = ref.watch(layoutProvider);

    return TDPopupMenuButton(
      icon: TDIcons.view_module,
      iconColor: tdTheme.textColorPrimary,
      items: _buildMenuItems(context, layoutState, tdTheme),
      onSelected: (value) => _handleMenuAction(ref, value),
    );
  }

  List<TDPopupMenuItem> _buildMenuItems(
    BuildContext context,
    LayoutState state,
    TDThemeData tdTheme,
  ) {
    return [
      // 左侧视图
      TDPopupMenuItem(
        value: 'left_header',
        icon: TDIcons.view_module,
        label: '─── 左侧视图 ───',
        textColor: tdTheme.textColorSecondary,
      ),
      ...state.leftViewConfigs.map((v) => TDPopupMenuItem(
            value: 'left_${v.id}',
            icon: v.icon,
            label: '${v.title}    ${v.shortcut}',
            iconColor: state.activeLeftView == v.id
                ? tdTheme.brandNormalColor
                : tdTheme.textColorSecondary,
          )),

      const TDPopupMenuItem.divider(),

      // 右侧视图
      TDPopupMenuItem(
        value: 'right_header',
        icon: TDIcons.info_circle,
        label: '─── 右侧视图 ───',
        textColor: tdTheme.textColorSecondary,
      ),
      TDPopupMenuItem(
        value: 'right_properties',
        icon: TDIcons.info_circle,
        label: '属性面板    Alt+P',
        iconColor: state.rightViewVisible
            ? tdTheme.brandNormalColor
            : tdTheme.textColorSecondary,
      ),

      const TDPopupMenuItem.divider(),

      // 底部视图
      TDPopupMenuItem(
        value: 'bottom_header',
        icon: TDIcons.terminal,
        label: '─── 底部视图 ───',
        textColor: tdTheme.textColorSecondary,
      ),
      ...state.bottomViewConfigs.map((v) => TDPopupMenuItem(
            value: 'bottom_${v.id}',
            icon: v.icon,
            label: '${v.title}    ${v.shortcut}',
            iconColor: state.activeBottomView == v.id
                ? tdTheme.brandNormalColor
                : tdTheme.textColorSecondary,
          )),

      const TDPopupMenuItem.divider(),

      // 布局操作
      TDPopupMenuItem(
        value: 'hide_all',
        icon: TDIcons.fullscreen,
        label: '全部隐藏',
      ),
      TDPopupMenuItem(
        value: 'restore',
        icon: TDIcons.refresh,
        label: '恢复默认布局',
      ),
    ];
  }

  void _handleMenuAction(WidgetRef ref, String value) {
    final notifier = ref.read(layoutProvider.notifier);

    if (value.startsWith('left_')) {
      final viewId = value.substring(5);
      if (viewId != 'header') {
        notifier.toggleLeftView(viewId);
      }
    } else if (value.startsWith('bottom_')) {
      final viewId = value.substring(7);
      if (viewId != 'header') {
        notifier.toggleBottomView(viewId);
      }
    } else if (value == 'right_properties') {
      notifier.toggleRightView();
    } else if (value == 'hide_all') {
      notifier.hideAllViews();
    } else if (value == 'restore') {
      notifier.restoreDefaultLayout();
    }
  }
}