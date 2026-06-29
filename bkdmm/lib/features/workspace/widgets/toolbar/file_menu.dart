import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../../shared/providers/providers.dart';
import '../../../../shared/widgets/td_popup_menu.dart';
import '../../../settings/views/settings_view.dart';

/// 文件管理菜单按钮
class FileMenuButton extends ConsumerWidget {
  const FileMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tdTheme = TDTheme.of(context);

    return TDPopupMenuButton(
      icon: TDIcons.folder,
      iconColor: tdTheme.textColorPrimary,
      items: [
        TDPopupMenuItem(
          value: 'new_project',
          icon: TDIcons.add,
          label: '新建项目',
        ),
        TDPopupMenuItem(
          value: 'open_project',
          icon: TDIcons.folder_open,
          label: '打开项目',
        ),
        TDPopupMenuItem(
          value: 'open_recent',
          icon: TDIcons.history,
          label: '打开最近项目...',
        ),
        const TDPopupMenuItem.divider(),
        TDPopupMenuItem(
          value: 'save',
          icon: TDIcons.save,
          label: '保存项目',
        ),
        TDPopupMenuItem(
          value: 'save_as',
          icon: TDIcons.folder,
          label: '另存为...',
        ),
        const TDPopupMenuItem.divider(),
        TDPopupMenuItem(
          value: 'project_settings',
          icon: TDIcons.setting,
          label: '项目设置',
        ),
        const TDPopupMenuItem.divider(),
        TDPopupMenuItem(
          value: 'close_project',
          icon: TDIcons.close,
          label: '关闭项目',
        ),
      ],
      onSelected: (value) => _handleMenuAction(context, ref, value),
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String value) {
    switch (value) {
      case 'new_project':
        // TODO: 新建项目
        TDToast.showText('新建项目功能开发中', context: context);
        break;
      case 'open_project':
        // TODO: 打开项目
        TDToast.showText('打开项目功能开发中', context: context);
        break;
      case 'open_recent':
        // TODO: 打开最近项目
        TDToast.showText('打开最近项目功能开发中', context: context);
        break;
      case 'save':
        _saveProject(context, ref);
        break;
      case 'save_as':
        TDToast.showText('另存为功能开发中', context: context);
        break;
      case 'project_settings':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const SettingsView(),
          ),
        );
        break;
      case 'close_project':
        _closeProject(context, ref);
        break;
    }
  }

  Future<void> _saveProject(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(projectProvider.notifier).saveProject();
      if (context.mounted) {
        TDToast.showSuccess('项目已保存', context: context);
      }
    } catch (e) {
      if (context.mounted) {
        TDToast.showText('保存失败: $e', context: context);
      }
    }
  }

  Future<void> _closeProject(BuildContext context, WidgetRef ref) async {
    final projectState = ref.read(projectProvider);

    // 检查未保存更改
    if (projectState.isDirty) {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) => TDAlertDialog(
          title: '保存更改',
          content: '项目有未保存的更改，是否保存？',
          leftBtn: TDDialogButtonOptions(
            title: '不保存',
            theme: TDButtonTheme.defaultTheme,
            type: TDButtonType.text,
            action: () => Navigator.pop(context, false),
          ),
          rightBtn: TDDialogButtonOptions(
            title: '保存',
            theme: TDButtonTheme.primary,
            type: TDButtonType.fill,
            action: () => Navigator.pop(context, true),
          ),
        ),
      );

      if (shouldSave == true) {
        await _saveProject(context, ref);
      }
    }

    // 关闭项目
    await ref.read(projectProvider.notifier).closeProject(promptSave: false);

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}