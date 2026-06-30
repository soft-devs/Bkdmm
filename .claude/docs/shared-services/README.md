# shared/services - 服务层

## 概述

服务层提供本地存储、文件操作、项目管理等核心功能。

## 依赖

- `hive_flutter` - 本地存储
- `file_picker` - 文件选择
- `path_provider` - 路径处理
- `shared/models` - 数据模型

## 服务清单

| 服务 | 描述 | 关键方法 |
|------|------|----------|
| StorageService | Hive本地存储 | init(), saveSetting(), getSetting() |
| FileService | 文件读写 | saveProject(), readProject(), createBackup() |
| ProjectService | 项目操作 | createProject(), openProject(), saveProject() |
| HistoryService | 历史记录 | addHistory(), getHistoryList(), removeHistory() |

## 详细文档

- [API文档](api-services.md)
- [坑点与注意事项](pitfalls.md)