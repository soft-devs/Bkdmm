import 'package:flutter/material.dart';
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
              FilledButton.icon(
                onPressed: _showAddIndexDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Index'),
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
                        Icons.sort_outlined,
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
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _showEditIndexDialog(index),
                  tooltip: 'Edit',
                ),
                // Delete button
                IconButton(
                  icon: Icon(Icons.delete, size: 18, color: colorScheme.error),
                  onPressed: () => _confirmDeleteIndex(index),
                  tooltip: 'Delete',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Fields
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: index.fields.map((fieldName) {
                return Chip(
                  label: Text(fieldName),
                  avatar: Icon(
                    Icons.arrow_right,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  visualDensity: VisualDensity.compact,
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
        return Icons.verified_outlined;
      case IndexType.fulltext:
        return Icons.text_fields;
      case IndexType.normal:
        return Icons.sort;
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
        builder: (context, setState) => AlertDialog(
          title: Text(existingIndex == null ? 'Add Index' : 'Edit Index'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Index Name *',
                      hintText: 'e.g., idx_user_id',
                      prefixIcon: Icon(Icons.label),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<IndexType>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Index Type',
                      prefixIcon: Icon(Icons.category),
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
                                return CheckboxListTile(
                                  title: Text(field.name),
                                  subtitle: Text(
                                    '${field.chnname} (${field.type})',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedFields.add(field.name);
                                      } else {
                                        selectedFields.remove(field.name);
                                      }
                                    });
                                  },
                                  dense: true,
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: remarkController,
                    decoration: const InputDecoration(
                      labelText: 'Remark',
                      hintText: 'Optional description',
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
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
                    const SnackBar(content: Text('Index name is required')),
                  );
                  return;
                }
                if (selectedFields.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Select at least one field')),
                  );
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
              child: Text(existingIndex == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteIndex(Index index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Index'),
        content: Text('Are you sure you want to delete index "${index.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              widget.onDeleteIndex(index.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}