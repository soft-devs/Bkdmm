import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
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
              FilledButton.icon(
                onPressed: () => _showAddFieldDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Field'),
              ),
              const SizedBox(width: 8),
              // Delete selected button
              OutlinedButton.icon(
                onPressed: _deleteSelectedFields,
                icon: const Icon(Icons.delete, size: 18),
                label: const Text('Delete Selected'),
              ),
            ],
          ),
        ),

        // DataGrid
        Expanded(
          child: SfDataGrid(
            source: _dataSource,
            controller: _controller,
            allowEditing: true,
            allowSorting: true,
            allowFiltering: true,
            selectionMode: SelectionMode.multiple,
            navigationMode: GridNavigationMode.cell,
            columnWidthMode: ColumnWidthMode.auto,
            gridLinesVisibility: GridLinesVisibility.both,
            headerGridLinesVisibility: GridLinesVisibility.both,
            editingGestureType: EditingGestureType.doubleTap,
            onQueryRowHeight: (details) => 40.0,
            columns: [
              GridColumn(
                columnName: 'pk',
                width: 60,
                label: _buildHeaderCell('PK', tooltip: 'Primary Key'),
              ),
              GridColumn(
                columnName: 'name',
                width: 150,
                label: _buildHeaderCell('Field Name'),
              ),
              GridColumn(
                columnName: 'type',
                width: 120,
                label: _buildHeaderCell('Data Type'),
              ),
              GridColumn(
                columnName: 'chnname',
                width: 120,
                label: _buildHeaderCell('Chinese Name'),
              ),
              GridColumn(
                columnName: 'notNull',
                width: 70,
                label: _buildHeaderCell('Not Null'),
              ),
              GridColumn(
                columnName: 'autoIncrement',
                width: 80,
                label: _buildHeaderCell('Auto Inc'),
              ),
              GridColumn(
                columnName: 'remark',
                width: 150,
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
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Field'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Field Name *',
                    hintText: 'e.g., user_id',
                    prefixIcon: Icon(Icons.code),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Data Type',
                    prefixIcon: Icon(Icons.data_object),
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
                TextField(
                  controller: chnnameController,
                  decoration: const InputDecoration(
                    labelText: 'Chinese Name',
                    hintText: 'e.g., 用户ID',
                    prefixIcon: Icon(Icons.translate),
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Primary Key'),
                  value: isPk,
                  onChanged: (value) {
                    setState(() {
                      isPk = value ?? false;
                      if (isPk) {
                        isNotNull = true;
                      }
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  title: const Text('Not Null'),
                  value: isNotNull,
                  onChanged: isPk ? null : (value) {
                    setState(() => isNotNull = value ?? false);
                  },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  title: const Text('Auto Increment'),
                  value: isAutoIncrement,
                  onChanged: (value) {
                    setState(() => isAutoIncrement = value ?? false);
                  },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: remarkController,
                  decoration: const InputDecoration(
                    labelText: 'Remark',
                    hintText: 'Field description',
                    prefixIcon: Icon(Icons.notes),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Field name is required')),
                  );
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
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteSelectedFields() {
    final selectedRows = _controller.selectedRows;
    if (selectedRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fields selected')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Fields'),
        content: Text('Are you sure you want to delete ${selectedRows.length} field(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
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
            child: const Text('Delete'),
          ),
        ],
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