import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../../../shared/models/models.dart';
import '../../../shared/providers/providers.dart';
import '../../../utils/id_generator.dart';
import '../providers/tab_provider.dart';

/// Shows dialog for creating a new module
void showAddModuleDialog(BuildContext context, WidgetRef ref, List<Module> modules) {
  final nameController = TextEditingController();
  final chnnameController = TextEditingController();
  final descController = TextEditingController();

  final screenWidth = MediaQuery.of(context).size.width;
  const double baseWidth = 500.0; // 400 * 1.25
  final dialogWidth = (screenWidth * 0.85).clamp(baseWidth, baseWidth * 1.3);

  showDialog(
    context: context,
    builder: (context) => TDAlertDialog(
      title: '创建模块',
      contentWidget: SizedBox(
        width: dialogWidth,
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
            const SizedBox(height: 16),
            TDInput(
              controller: chnnameController,
              leftLabel: '中文名称',
              hintText: '例如: 用户模块',
              leftIcon: const Icon(TDIcons.translate),
              backgroundColor: Colors.transparent,
            ),
            const SizedBox(height: 16),
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
          TDToast.showSuccess('模块已创建', context: context);
        },
      ),
    ),
  );
}

/// Shows dialog for creating a new entity/table
void showAddEntityDialog(
  BuildContext context,
  WidgetRef ref,
  List<Module> modules,
  {Module? selectedModule}
) {
  final titleController = TextEditingController();
  final chnnameController = TextEditingController();
  final remarkController = TextEditingController();
  String selectedModuleId = selectedModule?.id ??
      (modules.isNotEmpty ? modules.first.id : '');

  final screenWidth = MediaQuery.of(context).size.width;
  const double baseWidth = 500.0; // 400 * 1.25
  final dialogWidth = (screenWidth * 0.85).clamp(baseWidth, baseWidth * 1.3);

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        return TDAlertDialog(
          title: '创建表',
          contentWidget: SizedBox(
            width: dialogWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 模块选择下拉框
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: TDTheme.of(context).componentBorderColor),
                    borderRadius: BorderRadius.circular(TDTheme.of(context).radiusDefault),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedModuleId.isEmpty ? null : selectedModuleId,
                      hint: const Text('选择归属模块'),
                      isExpanded: true,
                      items: modules.map((m) {
                        return DropdownMenuItem(
                          value: m.id,
                          child: Text('${m.chnname} (${m.name})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedModuleId = value ?? '';
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TDInput(
                  controller: titleController,
                  leftLabel: '表名称 (英文)',
                  hintText: '例如: user_info',
                  leftIcon: const Icon(TDIcons.code),
                  backgroundColor: Colors.transparent,
                ),
                const SizedBox(height: 16),
                TDInput(
                  controller: chnnameController,
                  leftLabel: '中文名称',
                  hintText: '例如: 用户信息表',
                  leftIcon: const Icon(TDIcons.translate),
                  backgroundColor: Colors.transparent,
                ),
                const SizedBox(height: 16),
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
              if (selectedModuleId.isEmpty) {
                TDToast.showText('请选择归属模块', context: context);
                return;
              }
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

              // Find the module and update it
              final module = modules.firstWhere(
                (m) => m.id == selectedModuleId,
              );
              final updatedModule = module.copyWith(
                entities: [...module.entities, entity],
                updatedAt: now,
              );
              ref.read(projectNotifierProvider.notifier).updateModule(
                module.id,
                updatedModule,
              );
              TDToast.showSuccess('表已创建', context: context);

              // Open the new entity in tab
              ref.read(tabProvider.notifier).openEntity(entity, selectedModuleId);
            },
          ),
        );
      },
    ),
  );
}

/// Shows dialog for deleting a module
void showDeleteModuleDialog(BuildContext context, WidgetRef ref, Module module) {
  showDialog(
    context: context,
    builder: (context) => TDAlertDialog(
      title: '删除模块',
      content: '确定要删除模块 "${module.chnname}" 吗？\n'
          '这将同时删除 ${module.entities.length} 个表。',
      leftBtn: TDDialogButtonOptions(
        title: '取消',
        theme: TDButtonTheme.defaultTheme,
        type: TDButtonType.text,
        action: () => Navigator.pop(context),
      ),
      rightBtn: TDDialogButtonOptions(
        title: '删除',
        theme: TDButtonTheme.danger,
        type: TDButtonType.fill,
        action: () {
          Navigator.pop(context);
          ref.read(projectNotifierProvider.notifier).removeModule(module.id);
          TDToast.showSuccess('模块已删除', context: context);
        },
      ),
    ),
  );
}

