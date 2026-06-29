import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../../shared/providers/providers.dart';
import 'file_menu.dart';
import 'view_menu.dart';
import '../../../settings/views/settings_view.dart';

/// 顶部菜单栏
class TopMenuBar extends ConsumerWidget {
  const TopMenuBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tdTheme = TDTheme.of(context);
    final projectState = ref.watch(projectProvider);
    final project = projectState.project;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: tdTheme.bgColorContainer,
        border: Border(
          bottom: BorderSide(color: tdTheme.componentBorderColor),
        ),
      ),
      child: Row(
        children: [
          // 文件管理菜单
          const FileMenuButton(),
          const SizedBox(width: 4),

          // 视图管理菜单
          const ViewMenuButton(),
          const SizedBox(width: 8),

          // 分隔线
          Container(
            width: 1,
            height: 24,
            color: tdTheme.componentBorderColor,
          ),
          const SizedBox(width: 8),

          // 项目名称
          if (project != null) ...[
            Icon(TDIcons.folder_open,
                size: 18, color: tdTheme.brandNormalColor),
            const SizedBox(width: 4),
            TDText(
              project.name,
              font: tdTheme.fontBodyMedium,
              fontWeight: FontWeight.w600,
            ),
            if (projectState.isDirty)
              TDText(
                ' *',
                font: tdTheme.fontBodyMedium,
                textColor: tdTheme.brandNormalColor,
              ),
            const SizedBox(width: 8),
          ],

          const Spacer(),

          // 右侧操作按钮
          TDButton(
            icon: TDIcons.save,
            size: TDButtonSize.small,
            type: TDButtonType.text,
            theme: TDButtonTheme.defaultTheme,
            onTap: () => _saveProject(context, ref),
          ),
          TDButton(
            icon: TDIcons.code,
            size: TDButtonSize.small,
            type: TDButtonType.text,
            theme: TDButtonTheme.defaultTheme,
            onTap: () => _showGenerateMenu(context),
          ),
          TDButton(
            icon: TDIcons.setting,
            size: TDButtonSize.small,
            type: TDButtonType.text,
            theme: TDButtonTheme.defaultTheme,
            onTap: () => _openSettings(context),
          ),
        ],
      ),
    );
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

  void _showGenerateMenu(BuildContext context) {
    TDToast.showText('代码生成功能开发中', context: context);
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsView(),
      ),
    );
  }
}