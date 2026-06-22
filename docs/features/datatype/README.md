# 数据类型系统

> **阅读时机**: 开发数据类型配置、类型映射功能时

---

## 功能概述

数据类型系统定义抽象数据类型，映射到各数据库具体类型：

```
抽象类型(IdOrKey) → MYSQL: VARCHAR(32)
                  → ORACLE: VARCHAR2(32)
                  → JAVA: String
```

---

## 数据模型

```dart
// lib/shared/models/data_type.dart

class DataType {
  final String id;
  final String code;                  // 类型代码(唯一标识)
  final String chnname;               // 类型中文名
  final String? remark;
  final Map<String, String> apply;    // 各数据库映射
  final String? java;                 // Java类型映射
  
  DataType({
    required this.id,
    required this.code,
    required this.chnname,
    this.remark,
    required this.apply,
    this.java,
  });
  
  /// 获取指定数据库的类型映射
  String? getMappedType(String databaseCode) {
    return apply[databaseCode];
  }
}
```

---

## 预设数据类型

```dart
// lib/shared/constants/default_data_types.dart

const List<DataType> defaultDataTypes = [
  DataType(
    code: 'IdOrKey',
    chnname: '标识键',
    apply: {
      'MYSQL': 'VARCHAR(32)',
      'ORACLE': 'VARCHAR2(32)',
      'POSTGRESQL': 'VARCHAR(32)',
      'SQLSERVER': 'NVARCHAR(32)',
      'SQLITE': 'VARCHAR(32)',
    },
    java: 'String',
  ),
  DataType(
    code: 'Name',
    chnname: '名称',
    apply: {
      'MYSQL': 'VARCHAR(128)',
      'ORACLE': 'VARCHAR2(128)',
      'POSTGRESQL': 'VARCHAR(128)',
      'SQLSERVER': 'NVARCHAR(128)',
      'SQLITE': 'VARCHAR(128)',
    },
    java: 'String',
  ),
  DataType(
    code: 'Intro',
    chnname: '简介',
    apply: {
      'MYSQL': 'VARCHAR(512)',
      'ORACLE': 'VARCHAR2(512)',
      'POSTGRESQL': 'VARCHAR(512)',
      'SQLSERVER': 'NVARCHAR(512)',
      'SQLITE': 'VARCHAR(512)',
    },
    java: 'String',
  ),
  DataType(
    code: 'LongText',
    chnname: '长文本',
    apply: {
      'MYSQL': 'TEXT',
      'ORACLE': 'CLOB',
      'POSTGRESQL': 'TEXT',
      'SQLSERVER': 'NVARCHAR(MAX)',
      'SQLITE': 'TEXT',
    },
    java: 'String',
  ),
  DataType(
    code: 'Integer',
    chnname: '整数',
    apply: {
      'MYSQL': 'INT',
      'ORACLE': 'NUMBER(10)',
      'POSTGRESQL': 'INTEGER',
      'SQLSERVER': 'INT',
      'SQLITE': 'INTEGER',
    },
    java: 'Integer',
  ),
  DataType(
    code: 'Long',
    chnname: '长整数',
    apply: {
      'MYSQL': 'BIGINT',
      'ORACLE': 'NUMBER(19)',
      'POSTGRESQL': 'BIGINT',
      'SQLSERVER': 'BIGINT',
      'SQLITE': 'INTEGER',
    },
    java: 'Long',
  ),
  DataType(
    code: 'Money',
    chnname: '金额',
    apply: {
      'MYSQL': 'DECIMAL(32,8)',
      'ORACLE': 'NUMBER(32,8)',
      'POSTGRESQL': 'DECIMAL(32,8)',
      'SQLSERVER': 'DECIMAL(32,8)',
      'SQLITE': 'DECIMAL(32,8)',
    },
    java: 'BigDecimal',
  ),
  DataType(
    code: 'DateTime',
    chnname: '日期时间',
    apply: {
      'MYSQL': 'DATETIME',
      'ORACLE': 'TIMESTAMP',
      'POSTGRESQL': 'TIMESTAMP',
      'SQLSERVER': 'DATETIME2',
      'SQLITE': 'TEXT',
    },
    java: 'LocalDateTime',
  ),
  DataType(
    code: 'YesNo',
    chnname: '是否',
    apply: {
      'MYSQL': 'VARCHAR(1)',
      'ORACLE': 'VARCHAR2(1)',
      'POSTGRESQL': 'VARCHAR(1)',
      'SQLSERVER': 'NVARCHAR(1)',
      'SQLITE': 'VARCHAR(1)',
    },
    java: 'String',
  ),
  DataType(
    code: 'Dict',
    chnname: '字典',
    apply: {
      'MYSQL': 'VARCHAR(32)',
      'ORACLE': 'VARCHAR2(32)',
      'POSTGRESQL': 'VARCHAR(32)',
      'SQLSERVER': 'NVARCHAR(32)',
      'SQLITE': 'VARCHAR(32)',
    },
    java: 'String',
  ),
];
```