/// Shows dialog for deleting an entity
void showDeleteEntityDialog(BuildContext context, WidgetRef ref, Entity entity, Module module) {
  showDialog(
    context: context,
    builder: (context) => TDAlertDialog(
      title: '删除表',
      content: '确定要删除表 "${entity.chnname}" 吗？\n'
          '这将移除 ${entity.fields.length} 个字段。',
      leftBtn: TDDialogButtonOptions(
        title: '取消',
        theme: TDButtonTheme.defaultTheme,
        type: TDButtonType.text,
        action: () => Navigator.pop(context),
      ),
      rightBtn: TDDialogButtonOptions(
        title: '删除',
        theme: TDButtonTheme.danger,
        type: TDButtonType.fill,
        action: () {
          Navigator.pop(context);
          final now = DateTime.now();
          final updatedModule = module.copyWith(
            entities: module.entities.where((e) => e.id != entity.id).toList(),
            updatedAt: now,
          );
          ref.read(projectNotifierProvider.notifier).updateModule(
            module.id,
            updatedModule,
          );
          TDToast.showSuccess('表已删除', context: context);
        },
      ),
    ),
  );
}

/// Shows dialog for renaming a module
void showRenameModuleDialog(BuildContext context, WidgetRef ref, Module module) {
  final controller = TextEditingController(text: module.name);
  final chnController = TextEditingController(text: module.chnname);

  final screenWidth = MediaQuery.of(context).size.width;
  const double baseWidth = 500.0; // 400 * 1.25
  final dialogWidth = (screenWidth * 0.85).clamp(baseWidth, baseWidth * 1.3);

  showDialog(
    context: context,
    builder: (context) => TDAlertDialog(
      title: '重命名模块',
      contentWidget: SizedBox(
        width: dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TDInput(
              controller: controller,
              hintText: '模块名称 (英文)',
              leftLabel: '模块名称',
              autofocus: true,
              backgroundColor: Colors.transparent,
            ),
            const SizedBox(height: 16),
            TDInput(
              controller: chnController,
              hintText: '中文名称',
              leftLabel: '中文名称',
              backgroundColor: Colors.transparent,
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
        title: '确定',
        theme: TDButtonTheme.primary,
        type: TDButtonType.fill,
        action: () {
          Navigator.pop(context);
          if (controller.text.trim().isNotEmpty) {
            final updated = module.copyWith(
              name: controller.text.trim(),
              chnname: chnController.text.trim().isNotEmpty
                  ? chnController.text.trim()
                  : controller.text.trim(),
              updatedAt: DateTime.now(),
            );
            ref.read(projectNotifierProvider.notifier).updateModule(
              module.id,
              updated,
            );
          }
        },
      ),
    ),
  );
}

/// Shows dialog for renaming an entity
void showRenameEntityDialog(BuildContext context, WidgetRef ref, Entity entity, Module module) {
  final controller = TextEditingController(text: entity.title);
  final chnController = TextEditingController(text: entity.chnname);

  final screenWidth = MediaQuery.of(context).size.width;
  const double baseWidth = 500.0; // 400 * 1.25
  final dialogWidth = (screenWidth * 0.85).clamp(baseWidth, baseWidth * 1.3);

  showDialog(
    context: context,
    builder: (context) => TDAlertDialog(
      title: '重命名表',
      contentWidget: SizedBox(
        width: dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TDInput(
              controller: controller,
              hintText: '表名称 (英文)',
              leftLabel: '表名称',
              autofocus: true,
              backgroundColor: Colors.transparent,
            ),
            const SizedBox(height: 16),
            TDInput(
              controller: chnController,
              hintText: '中文名称',
              leftLabel: '中文名称',
              backgroundColor: Colors.transparent,
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
        title: '确定',
        theme: TDButtonTheme.primary,
        type: TDButtonType.fill,
        action: () {
          Navigator.pop(context);
          if (controller.text.trim().isNotEmpty) {
            final updatedEntity = entity.copyWith(
              title: controller.text.trim(),
              chnname: chnController.text.trim().isNotEmpty
                  ? chnController.text.trim()
                  : controller.text.trim(),
              updatedAt: DateTime.now(),
            );
            final updatedModule = module.copyWith(
              entities: module.entities
                  .map((e) => e.id == entity.id ? updatedEntity : e)
                  .toList(),
              updatedAt: DateTime.now(),
            );
            ref.read(projectNotifierProvider.notifier).updateModule(
              module.id,
              updatedModule,
            );
          }
        },
      ),
    ),
  );
}