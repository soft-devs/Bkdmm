import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:bkdmm/core/i18n/i18n.dart';
import 'package:bkdmm/l10n/app_localizations.dart';
import 'package:bkdmm/shared/models/models.dart';
import 'package:bkdmm/shared/utils/responsive_utils.dart';
import 'package:bkdmm/shared/widgets/widgets.dart';

/// Index editor widget for managing table indexes
///
/// Features:
/// - Index name and type (NORMAL/UNIQUE/FULLTEXT)
/// - Field selection with checkboxes
/// - Add/delete indexes
class IndexEditor extends StatefulWidget {
  final List<Index> indexes;
  final List<Field> availableFields;
  final Function(Index) onAddIndex;
  final Function(String, Index) onUpdateIndex;
  final Function(String) onDeleteIndex;

  const IndexEditor({
    super.key,
    required this.indexes,
    required this.availableFields,
    required this.onAddIndex,
    required this.onUpdateIndex,
    required this.onDeleteIndex,
  });

  @override
  State<IndexEditor> createState() => _IndexEditorState();
}

class _IndexEditorState extends State<IndexEditor> {
  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);
    final l10n = context.l10n;

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: tdTheme.bgColorSecondaryContainer,
            border: Border(
              bottom: BorderSide(color: tdTheme.componentBorderColor),
            ),
          ),
          child: Row(
            children: [
              TDText(
                '${l10n.indexes} (${widget.indexes.length})',
                font: tdTheme.fontTitleSmall,
                fontWeight: FontWeight.w600,
              ),
              const Spacer(),
              TDButton(
                text: l10n.addIndex,
                icon: TDIcons.add,
                theme: TDButtonTheme.primary,
                type: TDButtonType.fill,
                onTap: _showAddIndexDialog,
              ),
            ],
          ),
        ),

        // Index list
        Expanded(
          child: widget.indexes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        TDIcons.filter,
                        size: 64,
                        color: tdTheme.textColorSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      TDText(
                        l10n.noIndexesDefined,
                        font: tdTheme.fontTitleMedium,
                        textColor: tdTheme.textColorSecondary,
                      ),
                      const SizedBox(height: 8),
                      TDText(
                        l10n.addIndexHint,
                        font: tdTheme.fontBodyMedium,
                        textColor: tdTheme.textColorSecondary.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.indexes.length,
                  itemBuilder: (context, index) {
                    final idx = widget.indexes[index];
                    return _buildIndexCard(idx, tdTheme, l10n);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildIndexCard(Index index, TDThemeData tdTheme, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: tdTheme.bgColorContainer,
        borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
        border: Border.all(color: tdTheme.componentBorderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(
                _getIndexTypeIcon(index.type),
                size: 20,
                color: tdTheme.brandNormalColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TDText(
                  index.name,
                  font: tdTheme.fontTitleSmall,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Type chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getIndexTypeColor(index.type, tdTheme),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TDText(
                  _getIndexTypeLabel(index.type, l10n),
                  font: tdTheme.fontMarkExtraSmall,
                  textColor: tdTheme.textColorPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              // Edit button
              TDButton(
                icon: TDIcons.edit,
                theme: TDButtonTheme.defaultTheme,
                type: TDButtonType.text,
                size: TDButtonSize.small,
                onTap: () => _showEditIndexDialog(index),
              ),
              // Delete button
              TDButton(
                icon: TDIcons.delete,
                theme: TDButtonTheme.danger,
                type: TDButtonType.text,
                size: TDButtonSize.small,
                onTap: () => _confirmDeleteIndex(index),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Fields
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: index.fieldIds.map((fieldId) {
              final field = widget.availableFields.where((f) => f.id == fieldId).firstOrNull;
              final displayName = field?.name ?? fieldId;
              return TDTag(
                displayName,
                theme: TDTagTheme.primary,
                size: TDTagSize.small,
              );
            }).toList(),
          ),

          // Remark
          if (index.remark != null && index.remark!.isNotEmpty) ...[
            const SizedBox(height: 8),
            TDText(
              index.remark!,
              font: tdTheme.fontBodySmall,
              textColor: tdTheme.textColorSecondary,
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIndexTypeIcon(IndexType type) {
    switch (type) {
      case IndexType.unique:
        return TDIcons.check_circle;
      case IndexType.fulltext:
        return TDIcons.edit;
      case IndexType.normal:
        return TDIcons.filter;
    }
  }

  Color _getIndexTypeColor(IndexType type, TDThemeData tdTheme) {
    switch (type) {
      case IndexType.unique:
        return tdTheme.brandLightColor;
      case IndexType.fulltext:
        return tdTheme.warningColor5.withValues(alpha: 0.2);
      case IndexType.normal:
        return tdTheme.bgColorSecondaryContainer;
    }
  }

  String _getIndexTypeLabel(IndexType type, AppLocalizations l10n) {
    switch (type) {
      case IndexType.unique:
        return l10n.unique;
      case IndexType.fulltext:
        return l10n.fulltext;
      case IndexType.normal:
        return l10n.normal;
    }
  }

  void _showAddIndexDialog() {
    _showIndexDialog(null);
  }

  void _showEditIndexDialog(Index index) {
    _showIndexDialog(index);
  }

  void _showIndexDialog(Index? existingIndex) {
    final l10n = context.l10n;
    final nameController = TextEditingController(
      text: existingIndex?.name ?? 'idx_${widget.indexes.length + 1}',
    );
    final remarkController = TextEditingController(text: existingIndex?.remark ?? '');
    IndexType selectedType = existingIndex?.type ?? IndexType.normal;
    Set<String> selectedFieldIds = existingIndex?.fieldIds.toSet() ?? {};

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final tdTheme = TDTheme.of(context);
          final dialogL10n = context.l10n;
          final formSpacing = ResponsiveUtils.getFormFieldSpacing(context);
          // Responsive dialog width calculation using utility
          final dialogWidth = ResponsiveUtils.getDialogWidth(context, DialogSizePreset.form);

          return TDAlertDialog(
            title: existingIndex == null ? l10n.addIndex : l10n.editIndex,
            contentWidget: SizedBox(
              width: dialogWidth,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TDInput(
                      controller: nameController,
                      leftLabel: l10n.indexNameStar,
                      hintText: 'e.g., idx_user_id',
                      leftIcon: const Icon(TDIcons.edit),
                      backgroundColor: Colors.transparent,
                    ),
                    SizedBox(height: formSpacing * 0.75),
                    // Type selector using TDesign style
                    _buildTypeSelector(
                      context: context,
                      selectedType: selectedType,
                      onTypeChanged: (type) => setState(() => selectedType = type),
                    ),
                    SizedBox(height: formSpacing * 0.75),
                    TDText(
                      l10n.selectFieldsLabel,
                      font: tdTheme.fontTitleSmall,
                    ),
                    const SizedBox(height: 8),
                    // Fixed height container for field selection
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 180,
                        minHeight: 50,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: tdTheme.bgColorSecondaryContainer,
                          border: Border.all(color: tdTheme.componentBorderColor),
                          borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
                        ),
                        child: widget.availableFields.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: TDText(
                                    l10n.noFieldsAvailable,
                                    font: tdTheme.fontBodyMedium,
                                    textColor: tdTheme.textColorSecondary,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: widget.availableFields.length,
                                itemBuilder: (ctx, index) {
                                  final field = widget.availableFields[index];
                                  final isSelected = selectedFieldIds.contains(field.id);
                                  return TDCheckbox(
                                    title: field.name,
                                    subTitle: '${field.chnname} (${field.type})',
                                    checked: isSelected,
                                    onCheckBoxChanged: (checked) {
                                      setState(() {
                                        if (checked) {
                                          selectedFieldIds.add(field.id);
                                        } else {
                                          selectedFieldIds.remove(field.id);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                    ),
                    SizedBox(height: formSpacing * 0.75),
                    TDInput(
                      controller: remarkController,
                      leftLabel: l10n.fieldRemark,
                      hintText: l10n.optionalDescription,
                      backgroundColor: Colors.transparent,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            leftBtn: TDDialogButtonOptions(
              title: dialogL10n.cancel,
              theme: TDButtonTheme.defaultTheme,
              type: TDButtonType.text,
              action: () => Navigator.pop(context),
            ),
            rightBtn: TDDialogButtonOptions(
              title: existingIndex == null ? l10n.add : l10n.save,
              theme: TDButtonTheme.primary,
              type: TDButtonType.fill,
              action: () {
                if (nameController.text.trim().isEmpty) {
                  TDToast.showText(dialogL10n.indexNameRequired, context: context);
                  return;
                }
                if (selectedFieldIds.isEmpty) {
                  TDToast.showText(dialogL10n.selectAtLeastOneField, context: context);
                  return;
                }

                final index = Index(
                  id: existingIndex?.id ?? '',
                  name: nameController.text.trim(),
                  fieldIds: selectedFieldIds.toList(),
                  type: selectedType,
                  remark: remarkController.text.trim().isNotEmpty
                      ? remarkController.text.trim()
                      : null,
                );

                if (existingIndex == null) {
                  widget.onAddIndex(index);
                } else {
                  widget.onUpdateIndex(existingIndex.id, index);
                }
                Navigator.pop(context);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeSelector({
    required BuildContext context,
    required IndexType selectedType,
    required Function(IndexType) onTypeChanged,
  }) {
    final tdTheme = TDTheme.of(context);
    final l10n = context.l10n;

    final options = IndexType.values
        .map((type) => TDDropdownOption(
              value: type.name,
              label: _getIndexTypeLabel(type, l10n),
              selected: type == selectedType,
            ))
        .toList();

    return TDSelectDropdown(
      selectedValue: selectedType.name,
      options: options,
      onChanged: (value) {
        final newType = IndexType.values.firstWhere(
          (t) => t.name == value,
          orElse: () => IndexType.normal,
        );
        onTypeChanged(newType);
      },
      triggerBuilder: (ctx, selectedLabel) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: tdTheme.bgColorSecondaryContainer,
          borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
          border: Border.all(color: tdTheme.componentBorderColor),
        ),
        child: Row(
          children: [
            Icon(TDIcons.setting, size: 20, color: tdTheme.textColorSecondary),
            const SizedBox(width: 12),
            TDText(
              l10n.indexType,
              font: tdTheme.fontBodyMedium,
              textColor: tdTheme.textColorSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(_getIndexTypeIcon(selectedType), size: 18, color: tdTheme.brandNormalColor),
                  const SizedBox(width: 8),
                  TDText(
                    selectedLabel,
                    font: tdTheme.fontBodyMedium,
                    textColor: tdTheme.textColorPrimary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(TDIcons.chevron_down, size: 18, color: tdTheme.textColorSecondary),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteIndex(Index index) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: l10n.deleteIndex,
        content: l10n.deleteConfirmMessage(index.name),
        leftBtn: TDDialogButtonOptions(
          title: l10n.cancel,
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          action: () => Navigator.pop(context),
        ),
        rightBtn: TDDialogButtonOptions(
          title: l10n.delete,
          theme: TDButtonTheme.danger,
          type: TDButtonType.fill,
          action: () {
            widget.onDeleteIndex(index.id);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}