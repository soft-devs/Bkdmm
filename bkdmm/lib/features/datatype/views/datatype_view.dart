import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../core/i18n/i18n.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/providers.dart';
import '../providers/datatype_provider.dart';
import '../dialogs/datatype_dialogs.dart';
import '../widgets/datatype_type_card.dart';

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
    final l10n = context.l10n;
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
            l10n.dataTypeManagement,
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
              l10n.typesCount(state.dataTypes.length),
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
                l10n.modified,
                font: tdTheme.fontBodySmall,
                textColor: tdTheme.brandNormalColor,
              ),
            ),
          const Spacer(),
          // Action buttons
          TDButton(
            text: l10n.restoreDefaults,
            theme: TDButtonTheme.defaultTheme,
            icon: TDIcons.history,
            onTap: () => showRestoreDefaultsDialog(context, ref, _updateProject),
          ),
          const SizedBox(width: 12),
          TDButton(
            text: l10n.addType,
            theme: TDButtonTheme.primary,
            icon: TDIcons.add,
            onTap: () => showAddDataTypeDialog(context, ref, _updateProject),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(TDThemeData tdTheme) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Search field
          Expanded(
            child: TDInput(
              hintText: l10n.searchTypes,
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
              l10n.defaultTypes,
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
              l10n.customTypes,
              theme: _showCustomTypes ? TDTagTheme.primary : TDTagTheme.defaultTheme,
              size: TDTagSize.medium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(TDThemeData tdTheme) {
    final l10n = context.l10n;
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
            l10n.noDataTypesFound,
            font: tdTheme.fontTitleMedium,
            textColor: tdTheme.fontGyColor2,
          ),
          const SizedBox(height: 8),
          TDText(
            l10n.restoreDefaultsHint,
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
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Default types section
        if (_showDefaultTypes && defaultTypes.isNotEmpty) ...[
          _buildSectionHeader(
            l10n.defaultTypes,
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
            l10n.customTypes,
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
    final isSelected = _selectedTypeId == type.id;

    return DataTypeCard(
      type: type,
      isSelected: isSelected,
      onTap: () {
        setState(() {
          _selectedTypeId = isSelected ? null : type.id;
        });
      },
      onAction: (selectedType, action) => _handleTypeAction(selectedType, action),
    );
  }

  void _handleTypeAction(DataType type, String action) {
    switch (action) {
      case 'edit':
        showEditDataTypeDialog(context, ref, type, _updateProject);
        break;
      case 'duplicate':
        _duplicateType(type);
        break;
      case 'delete':
        final project = ref.read(currentProjectProvider);
        final modules = project?.modules ?? [];
        showDeleteDataTypeDialog(context, ref, type, modules, _updateProject);
        break;
    }
  }

  void _duplicateType(DataType type) {
    ref.read(dataTypeNotifierProvider.notifier).duplicateDataType(type.id);
    _updateProject();
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
