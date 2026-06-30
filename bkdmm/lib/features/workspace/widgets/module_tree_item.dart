import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import 'package:bkdmm/shared/models/models.dart';
import 'package:bkdmm/shared/widgets/td_popup_menu.dart';

/// Individual module tree item widget
class ModuleTreeItem extends StatelessWidget {
  final Module module;
  final bool isExpanded;
  final bool isSelected;
  final String? selectedEntityId;
  final VoidCallback onToggleExpand;
  final VoidCallback onSelectModule;
  final Function(Entity) onSelectEntity;
  final VoidCallback onDeleteModule;
  final Function(Entity) onDeleteEntity;
  final VoidCallback onRenameModule;
  final Function(Entity) onRenameEntity;
  final VoidCallback onOpenRelation;
  final TDThemeData tdTheme;

  const ModuleTreeItem({
    super.key,
    required this.module,
    required this.isExpanded,
    required this.isSelected,
    required this.selectedEntityId,
    required this.onToggleExpand,
    required this.onSelectModule,
    required this.onSelectEntity,
    required this.onDeleteModule,
    required this.onDeleteEntity,
    required this.onRenameModule,
    required this.onRenameEntity,
    required this.onOpenRelation,
    required this.tdTheme,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBg = isSelected
        ? tdTheme.brandNormalColor.withValues(alpha: 0.1)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Module row
        InkWell(
          onTap: onSelectModule,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: selectedBg,
            ),
            child: Row(
              children: [
                // Expand/collapse button
                GestureDetector(
                  onTap: onToggleExpand,
                  child: AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      TDIcons.chevron_right,
                      size: 18,
                      color: tdTheme.textColorSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Module icon
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? tdTheme.brandNormalColor.withValues(alpha: 0.15)
                        : tdTheme.bgColorSecondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    TDIcons.view_module,
                    size: 14,
                    color: isSelected
                        ? tdTheme.brandNormalColor
                        : tdTheme.textColorSecondary,
                  ),
                ),
                const SizedBox(width: 8),

                // Module name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TDText(
                        module.name,
                        font: tdTheme.fontBodyMedium,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      TDText(
                        module.chnname,
                        font: tdTheme.fontBodySmall,
                        textColor: tdTheme.textColorSecondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Entity count badge
                if (module.entities.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tdTheme.bgColorSecondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TDText(
                      '${module.entities.length}',
                      font: tdTheme.fontBodySmall,
                      textColor: tdTheme.textColorSecondary,
                    ),
                  ),

                // Context menu button
                _buildModuleContextMenu(context),
              ],
            ),
          ),
        ),

        // Entity list (if expanded)
        if (isExpanded)
          ...module.entities.map((entity) => EntityTreeItem(
                entity: entity,
                isSelected: selectedEntityId == entity.id,
                onSelect: () => onSelectEntity(entity),
                onDelete: () => onDeleteEntity(entity),
                onRename: () => onRenameEntity(entity),
                tdTheme: tdTheme,
              )),
      ],
    );
  }

  Widget _buildModuleContextMenu(BuildContext context) {
    return TDPopupMenuButton(
      icon: TDIcons.more,
      iconSize: 16,
      iconColor: tdTheme.textColorSecondary,
      items: [
        TDPopupMenuItem(
          value: 'open_relation',
          icon: TDIcons.link,
          label: '打开关系图',
        ),
        const TDPopupMenuItem.divider(),
        TDPopupMenuItem(
          value: 'rename',
          icon: TDIcons.edit,
          label: '重命名',
        ),
        const TDPopupMenuItem.divider(),
        TDPopupMenuItem(
          value: 'delete',
          icon: TDIcons.delete,
          label: '删除',
          iconColor: tdTheme.errorNormalColor,
          textColor: tdTheme.errorNormalColor,
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'open_relation':
            onOpenRelation();
            break;
          case 'rename':
            onRenameModule();
            break;
          case 'delete':
            onDeleteModule();
            break;
        }
      },
    );
  }
}

/// Individual entity tree item widget
class EntityTreeItem extends StatelessWidget {
  final Entity entity;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final TDThemeData tdTheme;

  const EntityTreeItem({
    super.key,
    required this.entity,
    required this.isSelected,
    required this.onSelect,
    required this.onDelete,
    required this.onRename,
    required this.tdTheme,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBg = isSelected
        ? tdTheme.brandNormalColor.withValues(alpha: 0.1)
        : null;

    return InkWell(
      onTap: onSelect,
      onDoubleTap: onSelect,
      child: Container(
        padding: const EdgeInsets.only(left: 44, right: 8, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: selectedBg,
        ),
        child: Row(
          children: [
            // Entity icon
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected
                    ? tdTheme.brandNormalColor.withValues(alpha: 0.15)
                    : tdTheme.bgColorSecondaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                TDIcons.table,
                size: 12,
                color: isSelected
                    ? tdTheme.brandNormalColor
                    : tdTheme.textColorSecondary,
              ),
            ),
            const SizedBox(width: 8),

            // Entity name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TDText(
                    entity.title,
                    font: tdTheme.fontBodySmall,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  TDText(
                    entity.chnname,
                    font: tdTheme.fontBodySmall,
                    textColor: tdTheme.textColorSecondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Field count
            if (entity.fields.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: tdTheme.bgColorSecondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TDText(
                  '${entity.fields.length}',
                  font: tdTheme.fontBodySmall,
                  textColor: tdTheme.textColorSecondary,
                ),
              ),

            // Context menu
            _buildEntityContextMenu(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEntityContextMenu(BuildContext context) {
    return TDPopupMenuButton(
      icon: TDIcons.more,
      iconSize: 14,
      iconColor: tdTheme.textColorSecondary,
      items: [
        TDPopupMenuItem(
          value: 'rename',
          icon: TDIcons.edit,
          label: '重命名',
        ),
        const TDPopupMenuItem.divider(),
        TDPopupMenuItem(
          value: 'delete',
          icon: TDIcons.delete,
          label: '删除',
          iconColor: tdTheme.errorNormalColor,
          textColor: tdTheme.errorNormalColor,
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'rename':
            onRename();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
    );
  }
}