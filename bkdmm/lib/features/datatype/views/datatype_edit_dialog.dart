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
      title: widget.existingType != null ? 'Edit Data Type' : 'Add Data Type',
      content: '',
      contentWidget: SizedBox(
        width: 780, // 600 * 1.3
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic info section
              _buildSectionHeader('Basic Info', TDIcons.info_circle, colorScheme),
              const SizedBox(height: 12),
              TDInput(
                controller: _nameController,
                leftLabel: 'Type Name (English)',
                hintText: 'e.g., MyCustomType',
                readOnly: _isDefaultType,
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
              _buildSectionHeader('Database Type Mapping', TDIcons.data_base, colorScheme),
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
      leftBtn: TDDialogButtonOptions(
        title: 'Cancel',
        theme: TDButtonTheme.defaultTheme,
        type: TDButtonType.text,
        action: () => Navigator.of(context).pop(),
      ),
      rightBtn: TDDialogButtonOptions(
        title: 'Save',
        theme: TDButtonTheme.primary,
        type: TDButtonType.fill,
        action: _isValid
            ? () {
                widget.onSave(_buildDataType());
                Navigator.of(context).pop();
              }
            : null,
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
