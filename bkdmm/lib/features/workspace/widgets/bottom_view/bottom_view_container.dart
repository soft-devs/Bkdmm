import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../providers/layout_provider.dart';
import '../../models/layout_state.dart';
import '../../models/view_config.dart';

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

    return AnimatedContainer(
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

          // 视图内容
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _getViewPanel(activeView, tdTheme),
            ),
          ),

          // 可拖拽调整高度的分隔条
          _buildResizeHandle(context, ref, tdTheme),
        ],
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
      case 'console':
        return _ConsolePanel(tdTheme: tdTheme);
      case 'log':
        return _LogPanel(tdTheme: tdTheme);
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

  /// 构建高度调整手柄
  Widget _buildResizeHandle(
    BuildContext context,
    WidgetRef ref,
    TDThemeData tdTheme,
  ) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        final newHeight = ref.read(layoutProvider).bottomViewHeight -
            details.delta.dy;
        ref.read(layoutProvider.notifier).setBottomViewHeight(newHeight);
      },
      child: Container(
        height: 4,
        color: tdTheme.bgColorSecondaryContainer,
        child: Center(
          child: Container(
            width: 40,
            height: 2,
            decoration: BoxDecoration(
              color: tdTheme.componentBorderColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ),
    );
  }
}

/// 控制台面板
class _ConsolePanel extends StatelessWidget {
  final TDThemeData tdTheme;

  const _ConsolePanel({required this.tdTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: tdTheme.bgColorContainer,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(TDIcons.terminal, size: 32, color: tdTheme.textColorSecondary),
            const SizedBox(height: 8),
            TDText(
              '控制台功能开发中',
              textColor: tdTheme.textColorSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// 日志面板
class _LogPanel extends StatelessWidget {
  final TDThemeData tdTheme;

  const _LogPanel({required this.tdTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: tdTheme.bgColorContainer,
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          _LogEntry(
            time: '2024-01-15 10:30:15',
            level: 'INFO',
            message: '项目加载完成',
            tdTheme: tdTheme,
          ),
          _LogEntry(
            time: '2024-01-15 10:30:16',
            level: 'INFO',
            message: '数据库连接成功',
            tdTheme: tdTheme,
          ),
          _LogEntry(
            time: '2024-01-15 10:30:20',
            level: 'WARN',
            message: '表 user 缺少主键定义',
            tdTheme: tdTheme,
          ),
        ],
      ),
    );
  }
}

/// 日志条目
class _LogEntry extends StatelessWidget {
  final String time;
  final String level;
  final String message;
  final TDThemeData tdTheme;

  const _LogEntry({
    required this.time,
    required this.level,
    required this.message,
    required this.tdTheme,
  });

  Color _getLevelColor() {
    switch (level) {
      case 'INFO':
        return tdTheme.brandNormalColor;
      case 'WARN':
        return tdTheme.warningColor5;
      case 'ERROR':
        return tdTheme.errorNormalColor;
      default:
        return tdTheme.textColorSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          TDText(
            time,
            font: tdTheme.fontMarkExtraSmall,
            textColor: tdTheme.textColorSecondary,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: _getLevelColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: TDText(
              level,
              font: tdTheme.fontMarkExtraSmall,
              textColor: _getLevelColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TDText(
              message,
              font: tdTheme.fontBodySmall,
              textColor: tdTheme.textColorPrimary,
            ),
          ),
        ],
      ),
    );
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