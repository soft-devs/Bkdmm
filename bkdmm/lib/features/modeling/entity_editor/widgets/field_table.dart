import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../../shared/models/models.dart';

/// Field table widget with custom table implementation
///
/// Features:
/// - Columns: Primary Key, Field Name, Data Type, Chinese Name, Not Null, Auto Increment, Remark
/// - Inline editing with checkboxes and type selector
/// - Add/delete rows
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
                'Fields (${widget.fields.length})',
                font: tdTheme.fontTitleSmall,
                fontWeight: FontWeight.w600,
              ),
              const Spacer(),
              // Add field button
              TDButton(
                text: 'Add Field',
                icon: TDIcons.add,
                theme: TDButtonTheme.primary,
                type: TDButtonType.fill,
                onTap: () => _showAddFieldDialog(),
              ),
              const SizedBox(width: 8),
              // Delete selected button
              TDButton(
                text: 'Delete',
                icon: TDIcons.delete,
                theme: TDButtonTheme.danger,
                type: TDButtonType.outline,
                disabled: _selectedFieldIds.isEmpty,
                onTap: _deleteSelectedFields,
              ),
            ],
          ),
        ),

        // Table content
        Expanded(
          child: widget.fields.isEmpty
              ? _buildEmptyState(tdTheme)
              : _buildTable(tdTheme),
        ),
      ],
    );
  }

  Widget _buildEmptyState(TDThemeData tdTheme) {
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
            'No fields defined',
            font: tdTheme.fontTitleMedium,
            textColor: tdTheme.textColorSecondary,
          ),
          const SizedBox(height: 8),
          TDText(
            'Click "Add Field" to create a new field',
            font: tdTheme.fontBodyMedium,
            textColor: tdTheme.textColorSecondary.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(TDThemeData tdTheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        // Column widths - adaptive
        final pkWidth = 48.0;
        final notNullWidth = 64.0;
        final autoIncWidth = 64.0;
        final fixedTotal = pkWidth + notNullWidth + autoIncWidth;

        final flexibleWidth = availableWidth - fixedTotal;
        final nameWidth = (flexibleWidth * 0.35).clamp(100.0, 300.0);
        final typeWidth = (flexibleWidth * 0.20).clamp(80.0, 150.0);
        final chnnameWidth = (flexibleWidth * 0.20).clamp(80.0, 150.0);
        final remarkWidth = (flexibleWidth * 0.25).clamp(80.0, 200.0);

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
                _buildHeaderRow(tdTheme, pkWidth, nameWidth, typeWidth, chnnameWidth, notNullWidth, autoIncWidth, remarkWidth),

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
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderRow(
    TDThemeData tdTheme,
    double pkWidth,
    double nameWidth,
    double typeWidth,
    double chnnameWidth,
    double notNullWidth,
    double autoIncWidth,
    double remarkWidth,
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
          _buildHeaderCell('PK', pkWidth, tdTheme, centered: true),
          _buildHeaderCell('Field Name', nameWidth, tdTheme),
          _buildHeaderCell('Data Type', typeWidth, tdTheme),
          _buildHeaderCell('Chinese Name', chnnameWidth, tdTheme),
          _buildHeaderCell('Not Null', notNullWidth, tdTheme, centered: true),
          _buildHeaderCell('Auto Inc', autoIncWidth, tdTheme, centered: true),
          _buildHeaderCell('Remark', remarkWidth, tdTheme),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, double width, TDThemeData tdTheme, {bool centered = false}) {
    return Container(
      width: width,
      height: 44,
      alignment: centered ? Alignment.center : Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: centered ? 4 : 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: tdTheme.componentBorderColor.withValues(alpha: 0.3))),
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
            // Field name
            _buildTextCell(field.name, nameWidth, tdTheme, isSelected),
            // Data type
            _buildTypeCell(field, typeWidth, tdTheme, isSelected),
            // Chinese name
            _buildTextCell(field.chnname, chnnameWidth, tdTheme, isSelected),
            // Not Null checkbox
            _buildCheckboxCell(field, 'notNull', notNullWidth, tdTheme, isSelected),
            // Auto Increment checkbox
            _buildCheckboxCell(field, 'autoIncrement', autoIncWidth, tdTheme, isSelected),
            // Remark
            _buildTextCell(field.remark ?? '', remarkWidth, tdTheme, isSelected),
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

  void _showTypeSelector(Field field, TDThemeData tdTheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => TDMultiPicker(
        title: 'Select Data Type',
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
    final nameController = TextEditingController();
    final chnnameController = TextEditingController();
    final remarkController = TextEditingController();
    String selectedType = widget.dataTypes.isNotEmpty ? widget.dataTypes.first.name : 'String';
    bool isPk = false;
    bool isNotNull = false;
    bool isAutoIncrement = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Responsive dialog width calculation
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        const minWidth = 650.0;
        const maxWidth = 845.0; // 1.3x the base minimum width
        final dialogWidth = (screenWidth * 0.85).clamp(minWidth, maxWidth);

        return StatefulBuilder(
          builder: (context, setState) => TDAlertDialog(
            title: 'Add Field',
            contentWidget: SizedBox(
              width: dialogWidth,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TDInput(
                      controller: nameController,
                      leftLabel: 'Field Name *',
                      hintText: 'e.g., user_id',
                      leftIcon: const Icon(TDIcons.code),
                      backgroundColor: Colors.transparent,
                    ),
                    const SizedBox(height: 16),
                    _buildTypeSelectorFormField(
                      context: dialogContext,
                      selectedType: selectedType,
                      onTypeChanged: (type) => setState(() => selectedType = type),
                    ),
                    const SizedBox(height: 16),
                    TDInput(
                      controller: chnnameController,
                      leftLabel: 'Chinese Name',
                      hintText: 'e.g., 用户ID',
                      leftIcon: const Icon(TDIcons.translate),
                      backgroundColor: Colors.transparent,
                    ),
                    const SizedBox(height: 16),
                    TDCheckbox(
                      title: 'Primary Key',
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
                      title: 'Not Null',
                      checked: isNotNull,
                      enable: !isPk,
                      onCheckBoxChanged: isPk ? null : (checked) {
                        setState(() => isNotNull = checked);
                      },
                    ),
                    const SizedBox(height: 8),
                    TDCheckbox(
                      title: 'Auto Increment',
                      checked: isAutoIncrement,
                      onCheckBoxChanged: (checked) {
                        setState(() => isAutoIncrement = checked);
                      },
                    ),
                    const SizedBox(height: 16),
                    TDInput(
                      controller: remarkController,
                      leftLabel: 'Remark',
                      hintText: 'Field description',
                      backgroundColor: Colors.transparent,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            leftBtn: TDDialogButtonOptions(
              title: 'Cancel',
              theme: TDButtonTheme.defaultTheme,
              type: TDButtonType.text,
              action: () => Navigator.pop(dialogContext),
            ),
            rightBtn: TDDialogButtonOptions(
              title: 'Add',
              theme: TDButtonTheme.primary,
              type: TDButtonType.fill,
              action: () {
                if (nameController.text.trim().isEmpty) {
                  TDToast.showText('Field name is required', context: dialogContext);
                  return;
                }
                widget.onAddField(Field(
                  id: '',
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
                ));
                Navigator.pop(dialogContext);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeSelectorFormField({
    required BuildContext context,
    required String selectedType,
    required Function(String) onTypeChanged,
  }) {
    final tdTheme = TDTheme.of(context);

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) => TDMultiPicker(
            title: 'Select Data Type',
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
              'Data Type',
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

  void _deleteSelectedFields() {
    if (_selectedFieldIds.isEmpty) {
      TDToast.showText('No fields selected', context: context);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: 'Delete Fields',
        content: 'Are you sure you want to delete ${_selectedFieldIds.length} field(s)?',
        leftBtn: TDDialogButtonOptions(
          title: 'Cancel',
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          action: () => Navigator.pop(context),
        ),
        rightBtn: TDDialogButtonOptions(
          title: 'Delete',
          theme: TDButtonTheme.danger,
          type: TDButtonType.fill,
          action: () {
            for (final fieldId in _selectedFieldIds.toList()) {
              widget.onDeleteField(fieldId);
            }
            setState(() {
              _selectedFieldIds.clear();
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}