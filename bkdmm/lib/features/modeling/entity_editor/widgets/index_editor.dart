import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../../shared/models/models.dart';

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
                'Indexes (${widget.indexes.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TDButton(
                text: 'Add Index',
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
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No indexes defined',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click "Add Index" to create a new index',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.indexes.length,
                  itemBuilder: (context, index) {
                    final idx = widget.indexes[index];
                    return _buildIndexCard(idx, theme, colorScheme);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildIndexCard(Index index, ThemeData theme, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
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
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    index.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Type chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getIndexTypeColor(index.type, colorScheme),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getIndexTypeLabel(index.type),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
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
              children: index.fields.map((fieldName) {
                return TDTag(
                  fieldName,
                  theme: TDTagTheme.primary,
                  size: TDTagSize.small,
                );
              }).toList(),
            ),

            // Remark
            if (index.remark != null && index.remark!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                index.remark!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
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

  Color _getIndexTypeColor(IndexType type, ColorScheme colorScheme) {
    switch (type) {
      case IndexType.unique:
        return colorScheme.primaryContainer;
      case IndexType.fulltext:
        return colorScheme.tertiaryContainer;
      case IndexType.normal:
        return colorScheme.secondaryContainer;
    }
  }

  String _getIndexTypeLabel(IndexType type) {
    switch (type) {
      case IndexType.unique:
        return 'UNIQUE';
      case IndexType.fulltext:
        return 'FULLTEXT';
      case IndexType.normal:
        return 'NORMAL';
    }
  }

  void _showAddIndexDialog() {
    _showIndexDialog(null);
  }

  void _showEditIndexDialog(Index index) {
    _showIndexDialog(index);
  }

  void _showIndexDialog(Index? existingIndex) {
    final nameController = TextEditingController(
      text: existingIndex?.name ?? 'idx_${widget.indexes.length + 1}',
    );
    final remarkController = TextEditingController(text: existingIndex?.remark ?? '');
    IndexType selectedType = existingIndex?.type ?? IndexType.normal;
    Set<String> selectedFields = existingIndex?.fields.toSet() ?? {};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => TDAlertDialog(
          title: existingIndex == null ? 'Add Index' : 'Edit Index',
          contentWidget: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TDInput(
                    controller: nameController,
                    leftLabel: 'Index Name *',
                    hintText: 'e.g., idx_user_id',
                    leftIcon: const Icon(TDIcons.edit),
                    backgroundColor: Colors.transparent,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<IndexType>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Index Type',
                      prefixIcon: Icon(TDIcons.setting),
                    ),
                    items: IndexType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(_getIndexTypeIcon(type), size: 18),
                            const SizedBox(width: 8),
                            Text(_getIndexTypeLabel(type)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Fields:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  // Fixed height container for field selection
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 200,
                      minHeight: 50,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: widget.availableFields.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'No fields available',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: widget.availableFields.length,
                              itemBuilder: (context, index) {
                                final field = widget.availableFields[index];
                                final isSelected = selectedFields.contains(field.name);
                                return TDCheckbox(
                                  title: field.name,
                                  subTitle: '${field.chnname} (${field.type})',
                                  checked: isSelected,
                                  onCheckBoxChanged: (checked) {
                                    setState(() {
                                      if (checked) {
                                        selectedFields.add(field.name);
                                      } else {
                                        selectedFields.remove(field.name);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TDInput(
                    controller: remarkController,
                    leftLabel: 'Remark',
                    hintText: 'Optional description',
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
            title: existingIndex == null ? 'Add' : 'Save',
            theme: TDButtonTheme.primary,
            type: TDButtonType.fill,
            action: () {
              if (nameController.text.trim().isEmpty) {
                TDToast.showText('Index name is required', context: context);
                return;
              }
              if (selectedFields.isEmpty) {
                TDToast.showText('Select at least one field', context: context);
                return;
              }

              final index = Index(
                id: existingIndex?.id ?? '',
                name: nameController.text.trim(),
                fields: selectedFields.toList(),
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
        ),
      ),
    );
  }

  void _confirmDeleteIndex(Index index) {
    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: 'Delete Index',
        content: 'Are you sure you want to delete index "${index.name}"?',
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
            widget.onDeleteIndex(index.id);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
