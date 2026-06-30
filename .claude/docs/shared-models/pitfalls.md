# 坑点与注意事项

## 1. ID唯一性

**问题**: Entity/Field/Index 的 ID 必须唯一，否则会导致数据混乱。

**解决方案**:
```dart
// 正确做法：使用 IdGenerator 生成唯一ID
final field = Field(
  id: IdGenerator.generate(), // 使用 ID 生成器
  name: 'user_id',
  // ...
);

// 错误做法：硬编码或使用空字符串
final field = Field(
  id: '', // ❌ 空 ID 会导致问题
  name: 'user_id',
);
```

**验证方法**:
```dart
// 验证模块内所有ID
if (!module.validateAllIds()) {
  // 自动修复
  module = module.fixAllIds();
}
```

## 2. JSON序列化依赖

**问题**: 修改模型后需要重新生成 `.g.dart` 文件。

**解决方案**:
```bash
# 修改模型后执行
cd bkdmm
flutter pub run build_runner build --delete-conflicting-outputs
```

## 3. copyWith 模式

**问题**: 模型是不可变的，修改字段必须使用 `copyWith`。

```dart
// 正确做法
final updatedEntity = entity.copyWith(
  chnname: '新名称',
  updatedAt: DateTime.now(),
);

// 错误做法：尝试直接修改
entity.chnname = '新名称'; // ❌ 编译错误
```

## 4. GraphCanvas 节点格式

**问题**: GraphNode.title 格式为 `表名:序号`，不是表ID。

```dart
// 正确格式
GraphNode(title: 'user:1', x: 100, y: 200)

// 错误格式
GraphNode(title: 'entity_id_123', x: 100, y: 200) // ❌
```

## 5. Field.type 是抽象类型

**问题**: Field.type 存储的是 DataType 的 code，不是数据库具体类型。

```dart
// 正确做法：通过 DataTypeDomains 转换
final dbType = dataType.getDatabaseType('MYSQL');

// 错误做法
if (field.type == 'VARCHAR') { // ❌ 这是数据库类型
  // ...
}

// 正确做法
if (field.type == 'String') { // ✅ 这是抽象类型
  final mysqlType = dataTypeDomains.datatype
    .firstWhere((t) => t.name == 'String')
    .getDatabaseType('MYSQL'); // VARCHAR
}
```

## 6. Index.fieldIds 存储的是字段ID

**问题**: Index.fieldIds 存储的是 Field.id，不是 Field.name。

```dart
// 获取索引字段名列表
final fieldNames = index.getFieldNames(entity.fields);

// 不要直接使用 fieldIds 作为字段名
for (final fieldId in index.fieldIds) {
  // fieldId 是 UUID，不是字段名
}
```

## 7. Module.entities 和 GraphCanvas.nodes 的关系

**问题**: 两者需要保持同步，但不是直接关联。

- `Module.entities` - 实际的数据表定义
- `Module.graphCanvas.nodes` - ER图上的节点位置

**坑点**: 删除 Entity 后需要同时更新 GraphCanvas.nodes。

```dart
// 删除表时的正确做法
final updatedEntities = module.entities.where((e) => e.id != entityId).toList();
final updatedNodes = module.graphCanvas.nodes.where((n) {
  // 节点格式是 "表名:序号"，需要匹配表名
  final tableName = n.title.split(':').first;
  return !deletedEntities.any((e) => e.title == tableName);
}).toList();
```

## 8. DateTime 序列化

**问题**: DateTime 在 JSON 序列化时会转为 ISO 8601 字符串。

```dart
// 存储时
final json = project.toJson();
// json['createdAt'] = "2024-01-15T10:30:00.000Z"

// 读取时自动转换
final restored = Project.fromJson(json);
// restored.createdAt 是 DateTime 对象
```

## 9. 空模块处理

**问题**: Module.empty 提供空实例，但 ID 为空字符串。

```dart
// 用于初始化或占位
final emptyModule = Module.empty;

// 不要直接使用 empty 模块
if (module.id.isEmpty) {
  // 生成新 ID
  module = module.copyWith(id: IdGenerator.generate());
}
```

## 10. Profile.defaultFieldsType

**问题**: defaultFieldsType 存储的是 DataType 的 ID，不是类型名称。

```dart
// 正确理解
profile.defaultFieldsType = '1'; // DataType.id = '1' (通常是主键类型)

// 获取具体类型
final defaultType = dataTypeDomains.datatype
  .firstWhere((t) => t.id == profile.defaultFieldsType);
```
