import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../providers/layout_provider.dart';
import '../../models/layout_state.dart';
import '../../models/view_config.dart';
import 'package:bkdmm/shared/log_viewer/widgets/log_viewer_shell.dart';
import 'package:bkdmm/shared/terminal/widgets/terminal_shell.dart';

/// 底部视图容器
class BottomViewContainer extends ConsumerWidget {
  const BottomViewContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tdTheme = TDTheme.of(context);
    final layoutState = ref.watch(layoutProvider);
    final activeView = layoutState.activeBottomView;

    // 无激活视图时返回空
    if (activeView == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        final newHeight = ref.read(layoutProvider).bottomViewHeight -
            details.delta.dy;
        ref.read(layoutProvider.notifier).setBottomViewHeight(newHeight);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: layoutState.bottomViewHeight,
        decoration: BoxDecoration(
          color: tdTheme.bgColorContainer,
          border: Border(
            top: BorderSide(color: tdTheme.componentBorderColor),
          ),
        ),
        child: Column(
          children: [
            // 视图标签栏
            _buildViewTabs(context, layoutState, ref, tdTheme),

            // 分隔线
            Container(
              height: 1,
              color: tdTheme.componentBorderColor,
            ),

            // 视图内容 - 使用 Stack + Offstage 保持所有视图状态
            Expanded(
              child: Stack(
                children: layoutState.bottomViewConfigs.map((config) {
                  final isActive = activeView == config.id;
                  return Offstage(
                    offstage: !isActive,
                    child: _getViewPanel(config.id, tdTheme),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建视图标签栏
  Widget _buildViewTabs(
    BuildContext context,
    LayoutState state,
    WidgetRef ref,
    TDThemeData tdTheme,
  ) {
    final sortedViews = List<ViewConfig>.from(state.bottomViewConfigs)
      ..sort((a, b) => a.order.compareTo(b.order));

    return Container(
      height: 32,
      color: tdTheme.bgColorSecondaryContainer,
      child: Row(
        children: [
          // 视图标签
          ...sortedViews.map((v) => _buildViewTab(
                context,
                v,
                state.activeBottomView == v.id,
                ref,
                tdTheme,
              )),

          const Spacer(),

          // 关闭按钮
          TDButton(
            icon: TDIcons.close,
            size: TDButtonSize.small,
            type: TDButtonType.text,
            theme: TDButtonTheme.defaultTheme,
            onTap: () => ref.read(layoutProvider.notifier).hideBottomView(),
          ),
        ],
      ),
    );
  }

  /// 构建单个视图标签
  Widget _buildViewTab(
    BuildContext context,
    ViewConfig config,
    bool isActive,
    WidgetRef ref,
    TDThemeData tdTheme,
  ) {
    return GestureDetector(
      onTap: () => ref.read(layoutProvider.notifier).showBottomView(config.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? tdTheme.bgColorContainer : null,
          border: isActive
              ? Border(
                  bottom: BorderSide(
                    color: tdTheme.brandNormalColor,
                    width: 2,
                  ),
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              config.icon,
              size: 14,
              color: isActive
                  ? tdTheme.brandNormalColor
                  : tdTheme.textColorSecondary,
            ),
            const SizedBox(width: 4),
            TDText(
              config.title,
              font: tdTheme.fontMarkExtraSmall,
              textColor: isActive
                  ? tdTheme.brandNormalColor
                  : tdTheme.textColorSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ],
        ),
      ),
    );
  }

  /// 根据视图ID返回对应面板
  Widget _getViewPanel(String viewId, TDThemeData tdTheme) {
    switch (viewId) {
      case 'terminal':
        return const TerminalShell();
      case 'log':
        return const LogViewerShell();
      case 'output':
        return _OutputPanel(tdTheme: tdTheme);
      default:
        return Center(
          child: TDText(
            '未知视图: $viewId',
            textColor: tdTheme.textColorSecondary,
          ),
        );
    }
  }
}

/// 输出面板
class _OutputPanel extends StatelessWidget {
  final TDThemeData tdTheme;

  const _OutputPanel({required this.tdTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: tdTheme.bgColorContainer,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(TDIcons.code, size: 32, color: tdTheme.textColorSecondary),
            const SizedBox(height: 8),
            TDText(
              '代码生成输出功能开发中',
              textColor: tdTheme.textColorSecondary,
            ),
          ],
        ),
      ),
    );
  }
}