import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../core/i18n/i18n.dart';
import '../../../shared/models/data_type.dart';
import '../../../shared/constants/default_data_types.dart';
import '../../../shared/utils/responsive_utils.dart';
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
    final tdTheme = TDTheme.of(context);
    final l10n = context.l10n;
    final formSpacing = ResponsiveUtils.getFormFieldSpacing(context);

    // Responsive width calculation using utility
    final dialogWidth = ResponsiveUtils.getDialogWidth(context, DialogSizePreset.large);

    return TDAlertDialog(
      title: widget.existingType != null ? l10n.editDataType : l10n.addDataType,
      content: '',
      contentWidget: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic info section
              _buildSectionHeader(l10n.basicInfo, TDIcons.info_circle, tdTheme),
              SizedBox(height: formSpacing * 0.6),
              TDInput(
                controller: _nameController,
                leftLabel: l10n.typeEnglishName,
                hintText: 'e.g., MyCustomType',
                readOnly: _isDefaultType,
                onChanged: (text) {
                  setState(() {});
                  _validate();
                },
              ),
              SizedBox(height: formSpacing * 0.6),
              TDInput(
                controller: _chnnameController,
                leftLabel: l10n.typeChineseName,
                hintText: 'e.g., 自定义类型',
                onChanged: (text) {
                  setState(() {});
                  _validate();
                },
              ),
              SizedBox(height: formSpacing * 0.6),
              TDInput(
                controller: _remarkController,
                leftLabel: l10n.dataTypeRemark,
                hintText: 'Description of this data type',
                maxLines: 2,
                onChanged: (text) {
                  setState(() {});
                },
              ),
              SizedBox(height: formSpacing * 0.6),
              TDInput(
                controller: _javaController,
                leftLabel: l10n.javaType,
                hintText: 'e.g., String, Integer, BigDecimal',
                onChanged: (text) {
                  setState(() {});
                },
              ),

              SizedBox(height: formSpacing),

              // Database mapping section
              _buildSectionHeader(l10n.databaseTypeMapping, TDIcons.data_base, tdTheme),
              const SizedBox(height: 8),
              TDText(
                l10n.databaseMappingHint,
                font: tdTheme.fontBodySmall,
                textColor: tdTheme.textColorSecondary,
              ),
              SizedBox(height: formSpacing * 0.6),

              // Database mappings - show in a scrollable container
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: DatabaseCodes.all.length,
                  itemBuilder: (context, index) {
                    final dbCode = DatabaseCodes.all[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: formSpacing * 0.5),
                      child: TDInput(
                        controller: _dbTypeControllers[dbCode],
                        leftLabel: DatabaseCodes.getDisplayName(dbCode),
                        hintText: 'e.g., VARCHAR(255)',
                        onChanged: (text) {
                          setState(() {});
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      leftBtn: TDDialogButtonOptions(
        title: l10n.cancel,
        theme: TDButtonTheme.defaultTheme,
        type: TDButtonType.text,
        action: () => Navigator.of(context).pop(),
      ),
      rightBtn: TDDialogButtonOptions(
        title: l10n.save,
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

  Widget _buildSectionHeader(String title, IconData icon, TDThemeData tdTheme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: tdTheme.brandNormalColor),
        const SizedBox(width: 8),
        TDText(
          title,
          font: tdTheme.fontTitleSmall,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }
}