---

## 数据类型服务 (使用 Riverpod)

```dart
// lib/features/datatype/services/datatype_service.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'datatype_service.g.dart';

@riverpod
DataTypeService dataTypeService(DataTypeServiceRef ref) {
  final project = ref.watch(projectNotifierProvider).project;
  return DataTypeService(
    dataTypes: project?.dataTypeDomains.datatype ?? defaultDataTypes,
  );
}

class DataTypeService {
  final List<DataType> _dataTypes;

  DataTypeService({required List<DataType> dataTypes}) : _dataTypes = dataTypes;

  /// 获取数据类型列表
  List<DataType> getAll() => List.unmodifiable(_dataTypes);

  /// 根据代码获取数据类型
  DataType? getByCode(String code) {
    try {
      return _dataTypes.firstWhere((dt) => dt.code == code);
    } catch (e) {
      return null;
    }
  }

  /// 获取类型映射
  String getMappedType(String dataTypeCode, String databaseCode) {
    final dataType = getByCode(dataTypeCode);
    if (dataType == null) {
      throw DataTypeException('数据类型不存在: $dataTypeCode');
    }

    final mapped = dataType.apply[databaseCode];
    if (mapped == null) {
      throw DataTypeException('数据库类型映射不存在: $databaseCode');
    }

    return mapped;
  }

  /// 新增数据类型
  void add(DataType dataType) {
    if (_dataTypes.any((dt) => dt.code == dataType.code)) {
      throw DataTypeException('数据类型代码已存在: ${dataType.code}');
    }
    _dataTypes.add(dataType);
  }

  /// 更新数据类型
  void update(DataType dataType) {
    final index = _dataTypes.indexWhere((dt) => dt.id == dataType.id);
    if (index == -1) {
      throw DataTypeException('数据类型不存在: ${dataType.id}');
    }
    _dataTypes[index] = dataType;
  }

  /// 删除数据类型
  void delete(String code) {
    _dataTypes.removeWhere((dt) => dt.code == code);
  }

  /// 检查类型是否被使用
  bool isTypeUsed(String code, List<Entity> entities) {
    for (final entity in entities) {
      if (entity.fields.any((f) => f.type == code)) {
        return true;
      }
    }
    return false;
  }
}

// 自定义异常
class DataTypeException implements Exception {
  final String message;
  const DataTypeException(this.message);

  @override
  String toString() => 'DataTypeException: $message';
}
```

---

## UI 组件 (使用 Riverpod + Freezed)

### 数据类型列表

