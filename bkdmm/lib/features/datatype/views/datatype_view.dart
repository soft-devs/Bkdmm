import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../shared/models/models.dart';
import '../../../shared/constants/default_data_types.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/td_popup_menu.dart';
import '../providers/datatype_provider.dart';
import 'datatype_edit_dialog.dart';

/// Data type management view
class DataTypeView extends ConsumerStatefulWidget {
  const DataTypeView({super.key});

  @override
  ConsumerState<DataTypeView> createState() => _DataTypeViewState();
}

class _DataTypeViewState extends ConsumerState<DataTypeView> {
  String _searchQuery = '';
  bool _showDefaultTypes = true;
  bool _showCustomTypes = true;
  String? _selectedTypeId;

  @override
  void initState() {
    super.initState();
    // Initialize data types from current project
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFromProject();
    });
  }

  void _initializeFromProject() {
    final project = ref.read(currentProjectProvider);
    if (project != null) {
      ref.read(dataTypeNotifierProvider.notifier).initialize(project.dataTypeDomains);
    }
  }

  List<DataType> _filterTypes(List<DataType> types) {
    if (_searchQuery.isEmpty) return types;
    final query = _searchQuery.toLowerCase();
    return types.where((t) {
      return t.name.toLowerCase().contains(query) ||
          t.chnname.toLowerCase().contains(query) ||
          (t.remark?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);
    final state = ref.watch(dataTypeNotifierProvider);

    final defaultTypes = _filterTypes(state.defaultTypes);
    final customTypes = _filterTypes(state.customTypes);

    return Scaffold(
      backgroundColor: tdTheme.grayColor1,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(tdTheme, state),

          // Search and filter bar
          _buildSearchBar(tdTheme),

          // Content
          Expanded(
            child: state.dataTypes.isEmpty
                ? _buildEmptyState(tdTheme)
                : _buildTypeList(tdTheme, defaultTypes, customTypes),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(TDThemeData tdTheme, DataTypeState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tdTheme.grayColor1,
        border: Border(
          bottom: BorderSide(
            color: tdTheme.componentStrokeColor,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            TDIcons.data,
            color: tdTheme.brandNormalColor,
          ),
          const SizedBox(width: 8),
          TDText(
            'Data Type Management',
            font: tdTheme.fontTitleMedium,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: tdTheme.grayColor3,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TDText(
              '${state.dataTypes.length} types',
              font: tdTheme.fontBodySmall,
              textColor: tdTheme.fontGyColor2,
            ),
          ),
          if (state.isDirty)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: tdTheme.brandLightColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TDText(
                'Modified',
                font: tdTheme.fontBodySmall,
                textColor: tdTheme.brandNormalColor,
              ),
            ),
          const Spacer(),
          // Action buttons
          TDButton(
            text: 'Restore Defaults',
            theme: TDButtonTheme.defaultTheme,
            icon: TDIcons.history,
            onTap: () => _showRestoreDefaultsDialog(),
          ),
          const SizedBox(width: 12),
          TDButton(
            text: 'Add Type',
            theme: TDButtonTheme.primary,
            icon: TDIcons.add,
            onTap: () => _showAddDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(TDThemeData tdTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Search field
          Expanded(
            child: TDInput(
              hintText: 'Search types...',
              leftIcon: Icon(TDIcons.search, color: tdTheme.fontGyColor3),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          // Filter toggles using TDTag wrapped in GestureDetector
          GestureDetector(
            onTap: () {
              setState(() {
                _showDefaultTypes = !_showDefaultTypes;
              });
            },
            child: TDTag(
              'Default Types',
              theme: _showDefaultTypes ? TDTagTheme.primary : TDTagTheme.defaultTheme,
              size: TDTagSize.medium,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              setState(() {
                _showCustomTypes = !_showCustomTypes;
              });
            },
            child: TDTag(
              'Custom Types',
              theme: _showCustomTypes ? TDTagTheme.primary : TDTagTheme.defaultTheme,
              size: TDTagSize.medium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(TDThemeData tdTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            TDIcons.data,
            size: 64,
            color: tdTheme.fontGyColor4,
          ),
          const SizedBox(height: 16),
          TDText(
            'No data types found',
            font: tdTheme.fontTitleMedium,
            textColor: tdTheme.fontGyColor2,
          ),
          const SizedBox(height: 8),
          TDText(
            'Click "Restore Defaults" to load default types',
            font: tdTheme.fontBodyMedium,
            textColor: tdTheme.fontGyColor3,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeList(
    TDThemeData tdTheme,
    List<DataType> defaultTypes,
    List<DataType> customTypes,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Default types section
        if (_showDefaultTypes && defaultTypes.isNotEmpty) ...[
          _buildSectionHeader(
            'Default Types',
            '${defaultTypes.length}',
            TDIcons.bookmark,
            tdTheme,
          ),
          const SizedBox(height: 8),
          ...defaultTypes.map((type) => _buildTypeCard(type, tdTheme)),
          const SizedBox(height: 24),
        ],

        // Custom types section
        if (_showCustomTypes && customTypes.isNotEmpty) ...[
          _buildSectionHeader(
            'Custom Types',
            '${customTypes.length}',
            TDIcons.extension,
            tdTheme,
          ),
          const SizedBox(height: 8),
          ...customTypes.map((type) => _buildTypeCard(type, tdTheme)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    String count,
    IconData icon,
    TDThemeData tdTheme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: tdTheme.brandNormalColor),
        const SizedBox(width: 8),
        TDText(
          title,
          font: tdTheme.fontTitleSmall,
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: tdTheme.grayColor3,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TDText(
            count,
            font: tdTheme.fontBodySmall,
            textColor: tdTheme.fontGyColor2,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeCard(DataType type, TDThemeData tdTheme) {
    final isDefault = DefaultDataTypes.isDefaultType(type.id);
    final isSelected = _selectedTypeId == type.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTypeId = isSelected ? null : type.id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? tdTheme.brandLightColor : tdTheme.whiteColor1,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? tdTheme.brandNormalColor : tdTheme.componentStrokeColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: tdTheme.grayColor4.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDefault ? tdTheme.brandLightColor : tdTheme.grayColor3,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTypeIcon(type.name),
                      size: 20,
                      color: isDefault ? tdTheme.brandNormalColor : tdTheme.fontGyColor1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            TDText(
                              type.name,
                              font: tdTheme.fontTitleSmall,
                              fontWeight: FontWeight.w600,
                            ),
                            const SizedBox(width: 8),
                            TDText(
                              type.chnname,
                              font: tdTheme.fontBodyMedium,
                              textColor: tdTheme.fontGyColor2,
                            ),
                          ],
                        ),
                        if (type.remark != null && type.remark!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: TDText(
                              type.remark!,
                              font: tdTheme.fontBodySmall,
                              textColor: tdTheme.fontGyColor3,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Actions using TDPopupMenuButton with TDIcons
                  TDPopupMenuButton(
                    icon: TDIcons.more,
                    iconColor: tdTheme.fontGyColor1,
                    items: [
                      TDPopupMenuItem(
                        value: 'edit',
                        icon: TDIcons.edit,
                        label: 'Edit',
                      ),
                      TDPopupMenuItem(
                        value: 'duplicate',
                        icon: TDIcons.copy,
                        label: 'Duplicate',
                      ),
                      if (!isDefault)
                        TDPopupMenuItem(
                          value: 'delete',
                          icon: TDIcons.delete,
                          label: 'Delete',
                          iconColor: tdTheme.errorColor6,
                          textColor: tdTheme.errorColor6,
                        ),
                    ],
                    onSelected: (action) => _handleTypeAction(type, action),
                  ),
                ],
              ),

              // Type mappings
              if (isSelected) ...[
                const SizedBox(height: 16),
                _buildTypeMappings(type, tdTheme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeMappings(DataType type, TDThemeData tdTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TDText(
          'Database Mappings',
          font: tdTheme.fontBodySmall,
          textColor: tdTheme.fontGyColor2,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: DatabaseCodes.all.map((dbCode) {
            final dbType = type.apply[dbCode];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: tdTheme.grayColor2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TDText(
                    DatabaseCodes.getDisplayName(dbCode),
                    font: tdTheme.fontBodySmall,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dbType ?? '-',
                    style: TextStyle(
                      fontSize: tdTheme.fontBodySmall?.size,
                      color: tdTheme.fontGyColor2,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        if (type.java != null) ...[
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TDText(
                'Java: ',
                font: tdTheme.fontBodySmall,
                textColor: tdTheme.fontGyColor2,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tdTheme.grayColor2,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  type.java!,
                  style: TextStyle(
                    fontSize: tdTheme.fontBodySmall?.size,
                    color: tdTheme.fontGyColor1,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  IconData _getTypeIcon(String typeName) {
    switch (typeName.toLowerCase()) {
      case 'idorkey':
        return TDIcons.key;
      case 'name':
        return TDIcons.edit;
      case 'intro':
        return TDIcons.edit;
      case 'longtext':
        return TDIcons.article;
      case 'integer':
        return TDIcons.filter_1;
      case 'long':
        return TDIcons.filter;
      case 'money':
        return TDIcons.money;
      case 'datetime':
        return TDIcons.time;
      case 'yesno':
        return TDIcons.check;
      case 'dict':
        return TDIcons.book;
      default:
        return TDIcons.data;
    }
  }

  void _handleTypeAction(DataType type, String action) {
    switch (action) {
      case 'edit':
        _showEditDialog(type);
        break;
      case 'duplicate':
        _duplicateType(type);
        break;
      case 'delete':
        _showDeleteDialog(type);
        break;
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => DataTypeEditDialog(
        onSave: (newType) {
          final notifier = ref.read(dataTypeNotifierProvider.notifier);
          final created = notifier.createNewDataType(
            name: newType.name,
            chnname: newType.chnname,
            remark: newType.remark,
            apply: newType.apply,
            java: newType.java,
          );
          if (notifier.addDataType(created)) {
            _updateProject();
          }
        },
      ),
    );
  }

  void _showEditDialog(DataType type) {
    showDialog(
      context: context,
      builder: (context) => DataTypeEditDialog(
        existingType: type,
        onSave: (updated) {
          if (ref.read(dataTypeNotifierProvider.notifier).updateDataType(type.id, updated)) {
            _updateProject();
          }
        },
      ),
    );
  }

  void _duplicateType(DataType type) {
    ref.read(dataTypeNotifierProvider.notifier).duplicateDataType(type.id);
    _updateProject();
  }

  void _showDeleteDialog(DataType type) {
    final project = ref.read(currentProjectProvider);
    final modules = project?.modules ?? [];

    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: 'Delete Data Type',
        content: 'Are you sure you want to delete "${type.name}"? This action cannot be undone.',
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
            final usage = ref
                .read(dataTypeNotifierProvider.notifier)
                .deleteDataType(type.id, modules);

            if (usage != null && usage.isNotEmpty) {
              // Type is in use, show warning
              Navigator.pop(context);
              _showUsageWarning(type, usage);
            } else if (usage == null) {
              // Deleted successfully
              Navigator.pop(context);
              _updateProject();
            }
          },
        ),
      ),
    );
  }

  void _showUsageWarning(DataType type, Map<String, List<String>> usage) {
    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: 'Type In Use',
        content: 'The type "${type.name}" is used in the following fields: ${usage.entries.map((e) => "${e.key}: ${e.value.join(', ')}").join("; ")}. Do you want to delete it anyway? Fields using this type may break.',
        leftBtn: TDDialogButtonOptions(
          title: 'Cancel',
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          action: () => Navigator.pop(context),
        ),
        rightBtn: TDDialogButtonOptions(
          title: 'Delete Anyway',
          theme: TDButtonTheme.danger,
          type: TDButtonType.fill,
          action: () {
            ref.read(dataTypeNotifierProvider.notifier).forceDeleteDataType(type.id);
            Navigator.pop(context);
            _updateProject();
          },
        ),
      ),
    );
  }

  void _showRestoreDefaultsDialog() {
    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: 'Restore Defaults',
        content: 'This will restore all default data types to their original values. Custom types will not be affected.',
        leftBtn: TDDialogButtonOptions(
          title: 'Cancel',
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          action: () => Navigator.pop(context),
        ),
        rightBtn: TDDialogButtonOptions(
          title: 'Restore',
          theme: TDButtonTheme.primary,
          type: TDButtonType.fill,
          action: () {
            ref.read(dataTypeNotifierProvider.notifier).restoreDefaults();
            Navigator.pop(context);
            _updateProject();
          },
        ),
      ),
    );
  }

  void _updateProject() {
    final project = ref.read(currentProjectProvider);
    if (project == null) return;

    final domains = ref.read(dataTypeNotifierProvider.notifier).toDataTypeDomains();
    final updated = project.copyWith(
      dataTypeDomains: domains,
      updatedAt: DateTime.now(),
    );
    ref.read(projectProvider.notifier).updateProject(updated);
  }
}
