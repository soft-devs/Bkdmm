import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../providers/layout_provider.dart';
import '../../providers/tab_provider.dart';
import '../module_tree.dart';
import '../../../datatype/views/datatype_view.dart';
import '../../../../shared/providers/providers.dart';
import '../../../../shared/models/models.dart';
import '../../../../utils/id_generator.dart';

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
        _showAddModuleDialog(context, ref);
      },
      onAddEntity: (module) {
        _showAddEntityDialog(context, ref, module);
      },
      onSelectModule: (module) {
        ref.read(tabProvider.notifier).openModule(module);
      },
    );
  }

  void _showAddModuleDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final chnnameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: '创建模块',
        contentWidget: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TDInput(
                controller: nameController,
                leftLabel: '模块名称 (英文)',
                hintText: '例如: user',
                leftIcon: const Icon(TDIcons.code),
                backgroundColor: Colors.transparent,
              ),
              const SizedBox(height: 12),
              TDInput(
                controller: chnnameController,
                leftLabel: '中文名称',
                hintText: '例如: 用户模块',
                leftIcon: const Icon(TDIcons.translate),
                backgroundColor: Colors.transparent,
              ),
              const SizedBox(height: 12),
              TDInput(
                controller: descController,
                leftLabel: '描述',
                hintText: '模块描述 (可选)',
                leftIcon: const Icon(TDIcons.edit),
                backgroundColor: Colors.transparent,
                maxLines: 2,
              ),
            ],
          ),
        ),
        leftBtn: TDDialogButtonOptions(
          title: '取消',
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          action: () => Navigator.pop(context),
        ),
        rightBtn: TDDialogButtonOptions(
          title: '创建',
          theme: TDButtonTheme.primary,
          type: TDButtonType.fill,
          action: () {
            if (nameController.text.trim().isEmpty) {
              TDToast.showText('请输入模块名称', context: context);
              return;
            }
            Navigator.pop(context);

            final now = DateTime.now();
            final module = Module(
              id: IdGenerator.generate(),
              name: nameController.text.trim(),
              chnname: chnnameController.text.trim().isNotEmpty
                  ? chnnameController.text.trim()
                  : nameController.text.trim(),
              description: descController.text.trim().isNotEmpty
                  ? descController.text.trim()
                  : null,
              entities: [],
              graphCanvas: GraphCanvas(),
              createdAt: now,
              updatedAt: now,
            );
            ref.read(projectNotifierProvider.notifier).addModule(module);
            TDToast.showText('模块已创建', context: context);
          },
        ),
      ),
    );
  }

  void _showAddEntityDialog(BuildContext context, WidgetRef ref, Module module) {
    final titleController = TextEditingController();
    final chnnameController = TextEditingController();
    final remarkController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: '在 "${module.chnname}" 中创建表',
        contentWidget: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TDInput(
                controller: titleController,
                leftLabel: '表名称 (英文)',
                hintText: '例如: user_info',
                leftIcon: const Icon(TDIcons.code),
                backgroundColor: Colors.transparent,
              ),
              const SizedBox(height: 12),
              TDInput(
                controller: chnnameController,
                leftLabel: '中文名称',
                hintText: '例如: 用户信息表',
                leftIcon: const Icon(TDIcons.translate),
                backgroundColor: Colors.transparent,
              ),
              const SizedBox(height: 12),
              TDInput(
                controller: remarkController,
                leftLabel: '备注',
                hintText: '表描述 (可选)',
                leftIcon: const Icon(TDIcons.edit),
                backgroundColor: Colors.transparent,
                maxLines: 2,
              ),
            ],
          ),
        ),
        leftBtn: TDDialogButtonOptions(
          title: '取消',
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          action: () => Navigator.pop(context),
        ),
        rightBtn: TDDialogButtonOptions(
          title: '创建',
          theme: TDButtonTheme.primary,
          type: TDButtonType.fill,
          action: () {
            if (titleController.text.trim().isEmpty) {
              TDToast.showText('请输入表名称', context: context);
              return;
            }
            Navigator.pop(context);

            final now = DateTime.now();
            final entity = Entity(
              id: IdGenerator.generate(),
              title: titleController.text.trim(),
              chnname: chnnameController.text.trim().isNotEmpty
                  ? chnnameController.text.trim()
                  : titleController.text.trim(),
              remark: remarkController.text.trim().isNotEmpty
                  ? remarkController.text.trim()
                  : null,
              fields: [],
              indexes: [],
              createdAt: now,
              updatedAt: now,
            );

            final updatedModule = module.copyWith(
              entities: [...module.entities, entity],
              updatedAt: now,
            );
            ref.read(projectNotifierProvider.notifier).updateModule(
              module.id,
              updatedModule,
            );
            TDToast.showText('表已创建', context: context);

            // 打开新创建的表编辑器
            ref.read(tabProvider.notifier).openEntity(entity, module.id);
          },
        ),
      ),
    );
  }
}