# 代码生成

> **阅读时机**: 开发 DDL 生成、代码预览、模板管理功能时

---

## 功能概述

代码生成模块负责：
- 多数据库 DDL 生成
- Java 实体类生成
- 自定义模板支持
- 代码预览

---

## 模板引擎选择

| 引擎 | 优势 | 推荐度 |
|------|------|--------|
| **mustache** | Dart 原生支持、语法简单 | ⭐⭐⭐⭐⭐ |
| jinja | Python 风格 | ⭐⭐⭐ |
| 自定义 | 完全控制 | ⭐⭐⭐ |

### 使用 mustache_template

```yaml
# pubspec.yaml
dependencies:
  mustache_template: ^2.0.0
```

```dart
// lib/features/codegen/services/template_service.dart

import 'package:mustache_template/mustache_template.dart';

class TemplateService {
  /// 渲染模板
  String render(String template, Map<String, dynamic> context) {
    final tpl = Template(template, htmlEscapeValues: false);
    return tpl.renderString(context);
  }
}
```

---

## 数据库模板配置

### 模板结构

```dart
// lib/shared/models/database_template.dart

class DatabaseTemplateConfig {
  final String code;                  // MYSQL, ORACLE, POSTGRESQL
  final String name;
  final String createTableTemplate;
  final String deleteTableTemplate;
  final String rebuildTableTemplate;
  final String createFieldTemplate;
  final String updateFieldTemplate;
  final String deleteFieldTemplate;
  final String createIndexTemplate;
  final String deleteIndexTemplate;
}
```

### MySQL 建表模板示例

```dart
// lib/templates/ddl/mysql.dart

const String mysqlCreateTableTemplate = '''
{{#entity}}
CREATE TABLE `{{title}}` (
  {{#fields}}
  `{{name}}` {{typeDB}}{{#length}}({{length}}{{#decimal}},{{decimal}}{{/decimal}}){{/length}}
    {{#pk}} PRIMARY KEY{{/pk}}
    {{#notNull}} NOT NULL{{/notNull}}
    {{#autoIncrement}} AUTO_INCREMENT{{/autoIncrement}}
    {{#defaultValue}} DEFAULT '{{defaultValue}}'{{/defaultValue}}
    COMMENT '{{chnname}}'{{^lastField}},{{/lastField}}
  {{/fields}}
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='{{chnname}}';
{{/entity}}
''';
```

### Oracle 建表模板示例

```dart
const String oracleCreateTableTemplate = '''
{{#entity}}
CREATE TABLE {{title}} (
  {{#fields}}
  {{name}} {{typeDB}}{{#length}}({{length}}{{#decimal}},{{decimal}}{{/decimal}}){{/length}}
    {{#notNull}} NOT NULL{{/notNull}}
    {{#defaultValue}} DEFAULT {{defaultValue}}{{/defaultValue}}
    {{^lastField}},{{/lastField}}
  {{/fields}}
);

COMMENT ON TABLE {{title}} IS '{{chnname}}';
{{#fields}}
COMMENT ON COLUMN {{title}}.{{name}} IS '{{chnname}}';
{{/fields}}
{{/entity}}
''';
```

---

## 代码生成服务 (使用 Riverpod)

```dart
// lib/features/codegen/services/codegen_service.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'codegen_service.g.dart';

@riverpod
CodeGenService codeGenService(CodeGenServiceRef ref) {
  return CodeGenService(
    templateService: ref.watch(templateServiceProvider),
    dataTypeService: ref.watch(dataTypeServiceProvider),
  );
}

class CodeGenService {
  final TemplateService _templateService;
  final DataTypeService _dataTypeService;

  CodeGenService({
    required TemplateService templateService,
    required DataTypeService dataTypeService,
  })  : _templateService = templateService,
        _dataTypeService = dataTypeService;

  /// 生成建表 DDL
  String generateCreateTableDDL({
    required Entity entity,
    required String databaseCode,
  }) {
    final template = _getTemplate(databaseCode, 'createTable');
    final context = _buildContext(entity, databaseCode);
    return _templateService.render(template, context);
  }

  /// 生成删表 DDL
  String generateDeleteTableDDL({
    required Entity entity,
    required String databaseCode,
  }) {
    final template = _getTemplate(databaseCode, 'deleteTable');
    final context = _buildContext(entity, databaseCode);
    return _templateService.render(template, context);
  }

  /// 生成表结构变更 DDL
  String generateRebuildTableDDL({
    required Entity oldEntity,
    required Entity newEntity,
    required String databaseCode,
  }) {
    final template = _getTemplate(databaseCode, 'rebuildTable');
    final context = {
      ..._buildContext(newEntity, databaseCode),
      'oldTableName': oldEntity.title,
      'backupTableName': 'PDMAN_UP_${oldEntity.title}',
      'intersectFields': _getIntersectFields(oldEntity, newEntity),
    };
    return _templateService.render(template, context);
  }

  /// 生成所有表的 DDL
  String generateAllTablesDDL({
    required List<Entity> entities,
    required String databaseCode,
  }) {
    final buffer = StringBuffer();

    for (final entity in entities) {
      buffer.writeln(generateCreateTableDDL(
        entity: entity,
        databaseCode: databaseCode,
      ));
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// 构建模板上下文
  Map<String, dynamic> _buildContext(Entity entity, String databaseCode) {
    return {
      'entity': {
        'title': entity.title,
        'chnname': entity.chnname,
        'remark': entity.remark,
        'fields': entity.fields.asMap().entries.map((entry) {
          final index = entry.key;
          final f = entry.value;
          return {
            'name': f.name,
            'type': f.type,
            'typeDB': _dataTypeService.getMappedType(f.type, databaseCode),
            'chnname': f.chnname,
            'remark': f.remark,
            'pk': f.pk,
            'notNull': f.notNull,
            'autoIncrement': f.autoIncrement,
            'defaultValue': f.defaultValue,
            'length': f.length,
            'decimal': f.decimal,
            'lastField': index == entity.fields.length - 1,
          };
        }).toList(),
        'indexes': entity.indexes.map((i) {
          return {
            'name': i.name,
            'fields': i.fields,
            'type': i.type.name.toUpperCase(),
          };
        }).toList(),
      },
      'func': {
        'camel': _camel,
        'underline': _underline,
        'upperCase': (String s) => s.toUpperCase(),
        'lowerCase': (String s) => s.toLowerCase(),
      },
    };
  }

  String _camel(String str, [bool firstUpper = false]) {
    final parts = str.split('_');
    if (parts.isEmpty) return str;

    final result = StringBuffer();
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isEmpty) continue;

      if (i == 0 && !firstUpper) {
        result.write(part.toLowerCase());
      } else {
        result.write(part[0].toUpperCase());
        result.write(part.substring(1).toLowerCase());
      }
    }
    return result.toString();
  }

  String _underline(String str, [bool upper = false]) {
    final result = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      final char = str[i];
      if (i > 0 && char.toUpperCase() == char && char.toLowerCase() != char) {
        result.write('_');
      }
      result.write(upper ? char.toUpperCase() : char.toLowerCase());
    }
    return result.toString();
  }
}
```

