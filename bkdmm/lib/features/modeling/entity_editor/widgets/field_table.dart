import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../../core/i18n/i18n.dart';
import '../../../../shared/models/models.dart';

/// Field table widget with custom table implementation
///
/// Features:
/// - Columns: Primary Key, Field Name, Data Type, Chinese Name, Not Null, Auto Increment, Remark, Actions
/// - Inline editing with checkboxes and type selector
/// - Add/edit/delete rows
/// - Row selection with highlight
class FieldTable extends StatefulWidget {
  final List<Field> fields;
  final List<DataType> dataTypes;
  final Function(Field) onAddField;
  final Function(String, Field) onUpdateField;
  final Function(String) onDeleteField;
  final Function(int, int) onReorderFields;

  const FieldTable({
    super.key,
    required this.fields,
    required this.dataTypes,
    required this.onAddField,
    required this.onUpdateField,
    required this.onDeleteField,
    required this.onReorderFields,
  });

  @override
  State<FieldTable> createState() => _FieldTableState();
}

class _FieldTableState extends State<FieldTable> {
  final Set<String> _selectedFieldIds = {};

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
                '${l10n.fields} (${widget.fields.length})',
                font: tdTheme.fontTitleSmall,
                fontWeight: FontWeight.w600,
              ),
              const Spacer(),
              // Add field button
              TDButton(
                text: l10n.addField,
                icon: TDIcons.add,
                theme: TDButtonTheme.primary,
                type: TDButtonType.fill,
                onTap: () => _showAddFieldDialog(),
              ),
            ],
          ),
        ),

        // Table content
        Expanded(
          child: widget.fields.isEmpty
              ? _buildEmptyState(tdTheme, l10n)
              : _buildTable(tdTheme, l10n),
        ),
      ],
    );
  }

  Widget _buildEmptyState(TDThemeData tdTheme, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            TDIcons.view_list,
            size: 48,
            color: tdTheme.textColorSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          TDText(
            l10n.noFieldsDefined,
            font: tdTheme.fontTitleMedium,
            textColor: tdTheme.textColorSecondary,
          ),
          const SizedBox(height: 8),
          TDText(
            l10n.noFieldsDefinedHint,
            font: tdTheme.fontBodyMedium,
            textColor: tdTheme.textColorSecondary.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(TDThemeData tdTheme, AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        // Column widths - fixed columns
        const double pkWidth = 48.0;
        const double notNullWidth = 64.0;
        const double autoIncWidth = 72.0;
        const double actionsWidth = 56.0; // Reduced to fit edit + delete icons
        const double fixedTotal = pkWidth + notNullWidth + autoIncWidth + actionsWidth;

        // Flexible columns - calculate remaining width and distribute
        final remainingWidth = availableWidth - fixedTotal;

        // Ensure minimum widths are respected, then distribute proportionally
        const double minNameWidth = 100.0;
        const double minTypeWidth = 80.0;
        const double minChnnameWidth = 80.0;
        const double minRemarkWidth = 60.0;
        const double totalMinFlexible = minNameWidth + minTypeWidth + minChnnameWidth + minRemarkWidth;

        // If remaining space is too small, use minimum widths
        if (remainingWidth < totalMinFlexible) {
          // Fall back to minimum widths - table will scroll horizontally
          final nameWidth = minNameWidth;
          final typeWidth = minTypeWidth;
          final chnnameWidth = minChnnameWidth;
          final remarkWidth = minRemarkWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: fixedTotal + totalMinFlexible,
              child: _buildTableContent(
                tdTheme,
                l10n,
                pkWidth, nameWidth, typeWidth, chnnameWidth,
                notNullWidth, autoIncWidth, remarkWidth, actionsWidth,
              ),
            ),
          );
        }

        // Distribute remaining width proportionally
        final nameWidth = (remainingWidth * 0.40).clamp(minNameWidth, remainingWidth - minTypeWidth - minChnnameWidth - minRemarkWidth);
        final typeWidth = (remainingWidth * 0.20).clamp(minTypeWidth, remainingWidth - nameWidth - minChnnameWidth - minRemarkWidth);
        final chnnameWidth = (remainingWidth * 0.20).clamp(minChnnameWidth, remainingWidth - nameWidth - typeWidth - minRemarkWidth);
        final remarkWidth = remainingWidth - nameWidth - typeWidth - chnnameWidth;

        return _buildTableContent(
          tdTheme,
          l10n,
          pkWidth, nameWidth, typeWidth, chnnameWidth,
          notNullWidth, autoIncWidth, remarkWidth, actionsWidth,
        );
      },
    );
  }

  Widget _buildTableContent(
    TDThemeData tdTheme,
    AppLocalizations l10n,
    double pkWidth,
    double nameWidth,
    double typeWidth,
    double chnnameWidth,
    double notNullWidth,
    double autoIncWidth,
    double remarkWidth,
    double actionsWidth,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: tdTheme.bgColorContainer,
        border: Border.all(color: tdTheme.componentBorderColor),
        borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
        child: Column(
          children: [
            // Header row
            _buildHeaderRow(tdTheme, l10n, pkWidth, nameWidth, typeWidth, chnnameWidth, notNullWidth, autoIncWidth, remarkWidth, actionsWidth),

            // Data rows
            Expanded(
              child: ListView.builder(
                itemCount: widget.fields.length,
                itemBuilder: (context, index) {
                  final field = widget.fields[index];
                  final isSelected = _selectedFieldIds.contains(field.id);
                  return _buildDataRow(
                    field,
                    index,
                    isSelected,
                    tdTheme,
                    pkWidth,
                    nameWidth,
                    typeWidth,
                    chnnameWidth,
                    notNullWidth,
                    autoIncWidth,
                    remarkWidth,
                    actionsWidth,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(
    TDThemeData tdTheme,
    AppLocalizations l10n,
    double pkWidth,
    double nameWidth,
    double typeWidth,
    double chnnameWidth,
    double notNullWidth,
    double autoIncWidth,
    double remarkWidth,
    double actionsWidth,
  ) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: tdTheme.bgColorSecondaryContainer,
        border: Border(
          bottom: BorderSide(color: tdTheme.componentBorderColor),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell(l10n.pk, pkWidth, tdTheme, centered: true),
          _buildHeaderCell(l10n.fieldName, nameWidth, tdTheme),
          _buildHeaderCell(l10n.dataType, typeWidth, tdTheme),
          _buildHeaderCell(l10n.chineseName, chnnameWidth, tdTheme),
          _buildHeaderCell(l10n.notNull, notNullWidth, tdTheme, centered: true),
          _buildHeaderCell(l10n.autoIncrement, autoIncWidth, tdTheme, centered: true),
          _buildHeaderCell(l10n.fieldRemark, remarkWidth, tdTheme),
          _buildHeaderCell(l10n.actions, actionsWidth, tdTheme, centered: true, isLast: true),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, double width, TDThemeData tdTheme, {bool centered = false, bool isLast = false}) {
    return Container(
      width: width,
      height: 44,
      alignment: centered ? Alignment.center : Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: centered ? 4 : 12, vertical: 8),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(right: BorderSide(color: tdTheme.componentBorderColor.withValues(alpha: 0.3))),
      ),
      child: TDText(
        title,
        font: tdTheme.fontBodySmall,
        fontWeight: FontWeight.w600,
        textColor: tdTheme.textColorSecondary,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDataRow(
    Field field,
    int index,
    bool isSelected,
    TDThemeData tdTheme,
    double pkWidth,
    double nameWidth,
    double typeWidth,
    double chnnameWidth,
    double notNullWidth,
    double autoIncWidth,
    double remarkWidth,
    double actionsWidth,
  ) {
    final rowColor = isSelected
        ? tdTheme.brandNormalColor.withValues(alpha: 0.08)
        : (index % 2 == 1 ? tdTheme.bgColorSecondaryContainer.withValues(alpha: 0.3) : tdTheme.bgColorContainer);

    return InkWell(
      onTap: () {
        setState(() {
          if (_selectedFieldIds.contains(field.id)) {
            _selectedFieldIds.remove(field.id);
          } else {
            _selectedFieldIds.add(field.id);
          }
        });
      },
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: rowColor,
          border: Border(
            bottom: BorderSide(color: tdTheme.componentBorderColor.withValues(alpha: 0.2)),
          ),
        ),
        child: Row(
          children: [
            // PK checkbox
            _buildCheckboxCell(field, 'pk', pkWidth, tdTheme, isSelected),
            // Field name - clickable for edit
            _buildEditableTextCell(field.name, nameWidth, tdTheme, isSelected, () => _showEditFieldDialog(field)),
            // Data type
            _buildTypeCell(field, typeWidth, tdTheme, isSelected),
            // Chinese name - clickable for edit
            _buildEditableTextCell(field.chnname, chnnameWidth, tdTheme, isSelected, () => _showEditFieldDialog(field)),
            // Not Null checkbox
            _buildCheckboxCell(field, 'notNull', notNullWidth, tdTheme, isSelected),
            // Auto Increment checkbox
            _buildCheckboxCell(field, 'autoIncrement', autoIncWidth, tdTheme, isSelected),
            // Remark
            _buildTextCell(field.remark ?? '', remarkWidth, tdTheme, isSelected),
            // Actions
            _buildActionsCell(field, actionsWidth, tdTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxCell(Field field, String property, double width, TDThemeData tdTheme, bool isRowSelected) {
    bool value = false;
    switch (property) {
      case 'pk':
        value = field.pk;
        break;
      case 'notNull':
        value = field.notNull;
        break;
      case 'autoIncrement':
        value = field.autoIncrement;
        break;
    }

    return Container(
      width: width,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: tdTheme.componentBorderColor.withValues(alpha: 0.3))),
      ),
      child: GestureDetector(
        onTap: () {
          _updateFieldProperty(field, property, !value);
        },
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: value
                ? tdTheme.brandNormalColor
                : tdTheme.bgColorContainer,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: value
                  ? tdTheme.brandNormalColor
                  : tdTheme.componentBorderColor,
              width: 1.5,
            ),
          ),
          child: value
              ? Icon(TDIcons.check, size: 14, color: Colors.white)
              : null,
        ),
      ),
    );
  }

  Widget _buildTextCell(String value, double width, TDThemeData tdTheme, bool isRowSelected) {
    return Container(
      width: width,
      height: 44,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: tdTheme.componentBorderColor.withValues(alpha: 0.3))),
      ),
      child: TDText(
        value,
        font: tdTheme.fontBodySmall,
        textColor: isRowSelected
            ? tdTheme.brandNormalColor
            : tdTheme.textColorPrimary,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildEditableTextCell(String value, double width, TDThemeData tdTheme, bool isRowSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: width,
        height: 44,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: tdTheme.componentBorderColor.withValues(alpha: 0.3))),
        ),
        child: Row(
          children: [
            Expanded(
              child: TDText(
                value,
                font: tdTheme.fontBodySmall,
                textColor: isRowSelected
                    ? tdTheme.brandNormalColor
                    : tdTheme.textColorPrimary,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Icon(
              TDIcons.edit,
              size: 14,
              color: tdTheme.textColorSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCell(Field field, double width, TDThemeData tdTheme, bool isRowSelected) {
    return Container(
      width: width,
      height: 44,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: tdTheme.componentBorderColor.withValues(alpha: 0.3))),
      ),
      child: InkWell(
        onTap: () => _showTypeSelector(field, tdTheme),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: TDText(
                field.type,
                font: tdTheme.fontBodySmall,
                textColor: isRowSelected
                    ? tdTheme.brandNormalColor
                    : tdTheme.textColorPrimary,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              TDIcons.chevron_down,
              size: 12,
              color: tdTheme.textColorSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCell(Field field, double width, TDThemeData tdTheme) {
    // Responsive layout: adjust icon sizes based on available width
    final iconSize = width < 48 ? 12.0 : (width < 56 ? 13.0 : 14.0);
    final padding = width < 48 ? 2.0 : (width < 56 ? 3.0 : 4.0);

    return Container(
      width: width,
      height: 44,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Edit button - flexible
          Flexible(
            child: InkWell(
              onTap: () => _showEditFieldDialog(field),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Icon(
                  TDIcons.edit,
                  size: iconSize,
                  color: tdTheme.textColorSecondary,
                ),
              ),
            ),
          ),
          // Delete button - flexible
          Flexible(
            child: InkWell(
              onTap: () => _confirmDeleteField(field),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Icon(
                  TDIcons.delete,
                  size: iconSize,
                  color: tdTheme.errorNormalColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTypeSelector(Field field, TDThemeData tdTheme) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => TDMultiPicker(
        title: l10n.selectDataType,
        data: [widget.dataTypes.map((dt) => dt.name).toList()],
        initialIndexes: [
          widget.dataTypes.indexWhere((dt) => dt.name == field.type).clamp(0, widget.dataTypes.length - 1),
        ],
        onConfirm: (selected) {
          if (selected.isNotEmpty && selected[0] < widget.dataTypes.length) {
            final newType = widget.dataTypes[selected[0]].name;
            if (newType != field.type) {
              _updateFieldProperty(field, 'type', newType);
            }
          }
          Navigator.pop(context);
        },
        onCancel: (_) => Navigator.pop(context),
      ),
    );
  }

  void _updateFieldProperty(Field field, String property, dynamic value) {
    Field updatedField;
    switch (property) {
      case 'pk':
        updatedField = field.copyWith(pk: value as bool);
        break;
      case 'notNull':
        updatedField = field.copyWith(notNull: value as bool);
        break;
      case 'autoIncrement':
        updatedField = field.copyWith(autoIncrement: value as bool);
        break;
      case 'type':
        updatedField = field.copyWith(type: value as String);
        break;
      default:
        return;
    }
    widget.onUpdateField(field.id, updatedField);
  }

  void _showAddFieldDialog() {
    _showFieldDialog(null);
  }

  void _showEditFieldDialog(Field field) {
    _showFieldDialog(field);
  }

  void _showFieldDialog(Field? existingField) {
    final l10n = context.l10n;
    final nameController = TextEditingController(text: existingField?.name ?? '');
    final chnnameController = TextEditingController(text: existingField?.chnname ?? '');
    final remarkController = TextEditingController(text: existingField?.remark ?? '');
    String selectedType = existingField?.type ?? (widget.dataTypes.isNotEmpty ? widget.dataTypes.first.name : 'String');
    bool isPk = existingField?.pk ?? false;
    bool isNotNull = existingField?.notNull ?? false;
    bool isAutoIncrement = existingField?.autoIncrement ?? false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final tdTheme = TDTheme.of(context);
          final dialogL10n = context.l10n;
          // Responsive dialog width
          final screenWidth = MediaQuery.of(context).size.width;
          const baseMinWidth = 400.0;
          final maxWidth = baseMinWidth * 1.4; // 560
          final dialogWidth = (screenWidth * 0.85).clamp(baseMinWidth, maxWidth);

          return TDAlertDialog(
            title: existingField == null ? l10n.addField : l10n.editField,
            content: '',
            contentWidget: SizedBox(
              width: dialogWidth,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TDInput(
                      controller: nameController,
                      leftLabel: l10n.fieldNameStar,
                      hintText: 'e.g., user_id',
                      leftIcon: const Icon(TDIcons.code),
                      backgroundColor: Colors.transparent,
                    ),
                    const SizedBox(height: 12),
                    _buildTypeSelectorFormField(
                      context: context,
                      selectedType: selectedType,
                      onTypeChanged: (type) => setState(() => selectedType = type),
                    ),
                    const SizedBox(height: 12),
                    TDInput(
                      controller: chnnameController,
                      leftLabel: l10n.chineseName,
                      hintText: 'e.g., 用户ID',
                      leftIcon: const Icon(TDIcons.translate),
                      backgroundColor: Colors.transparent,
                    ),
                    const SizedBox(height: 12),
                    // Checkbox section in a container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: tdTheme.bgColorSecondaryContainer,
                        borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
                      ),
                      child: Column(
                        children: [
                          TDCheckbox(
                            title: l10n.primaryKey,
                            checked: isPk,
                            onCheckBoxChanged: (checked) {
                              setState(() {
                                isPk = checked;
                                if (isPk) {
                                  isNotNull = true;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          TDCheckbox(
                            title: l10n.notNull,
                            checked: isNotNull,
                            enable: !isPk,
                            onCheckBoxChanged: isPk ? null : (checked) {
                              setState(() => isNotNull = checked);
                            },
                          ),
                          const SizedBox(height: 8),
                          TDCheckbox(
                            title: l10n.autoIncrement,
                            checked: isAutoIncrement,
                            onCheckBoxChanged: (checked) {
                              setState(() => isAutoIncrement = checked);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TDInput(
                      controller: remarkController,
                      leftLabel: l10n.fieldRemark,
                      hintText: l10n.fieldDescription,
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
              title: existingField == null ? l10n.add : l10n.save,
              theme: TDButtonTheme.primary,
              type: TDButtonType.fill,
              action: () {
                if (nameController.text.trim().isEmpty) {
                  TDToast.showText(dialogL10n.fieldNameRequired, context: context);
                  return;
                }

                final updatedField = Field(
                  id: existingField?.id ?? '',
                  name: nameController.text.trim(),
                  type: selectedType,
                  chnname: chnnameController.text.trim().isNotEmpty
                      ? chnnameController.text.trim()
                      : nameController.text.trim(),
                  pk: isPk,
                  notNull: isNotNull,
                  autoIncrement: isAutoIncrement,
                  remark: remarkController.text.trim().isNotEmpty
                      ? remarkController.text.trim()
                      : null,
                );

                if (existingField == null) {
                  widget.onAddField(updatedField);
                } else {
                  widget.onUpdateField(existingField.id, updatedField);
                }
                Navigator.pop(context);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeSelectorFormField({
    required BuildContext context,
    required String selectedType,
    required Function(String) onTypeChanged,
  }) {
    final tdTheme = TDTheme.of(context);
    final l10n = context.l10n;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) => TDMultiPicker(
            title: l10n.selectDataType,
            data: [widget.dataTypes.map((dt) => '${dt.name} (${dt.chnname})').toList()],
            initialIndexes: [
              widget.dataTypes.indexWhere((dt) => dt.name == selectedType).clamp(0, widget.dataTypes.length - 1),
            ],
            onConfirm: (selected) {
              if (selected.isNotEmpty && selected[0] < widget.dataTypes.length) {
                final newType = widget.dataTypes[selected[0]].name;
                onTypeChanged(newType);
              }
              Navigator.pop(ctx);
            },
            onCancel: (_) => Navigator.pop(ctx),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: tdTheme.bgColorSecondaryContainer,
          borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
          border: Border.all(color: tdTheme.componentBorderColor),
        ),
        child: Row(
          children: [
            Icon(TDIcons.data, size: 20, color: tdTheme.textColorSecondary),
            const SizedBox(width: 12),
            TDText(
              l10n.dataTypeLabel,
              font: tdTheme.fontBodyMedium,
              textColor: tdTheme.textColorSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TDText(
                '$selectedType (${widget.dataTypes.firstWhere((dt) => dt.name == selectedType, orElse: () => widget.dataTypes.first).chnname})',
                font: tdTheme.fontBodyMedium,
                textColor: tdTheme.textColorPrimary,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: 8),
            Icon(TDIcons.chevron_down, size: 18, color: tdTheme.textColorSecondary),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteField(Field field) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: l10n.deleteField,
        content: l10n.deleteFieldConfirm(field.name),
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
            widget.onDeleteField(field.id);
            setState(() {
              _selectedFieldIds.remove(field.id);
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
