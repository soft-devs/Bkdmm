import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../providers/layout_provider.dart';
import '../module_tree.dart';
import '../../../datatype/views/datatype_view.dart';
import '../../../../shared/providers/providers.dart';

/// 左侧视图容器
class LeftViewContainer extends ConsumerWidget {
  const LeftViewContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tdTheme = TDTheme.of(context);
    final layoutState = ref.watch(layoutProvider);
    final activeView = layoutState.activeLeftView;

    // 无激活视图时返回空
    if (activeView == null) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: layoutState.leftViewWidth,
      decoration: BoxDecoration(
        color: tdTheme.bgColorContainer,
        border: Border(
          right: BorderSide(color: tdTheme.componentBorderColor),
        ),
      ),
      child: Column(
        children: [
          // 视图标题栏
          _buildTitleBar(context, activeView, ref, tdTheme),

          // 分隔线
          Container(
            height: 1,
            color: tdTheme.componentBorderColor,
          ),

          // 视图内容
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _getViewPanel(activeView, ref),
            ),
          ),

          // 可拖拽调整宽度的分隔条
          _buildResizeHandle(context, ref, tdTheme),
        ],
      ),
    );
  }

  /// 构建标题栏
  Widget _buildTitleBar(
    BuildContext context,
    String viewId,
    WidgetRef ref,
    TDThemeData tdTheme,
  ) {
    final title = _getViewTitle(viewId);

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          TDText(
            title,
            font: tdTheme.fontTitleSmall,
            fontWeight: FontWeight.w600,
          ),
          const Spacer(),
          // 关闭按钮
          TDButton(
            icon: TDIcons.close,
            size: TDButtonSize.extraSmall,
            type: TDButtonType.text,
            theme: TDButtonTheme.defaultTheme,
            onTap: () => ref.read(layoutProvider.notifier).hideLeftView(),
          ),
        ],
      ),
    );
  }

  /// 获取视图标题
  String _getViewTitle(String viewId) {
    switch (viewId) {
      case 'module_tree':
        return '模块树';
      case 'datatype':
        return '数据类型';
      default:
        return '视图';
    }
  }

  /// 根据视图ID返回对应面板
  Widget _getViewPanel(String viewId, WidgetRef ref) {
    switch (viewId) {
      case 'module_tree':
        return _ModuleTreePanel();
      case 'datatype':
        return const DataTypeView();
      default:
        return const Center(child: Text('未知视图'));
    }
  }

  /// 构建宽度调整手柄
  Widget _buildResizeHandle(
    BuildContext context,
    WidgetRef ref,
    TDThemeData tdTheme,
  ) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        final newWidth =
            ref.read(layoutProvider).leftViewWidth + details.delta.dx;
        ref.read(layoutProvider.notifier).setLeftViewWidth(newWidth);
      },
      child: Container(
        width: 4,
        color: tdTheme.bgColorSecondaryContainer,
        child: Center(
          child: Container(
            width: 2,
            height: 40,
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

/// 模块树面板包装
class _ModuleTreePanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectState = ref.watch(projectProvider);
    final project = projectState.project;

    if (project == null) {
      return const Center(child: Text('未打开项目'));
    }

    return ModuleTree(
      project: project,
      onAddModule: () {
        // TODO: 添加模块
      },
      onAddEntity: (module) {
        // TODO: 添加实体
      },
      onSelectModule: (module) {
        // TODO: 选择模块
      },
    );
  }
}