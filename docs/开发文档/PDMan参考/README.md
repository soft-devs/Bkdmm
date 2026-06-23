# PDMan 参考文档

> 原项目: https://github.com/pdman/pdman
> 技术栈: Electron + React + G6

---

## 模块参考

| 模块 | 描述 | 文档 |
|------|------|------|
| components | UI组件库 | [components.md](components.md) |
| utils | 工具函数 | [utils.md](utils.md) |
| table | 表编辑器 | [table.md](table.md) |
| relation | 关系图 | [relation.md](relation.md) |
| database | 数据库模板 | [database.md](database.md) |
| datatype | 数据类型 | [datatype.md](datatype.md) |
| module | 模块管理 | [module.md](module.md) |
| main-app | 主应用 | [main-app.md](main-app.md) |
| config | 构建配置 | [config.md](config.md) |
| bin | 启动脚本 | [bin.md](bin.md) |

---

## 关键参考

### 关系图

原项目用 G6，Flutter 需自研 CustomPainter

### 代码生成

原项目用 doT.js，Flutter 用 mustache_template

---

## 已知坑点

1. 表名不能包含 `/`、`&`、`:`
2. 节点标题格式: `表名:序号`
3. G6 版本锁定 1.2.8