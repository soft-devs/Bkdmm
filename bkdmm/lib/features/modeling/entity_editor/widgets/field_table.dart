import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../../shared/models/models.dart';

/// Field table widget using TDTable
///
/// Features:
/// - Columns: Primary Key, Field Name, Data Type, Chinese Name, Not Null, Auto Increment, Remark
/// - Inline editing with checkboxes and type selector
/// - Add/delete rows
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
  final Set<int> _selectedRows = {};

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
                disabled: _selectedRows.isEmpty,
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
    // Build columns for TDTable
    final columns = [
      TDTableCol(
        title: 'PK',
        colKey: 'pk',
        width: 60,
        align: TDTableColAlign.center,
        cellBuilder: (context, index) => _buildCheckboxCell(index, 'pk', tdTheme),
      ),
      TDTableCol(
        title: 'Field Name',
        colKey: 'name',
        width: 150,
        ellipsis: true,
        cellBuilder: (context, index) => _buildTextCell(index, 'name', tdTheme),
      ),
      TDTableCol(
        title: 'Data Type',
        colKey: 'type',
        width: 120,
        cellBuilder: (context, index) => _buildTypeCell(index, tdTheme),
      ),
      TDTableCol(
        title: 'Chinese Name',
        colKey: 'chnname',
        width: 120,
        ellipsis: true,
        cellBuilder: (context, index) => _buildTextCell(index, 'chnname', tdTheme),
      ),
      TDTableCol(
        title: 'Not Null',
        colKey: 'notNull',
        width: 80,
        align: TDTableColAlign.center,
        cellBuilder: (context, index) => _buildCheckboxCell(index, 'notNull', tdTheme),
      ),
      TDTableCol(
        title: 'Auto Inc',
        colKey: 'autoIncrement',
        width: 80,
        align: TDTableColAlign.center,
        cellBuilder: (context, index) => _buildCheckboxCell(index, 'autoIncrement', tdTheme),
      ),
      TDTableCol(
        title: 'Remark',
        colKey: 'remark',
        width: 150,
        ellipsis: true,
        cellBuilder: (context, index) => _buildTextCell(index, 'remark', tdTheme),
      ),
    ];

    // Build data for TDTable
    final data = widget.fields.map((field) => {
      'pk': field.pk,
      'name': field.name,
      'type': field.type,
      'chnname': field.chnname,
      'notNull': field.notNull,
      'autoIncrement': field.autoIncrement,
      'remark': field.remark ?? '',
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: tdTheme.bgColorContainer,
        border: Border.all(color: tdTheme.componentBorderColor),
        borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
      ),
      child: TDTable(
        columns: columns,
        data: data,
        bordered: true,
        stripe: true,
        rowHeight: 44,
        backgroundColor: tdTheme.bgColorContainer,
        onCellTap: (rowIndex, row, col) {
          // Toggle row selection
          setState(() {
            if (_selectedRows.contains(rowIndex)) {
              _selectedRows.remove(rowIndex);
            } else {
              _selectedRows.add(rowIndex);
            }
          });
        },
      ),
    );
  }

  Widget _buildCheckboxCell(int index, String property, TDThemeData tdTheme) {
    final field = widget.fields[index];
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
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TDCheckbox(
        title: '',
        checked: value,
        onCheckBoxChanged: (newValue) {
          _updateFieldProperty(field, property, newValue);
        },
      ),
    );
  }

  Widget _buildTextCell(int index, String property, TDThemeData tdTheme) {
    final field = widget.fields[index];
    String value = '';
    switch (property) {
      case 'name':
        value = field.name;
        break;
      case 'chnname':
        value = field.chnname;
        break;
      case 'remark':
        value = field.remark ?? '';
        break;
    }

    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TDText(
        value,
        font: tdTheme.fontBodySmall,
        textColor: _selectedRows.contains(index)
            ? tdTheme.brandNormalColor
            : tdTheme.textColorPrimary,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildTypeCell(int index, TDThemeData tdTheme) {
    final field = widget.fields[index];
    final currentType = field.type;

    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () => _showTypeSelector(index, currentType, tdTheme),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: tdTheme.bgColorSecondaryContainer,
            borderRadius: BorderRadius.circular(tdTheme.radiusSmall),
            border: Border.all(color: tdTheme.componentBorderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TDText(
                currentType,
                font: tdTheme.fontBodySmall,
                textColor: tdTheme.textColorPrimary,
              ),
              const SizedBox(width: 4),
              Icon(
                TDIcons.chevron_down,
                size: 14,
                color: tdTheme.textColorSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTypeSelector(int index, String currentType, TDThemeData tdTheme) {
    final field = widget.fields[index];

    // Use TDPicker for type selection
    TDPicker.show(
      context,
      title: 'Select Data Type',
      options: widget.dataTypes.map((dt) => dt.name).toList(),
      defaultValue: currentType,
    ).then((result) {
      if (result != null && result != currentType) {
        _updateFieldProperty(field, 'type', result);
      }
    });
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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => TDAlertDialog(
          title: 'Add Field',
          contentWidget: SizedBox(
            width: 500,
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
                  // Type selector using GestureDetector + TDPicker
                  _buildTypeSelectorFormField(
                    context: context,
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
            action: () => Navigator.pop(context),
          ),
          rightBtn: TDDialogButtonOptions(
            title: 'Add',
            theme: TDButtonTheme.primary,
            type: TDButtonType.fill,
            action: () {
              if (nameController.text.trim().isEmpty) {
                TDToast.showText('Field name is required', context: context);
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
              Navigator.pop(context);
            },
          ),
        ),
      ),
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
        TDPicker.show(
          context,
          title: 'Select Data Type',
          options: widget.dataTypes.map((dt) => '${dt.name} (${dt.chnname})').toList(),
          defaultValue: '${selectedType} (${widget.dataTypes.firstWhere((dt) => dt.name == selectedType, orElse: () => widget.dataTypes.first).chnname})',
        ).then((result) {
          if (result != null) {
            // Extract type name from "TypeName (ChineseName)" format
            final typeName = result.split(' ').first;
            onTypeChanged(typeName);
          }
        });
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
    if (_selectedRows.isEmpty) {
      TDToast.showText('No fields selected', context: context);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: 'Delete Fields',
        content: 'Are you sure you want to delete ${_selectedRows.length} field(s)?',
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
            for (final index in _selectedRows.toList()) {
              if (index < widget.fields.length) {
                widget.onDeleteField(widget.fields[index].id);
              }
            }
            setState(() {
              _selectedRows.clear();
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}