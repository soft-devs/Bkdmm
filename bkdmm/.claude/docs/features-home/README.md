# features/home - 首页模块

## 概述

应用首页，显示项目历史和快捷操作入口。

## 模块结构

```
home/
├── views/
│   └── home_view.dart     # 主视图 (478行)
└── widgets/
    ├── history_list_tile.dart  # 历史项目项
    └── quick_action_card.dart  # 快捷操作卡片
```

## 对外API

| 组件 | 说明 |
|------|------|
| HomeView | 首页主视图，ConsumerStatefulWidget |

## 核心功能

### HomeView

**功能**:
- 显示欢迎区域
- 快捷操作：新建项目、打开项目、导入
- 最近项目列表
- 设置入口

**状态依赖**:
- `historyNotifierProvider` - 项目历史
- `projectProvider` - 项目状态

**导航**:
- 点击"新建项目" → CreateProjectDialog
- 点击"打开项目" → OpenProjectDialog
- 打开历史项目 → WorkspaceView
- 设置按钮 → SettingsView

## 数据流

```
HomeView
├── 读取 historyNotifierProvider
│   └── 显示最近项目列表
├── 调用 projectProvider.createProject()
│   └── 导航到 WorkspaceView
└── 调用 projectProvider.openProject()
    └── 导航到 WorkspaceView
```

## 坑点

1. **创建项目状态**: `_isCreating` 状态用于防止重复点击
2. **历史列表为空**: 显示空状态提示
3. **项目打开失败**: 显示错误Toast

## 详细文档

- [data-model.md](data-model.md) - 数据结构
- [pitfalls.md](pitfalls.md) - 已知坑点