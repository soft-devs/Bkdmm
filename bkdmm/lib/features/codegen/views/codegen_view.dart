import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/providers.dart';
import '../providers/codegen_provider.dart';
import '../services/codegen_service.dart';

/// Code generation view for DDL preview and export
///
/// Features:
/// - Database selector dropdown
/// - Entity/module/project tree selection
/// - DDL type selector (create/drop/alter)
/// - Syntax-highlighted SQL preview
/// - Copy to clipboard
/// - Download as .sql file
class CodegenView extends ConsumerStatefulWidget {
  /// Optional entity to pre-select
  final Entity? initialEntity;

  /// Optional module to pre-select
  final Module? initialModule;

  const CodegenView({
    super.key,
    this.initialEntity,
    this.initialModule,
  });

  @override
  ConsumerState<CodegenView> createState() => _CodegenViewState();
}

class _CodegenViewState extends ConsumerState<CodegenView> {
  final ScrollController _scrollController = ScrollController();
  late TextEditingController _sqlController;

  @override
  void initState() {
    super.initState();
    _sqlController = TextEditingController();

    // Initialize selection if provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialEntity != null) {
        ref.read(codegenProvider.notifier).selectEntity(widget.initialEntity!);
      } else if (widget.initialModule != null) {
        ref.read(codegenProvider.notifier).selectModule(widget.initialModule!);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _sqlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);
    final codegenState = ref.watch(codegenProvider);
    final project = ref.watch(currentProjectProvider);

    // Update SQL controller when DDL changes
    if (_sqlController.text != codegenState.generatedDdl) {
      _sqlController.text = codegenState.generatedDdl;
    }