```dart
// lib/features/datatype/views/datatype_list.dart

class DataTypeListView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataTypes = ref.watch(dataTypeServiceProvider).getAll();
    final project = ref.watch(projectNotifierProvider).project;

    return Scaffold(
      body: Column(
        children: [
          // 工具栏
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '数据类型管理',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('新增'),
                  onPressed: () => _showAddDialog(context, ref),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.restore),
                  label: const Text('恢复默认'),
                  onPressed: () => _confirmRestoreDefaults(context, ref),
                ),
              ],
            ),
          ),

          // 列表
          Expanded(
            child: dataTypes.isEmpty
                ? const Center(child: Text('暂无数据类型'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: dataTypes.length,
                    itemBuilder: (context, index) {
                      return _buildDataTypeCard(context, ref, dataTypes[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTypeCard(
    BuildContext context,
    WidgetRef ref,
    DataType dt,
  ) {
    final entities = ref.watch(allEntitiesProvider);
    final isUsed = ref.watch(dataTypeServiceProvider).isTypeUsed(dt.code, entities);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(
          Icons.data_object,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(dt.chnname),
        subtitle: Text(dt.code),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditDialog(context, ref, dt),
              tooltip: '编辑',
            ),
            IconButton(
              icon: Icon(
                Icons.delete,
                color: isUsed ? Colors.grey : Colors.red,
              ),
              onPressed: isUsed
                  ? null
                  : () => _confirmDelete(context, ref, dt),
              tooltip: isUsed ? '类型正在使用中，无法删除' : '删除',
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '数据库映射:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...dt.apply.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(e.key),
                      ),
                      const Text('→'),
                      const SizedBox(width: 8),
                      Text(
                        e.value,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                )),
                if (dt.java != null) ...[
                  const SizedBox(height: 8),
                  Text('Java类型: ${dt.java}'),
                ],
                if (dt.remark != null) ...[
                  const SizedBox(height: 8),
                  Text('备注: ${dt.remark}'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 数据类型编辑对话框 (使用 Freezed 模型)

```dart
// lib/features/datatype/views/datatype_edit_dialog.dart

class DataTypeEditDialog extends ConsumerStatefulWidget {
  final DataType? dataType;

  const DataTypeEditDialog({this.dataType, super.key});

  @override
  ConsumerState<DataTypeEditDialog> createState() => _DataTypeEditDialogState();
}

class _DataTypeEditDialogState extends ConsumerState<DataTypeEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _chnnameController;
  late TextEditingController _remarkController;
  late TextEditingController _javaController;
  late Map<String, TextEditingController> _applyControllers;

  final List<String> _databaseCodes = [
    'MYSQL',
    'ORACLE',
    'POSTGRESQL',
    'SQLSERVER',
    'SQLITE',
  ];

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.dataType?.code ?? '');
    _chnnameController = TextEditingController(text: widget.dataType?.chnname ?? '');
    _remarkController = TextEditingController(text: widget.dataType?.remark ?? '');
    _javaController = TextEditingController(text: widget.dataType?.java ?? '');

    _applyControllers = {};
    for (final code in _databaseCodes) {
      _applyControllers[code] = TextEditingController(
        text: widget.dataType?.apply[code] ?? '',
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _chnnameController.dispose();
    _remarkController.dispose();
    _javaController.dispose();
    for (final controller in _applyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.dataType == null ? '新增数据类型' : '编辑数据类型'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: '类型代码 *',
                  hintText: '例如: IdOrKey',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return '必填';
                  if (RegExp(r'[^a-zA-Z0-9]').hasMatch(v)) return '只能包含英文字母和数字';
                  return null;
                },
              ),
              TextFormField(
                controller: _chnnameController,
                decoration: const InputDecoration(
                  labelText: '类型名称 *',
                  hintText: '例如: 标识键',
                ),
                validator: (v) => v == null || v.isEmpty ? '必填' : null,
              ),
              TextFormField(
                controller: _remarkController,
                decoration: const InputDecoration(
                  labelText: '备注',
                  hintText: '类型说明',
                ),
              ),
              TextFormField(
                controller: _javaController,
                decoration: const InputDecoration(
                  labelText: 'Java类型',
                  hintText: '例如: String',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '数据库映射:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ..._databaseCodes.map((code) {
                return TextFormField(
                  controller: _applyControllers[code],
                  decoration: InputDecoration(
                    labelText: code,
                    hintText: '例如: VARCHAR(32)',
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('保存'),
        ),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final apply = <String, String>{};
    for (final code in _databaseCodes) {
      if (_applyControllers[code]!.text.isNotEmpty) {
        apply[code] = _applyControllers[code]!.text;
      }
    }

    final dataType = DataType(
      id: widget.dataType?.id ?? const Uuid().v4(),
      code: _codeController.text,
      chnname: _chnnameController.text,
      remark: _remarkController.text.isEmpty ? null : _remarkController.text,
      apply: apply,
      java: _javaController.text.isEmpty ? null : _javaController.text,
    );

    Navigator.pop(context, dataType);
  }
}
```

---

## 相关文档

- [代码生成](../codegen/README.md)
- [数据模型设计](../../data-model/README.md)