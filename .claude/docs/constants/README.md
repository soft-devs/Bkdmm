# constants - 默认常量

## 概述

应用默认配置常量，主要是默认数据类型定义。

## 文件

| 文件 | 描述 |
|------|------|
| default_data_types.dart | 默认数据类型配置 |
| app_constants.dart | 应用常量 |

## DefaultDataTypes

提供内置的数据类型配置，用于新项目初始化。

```dart
static final List<DataType> defaultTypes = [
  DataType(id: '1', name: 'IdOrKey', chnname: '标识键'),
  DataType(id: '2', name: 'Name', chnname: '名称'),
  DataType(id: '3', name: 'String', chnname: '字符串'),
  DataType(id: '4', name: 'Integer', chnname: '整数'),
  DataType(id: '5', name: 'Long', chnname: '长整数'),
  DataType(id: '6', name: 'DateTime', chnname: '日期时间'),
  // ...
];
```

## 使用方法

```dart
// 获取默认数据类型
final types = DefaultDataTypes.defaultTypes;

// 创建新项目时使用
final project = Project(
  dataTypeDomains: DataTypeDomains(
    datatype: DefaultDataTypes.defaultTypes,
  ),
);
```