    return Scaffold(
      body: Column(
        children: [
          // Toolbar
          _buildToolbar(tdTheme, codegenState, project),

          // Main content
          Expanded(
            child: project == null
                ? _buildEmptyState(tdTheme)
                : Row(
                    children: [
                      // Selection tree (left panel)
                      SizedBox(
                        width: 280,
                        child: _buildSelectionTree(tdTheme, project),
                      ),

                      // Divider
                      VerticalDivider(
                        width: 1,
                        color: tdTheme.componentStrokeColor,
                      ),

                      // Preview panel (right panel)
                      Expanded(
                        child: _buildPreviewPanel(tdTheme, codegenState),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Build toolbar with database selector and actions
  Widget _buildToolbar(
    TDThemeData tdTheme,
    CodegenState state,
    Project? project,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: tdTheme.bgColorContainer,
        border: Border(
          bottom: BorderSide(color: tdTheme.componentStrokeColor),
        ),
      ),
      child: Row(
        children: [
          // Database selector
          _buildDatabaseSelector(tdTheme, state),

          const SizedBox(width: 16),

          // DDL type selector
          _buildDdlTypeSelector(tdTheme, state),

          const Spacer(),

          // Copy button
          TDButton(
            icon: TDIcons.file_copy,
            onTap: state.hasOutput ? _copyToClipboard : null,
            theme: TDButtonTheme.defaultTheme,
            type: TDButtonType.outline,
            size: TDButtonSize.small,
          ),

          const SizedBox(width: 8),

          // Download button
          TDButton(
            onTap: state.hasOutput ? _downloadSql : null,
            icon: TDIcons.download,
            text: 'Download .sql',
            theme: TDButtonTheme.primary,
            type: TDButtonType.fill,
            size: TDButtonSize.small,
          ),

          const SizedBox(width: 8),

          // Export all button
          TDButton(
            onTap: project != null ? _exportAll : null,
            icon: TDIcons.download,
            text: 'Export All',
            theme: TDButtonTheme.defaultTheme,
            type: TDButtonType.outline,
            size: TDButtonSize.small,
          ),
        ],
      ),
    );
  }

  /// Build database selector dropdown using TDesign styled button
  Widget _buildDatabaseSelector(
    TDThemeData tdTheme,
    CodegenState state,
  ) {
    final databases = ref.watch(availableDatabasesProvider);
    final selectedDb = databases.firstWhere(
      (db) => db.code == state.selectedDatabase,
      orElse: () => databases.first,
    );

    return TDButton(
      onTap: () => _showDatabaseSelectorDialog(databases, state.selectedDatabase),
      type: TDButtonType.outline,
      theme: TDButtonTheme.defaultTheme,
      size: TDButtonSize.medium,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(TDIcons.data_base, size: 18, color: tdTheme.brandNormalColor),
          const SizedBox(width: 8),
          TDText(
            selectedDb.name,
            font: tdTheme.fontBodyMedium,
            textColor: tdTheme.textColorPrimary,
          ),
          const SizedBox(width: 4),
          Icon(TDIcons.chevron_down, size: 16, color: tdTheme.textColorSecondary),
        ],
      ),
    );
  }

  /// Show database selector dialog
  void _showDatabaseSelectorDialog(List<DatabaseTemplate> databases, String currentSelection) {
    final tdTheme = TDTheme.of(context);

    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: 'Select Database',
        content: '',
        contentWidget: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: databases.length,
            itemBuilder: (context, index) {
              final db = databases[index];
              final isSelected = db.code == currentSelection;
              final cellStyle = TDCellStyle(context: context);
              if (isSelected) {
                cellStyle.leftIconColor = tdTheme.brandNormalColor;
                cellStyle.rightIconColor = tdTheme.brandNormalColor;
              } else {
                cellStyle.leftIconColor = tdTheme.textColorSecondary;
              }

              return TDCell(
                leftIcon: TDIcons.data_base,
                title: db.name,
                description: db.code.toUpperCase(),
                arrow: false,
                onClick: (_) {
                  ref.read(codegenProvider.notifier).selectDatabase(db.code);
                  Navigator.pop(context);
                },
                rightIcon: isSelected ? TDIcons.check : null,
                style: cellStyle,
              );
            },
          ),
        ),
        leftBtn: TDDialogButtonOptions(
          title: 'Cancel',
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          action: () => Navigator.pop(context),
        ),
      ),
    );
  }

  /// Build DDL type selector using TDesign styled button
  Widget _buildDdlTypeSelector(
    TDThemeData tdTheme,
    CodegenState state,
  ) {
    return TDButton(
      onTap: () => _showDdlTypeSelectorDialog(state.ddlType),
      type: TDButtonType.outline,
      theme: TDButtonTheme.defaultTheme,
      size: TDButtonSize.medium,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(TDIcons.code, size: 18, color: tdTheme.brandNormalColor),
          const SizedBox(width: 8),
          TDText(
            _getDdlTypeLabel(state.ddlType),
            font: tdTheme.fontBodyMedium,
            textColor: tdTheme.textColorPrimary,
          ),
          const SizedBox(width: 4),
          Icon(TDIcons.chevron_down, size: 16, color: tdTheme.textColorSecondary),
        ],
      ),
    );
  }

  /// Get DDL type label
  String _getDdlTypeLabel(DdlType type) {
    switch (type) {
      case DdlType.createTable:
        return 'CREATE TABLE';
      case DdlType.dropTable:
        return 'DROP TABLE';
      case DdlType.createIndex:
        return 'CREATE INDEX';
      case DdlType.dropIndex:
        return 'DROP INDEX';
      case DdlType.alterTableAddColumn:
        return 'ALTER TABLE ADD';
      case DdlType.alterTableDropColumn:
        return 'ALTER TABLE DROP';
      case DdlType.alterTableModifyColumn:
        return 'ALTER TABLE MODIFY';
    }
  }

  /// Show DDL type selector dialog
  void _showDdlTypeSelectorDialog(DdlType currentSelection) {
    final tdTheme = TDTheme.of(context);

    final ddlTypes = [
      (DdlType.createTable, 'CREATE TABLE', 'Create new table'),
      (DdlType.dropTable, 'DROP TABLE', 'Drop existing table'),
      (DdlType.createIndex, 'CREATE INDEX', 'Create index on table'),
      (DdlType.dropIndex, 'DROP INDEX', 'Drop existing index'),
    ];

    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: 'Select DDL Type',
        content: '',
        contentWidget: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: ddlTypes.length,
            itemBuilder: (context, index) {
              final (type, label, description) = ddlTypes[index];
              final isSelected = type == currentSelection;
              final cellStyle = TDCellStyle(context: context);
              if (isSelected) {
                cellStyle.leftIconColor = tdTheme.brandNormalColor;
                cellStyle.rightIconColor = tdTheme.brandNormalColor;
              } else {
                cellStyle.leftIconColor = tdTheme.textColorSecondary;
              }

              return TDCell(
                leftIcon: TDIcons.code,
                title: label,
                description: description,
                arrow: false,
                onClick: (_) {
                  ref.read(codegenProvider.notifier).setDdlType(type);
                  Navigator.pop(context);
                },
                rightIcon: isSelected ? TDIcons.check : null,
                style: cellStyle,
              );
            },
          ),
        ),
        leftBtn: TDDialogButtonOptions(
          title: 'Cancel',
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          action: () => Navigator.pop(context),
        ),
      ),
    );
  }

  /// Build selection tree for entities/modules
  Widget _buildSelectionTree(
    TDThemeData tdTheme,
    Project project,
  ) {
    return Container(
      color: tdTheme.bgColorContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: tdTheme.componentStrokeColor),
              ),
            ),
            child: Row(
              children: [
                Icon(TDIcons.tree_square_dot, size: 20, color: tdTheme.brandNormalColor),
                const SizedBox(width: 8),
                TDText(
                  'Select Target',
                  font: tdTheme.fontTitleSmall,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),

          // Project root
          Expanded(
            child: ListView.builder(
              itemCount: project.modules.length + 1, // +1 for project root
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Project root node
                  return _buildProjectNode(tdTheme, project);
                }

                final moduleIndex = index - 1;
                final module = project.modules[moduleIndex];
                return _buildModuleNode(tdTheme, module);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build project root node using custom Row + TDText
  Widget _buildProjectNode(
    TDThemeData tdTheme,
    Project project,
  ) {
    final codegenState = ref.watch(codegenProvider);
    final isSelected = codegenState.generateProject;

    return InkWell(
      onTap: () {
        ref.read(codegenProvider.notifier).selectProject();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? tdTheme.brandLightColor : null,
        child: Row(
          children: [
            Icon(
              TDIcons.folder,
              size: 20,
              color: isSelected ? tdTheme.brandNormalColor : tdTheme.textColorSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TDText(
                'All Project (${project.modules.length} modules)',
                font: tdTheme.fontBodyMedium,
                textColor: isSelected ? tdTheme.brandNormalColor : tdTheme.textColorPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build module node with expandable entities using ExpansionTile with TDIcons
  Widget _buildModuleNode(
    TDThemeData tdTheme,
    Module module,
  ) {
    final codegenState = ref.watch(codegenProvider);
    final isModuleSelected = codegenState.selectedModule?.id == module.id;

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        leading: Icon(
          TDIcons.book,
          size: 20,
          color: isModuleSelected ? tdTheme.brandNormalColor : tdTheme.textColorSecondary,
        ),
        title: TDText(
          module.chnname,
          font: tdTheme.fontBodyMedium,
          textColor: isModuleSelected ? tdTheme.brandNormalColor : tdTheme.textColorPrimary,
          fontWeight: isModuleSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        subtitle: TDText(
          '${module.entities.length} tables',
          font: tdTheme.fontBodySmall,
          textColor: tdTheme.textColorSecondary,
        ),
        trailing: Icon(
          TDIcons.chevron_down,
          size: 20,
          color: tdTheme.textColorSecondary,
        ),
        initiallyExpanded: module.entities.isNotEmpty,
        children: module.entities.map((entity) {
          return _buildEntityTile(tdTheme, entity, module);
        }).toList(),
      ),
    );
  }

  /// Build entity tile using custom Row + TDText
  Widget _buildEntityTile(
    TDThemeData tdTheme,
    Entity entity,
    Module module,
  ) {
    final codegenState = ref.watch(codegenProvider);
    final isSelected = codegenState.selectedEntity?.id == entity.id;

    return InkWell(
      onTap: () {
        ref.read(codegenProvider.notifier).selectEntity(entity);
      },
      child: Container(
        padding: const EdgeInsets.only(left: 56, right: 16, top: 8, bottom: 8),
        color: isSelected ? tdTheme.brandLightColor : null,
        child: Row(
          children: [
            Icon(
              TDIcons.table,
              size: 18,
              color: isSelected ? tdTheme.brandNormalColor : tdTheme.textColorSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TDText(
                    entity.title,
                    font: tdTheme.fontBodyMedium,
                    textColor: isSelected ? tdTheme.brandNormalColor : tdTheme.textColorPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  TDText(
                    entity.chnname,
                    font: tdTheme.fontBodySmall,
                    textColor: tdTheme.textColorSecondary,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: tdTheme.grayColor1,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TDText(
                '${entity.fields.length}',
                font: tdTheme.fontMarkSmall,
                textColor: tdTheme.textColorSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build preview panel with syntax highlighting
  Widget _buildPreviewPanel(
    TDThemeData tdTheme,
    CodegenState state,
  ) {
    if (!state.hasOutput && !state.hasEntity && !state.hasModule && !state.generateProject) {
      return _buildNoSelectionState(tdTheme);
    }

    if (state.error != null) {
      return _buildErrorState(tdTheme, state);
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tdTheme.grayColor1,
        borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
        border: Border.all(color: tdTheme.componentStrokeColor),
      ),
      child: Column(
        children: [
          // File header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: tdTheme.bgColorSecondaryContainer,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(tdTheme.radiusDefault),
                topRight: Radius.circular(tdTheme.radiusDefault),
              ),
            ),
            child: Row(
              children: [
                Icon(TDIcons.code, size: 16, color: tdTheme.brandNormalColor),
                const SizedBox(width: 8),
                TDText(
                  _getFileName(state),
                  font: tdTheme.fontBodySmall,
                  fontWeight: FontWeight.w500,
                ),
                const Spacer(),
                TDText(
                  state.selectedDatabase,
                  font: tdTheme.fontMarkSmall,
                  textColor: tdTheme.textColorSecondary,
                ),
              ],
            ),
          ),

          // SQL content
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: _buildSqlContent(tdTheme, state),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build SQL content with syntax highlighting
  Widget _buildSqlContent(TDThemeData tdTheme, CodegenState state) {
    final fontSize = tdTheme.fontBodyMedium?.size ?? 14;
    return SelectableText.rich(
      TextSpan(
        children: _highlightSql(state.generatedDdl, tdTheme),
        style: TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: fontSize,
          color: tdTheme.textColorPrimary,
        ),
      ),
    );
  }

  /// Highlight SQL keywords
  List<TextSpan> _highlightSql(String sql, TDThemeData tdTheme) {
    final spans = <TextSpan>[];

    // Simple keyword highlighting
    final keywords = [
      'CREATE', 'TABLE', 'DROP', 'ALTER', 'ADD', 'COLUMN', 'MODIFY',
      'INDEX', 'UNIQUE', 'FULLTEXT', 'PRIMARY', 'KEY', 'FOREIGN',
      'REFERENCES', 'NOT', 'NULL', 'DEFAULT', 'AUTO_INCREMENT',
      'IDENTITY', 'AUTOINCREMENT', 'ENGINE', 'CHARSET', 'COMMENT',
      'ON', 'IF', 'EXISTS', 'INT', 'BIGINT', 'VARCHAR', 'NVARCHAR',
      'TEXT', 'DATETIME', 'TIMESTAMP', 'DATE', 'DECIMAL', 'NUMBER',
      'INTEGER', 'BOOLEAN', 'CLOB', 'BLOB', 'MAX', 'SERIAL',
    ];

    final lines = sql.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final words = line.split(RegExp(r'(\s+)'));

      for (var j = 0; j < words.length; j++) {
        final word = words[j];
        final isKeyword = keywords.contains(word.toUpperCase());

        if (isKeyword) {
          spans.add(TextSpan(
            text: word,
            style: TextStyle(color: tdTheme.brandNormalColor, fontWeight: FontWeight.w600),
          ));
        } else if (word.startsWith("'") && word.endsWith("'")) {
          // String/comment
          spans.add(TextSpan(
            text: word,
            style: TextStyle(color: tdTheme.warningNormalColor),
          ));
        } else if (word.startsWith('--') || word.startsWith('/*')) {
          // Comment
          spans.add(TextSpan(
            text: word,
            style: TextStyle(color: tdTheme.textColorSecondary),
          ));
        } else if (word.startsWith('`') && word.endsWith('`')) {
          // Quoted identifier
          spans.add(TextSpan(
            text: word,
            style: TextStyle(color: tdTheme.successNormalColor),
          ));
        } else {
          spans.add(TextSpan(text: word));
        }

        // Add the separator between words
        if (j < words.length - 1) {
          final separator = RegExp(r'(\s+)').firstMatch(line.substring(line.indexOf(word) + word.length))?.group(1) ?? ' ';
          spans.add(TextSpan(text: separator));
        }
      }

      // Add newline
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return spans;
  }

  /// Get file name based on selection
  String _getFileName(CodegenState state) {
    if (state.selectedEntity != null) {
      return '${state.selectedEntity!.title}.sql';
    } else if (state.selectedModule != null) {
      return '${state.selectedModule!.name}.sql';
    } else if (state.generateProject) {
      return 'project_ddl.sql';
    }
    return 'output.sql';
  }

  /// Build empty state when no project is loaded
  Widget _buildEmptyState(TDThemeData tdTheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            TDIcons.folder_open,
            size: 64,
            color: tdTheme.textColorSecondary,
          ),
          const SizedBox(height: 16),
          TDText(
            'No Project Loaded',
            font: tdTheme.fontTitleMedium,
            textColor: tdTheme.textColorSecondary,
          ),
          const SizedBox(height: 8),
          TDText(
            'Open a project to generate DDL',
            font: tdTheme.fontBodyMedium,
            textColor: tdTheme.textColorPlaceholder,
          ),
        ],
      ),
    );
  }

  /// Build no selection state
  Widget _buildNoSelectionState(TDThemeData tdTheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            TDIcons.gesture_click,
            size: 64,
            color: tdTheme.textColorSecondary,
          ),
          const SizedBox(height: 16),
          TDText(
            'Select a Target',
            font: tdTheme.fontTitleMedium,
            textColor: tdTheme.textColorSecondary,
          ),
          const SizedBox(height: 8),
          TDText(
            'Choose a table, module, or entire project',
            font: tdTheme.fontBodyMedium,
            textColor: tdTheme.textColorPlaceholder,
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(TDThemeData tdTheme, CodegenState state) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            TDIcons.close_circle,
            size: 64,
            color: tdTheme.errorNormalColor,
          ),
          const SizedBox(height: 16),
          TDText(
            'Generation Error',
            font: tdTheme.fontTitleMedium,
            textColor: tdTheme.errorNormalColor,
          ),
          const SizedBox(height: 8),
          TDText(
            state.error ?? 'Unknown error',
            font: tdTheme.fontBodyMedium,
            textColor: tdTheme.errorNormalColor,
          ),
          const SizedBox(height: 16),
          TDButton(
            onTap: () => ref.read(codegenProvider.notifier).refresh(),
            text: 'Retry',
            theme: TDButtonTheme.primary,
            type: TDButtonType.fill,
          ),
        ],
      ),
    );
  }

  /// Copy DDL to clipboard
  void _copyToClipboard() {
    final state = ref.read(codegenProvider);
    Clipboard.setData(ClipboardData(text: state.generatedDdl));
    TDToast.showSuccess('DDL copied to clipboard', context: context);
  }

  /// Download SQL file (placeholder - would use file_picker in real implementation)
  void _downloadSql() {
    final state = ref.read(codegenProvider);
    final fileName = _getFileName(state);

    TDToast.showText('Ready to download: $fileName', context: context);
  }

  /// Export all DDL for the project
  void _exportAll() {
    final project = ref.read(currentProjectProvider);
    if (project == null) return;

    ref.read(codegenProvider.notifier).selectProject();

    TDToast.showText('Generating DDL for ${project.modules.length} modules...', context: context);
  }
}