---

## 代码预览组件 (使用 Riverpod)

```dart
// lib/features/codegen/widgets/code_preview.dart

class CodePreview extends ConsumerStatefulWidget {
  final Entity entity;
  final String initialDatabase;

  const CodePreview({
    required this.entity,
    required this.initialDatabase,
    super.key,
  });

  @override
  ConsumerState<CodePreview> createState() => _CodePreviewState();
}

class _CodePreviewState extends ConsumerState<CodePreview> {
  late String _selectedDatabase;
  String? _code;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDatabase = widget.initialDatabase;
    _generateCode();
  }

  void _generateCode() {
    setState(() => _isLoading = true);

    final service = ref.read(codeGenServiceProvider);
    _code = service.generateCreateTableDDL(
      entity: widget.entity,
      databaseCode: _selectedDatabase,
    );

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final databases = ref.watch(availableDatabasesProvider);

    return Column(
      children: [
        // 工具栏
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('数据库类型: '),
              const SizedBox(width: 8),
              DropdownButtonFormField<String>(
                value: _selectedDatabase,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                items: databases.map((db) {
                  return DropdownMenuItem(
                    value: db.code,
                    child: Text(db.name),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedDatabase = v!;
                    _generateCode();
                  });
                },
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: _copyCode,
                tooltip: '复制代码',
              ),
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: _downloadCode,
                tooltip: '下载文件',
              ),
            ],
          ),
        ),

        // 代码显示
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Card(
                  margin: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _code ?? '',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  void _copyCode() {
    if (_code == null) return;

    Clipboard.setData(ClipboardData(text: _code!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('代码已复制到剪贴板'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _downloadCode() async {
    if (_code == null) return;

    final path = await FilePicker.platform.saveFile(
      type: FileType.custom,
      allowedExtensions: ['sql'],
      dialogTitle: '保存SQL文件',
      fileName: '${widget.entity.title}_ddl.sql',
    );

    if (path != null) {
      final file = File(path);
      await file.writeAsString(_code!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SQL文件已保存: $path'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
```

---

## 模板编辑器

```dart
// lib/features/codegen/widgets/template_editor.dart

class TemplateEditor extends StatefulWidget {
  final DatabaseTemplateConfig template;
  final void Function(DatabaseTemplateConfig) onSave;
  
  @override
  State<TemplateEditor> createState() => _TemplateEditorState();
}

class _TemplateEditorState extends State<TemplateEditor> {
  late Map<String, TextEditingController> _controllers;
  
  @override
  void initState() {
    super.initState();
    _controllers = {
      'createTable': TextEditingController(text: widget.template.createTableTemplate),
      'deleteTable': TextEditingController(text: widget.template.deleteTableTemplate),
      'rebuildTable': TextEditingController(text: widget.template.rebuildTableTemplate),
      // ...
    };
  }
  
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 8,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: '建表语句'),
              Tab(text: '删表语句'),
              Tab(text: '表结构变更'),
              Tab(text: '新增字段'),
              Tab(text: '修改字段'),
              Tab(text: '删除字段'),
              Tab(text: '建索引'),
              Tab(text: '删索引'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: _controllers.entries.map((e) {
                return _buildTemplateEditor(e.key, e.value);
              }).toList(),
            ),
          ),
          // 保存按钮
          ButtonBar(
            children: [
              TextButton(child: Text('取消'), onPressed: () => Navigator.pop(context)),
              ElevatedButton(child: Text('保存'), onPressed: _save),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTemplateEditor(String key, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              style: TextStyle(fontFamily: 'monospace'),
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: '输入模板内容...',
              ),
            ),
          ),
          SizedBox(height: 8),
          // 模板变量帮助
          ExpansionTile(
            title: Text('模板变量参考'),
            children: [
              ListView(
                shrinkWrap: true,
                children: [
                  ListTile(title: Text('{{entity.title}} - 表代码')),
                  ListTile(title: Text('{{entity.chnname}} - 表中文名')),
                  ListTile(title: Text('{{#fields}}...{{/fields}} - 遍历字段')),
                  ListTile(title: Text('{{func.camel}} - 驼峰转换')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## 相关文档

- [数据类型系统](../datatype/README.md)
- [数据模型设计](../../data-model/README.md)