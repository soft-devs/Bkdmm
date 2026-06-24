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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
          _buildToolbar(theme, colorScheme, codegenState, project),

          // Main content
          Expanded(
            child: project == null
                ? _buildEmptyState(theme, colorScheme)
                : Row(
                    children: [
                      // Selection tree (left panel)
                      SizedBox(
                        width: 280,
                        child: _buildSelectionTree(theme, colorScheme, project),
                      ),

                      // Divider
                      VerticalDivider(
                        width: 1,
                        color: colorScheme.outlineVariant,
                      ),

                      // Preview panel (right panel)
                      Expanded(
                        child: _buildPreviewPanel(theme, colorScheme, codegenState),
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
    ThemeData theme,
    ColorScheme colorScheme,
    CodegenState state,
    Project? project,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          // Database selector
          _buildDatabaseSelector(theme, colorScheme, state),

          const SizedBox(width: 16),

          // DDL type selector
          _buildDdlTypeSelector(theme, colorScheme, state),

          const Spacer(),

          // Copy button
          TDButton(
            icon: TDIcons.file_copy,
            onPressed: state.hasOutput ? _copyToClipboard : null,
            theme: TDButtonTheme.defaultTheme,
            type: TDButtonType.outline,
            size: TDButtonSize.small,
          ),

          const SizedBox(width: 8),

          // Download button
          TDButton(
            onPressed: state.hasOutput ? _downloadSql : null,
            icon: TDIcons.download,
            text: 'Download .sql',
            theme: TDButtonTheme.primary,
            type: TDButtonType.fill,
            size: TDButtonSize.small,
          ),

          const SizedBox(width: 8),

          // Export all button
          TDButton(
            onPressed: project != null ? _exportAll : null,
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

  /// Build database selector dropdown
  Widget _buildDatabaseSelector(
    ThemeData theme,
    ColorScheme colorScheme,
    CodegenState state,
  ) {
    final databases = ref.watch(availableDatabasesProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: DropdownButton<String>(
        value: state.selectedDatabase,
        items: databases.map((db) {
          return DropdownMenuItem(
            value: db.code,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(TDIcons.storage, size: 18),
                const SizedBox(width: 8),
                Text(db.name),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            ref.read(codegenProvider.notifier).selectDatabase(value);
          }
        },
        underline: const SizedBox(),
        borderRadius: BorderRadius.circular(8),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  /// Build DDL type selector
  Widget _buildDdlTypeSelector(
    ThemeData theme,
    ColorScheme colorScheme,
    CodegenState state,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: DropdownButton<DdlType>(
        value: state.ddlType,
        items: const [
          DropdownMenuItem(
            value: DdlType.createTable,
            child: Text('CREATE TABLE'),
          ),
          DropdownMenuItem(
            value: DdlType.dropTable,
            child: Text('DROP TABLE'),
          ),
          DropdownMenuItem(
            value: DdlType.createIndex,
            child: Text('CREATE INDEX'),
          ),
          DropdownMenuItem(
            value: DdlType.dropIndex,
            child: Text('DROP INDEX'),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            ref.read(codegenProvider.notifier).setDdlType(value);
          }
        },
        underline: const SizedBox(),
        borderRadius: BorderRadius.circular(8),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  /// Build selection tree for entities/modules
  Widget _buildSelectionTree(
    ThemeData theme,
    ColorScheme colorScheme,
    Project project,
  ) {
    return Container(
      color: colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Icon(TDIcons.tree, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Select Target',
                  style: theme.textTheme.titleSmall,
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
                  return _buildProjectNode(theme, colorScheme, project);
                }

                final moduleIndex = index - 1;
                final module = project.modules[moduleIndex];
                return _buildModuleNode(theme, colorScheme, module);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build project root node
  Widget _buildProjectNode(
    ThemeData theme,
    ColorScheme colorScheme,
    Project project,
  ) {
    final codegenState = ref.watch(codegenProvider);
    final isSelected = codegenState.generateProject;

    return ListTile(
      leading: Icon(
        TDIcons.folder,
        size: 20,
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        'All Project (${project.modules.length} modules)',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isSelected ? colorScheme.primary : null,
          fontWeight: isSelected ? FontWeight.w600 : null,
        ),
      ),
      selected: isSelected,
      selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.2),
      onTap: () {
        ref.read(codegenProvider.notifier).selectProject();
      },
    );
  }

  /// Build module node with expandable entities
  Widget _buildModuleNode(
    ThemeData theme,
    ColorScheme colorScheme,
    Module module,
  ) {
    final codegenState = ref.watch(codegenProvider);
    final isModuleSelected = codegenState.selectedModule?.id == module.id;

    return ExpansionTile(
      leading: Icon(
        TDIcons.books,
        size: 20,
        color: isModuleSelected
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        module.chnname,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isModuleSelected ? colorScheme.primary : null,
          fontWeight: isModuleSelected ? FontWeight.w600 : null,
        ),
      ),
      subtitle: Text(
        '${module.entities.length} tables',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      initiallyExpanded: module.entities.isNotEmpty,
      children: module.entities.map((entity) {
        return _buildEntityTile(theme, colorScheme, entity, module);
      }).toList(),
    );
  }

  /// Build entity tile
  Widget _buildEntityTile(
    ThemeData theme,
    ColorScheme colorScheme,
    Entity entity,
    Module module,
  ) {
    final codegenState = ref.watch(codegenProvider);
    final isSelected = codegenState.selectedEntity?.id == entity.id;

    return ListTile(
      leading: Icon(
        TDIcons.table,
        size: 18,
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        entity.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isSelected ? colorScheme.primary : null,
          fontWeight: isSelected ? FontWeight.w600 : null,
        ),
      ),
      subtitle: Text(
        entity.chnname,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Text(
        '${entity.fields.length}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.outline,
        ),
      ),
      selected: isSelected,
      selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.2),
      dense: true,
      onTap: () {
        ref.read(codegenProvider.notifier).selectEntity(entity);
      },
    );
  }

  /// Build preview panel with syntax highlighting
  Widget _buildPreviewPanel(
    ThemeData theme,
    ColorScheme colorScheme,
    CodegenState state,
  ) {
    if (!state.hasOutput && !state.hasEntity && !state.hasModule && !state.generateProject) {
      return _buildNoSelectionState(theme, colorScheme);
    }

    if (state.error != null) {
      return _buildErrorState(theme, colorScheme, state);
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          // File header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(TDIcons.code, size: 16, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  _getFileName(state),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  state.selectedDatabase,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
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
                child: _buildSqlContent(theme, state),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build SQL content with syntax highlighting
  Widget _buildSqlContent(ThemeData theme, CodegenState state) {
    return RichText(
      text: TextSpan(
        children: _highlightSql(state.generatedDdl, theme),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'RobotoMono',
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  /// Highlight SQL keywords
  List<TextSpan> _highlightSql(String sql, ThemeData theme) {
    final colorScheme = theme.colorScheme;
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
            style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
          ));
        } else if (word.startsWith("'") && word.endsWith("'")) {
          // String/comment
          spans.add(TextSpan(
            text: word,
            style: TextStyle(color: colorScheme.secondary),
          ));
        } else if (word.startsWith('--') || word.startsWith('/*')) {
          // Comment
          spans.add(TextSpan(
            text: word,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ));
        } else if (word.startsWith('`') && word.endsWith('`')) {
          // Quoted identifier
          spans.add(TextSpan(
            text: word,
            style: TextStyle(color: colorScheme.tertiary),
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
  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            TDIcons.folder_open,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Project Loaded',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Open a project to generate DDL',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  /// Build no selection state
  Widget _buildNoSelectionState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            TDIcons.touch_app,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a Target',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a table, module, or entire project',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(ThemeData theme, ColorScheme colorScheme, CodegenState state) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            TDIcons.close_circle,
            size: 64,
            color: colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Generation Error',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.error ?? 'Unknown error',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 16),
          TDButton(
            onPressed: () => ref.read(codegenProvider.notifier).refresh(),
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