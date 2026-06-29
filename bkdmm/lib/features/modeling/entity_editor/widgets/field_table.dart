import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../../core/i18n/i18n.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/models.dart';

/// Field table widget - 字段编辑表格
///
/// 布局设计遵循:
/// - 使用 LayoutBuilder 获取约束，响应式处理宽度
/// - 表格需要明确的宽度约束
/// - 固定宽度列使用最小宽度，弹性列自动分配剩余空间
/// - 窄屏时启用横向滚动
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
  // 内联编辑状态
  String? _editingFieldId;
  String? _editingProperty;
  final TextEditingController _editController = TextEditingController();
  final FocusNode _editFocusNode = FocusNode();

  @override
  void dispose() {
    _editController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);
    final l10n = context.l10n;

    return Column(
      children: [
        // 工具栏 - 固定高度
        _buildToolbar(tdTheme, l10n),

        // 表格内容 - 填充剩余空间
        Expanded(
          child: widget.fields.isEmpty
              ? _buildEmptyState(tdTheme, l10n)
              : _buildTableContent(context, tdTheme, l10n),
        ),
      ],
    );
  }

  /// 工具栏
  Widget _buildToolbar(TDThemeData tdTheme, AppLocalizations l10n) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
          TDButton(
            text: l10n.addField,
            icon: TDIcons.add,
            theme: TDButtonTheme.primary,
            type: TDButtonType.fill,
            size: TDButtonSize.small,
            onTap: () => _showFieldDialog(null),
          ),
        ],
      ),
    );
  }

  /// 空状态
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

  /// 表格内容 - 使用 LayoutBuilder 响应式处理
  Widget _buildTableContent(BuildContext context, TDThemeData tdTheme, AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算表格所需的最小宽度
        // 固定列: # (32) + PK (40) + 非空 (48) + 自增 (48) + 操作 (56) = 224
        // 弹性列: 字段名 + 类型 + 中文名 + 备注 (需要至少 200)
        const fixedColumnsWidth = 32 + 40 + 48 + 48 + 56;
        const minFlexibleWidth = 200;
        const minTableWidth = fixedColumnsWidth + minFlexibleWidth;

        final availableWidth = constraints.maxWidth;
        final needHorizontalScroll = availableWidth < minTableWidth;

        // 构建表格
        final table = _buildDataTable(tdTheme, l10n, availableWidth);

        if (needHorizontalScroll) {
          // 窄屏: 启用横向滚动
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: minTableWidth + 200, // 给弹性列更多空间
              child: table,
            ),
          );
        }

        return table;
      },
    );
  }

  /// 构建数据表格
  Widget _buildDataTable(TDThemeData tdTheme, AppLocalizations l10n, double availableWidth) {
    // 准备表格数据
    final tableData = widget.fields.asMap().entries.map((entry) {
      final field = entry.value;
      return <String, dynamic>{
        'order': '${entry.key + 1}',
        'pk': field.pk ? '1' : '',
        'name': field.name,
        'type': field.type,
        'chnname': field.chnname,
        'notNull': field.notNull ? '1' : '',
        'autoIncrement': field.autoIncrement ? '1' : '',
        'remark': field.remark ?? '',
        '_field': field,
        '_index': entry.key,
      };
    }).toList();

    // 列配置
    // 固定宽度列: #, PK, 非空, 自增, 操作
    // 弹性列: 字段名, 类型, 中文名, 备注 (通过不设置 width 实现自动分配)
    final columns = [
      TDTableCol(
        title: '#',
        colKey: 'order',
        width: 32,
        align: TDTableColAlign.center,
      ),
      TDTableCol(
        title: l10n.pk,
        colKey: 'pk',
        width: 40,
        align: TDTableColAlign.center,
        cellBuilder: (context, rowIndex) => _buildPkCell(rowIndex, tdTheme),
      ),
      // 弹性列 - 不设置 width
      TDTableCol(
        title: l10n.fieldName,
        colKey: 'name',
        ellipsis: true,
        cellBuilder: (context, rowIndex) => _buildEditableCell(rowIndex, 'name', tdTheme),
      ),
      TDTableCol(
        title: l10n.dataType,
        colKey: 'type',
        ellipsis: true,
        cellBuilder: (context, rowIndex) => _buildTypeCell(rowIndex, tdTheme),
      ),
      TDTableCol(
        title: l10n.chineseName,
        colKey: 'chnname',
        ellipsis: true,
        cellBuilder: (context, rowIndex) => _buildEditableCell(rowIndex, 'chnname', tdTheme),
      ),
      TDTableCol(
        title: l10n.notNull,
        colKey: 'notNull',
        width: 48,
        align: TDTableColAlign.center,
        cellBuilder: (context, rowIndex) => _buildBoolCell(rowIndex, 'notNull', tdTheme),
      ),
      TDTableCol(
        title: l10n.autoIncrement,
        colKey: 'autoIncrement',
        width: 48,
        align: TDTableColAlign.center,
        cellBuilder: (context, rowIndex) => _buildBoolCell(rowIndex, 'autoIncrement', tdTheme),
      ),
      // 弹性列
      TDTableCol(
        title: l10n.fieldRemark,
        colKey: 'remark',
        ellipsis: true,
        cellBuilder: (context, rowIndex) => _buildEditableCell(rowIndex, 'remark', tdTheme),
      ),
      TDTableCol(
        title: l10n.actions,
        colKey: 'actions',
        width: 56,
        align: TDTableColAlign.center,
        cellBuilder: (context, rowIndex) => _buildActionsCell(rowIndex, tdTheme),
      ),
    ];

    return TDTable(
      columns: columns,
      data: tableData,
      bordered: true,
      width: availableWidth,
      rowHeight: 40,
      backgroundColor: tdTheme.bgColorContainer,
      stripe: true,
      onCellTap: (rowIndex, row, col) {
        final field = row['_field'] as Field;
        final colKey = col.colKey;

        // 可编辑列: 点击进入编辑模式
        if (colKey == 'name' || colKey == 'chnname' || colKey == 'remark') {
          _startEditing(field, colKey!);
        }
      },
    );
  }

  /// 主键单元格
  Widget _buildPkCell(int rowIndex, TDThemeData tdTheme) {
    final field = widget.fields[rowIndex];
    return GestureDetector(
      onTap: () => _updateField(field, 'pk', !field.pk),
      child: Icon(
        field.pk ? TDIcons.check_rectangle_filled : TDIcons.rectangle,
        size: 16,
        color: field.pk ? tdTheme.brandNormalColor : tdTheme.textColorPlaceholder,
      ),
    );
  }

  /// 可编辑单元格
  Widget _buildEditableCell(int rowIndex, String property, TDThemeData tdTheme) {
    final field = widget.fields[rowIndex];
    final value = _getFieldValue(field, property);
    final isEditing = _editingFieldId == field.id && _editingProperty == property;

    if (isEditing) {
      return TextField(
        controller: _editController,
        focusNode: _editFocusNode,
        autofocus: true,
        style: TextStyle(fontSize: 14, color: tdTheme.textColorPrimary),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: tdTheme.brandNormalColor, width: 2),
          ),
        ),
        onSubmitted: (newValue) => _finishEditing(field, property, newValue),
        onEditingComplete: () => _finishEditing(field, property, _editController.text),
      );
    }

    return TDText(
      value,
      font: tdTheme.fontBodySmall,
      textColor: tdTheme.textColorPrimary,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  /// 类型选择单元格
  Widget _buildTypeCell(int rowIndex, TDThemeData tdTheme) {
    final field = widget.fields[rowIndex];
    return InkWell(
      onTap: () => _showTypeSelector(field),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: TDText(
              field.type,
              font: tdTheme.fontBodySmall,
              textColor: tdTheme.textColorPrimary,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(TDIcons.chevron_down, size: 12, color: tdTheme.textColorSecondary),
        ],
      ),
    );
  }

  /// Boolean 单元格
  Widget _buildBoolCell(int rowIndex, String property, TDThemeData tdTheme) {
    final field = widget.fields[rowIndex];
    final value = property == 'notNull' ? field.notNull : field.autoIncrement;

    return GestureDetector(
      onTap: () => _updateField(field, property, !value),
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: value ? tdTheme.brandNormalColor : tdTheme.bgColorContainer,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: value ? tdTheme.brandNormalColor : tdTheme.componentBorderColor,
            width: 1.5,
          ),
        ),
        child: value ? Icon(TDIcons.check, size: 12, color: Colors.white) : null,
      ),
    );
  }

  /// 操作单元格
  Widget _buildActionsCell(int rowIndex, TDThemeData tdTheme) {
    final field = widget.fields[rowIndex];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _showFieldDialog(field),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(TDIcons.edit, size: 14, color: tdTheme.textColorSecondary),
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: () => _confirmDelete(field),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(TDIcons.delete, size: 14, color: tdTheme.errorColor6),
          ),
        ),
      ],
    );
  }

  String _getFieldValue(Field field, String property) {
    switch (property) {
      case 'name':
        return field.name;
      case 'chnname':
        return field.chnname;
      case 'remark':
        return field.remark ?? '';
      default:
        return '';
    }
  }

  void _startEditing(Field field, String property) {
    setState(() {
      _editingFieldId = field.id;
      _editingProperty = property;
      _editController.text = _getFieldValue(field, property);
    });
    _editFocusNode.requestFocus();
  }

  void _finishEditing(Field field, String property, String newValue) {
    if (newValue.trim() != _getFieldValue(field, property)) {
      _updateField(field, property, newValue.trim());
    }
    setState(() {
      _editingFieldId = null;
      _editingProperty = null;
      _editController.clear();
    });
  }

  void _updateField(Field field, String property, dynamic value) {
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
        if ((value as String).isEmpty) return;
        updatedField = field.copyWith(name: value);
        break;
      case 'chnname':
        updatedField = field.copyWith(chnname: (value as String).isEmpty ? field.name : value);
        break;
      case 'remark':
        updatedField = field.copyWith(remark: (value as String).isEmpty ? null : value);
        break;
      default:
        return;
    }
    widget.onUpdateField(field.id, updatedField);
  }

  void _showTypeSelector(Field field) {
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
              _updateField(field, 'type', newType);
            }
          }
          Navigator.pop(context);
        },
        onCancel: (_) => Navigator.pop(context),
      ),
    );
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

          return TDAlertDialog(
            title: existingField == null ? l10n.addField : l10n.editField,
            content: '',
            contentWidget: SizedBox(
              width: 480,
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
                    _buildTypeSelectorFormField(context, selectedType, (type) => setState(() => selectedType = type)),
                    const SizedBox(height: 12),
                    TDInput(
                      controller: chnnameController,
                      leftLabel: l10n.chineseName,
                      hintText: 'e.g., 用户ID',
                      leftIcon: const Icon(TDIcons.translate),
                      backgroundColor: Colors.transparent,
                    ),
                    const SizedBox(height: 12),
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
                                if (isPk) isNotNull = true;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          TDCheckbox(
                            title: l10n.notNull,
                            checked: isNotNull,
                            enable: !isPk,
                            onCheckBoxChanged: isPk ? null : (checked) => setState(() => isNotNull = checked),
                          ),
                          const SizedBox(height: 8),
                          TDCheckbox(
                            title: l10n.autoIncrement,
                            checked: isAutoIncrement,
                            onCheckBoxChanged: (checked) => setState(() => isAutoIncrement = checked),
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
                  remark: remarkController.text.trim().isNotEmpty ? remarkController.text.trim() : null,
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

  Widget _buildTypeSelectorFormField(BuildContext context, String selectedType, Function(String) onTypeChanged) {
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
                onTypeChanged(widget.dataTypes[selected[0]].name);
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
            TDText(l10n.dataTypeLabel, font: tdTheme.fontBodyMedium, textColor: tdTheme.textColorSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: TDText(
                '$selectedType (${widget.dataTypes.firstWhere((dt) => dt.name == selectedType, orElse: () => widget.dataTypes.first).chnname})',
                font: tdTheme.fontBodyMedium,
                textColor: tdTheme.textColorPrimary,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(TDIcons.chevron_down, size: 18, color: tdTheme.textColorSecondary),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Field field) {
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
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
