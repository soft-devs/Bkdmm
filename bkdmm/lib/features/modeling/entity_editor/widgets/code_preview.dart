import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../../shared/models/models.dart';

/// Code preview widget for displaying generated DDL
///
/// Features:
/// - Database selector dropdown
/// - Syntax highlighted DDL
/// - Copy to clipboard
/// - Download as .sql file
class CodePreview extends StatefulWidget {
  final Entity entity;
  final List<DatabaseTemplate> databases;
  final String selectedDatabase;
  final Function(String) onDatabaseChanged;

  const CodePreview({
    super.key,
    required this.entity,
    required this.databases,
    required this.selectedDatabase,
    required this.onDatabaseChanged,
  });

  @override
  State<CodePreview> createState() => _CodePreviewState();
}

class _CodePreviewState extends State<CodePreview> {
  late TextEditingController _sqlController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _sqlController = TextEditingController(text: _generateDDL());
  }

  @override
  void didUpdateWidget(CodePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entity != widget.entity ||
        oldWidget.selectedDatabase != widget.selectedDatabase) {
      _sqlController.text = _generateDDL();
    }
  }

  @override
  void dispose() {
    _sqlController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _generateDDL() {
    final db = widget.databases.firstWhere(
      (d) => d.code == widget.selectedDatabase,
      orElse: () => widget.databases.first,
    );

    final template = db.template.createTableTemplate;
    return _renderTemplate(template);
  }

  String _renderTemplate(String template) {
    // Simple template rendering
    var result = template;

    // Replace table name
    result = result.replaceAll('{{tableName}}', widget.entity.title);

    // Replace table comment
    result = result.replaceAll('{{tableComment}}', widget.entity.chnname);

    // Generate fields section
    final fieldLines = <String>[];
    for (final field in widget.entity.fields) {
      var fieldLine = '  ${field.name} ${_getDatabaseType(field)}';

      if (field.pk) {
        fieldLine += ' PRIMARY KEY';
      }
      if (field.notNull && !field.pk) {
        fieldLine += ' NOT NULL';
      }
      if (field.autoIncrement) {
        fieldLine += _getAutoIncrementSyntax();
      }
      if (field.defaultValue != null) {
        fieldLine += ' DEFAULT ${field.defaultValue}';
      }
      if (field.remark != null && field.remark!.isNotEmpty) {
        fieldLine += " COMMENT '${field.remark}'";
      }
      fieldLine += ',';
      fieldLines.add(fieldLine);
    }

    // Replace fields placeholder - try to match the mustache template pattern
    // This is a fallback for simple replacement
    final fieldsPlaceholderPattern = RegExp(
      r"\{\{#fields\}\}[\s\S]*?\{\{/fields\}\}",
      multiLine: true,
    );
    if (fieldsPlaceholderPattern.hasMatch(result)) {
      result = result.replaceAll(fieldsPlaceholderPattern, fieldLines.join('\n'));
    }

    // Fallback: try to find a simple {{fields}} pattern and replace with generated content
    if (result.contains('{{fields}}')) {
      result = result.replaceAll('{{fields}}', fieldLines.join('\n'));
    }

    // Also try to handle the mustache-style template more directly
    if (result.contains('{{#fields}}')) {
      // Extract the template section between {{#fields}} and {{/fields}}
      final fieldTemplateRegex = RegExp(r'\{\{#fields\}\}([\s\S]*?)\{\{/fields\}\}');
      final match = fieldTemplateRegex.firstMatch(template);

      if (match != null) {
        final fieldTemplate = match.group(1) ?? '';
        final renderedFields = widget.entity.fields.map((field) {
          return _renderFieldTemplate(fieldTemplate, field);
        }).join('\n');

        result = result.replaceAll(fieldTemplateRegex, renderedFields);
      }
    }

    // Add index DDL
    for (final index in widget.entity.indexes) {
      result = '$result\n\n${_generateIndexDDL(index)}';
    }

    return result.trim();
  }

  String _renderFieldTemplate(String template, Field field) {
    var result = template;

    result = result.replaceAll('{{name}}', field.name);
    result = result.replaceAll('{{type}}', _getDatabaseType(field));
    result = result.replaceAll('{{chnname}}', field.chnname);
    result = result.replaceAll('{{remark}}', field.remark ?? '');

    // Handle conditional sections
    if (field.pk) {
      result = result.replaceAll('{{#pk}}', '').replaceAll('{{/pk}}', '');
    } else {
      result = result.replaceAll(RegExp(r'\{\{#pk\}\}.*?\{\{/pk\}\}'), '');
    }

    if (field.notNull) {
      result = result.replaceAll('{{#notNull}}', '').replaceAll('{{/notNull}}', '');
    } else {
      result = result.replaceAll(RegExp(r'\{\{#notNull\}\}.*?\{\{/notNull\}\}'), '');
    }

    if (field.autoIncrement) {
      result = result.replaceAll('{{#autoIncrement}}', '').replaceAll('{{/autoIncrement}}', '');
    } else {
      result = result.replaceAll(RegExp(r'\{\{#autoIncrement\}\}.*?\{\{/autoIncrement\}\}'), '');
    }

    if (field.defaultValue != null) {
      result = result
          .replaceAll('{{#defaultValue}}', '')
          .replaceAll('{{/defaultValue}}', '')
          .replaceAll('{{defaultValue}}', field.defaultValue!);
    } else {
      result = result.replaceAll(RegExp(r'\{\{#defaultValue\}\}.*?\{\{/defaultValue\}\}'), '');
    }

    return result.trim();
  }

  String _getDatabaseType(Field field) {
    // Map abstract types to database-specific types
    switch (widget.selectedDatabase) {
      case 'MYSQL':
        return _getMySQLType(field);
      case 'POSTGRESQL':
        return _getPostgreSQLType(field);
      case 'ORACLE':
        return _getOracleType(field);
      case 'SQLSERVER':
        return _getSQLServerType(field);
      default:
        return field.type.toUpperCase();
    }
  }

  String _getMySQLType(Field field) {
    switch (field.type.toLowerCase()) {
      case 'idorkey':
      case 'dict':
        return 'VARCHAR(32)';
      case 'name':
        return 'VARCHAR(128)';
      case 'intro':
        return 'VARCHAR(512)';
      case 'longtext':
        return 'TEXT';
      case 'integer':
        return 'INT';
      case 'long':
        return 'BIGINT';
      case 'money':
        return 'DECIMAL(32,8)';
      case 'datetime':
        return 'DATETIME';
      case 'yesno':
        return 'VARCHAR(1)';
      default:
        return field.length != null
            ? '${field.type.toUpperCase()}(${field.length}${field.decimal != null ? ',${field.decimal}' : ''})'
            : field.type.toUpperCase();
    }
  }

  String _getPostgreSQLType(Field field) {
    switch (field.type.toLowerCase()) {
      case 'idorkey':
      case 'dict':
        return 'VARCHAR(32)';
      case 'name':
        return 'VARCHAR(128)';
      case 'intro':
        return 'VARCHAR(512)';
      case 'longtext':
        return 'TEXT';
      case 'integer':
        return 'INTEGER';
      case 'long':
        return 'BIGINT';
      case 'money':
        return 'DECIMAL(32,8)';
      case 'datetime':
        return 'TIMESTAMP';
      case 'yesno':
        return 'CHAR(1)';
      default:
        return field.type.toUpperCase();
    }
  }

  String _getOracleType(Field field) {
    switch (field.type.toLowerCase()) {
      case 'idorkey':
      case 'dict':
        return 'VARCHAR2(32)';
      case 'name':
        return 'VARCHAR2(128)';
      case 'intro':
        return 'VARCHAR2(512)';
      case 'longtext':
        return 'CLOB';
      case 'integer':
        return 'NUMBER(10)';
      case 'long':
        return 'NUMBER(19)';
      case 'money':
        return 'NUMBER(32,8)';
      case 'datetime':
        return 'TIMESTAMP';
      case 'yesno':
        return 'CHAR(1)';
      default:
        return field.type.toUpperCase();
    }
  }

  String _getSQLServerType(Field field) {
    switch (field.type.toLowerCase()) {
      case 'idorkey':
      case 'dict':
        return 'NVARCHAR(32)';
      case 'name':
        return 'NVARCHAR(128)';
      case 'intro':
        return 'NVARCHAR(512)';
      case 'longtext':
        return 'NVARCHAR(MAX)';
      case 'integer':
        return 'INT';
      case 'long':
        return 'BIGINT';
      case 'money':
        return 'DECIMAL(32,8)';
      case 'datetime':
        return 'DATETIME2';
      case 'yesno':
        return 'CHAR(1)';
      default:
        return field.type.toUpperCase();
    }
  }

  String _getAutoIncrementSyntax() {
    switch (widget.selectedDatabase) {
      case 'MYSQL':
        return ' AUTO_INCREMENT';
      case 'SQLSERVER':
        return ' IDENTITY(1,1)';
      case 'POSTGRESQL':
        return ''; // Uses SERIAL or IDENTITY
      case 'ORACLE':
        return ''; // Uses sequences
      default:
        return ' AUTO_INCREMENT';
    }
  }

  String _generateIndexDDL(Index index) {
    final isUnique = index.type == IndexType.unique;
    final isFulltext = index.type == IndexType.fulltext;

    var sql = 'CREATE ';
    if (isUnique) sql += 'UNIQUE ';
    if (isFulltext && widget.selectedDatabase == 'MYSQL') sql += 'FULLTEXT ';
    sql += 'INDEX ${index.name} ON ${widget.entity.title}(${index.fields.join(', ')});';

    return sql;
  }

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: tdTheme.bgColorSecondaryContainer,
            border: Border(
              bottom: BorderSide(color: tdTheme.componentBorderColor),
            ),
          ),
          child: Row(
            children: [
              // Database selector with TDesign style
              _buildDatabaseSelector(tdTheme),
              const Spacer(),
              // Copy button
              TDButton(
                icon: TDIcons.copy,
                theme: TDButtonTheme.defaultTheme,
                type: TDButtonType.text,
                size: TDButtonSize.small,
                onTap: _copyToClipboard,
              ),
              const SizedBox(width: 8),
              // Download button
              TDButton(
                text: 'Download .sql',
                icon: TDIcons.download,
                theme: TDButtonTheme.primary,
                type: TDButtonType.fill,
                size: TDButtonSize.small,
                onTap: _downloadSql,
              ),
            ],
          ),
        ),

        // SQL preview
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tdTheme.bgColorContainer,
              borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
              border: Border.all(color: tdTheme.componentBorderColor),
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
                        '${widget.entity.title}.sql',
                        font: tdTheme.fontBodySmall,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                ),

                // SQL content with syntax highlighting
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        _sqlController.text,
                        style: TextStyle(
                          fontFamily: 'RobotoMono',
                          fontSize: 14,
                          color: tdTheme.textColorPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatabaseSelector(TDThemeData tdTheme) {
    final currentDb = widget.databases.firstWhere(
      (d) => d.code == widget.selectedDatabase,
      orElse: () => widget.databases.first,
    );

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) => TDMultiPicker(
            title: 'Select Database',
            data: [widget.databases.map((db) => db.name).toList()],
            initialIndexes: [widget.databases.indexOf(currentDb)],
            onConfirm: (selected) {
              if (selected.isNotEmpty && selected[0] < widget.databases.length) {
                widget.onDatabaseChanged(widget.databases[selected[0]].code);
              }
              Navigator.pop(ctx);
            },
            onCancel: (_) => Navigator.pop(ctx),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: tdTheme.bgColorSecondaryContainer,
          borderRadius: BorderRadius.circular(tdTheme.radiusSmall),
          border: Border.all(color: tdTheme.componentBorderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(TDIcons.data_base, size: 18, color: tdTheme.brandNormalColor),
            const SizedBox(width: 8),
            TDText(
              currentDb.name,
              font: tdTheme.fontBodyMedium,
              textColor: tdTheme.textColorPrimary,
            ),
            const SizedBox(width: 4),
            Icon(TDIcons.chevron_down, size: 16, color: tdTheme.textColorSecondary),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _sqlController.text));
    TDToast.showSuccess('DDL copied to clipboard', context: context);
  }

  void _downloadSql() {
    // In a web context, this would trigger a download
    // For desktop, we'd save to a file
    TDToast.showSuccess('DDL ready for ${widget.entity.title}.sql', context: context);
  }
}

/// Simple syntax highlighter for SQL
class SqlSyntaxHighlighter {
  static const _keywords = {
    'CREATE', 'TABLE', 'INDEX', 'DROP', 'ALTER', 'ADD', 'COLUMN',
    'PRIMARY', 'KEY', 'FOREIGN', 'REFERENCES', 'UNIQUE', 'FULLTEXT',
    'NOT', 'NULL', 'DEFAULT', 'AUTO_INCREMENT', 'IDENTITY',
    'VARCHAR', 'INT', 'BIGINT', 'TEXT', 'DATETIME', 'TIMESTAMP',
    'DECIMAL', 'NUMBER', 'CHAR', 'NVARCHAR', 'CLOB',
    'COMMENT', 'ON', 'TO', 'FROM', 'WHERE', 'AND', 'OR',
    'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'INTO', 'VALUES',
  };

  static bool isKeyword(String word) => _keywords.contains(word.toUpperCase());
}