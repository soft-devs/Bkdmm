# shared/providers - 全局状态管理

## 概述

基于 Riverpod 的全局状态管理层，提供应用级和项目级的状态管理。

## 依赖

- `flutter_riverpod` - 状态管理框架
- `shared/services` - 存储服务
- `shared/models` - 数据模型
- `features/project` - 项目状态

## Provider 清单

| Provider | 类型 | 描述 |
|----------|------|------|
| settingsProvider | StateNotifierProvider | 应用全局设置 |
| projectNotifierProvider | StateNotifierProvider | 当前项目状态 (来自features/project) |
| projectSettingsProvider | StateNotifierProvider | 项目级设置 |
| historyProvider | StateNotifierProvider | 项目历史记录 |

## 详细文档

- [API文档](api-providers.md)
- [坑点与注意事项](pitfalls.md)
