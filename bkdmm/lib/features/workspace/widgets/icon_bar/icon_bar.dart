import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../providers/layout_provider.dart';
import 'upper_section.dart';
import 'lower_section.dart';

/// 左侧图标栏
class IconBar extends ConsumerWidget {
  const IconBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tdTheme = TDTheme.of(context);
    final layoutState = ref.watch(layoutProvider);

    return Container(
      width: layoutState.iconBarWidth,
      decoration: BoxDecoration(
        color: tdTheme.bgColorContainer,
        border: Border(
          right: BorderSide(color: tdTheme.grayColor13),
        ),
      ),
      child: Column(
        children: [
          // 上部图标区 - 控制左侧视图
          Expanded(
            child: UpperSection(
              views: layoutState.leftViewConfigs,
              activeViewId: layoutState.activeLeftView,
              onViewToggle: (viewId) =>
                  ref.read(layoutProvider.notifier).toggleLeftView(viewId),
            ),
          ),

          // 分割线
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 8),
            color: tdTheme.componentBorderColor,
          ),

          // 下部图标区 - 控制底部视图
          LowerSection(
            views: layoutState.bottomViewConfigs,
            activeViewId: layoutState.activeBottomView,
            onViewToggle: (viewId) =>
                ref.read(layoutProvider.notifier).toggleBottomView(viewId),
          ),
        ],
      ),
    );
  }
}