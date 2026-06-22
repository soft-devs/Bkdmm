# Main-App - 主应用

## 概述

主应用模块，包含首页项目管理、主工作区、设置面板、加载界面等核心页面组件。是用户交互的入口层。

## 文件结构

```
app/
├── index.js       # 主应用组件(App)
├── Home.js        # 首页(项目管理)
├── Header.js      # 标题栏
├── Setting.js     # 设置面板
├── Loading.js     # 加载界面
├── CreatePro.js   # 创建项目弹窗
├── ExportImg.js   # 导出图片配置
└── defaultData.json # 默认数据配置
└── style/         # 样式文件
```

## 核心组件

### App (index.js)

主工作区组件，管理左侧导航树、Tab工作区、工具栏等。

**Props**:
| 属性 | 类型 | 说明 |
|------|------|------|
| dataSource | object | 项目数据源 |
| project | string | 项目名 |
| saveProject | function | 保存项目 |
| closeProject | function | 关闭项目 |
| openObject | function | 打开项目/文件 |
| changeDataType | string | 数据变更类型 |

**核心功能**:
- 左侧树形导航(模块/数据域)
- Tab工作区管理
- 工具栏菜单(开始/关系图/模型)
- 右键菜单操作
- 快捷键处理(Ctrl+S保存, Ctrl+E关闭Tab)

**主要State**:
| 状态 | 类型 | 说明 |
|------|------|------|
| tools | string | 当前工具栏(file/map/entity/plug) |
| tab | string | 左侧Tab(table/domain) |
| tabs | array | 工作区Tab列表 |
| show | string | 当前显示Tab |
| clicked | string | 关系图模式(drag/edit) |

### Home

首页组件，管理项目历史记录、创建/打开项目。

**Props**:
| 属性 | 类型 | 说明 |
|------|------|------|
| histories | array | 项目历史记录列表 |

**核心功能**:
- 项目历史记录展示
- 新建项目
- 打开现有项目
- 删除历史记录
- 版本更新检查

**数据存储**:
- 历史记录存储在: `{userData}/config.pdman.json`

### Setting

设置面板，配置默认数据类型、数据库模板等。

**功能**:
- 配置默认字段(defaultFields)
- 配置数据类型(datatype)
- 配置数据库(database)
- 配置模板

### Loading

加载界面，项目加载时的过渡界面。

**功能**:
- 显示加载进度
- 初始化项目数据
- 调用window.PDMan.loading完成回调

## 关键流程

### 项目打开流程

```
Home._open() → openObject()
    ↓
文件选择对话框
    ↓
读取.pdman.json文件
    ↓
upgrade() 数据升级(如需)
    ↓
setState(dataSource)
    ↓
Loading → App渲染
```

### 项目保存流程

```
Ctrl+S / 点击保存 → _saveAll()
    ↓
遍历所有Tab实例
    ↓
调用tableInstance/relationInstance.promiseSave()
    ↓
等待所有Promise完成
    ↓
saveProject() 写入文件
    ↓
Message.success() 提示
```

### Tab管理流程

```
双击树节点 → _onDoubleClick(value)
    ↓
解析value类型(entity&/map&/datatype&/database&)
    ↓
检查Tab是否已存在
    ↓
不存在: 创建新Tab并push
    ↓
存在: 激活已有Tab
    ↓
_setTabsWidth() 调整Tab宽度(超宽自动折叠)
```

## IPC通信

### 主进程监听

```javascript
// jarPath: 获取JAR路径
ipcMain.on("jarPath", (event) => {
  event.returnValue = jarPath;
});

// headerType: 窗口控制
ipcMain.on("headerType", (event, args) => {
  switch (args) {
    case 'minimize': win.minimize();
    case 'maximize': win.maximize();
    case 'close': win.close();
    case 'openDev': win.webContents.openDevTools();
  }
});
```

### 渲染进程调用

```javascript
// 同步获取JAR路径
const jarPath = ipcRenderer.sendSync('jarPath');

// 窗口控制
ipcRenderer.sendSync('headerType', 'maximize');
```

## 快捷键

| 组合键 | 功能 |
|--------|------|
| Ctrl+S | 保存项目 |
| Ctrl+E | 关闭当前Tab |
| Ctrl+Shift+D | 打开开发者工具 |

## 已知坑点

1. **Tab折叠机制**: 超出宽度自动折叠到溢出面板
2. **Tab更新**: 重命名模块/表需手动更新Tab的key/title
3. **关系图实例**: 通过relationInstance[key]存储多个实例
4. **数据表实例**: 通过tableInstance[key]存储多个实例
5. **版本更新**: forceUpdate=true时关闭弹窗自动退出应用
6. **Mac窗口**: 使用setFullScreen而非maximize
7. **Loading回调**: 需调用window.PDMan.loading完成初始化

## 详细文档

- [api-app.md](api-app.md) - 主应用详细API
- [api-home.md](api-home.md) - 首页详细API
- [ipc-communication.md](ipc-communication.md) - IPC通信说明