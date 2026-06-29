# 已知坑点

## 1. ID生成

**问题**: 直接使用字符串作为ID可能导致重复。

**解决方案**: 始终使用 `IdGenerator.generate()` 生成UUID。

```dart
// ❌ 错误
final entity = Entity(id: 'user_table', ...);

// ✅ 正确
final entity = Entity(id: IdGenerator.generate(), ...);
```

## 2. 不可变更新

**问题**: Dart模型是不可变的，直接赋值会报错。

**解决方案**: 使用 `copyWith()` 方法更新。

```dart
// ❌ 错误
entity.chnname = '新名称';

// ✅ 正确
final updated = entity.copyWith(
  chnname: '新名称',
  updatedAt: DateTime.now(),
);
```

## 3. 时间字段维护

**问题**: `createdAt` 和 `updatedAt` 不会自动更新。

**解决方案**: 创建时手动设置，更新时在 `copyWith()` 中更新 `updatedAt`。

```dart
// 创建
final now = DateTime.now();
final entity = Entity(
  id: id,
  title: 'user',
  chnname: '用户表',
  createdAt: now,
  updatedAt: now,
);

// 更新
final updated = entity.copyWith(
  chnname: '用户信息表',
  updatedAt: DateTime.now(),
);
```

## 4. JSON序列化生成

**问题**: 修改模型后未重新生成 `.g.dart` 文件导致序列化失败。

**解决方案**: 修改模型后运行：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 5. 空列表默认值

**问题**: 构造函数中列表参数默认值可能为null。

**解决方案**: 使用 `const []` 作为默认值。

```dart
// ✅ 正确
Entity({
  this.fields = const [],
  this.indexes = const [],
});
```

## 6. 字段类型验证

**问题**: `type` 字段是字符串，可能包含无效的类型名。

**解决方案**: 使用 `DataTypeDomains` 中定义的类型，或验证类型是否在支持列表中。

## 7. 模块与实体关联

**问题**: 实体的 `id` 变更后，模块中的引用未同步。

**解决方案**: 实体ID创建后不应修改。如需修改，必须同步更新所有引用。

## 8. 项目文件路径

**问题**: Windows路径使用反斜杠 `\`，跨平台保存时可能出问题。

**解决方案**: 使用 `path` 包处理路径，或统一使用正斜杠 `/`。
