import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../shared/models/data_type.dart';
import '../../../shared/constants/default_data_types.dart';
import '../providers/datatype_provider.dart';

/// Dialog for editing a data type
class DataTypeEditDialog extends ConsumerStatefulWidget {
  /// Existing data type to edit (null for new)
  final DataType? existingType;

  /// Callback when save is pressed
  final void Function(DataType) onSave;

  const DataTypeEditDialog({
    super.key,
    this.existingType,
    required this.onSave,
  });

  @override
  ConsumerState<DataTypeEditDialog> createState() => _DataTypeEditDialogState();
}

class _DataTypeEditDialogState extends ConsumerState<DataTypeEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _chnnameController;
  late TextEditingController _remarkController;
  late TextEditingController _javaController;

  late Map<String, TextEditingController> _dbTypeControllers;

  bool _isDefaultType = false;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();

    final existing = widget.existingType;
    _isDefaultType = existing != null && DefaultDataTypes.isDefaultType(existing.id);

    _nameController = TextEditingController(text: existing?.name ?? '');
    _chnnameController = TextEditingController(text: existing?.chnname ?? '');
    _remarkController = TextEditingController(text: existing?.remark ?? '');
    _javaController = TextEditingController(text: existing?.java ?? '');

    // Initialize database type controllers
    _dbTypeControllers = {};
    for (final dbCode in DatabaseCodes.all) {
      _dbTypeControllers[dbCode] = TextEditingController(
        text: existing?.apply[dbCode] ?? '',
      );
    }

    // Add listeners
    _nameController.addListener(_validate);
    _chnnameController.addListener(_validate);

    _validate();
  }

  void _validate() {
    final name = _nameController.text.trim();
    final chnname = _chnnameController.text.trim();

    // Check basic validity
    final hasName = name.isNotEmpty;
    final hasChnname = chnname.isNotEmpty;

    // Check if name already exists (for new types or changed names)
    final nameExists = ref.read(dataTypeNotifierProvider).nameExists(
          name,
          excludeId: widget.existingType?.id,
        );

    setState(() {
      _isValid = hasName && hasChnname && !nameExists;
    });
  }

  Map<String, String> _buildApplyMap() {
    final apply = <String, String>{};
    for (final entry in _dbTypeControllers.entries) {
      final value = entry.value.text.trim();
      if (value.isNotEmpty) {
        apply[entry.key] = value;
      }
    }
    return apply;
  }

  DataType _buildDataType() {
    final existing = widget.existingType;

    return DataType(
      id: existing?.id ?? '',
      name: _nameController.text.trim(),
      chnname: _chnnameController.text.trim(),
      remark: _remarkController.text.trim().isEmpty
          ? null
          : _remarkController.text.trim(),
      apply: _buildApplyMap(),
      java: _javaController.text.trim().isEmpty
          ? null
          : _javaController.text.trim(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _chnnameController.dispose();
    _remarkController.dispose();
    _javaController.dispose();
    for (final controller in _dbTypeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TDAlertDialog(
      title: Row(
        children: [
          Icon(
            widget.existingType != null ? TDIcons.edit : TDIcons.add,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            widget.existingType != null ? 'Edit Data Type' : 'Add Data Type',
          ),
          if (_isDefaultType)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Default',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic info section
              _buildSectionHeader('Basic Info', TDIcons.info_outline),
              const SizedBox(height: 12),
              TDInput(
                controller: _nameController,
                leftLabel: 'Type Name (English)',
                hintText: 'e.g., MyCustomType',
                readOnly: _isDefaultType,
                autofocus: widget.existingType == null,
                onChanged: (text) {
                  setState(() {});
                  _validate();
                },
              ),
              const SizedBox(height: 16),
              TDInput(
                controller: _chnnameController,
                leftLabel: 'Chinese Name',
                hintText: 'e.g., 自定义类型',
                onChanged: (text) {
                  setState(() {});
                  _validate();
                },
              ),
              const SizedBox(height: 16),
              TDInput(
                controller: _remarkController,
                leftLabel: 'Remark',
                hintText: 'Description of this data type',
                maxLines: 2,
                onChanged: (text) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              TDInput(
                controller: _javaController,
                leftLabel: 'Java Type',
                hintText: 'e.g., String, Integer, BigDecimal',
                onChanged: (text) {
                  setState(() {});
                },
              ),

              const SizedBox(height: 24),

              // Database mapping section
              _buildSectionHeader('Database Type Mapping', TDIcons.storage),
              const SizedBox(height: 12),
              Text(
                'Define how this type maps to each database',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // Database mappings
              ...DatabaseCodes.all.map((dbCode) {
                final defaultMapping = _getDefaultMapping(dbCode);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TDInput(
                    controller: _dbTypeControllers[dbCode],
                    leftLabel: DatabaseCodes.getDisplayName(dbCode),
                    hintText: 'e.g., VARCHAR(255)',
                    onChanged: (text) {
                      setState(() {});
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TDButton(
          text: 'Cancel',
          theme: TDButtonTheme.defaultTheme,
          onTap: () => Navigator.of(context).pop(),
        ),
        if (widget.existingType != null && _isDefaultType)
          TDButton(
            text: 'Restore Default',
            theme: TDButtonTheme.defaultTheme,
            onTap: () {
              // Restore default values
              final defaultType = DefaultDataTypes.getById(widget.existingType!.id);
              if (defaultType != null) {
                _nameController.text = defaultType.name;
                _chnnameController.text = defaultType.chnname;
                _remarkController.text = defaultType.remark ?? '';
                _javaController.text = defaultType.java ?? '';
                for (final entry in defaultType.apply.entries) {
                  _dbTypeControllers[entry.key]?.text = entry.value;
                }
              }
            },
          ),
        TDButton(
          text: 'Save',
          theme: TDButtonTheme.primary,
          onTap: _isValid
              ? () {
                  widget.onSave(_buildDataType());
                  Navigator.of(context).pop();
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDatabaseIcon(String dbCode) {
    IconData icon;
    switch (dbCode) {
      case DatabaseCodes.mysql:
        icon = TDIcons.storage;
        break;
      case DatabaseCodes.postgresql:
        icon = TDIcons.storage;
        break;
      case DatabaseCodes.oracle:
        icon = TDIcons.business;
        break;
      case DatabaseCodes.sqlServer:
        icon = TDIcons.business;
        break;
      case DatabaseCodes.sqlite:
        icon = TDIcons.phone_android;
        break;
      default:
        icon = TDIcons.storage;
    }
    return Icon(icon);
  }

  String _getDefaultMapping(String dbCode) {
    final defaultType = widget.existingType != null
        ? DefaultDataTypes.getById(widget.existingType!.id)
        : null;
    return defaultType?.apply[dbCode] ?? '';
  }
}