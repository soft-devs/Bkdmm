import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../../shared/models/models.dart';

/// Field table widget using Syncfusion DataGrid
///
/// Features:
/// - Columns: Primary Key, Field Name, Data Type, Chinese Name, Not Null, Auto Increment, Remark
/// - Inline editing
/// - Add/delete rows
/// - Drag to reorder
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
  late FieldDataSource _dataSource;
  final DataGridController _controller = DataGridController();

  @override
  void initState() {
    super.initState();
    _dataSource = FieldDataSource(
      fields: widget.fields,
      dataTypes: widget.dataTypes,
      onUpdateField: widget.onUpdateField,
    );
  }

  @override
  void didUpdateWidget(FieldTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fields != widget.fields) {
      _dataSource.updateFields(widget.fields);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              Text(
                'Fields (${widget.fields.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
                theme: TDButtonTheme.defaultTheme,
                type: TDButtonType.outline,
                onTap: _deleteSelectedFields,
              ),
            ],
          ),
        ),

        // DataGrid - use Expanded to fill available space
        Expanded(
          child: SfDataGrid(
            source: _dataSource,
            controller: _controller,
            allowEditing: true,
            allowSorting: true,
            selectionMode: SelectionMode.multiple,
            navigationMode: GridNavigationMode.cell,
            columnWidthMode: ColumnWidthMode.lastColumnFill,
            gridLinesVisibility: GridLinesVisibility.horizontal,
            headerGridLinesVisibility: GridLinesVisibility.both,
            editingGestureType: EditingGestureType.doubleTap,
            rowHeight: 44,
            headerRowHeight: 48,
            columns: [
              GridColumn(
                columnName: 'pk',
                autoFitPadding: const EdgeInsets.symmetric(horizontal: 8),
                columnWidthMode: ColumnWidthMode.fitByCellValue,
                label: _buildHeaderCell('PK', tooltip: 'Primary Key'),
              ),
              GridColumn(
                columnName: 'name',
                minimumWidth: 100,
                maximumWidth: 200,
                columnWidthMode: ColumnWidthMode.fitByColumnName,
                label: _buildHeaderCell('Field Name'),
              ),
              GridColumn(
                columnName: 'type',
                minimumWidth: 80,
                maximumWidth: 150,
                columnWidthMode: ColumnWidthMode.fitByColumnName,
                label: _buildHeaderCell('Data Type'),
              ),
              GridColumn(
                columnName: 'chnname',
                minimumWidth: 80,
                maximumWidth: 150,
                columnWidthMode: ColumnWidthMode.fitByColumnName,
                label: _buildHeaderCell('Chinese Name'),
              ),
              GridColumn(
                columnName: 'notNull',
                autoFitPadding: const EdgeInsets.symmetric(horizontal: 8),
                columnWidthMode: ColumnWidthMode.fitByCellValue,
                label: _buildHeaderCell('Not Null'),
              ),
              GridColumn(
                columnName: 'autoIncrement',
                autoFitPadding: const EdgeInsets.symmetric(horizontal: 8),
                columnWidthMode: ColumnWidthMode.fitByCellValue,
                label: _buildHeaderCell('Auto Inc'),
              ),
              GridColumn(
                columnName: 'remark',
                minimumWidth: 100,
                label: _buildHeaderCell('Remark'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text, {String? tooltip}) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: tooltip != null
          ? Tooltip(
              message: tooltip,
              child: Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            )
          : Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
    );
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
          contentWidget: SingleChildScrollView(
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
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Data Type',
                    prefixIcon: Icon(TDIcons.data),
                  ),
                  items: widget.dataTypes.map((dt) {
                    return DropdownMenuItem(
                      value: dt.name,
                      child: Text('${dt.name} (${dt.chnname})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedType = value);
                    }
                  },
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

  void _deleteSelectedFields() {
    final selectedRows = _controller.selectedRows;
    if (selectedRows.isEmpty) {
      TDToast.showText('No fields selected', context: context);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: 'Delete Fields',
        content: 'Are you sure you want to delete ${selectedRows.length} field(s)?',
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
            for (final row in selectedRows) {
              // Get the field name from the row's cells
              final cells = row.getCells();
              String? fieldName;
              for (final cell in cells) {
                if (cell.columnName == 'name') {
                  fieldName = cell.value as String;
                  break;
                }
              }
              if (fieldName == null) continue;
              final fieldObj = widget.fields.firstWhere(
                (f) => f.name == fieldName,
                orElse: () => widget.fields.first,
              );
              widget.onDeleteField(fieldObj.id);
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

/// Data source for the field grid
class FieldDataSource extends DataGridSource {
  List<Field> _fields;
  final List<DataType> dataTypes;
  final Function(String, Field) onUpdateField;

  List<DataGridRow> _rows = [];

  FieldDataSource({
    required List<Field> fields,
    required this.dataTypes,
    required this.onUpdateField,
  }) : _fields = fields {
    _buildRows();
  }

  void updateFields(List<Field> fields) {
    _fields = fields;
    _buildRows();
    notifyDataSourceListeners();
  }

  void _buildRows() {
    _rows = _fields.map((field) => DataGridRow(
      cells: [
        DataGridCell<bool>(columnName: 'pk', value: field.pk),
        DataGridCell<String>(columnName: 'name', value: field.name),
        DataGridCell<String>(columnName: 'type', value: field.type),
        DataGridCell<String>(columnName: 'chnname', value: field.chnname),
        DataGridCell<bool>(columnName: 'notNull', value: field.notNull),
        DataGridCell<bool>(columnName: 'autoIncrement', value: field.autoIncrement),
        DataGridCell<String>(columnName: 'remark', value: field.remark ?? ''),
      ],
    )).toList();
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map((cell) {
        return _buildCell(cell, row);
      }).toList(),
    );
  }

  Widget _buildCell(DataGridCell cell, DataGridRow row) {
    // Get the field name from the row's cells
    final cells = row.getCells();
    String fieldName = '';
    for (final c in cells) {
      if (c.columnName == 'name') {
        fieldName = c.value as String;
        break;
      }
    }
    final field = _fields.firstWhere(
      (f) => f.name == fieldName,
      orElse: () => _fields.isNotEmpty ? _fields.first : Field(
        id: '',
        name: '',
        type: 'String',
        chnname: '',
      ),
    );

    switch (cell.columnName) {
      case 'pk':
      case 'notNull':
      case 'autoIncrement':
        final value = cell.value as bool;
        return Container(
          alignment: Alignment.center,
          child: Checkbox(
            value: value,
            onChanged: (newValue) {
              _updateFieldProperty(field, cell.columnName, newValue ?? false);
            },
          ),
        );
      case 'type':
        return Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: DropdownButton<String>(
            value: cell.value as String,
            isDense: true,
            underline: const SizedBox(),
            items: dataTypes.map((dt) {
              return DropdownMenuItem(
                value: dt.name,
                child: Text(dt.name),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                _updateFieldProperty(field, 'type', newValue);
              }
            },
          ),
        );
      default:
        return Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            cell.value?.toString() ?? '',
            overflow: TextOverflow.ellipsis,
          ),
        );
    }
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
      case 'name':
        updatedField = field.copyWith(name: value as String);
        break;
      case 'chnname':
        updatedField = field.copyWith(chnname: value as String);
        break;
      case 'remark':
        updatedField = field.copyWith(remark: value as String);
        break;
      default:
        return;
    }
    onUpdateField(field.id, updatedField);
  }

  // Note: onCellBeginEdit and onCellSubmitEdit may not be needed
  // since we're using direct cell widget interaction (checkboxes/dropdowns)
  // The editing happens directly in the buildRow method
}
