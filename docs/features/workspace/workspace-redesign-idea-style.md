# 工作区视图重设计方案 - 基于 IntelliJ IDEA 真实设计

> 基于 IntelliJ IDEA 官方文档和真实 UI 设计研究，为 Bkdmm 数据库建模工具设计工作区视图

**研究来源：**
- [IntelliJ IDEA Interface Guide](https://www.jetbrains.com/help/idea/guided-tour-around-the-intellij-idea-interface.html)
- [Tool Windows Guide](https://www.jetbrains.com/help/idea/tool-windows.html)
- [Editor Tabs Guide](https://www.jetbrains.com/help/idea/using-editor-tabs.html)
- [Project Tool Window](https://www.jetbrains.com/help/idea/project-tool-window.html)
- [New UI Introduction](https://blog.jetbrains.com/idea/2023/03/introducing-the-new-ui-in-intellij-idea/)
- [Tool Windows Plugin Docs](https://plugins.jetbrains.com/docs/intellij/tool-windows.html)

---

## 一、IDEA 真实布局结构分析

### 1.1 整体窗口组织

IntelliJ IDEA 采用 **中央编辑区 + 环绕工具窗口** 的布局模式：

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Main Menu Bar (菜单栏)                                                  │
│  File | Edit | View | Navigate | Code | Refactor | Build | Run | ...   │
├─────────────────────────────────────────────────────────────────────────┤
│  Main Toolbar (主工具栏)                                                 │
│  [Run ▼] [Debug] [Build] [Undo] [Redo] [←] [→] [Commit] [Push]         │
├─────────────────────────────────────────────────────────────────────────┤
│  Navigation Bar (导航栏 - 可选显示)                                      │
│  Project > Module > Directory > File > Class                            │
├────┬────────────────────────────────────────────────────────────────┬────┤
│ L  │                         Editor Area                            │ R  │
│ e  │  ┌──────────────────────────────────────────────────────────┐  │ i  │
│ f  │  │ Editor Tabs                                              │  │ g  │
│ t  │  │ [File1.java ×] [File2.java* ×] [Config.xml ×] [▼][+]    │  │ h  │
│ S  │  ├──────────────────────────────────────────────────────────┤  │ t  │
│ t  │  │                                                          │  │    │
│ r  │  │                    Editor Content                        │  │ S  │
│ i  │  │                                                          │  │ t  │
│ p  │  │   - Gutter (行号、断点、折叠图标)                        │  │ r  │
│    │  │   - Code Area                                           │  │ i  │
│ 1  │  │   - Minimap (可选)                                      │  │ p  │
│ 7  │  │                                                          │  │    │
│ 2  │  └──────────────────────────────────────────────────────────┘  │ D  │
│ 0  │                                                                  │ a  │
│    │                                                                  │ t  │
├────┴────────────────────────────────────────────────────────────────┴────┤
│  Bottom Tool Windows Strip                                               │
│  [Terminal:12] [Problems:6] [Build:4] [Run:5] [Find:3]                  │
├─────────────────────────────────────────────────────────────────────────┤
│  Status Bar                                                              │
│  [12:34] [UTF-8] [LF] | [main branch] | [✓ Analysis] [🔔] [512M/1G]    │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 IDEA 新版 UI (2023+) 特点

IDEA 2023 推出了新版 UI，更简洁现代：

| 特性 | Classic UI | New UI (2023+) |
|------|-----------|----------------|
| 工具栏 | 多按钮，功能丰富 | 紧凑，项目名作为面包屑 |
| 菜单 | 传统菜单栏 | 部分合并到汉堡菜单 |
| Run/Debug | 下拉 + 按钮 | 更突出显示 |
| Search | 搜索按钮 | Search Everywhere 放大镜 |
| 工具窗口条 | 分离的侧边条 | 与头部整合 |

---

## 二、核心组件详解

### 2.1 工具窗口系统 (Tool Windows)

IDEA 的工具窗口系统是其核心特性：

#### 工具窗口条 (Tool Window Strip)

```
左侧条:                    右侧条:                    底部条:
┌──────┐                  ┌──────┐                  ┌────────────────────┐
│ [1]  │ Project          │      │ Database         │ [F12] Terminal     │
│ [7]  │ Structure        │      │ Gradle           │ [6]   Problems     │
│ [2]  │ Favorites        │      │ Maven            │ [4]   Build        │
│ [0]  │ Commit           │      │ Notifications    │ [5]   Run          │
│      │                  │      │                  │ [3]   Find         │
└──────┘                  └──────┘                  └────────────────────┘
```

**关键设计：**
- 数字徽章显示快捷键 (Alt+数字)
- 激活的工具窗口高亮显示
- 拖拽图标可重新定位到不同边缘

#### 工具窗口状态

| 状态 | 描述 | 行为 |
|------|------|------|
| **Hidden** | 仅显示条图标 | 点击图标展开 |
| **Docked** | 固定显示，占用编辑区空间 | 可拖拽调整大小 |
| **Floating** | 独立窗口，可任意移动 | 不占用主窗口空间 |
| **Windowed** | 浮动 + 始终置顶 | 适合多显示器 |
| **Pinned** | 固定钉住 | 焦点移开后保持打开 |
| **Auto-hidden** | 自动隐藏 | 鼠标移开后滑出隐藏 |

#### 锚定系统 (Anchoring)

```
工具窗口可锚定到三个位置:

LEFT ←─────────────────────────────────────────→ RIGHT
                      │
                      ↓
                    BOTTOM

同一锚点位置只能显示一个工具窗口
多个工具窗口共享锚点时通过标签页切换
```

#### 工具窗口内部结构

```
┌─────────────────────────────────────┐
│ Project                    [−][×][⚙]│  ← 标题栏
├─────────────────────────────────────┤
│ [Project] [Packages] [Scope]       │  ← 内部标签页
├─────────────────────────────────────┤
│ 🔍 搜索框                           │  ← 工具栏/搜索
├─────────────────────────────────────┤
│                                     │
│ ▼ 📁 Project Root                   │
│   ├─ 📁 Module1                     │
│   │   ├─ 📄 File1.java              │
│   │   └─ 📄 File2.kt                │
│   └─ 📁 Module2                     │
│                                     │
├─────────────────────────────────────┤
│ [+] [−] [⚙ View Options]           │  ← 底部工具栏
└─────────────────────────────────────┘
```

### 2.2 编辑器标签页 (Editor Tabs)

#### 标签栏结构

```
┌──────────────────────────────────────────────────────────────────────┐
│ [📄 User.java ×] [📄 Order.java* ×] [📁 Module1 ×] [▼下拉] [+]      │
└──────────────────────────────────────────────────────────────────────┘

标签组成:
┌─────────────────────┐
│ [图标] 文件名 [×]   │  ← 正常状态
└─────────────────────┘

┌─────────────────────┐
│ [图标] 文件名* [×]  │  ← 已修改 (*标记)
└─────────────────────┘

┌─────────────────────┐
│ [图标] 文件名 📌[×] │  ← 已固定 (pin图标)
└─────────────────────┘

┌═════════════════════┐
║ [图标] 文件名 [×]   ║  ← 激活状态 (高亮背景)
┚═════════════════════┛
```

#### 标签管理功能

| 功能 | 操作方式 |
|------|---------|
| **分屏编辑** | 右键菜单 → Split Vertically/Horizontally |
| **拖拽移动** | 拖拽标签到另一个分屏 |
| **右侧打开** | 右键 → Open in Right Split |
| **固定标签** | 点击 pin 图标，防止自动关闭 |
| **关闭策略** | 可配置最大标签数和关闭策略 |
| **批量关闭** | Close Others / Close All / Close Unmodified |

#### 标签行为

| 操作 | 行为 |
|------|------|
| 单击 | 打开文件 |
| 双击 | 在新分屏中打开 |
| 中键点击 | 关闭标签 |
| Ctrl+Tab | 快速切换器 (最近文件) |
| [▼] 下拉 | 显示所有打开的标签列表 |

#### 视觉指示器

| 指示器 | 含义 |
|--------|------|
| 高亮背景 + 粗体 | 激活标签 |
| 柔和背景 | 未激活标签 |
| `*` 或蓝色圆点 | 已修改未保存 |
| 绿色 | 新添加文件 |
| 蓝色 | 已修改文件 |
| 红色 | 冲突文件 |

### 2.3 项目视图 (Project View)

#### 树结构

```
┌─────────────────────────────────────┐
│ 📁 Project Name (Root)              │
│ ├─ 📁 Module1                       │
│ │   ├─ 📁 src/main/java             │
│ │   │   ├─ 📄 UserService.java      │
│ │   │   └─ 📄 UserController.java   │
│ │   └─ 📁 src/test                  │
│ ├─ 📁 Module2                       │
│ ├─ 📁 External Libraries            │
│ │   ├─ 📁 JDK 17                    │
│ │   └─ 📁 Maven Dependencies        │
│ └───────────────────────────────────│
```

#### 视图模式

| 模式 | 说明 |
|------|------|
| **Project** (默认) | 文件和文件夹层级结构 |
| **Packages** | Java 包结构视图 |
| **Project Files** | 所有文件（不含 .idea 过滤） |
| **Problems** | 有错误/警告的文件 |
| **Production** | 仅主源代码 |
| **Tests** | 仅测试代码 |

#### Scope 系统

- 预定义 Scope: Project Files, Open Files, Recent Files
- 自定义 Scope: 用户定义的文件模式
- Scope 颜色: 不同 Scope 用不同颜色区分

#### 功能特性

| 功能 | 说明 |
|------|------|
| 搜索/过滤栏 | 顶部搜索框快速过滤 |
| Flatten Packages | 展平包结构显示 |
| Abbreviate Names | 缩写限定包名 |
| Autoscroll from Source | 自动选中当前编辑的文件 |
| 拖拽操作 | 拖拽移动/复制文件 |
| 右键菜单 | VCS 操作、重构等 |

#### 视觉指示器

| 图标/颜色 | 含义 |
|----------|------|
| 绿色文件名 | 新添加的文件 |
| 蓝色文件名 | 已修改的文件 |
| 红色文件名 | 忽略/冲突文件 |
| 灰色文件名 | 排除的文件 |
| 🔒 锁图标 | 只读文件 |
| ⚠ 警告三角 | 有问题的文件 |

### 2.4 状态栏 (Status Bar)

```
┌──────────────────────────────────────────────────────────────────────┐
│ [12:34] [UTF-8 ▼] [LF ▼] │ [main ▼ branch] │ [✓ 0 errors] [🔔] [⚙] │
└──────────────────────────────────────────────────────────────────────┘

分区结构:
- 左侧: 行/列号、文件编码、换行符
- 中间: Git 分支、VCS 状态、构建进度
- 右侧: 通知铃铛、分析状态、内存使用

所有元素都是可点击的，提供快速操作
```

---

## 三、Bkdmm 工作区设计方案

基于 IDEA 的真实设计，为 Bkdmm 设计适配的工作区：

### 3.1 整体布局

```
┌─────────────────────────────────────────────────────────────────────┐
│  Main Toolbar (项目工具栏)                                          │
│  [📁 项目名*] │ [保存] [撤销] [重做] │ [生成代码 ▼] │ [🔍 搜索] [⚙] │
├────┬────────────────────────────────────────────────────────────┬────┤
│ L  │  Editor Tabs                                             │ R  │
│ e  │  [📊 User ×] [📊 Order* ×] [📁 模块1 ×] [▼][+]           │ i  │
│ f  ├───────────────────────────────────────────────────────────┤ g  │
│ t  │                                                           │ h  │
│ S  │                     Editor Area                           │ t  │
│ t  │                                                           │    │
│ r  │   ┌───────────────────────────────────────────────────┐   │ P  │
│ i  │   │                                                   │   │ r  │
│ p  │   │         Entity Editor / Module Diagram            │   │ o  │
│    │   │                                                   │   │ p  │
│ 1  │   │                                                   │   │ s  │
│ 7  │   └───────────────────────────────────────────────────┘   │    │
│    │                                                           │ W  │
├────┴───────────────────────────────────────────────────────────┴────┤
│  Bottom Tool Windows Strip                                           │
│  [结构:7] [图表:8] [日志:9] [输出:0]              [属性:F12] [预览] │
├─────────────────────────────────────────────────────────────────────┤
│  Status Bar                                                          │
│  [模块:2] [表:8] [字段:45] │ [main branch] │ [● 未保存] │ [v1.0.0] │
└─────────────────────────────────────────────────────────────────────┘
```

### 3.2 工具窗口映射

将 IDEA 的工具窗口概念映射到 Bkdmm：

| IDEA 工具窗口 | Bkdmm 对应 | 功能 | 快捷键 |
|--------------|-----------|------|--------|
| Project (Alt+1) | **模块树** | 显示项目模块和表结构 | Alt+1 |
| Structure (Alt+7) | **结构大纲** | 当前表的字段结构大纲 | Alt+7 |
| Database | **数据类型** | 自定义数据类型管理 | Alt+D |
| Problems (Alt+6) | **问题面板** | 显示验证错误和警告 | Alt+6 |
| Build (Alt+4) | **生成输出** | 代码生成结果输出 | Alt+4 |
| Terminal (Alt+F12) | **SQL预览** | SQL 代码预览 | Alt+F12 |
| Commit (Alt+0) | **保存/提交** | 项目保存和变更管理 | Alt+0 |
| - | **ER图表** | ER 图缩略图导航 | Alt+8 |
| - | **日志** | 操作日志和错误日志 | Alt+9 |
| - | **属性** | 选中项属性面板 | Alt+Enter |

### 3.3 项目视图设计

```
┌─────────────────────────────────────┐
│ Project                    [−][×][⚙]│
├─────────────────────────────────────┤
│ [模块] [表] [关系] [搜索结果]       │  ← 视图模式切换
├─────────────────────────────────────┤
│ 🔍 [搜索表、字段...]                │
├─────────────────────────────────────┤
│                                     │
│ ▼ 📁 用户模块                       │
│   ├─ 📊 user (用户表)       [🔵]    │  ← 蓝色表示已修改
│   ├─ 📊 role (角色表)               │
│   └─ 🔗 user_role (关系)            │
│                                     │
│ ▶ 📁 订单模块                       │
│                                     │
│ ▼ 📁 External Types                 │
│   ├─ 📄 CustomType1                 │
│   └─ 📄 CustomType2                 │
│                                     │
├─────────────────────────────────────┤
│ [➕ 模块] [➕ 表] [🔄 刷新]          │
└─────────────────────────────────────┘
```

#### 视图模式

| 模式 | 显示内容 |
|------|---------|
| **模块** | 模块 → 表层级结构 |
| **表** | 所有表平铺列表 |
| **关系** | 表关系图预览 |
| **搜索结果** | 搜索匹配的结果 |

#### 交互设计

| 操作 | 行为 |
|------|------|
| 单击 | 选中，右侧显示属性预览 |
| 双击 | 在编辑区打开 |
| 中键点击 | 后台打开（不激活） |
| 右键 | 上下文菜单 |
| F2 | 重命名 |
| Delete | 删除 |
| Ctrl+C | 复制表结构 |

### 3.4 编辑器标签设计

```
┌──────────────────────────────────────────────────────────────────────┐
│ [📊 user ×] [📊 order* ×] [📊 product 📌×] [📁 模块1 ×] [▼] [+][×]  │
└──────────────────────────────────────────────────────────────────────┘

标签类型:
- 📊 数据表编辑器
- 📁 模块视图 (ER图)
- 🔗 关系图编辑器
- 📄 数据类型编辑器
- ⚙ 设置页面
```

#### 标签功能

| 功能 | 实现方式 |
|------|---------|
| 滚动溢出 | 标签超出时显示左右箭头 |
| 下拉列表 | [▼] 显示所有打开的标签 |
| 固定标签 | 点击 pin 图标固定 |
| 分屏编辑 | 右键 → Split Right/Below |
| 关闭操作 | Close / Close Others / Close All |

### 3.5 工具窗口条设计

```
底部工具窗口条:

┌─────────────────────────────────────────────────────────────────────┐
│ [📋 7:结构] [📊 8:图表] [📝 9:日志] [⚙ 0:输出]    [属性] [预览:F12] │
└─────────────────────────────────────────────────────────────────────┘

展开工具窗口后:

┌─────────────────────────────────────────────────────────────────────┐
│ [📋 7:结构] [📊 8:图表] [📝 9:日志*] [⚙ 0:输出]  [属性] [预览:F12] │
├─────────────────────────────────────────────────────────────────────┤
│ 日志窗口                                              [−][□][×]     │
│ ──────────────────────────────────────────────────────────────────── │
│ [全部] [错误] [警告] [信息]           [🔍 搜索] [🗑 清空]            │
│ ──────────────────────────────────────────────────────────────────── │
│ > 2024-01-15 [INFO] 项目加载完成                                    │
│ > 2024-01-15 [INFO] 数据库连接成功                                  │
│ > 2024-01-15 [WARN] 表 user 缺少主键                     ⚠         │
│ > 2024-01-15 [ERROR] 生成失败: 字段类型未定义             ✗         │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 3.6 快捷键设计

完全参考 IDEA 的快捷键体系：

#### 工具窗口快捷键

| 快捷键 | 功能 |
|--------|------|
| **Alt+1** | 模块树 (Project View) |
| **Alt+7** | 结构大纲 (Structure) |
| **Alt+8** | ER图表预览 (Diagram) |
| **Alt+9** | 操作日志 (Log) |
| **Alt+0** | 生成输出 (Output) |
| **Alt+D** | 数据类型 (Data Types) |
| **Alt+F12** | SQL预览 (Preview) |
| **Alt+Enter** | 属性面板 (Properties) |

#### 编辑器快捷键

| 快捷键 | 功能 |
|--------|------|
| **Ctrl+Tab** | 快速切换器 |
| **Ctrl+E** | 最近打开的表 |
| **Ctrl+W** | 关闭当前标签 |
| **Ctrl+Shift+W** | 关闭所有标签 |
| **Ctrl+S** | 保存项目 |
| **Ctrl+F** | 在编辑器中搜索 |
| **Ctrl+H** | 在项目中搜索 |

#### 布局快捷键

| 快捷键 | 功能 |
|--------|------|
| **Ctrl+Shift+F12** | 隐藏所有工具窗口 |
| **Shift+Escape** | 隐藏当前工具窗口 |
| **F12** | 跳转到最后一个工具窗口 |

#### 项目视图快捷键

| 快捷键 | 功能 |
|--------|------|
| **Enter** | 打开选中项 |
| **Space** | 展开/折叠 |
| **F2** | 重命名 |
| **Delete** | 删除 |
| **Insert** | 新建 |

---

## 四、响应式设计

参考 IDEA 的响应式行为：

### 4.1 窗口调整行为

| 场景 | IDEA 行为 | Bkdmm 实现 |
|------|-----------|-----------|
| 空间不足 | 工具窗口自动隐藏 | 同样实现自动隐藏 |
| 标签溢出 | 标签栏滚动 + 下拉列表 | 同样实现 |
| 编辑区优先 | 编辑区获得空间分配优先权 | 同样实现 |

### 4.2 工具窗口模式

实现 IDEA 的四种工具窗口模式：

| 模式 | 描述 | Flutter 实现 |
|------|------|-------------|
| **Docked** | 固定显示，占用空间 | 固定位置 Widget |
| **Floating** | 独立窗口 | showModalDialog + Draggable |
| **Windowed** | 浮动置顶 | showModalDialog + always on top |
| **Auto-hide** | 自动隐藏 | AnimatedSlide + hover trigger |

### 4.3 布局持久化

参考 IDEA 的布局管理：

| 功能 | 说明 |
|------|------|
| **项目布局** | 每个项目保存独立的布局配置 |
| **默认布局** | 全局默认布局，新项目使用 |
| **恢复默认** | Restore Default Layout 菜单 |
| **命名布局** | 保存命名布局，快速切换 |

---

## 五、技术实现方案

### 5.1 组件架构

```
lib/features/workspace/
├── views/
│   └── workspace_view.dart              # 工作区主视图
├── widgets/
│   ├── toolbar/
│   │   ├── main_toolbar.dart            # 项目工具栏
│   │   ├── toolbar_button.dart          # 工具栏按钮
│   │   └── search_box.dart              # 搜索框
│   ├── project_view/
│   │   ├── project_view_panel.dart      # 项目视图面板
│   │   ├── project_tree.dart            # 项目树
│   │   ├── tree_node.dart               # 树节点
│   │   ├── view_mode_tabs.dart          # 视图模式切换
│   │   └── search_filter.dart           # 搜索过滤
│   ├── editor_area/
│   │   ├── editor_tabs_bar.dart         # 标签栏
│   │   ├── editor_tab.dart              # 单个标签
│   │   ├── editor_content.dart          # 编辑器内容
│   │   ├── split_editor.dart            # 分屏编辑器
│   │   └── tabs_dropdown.dart           # 标签下拉列表
│   ├── tool_windows/
│   │   ├── tool_window_strip.dart       # 工具窗口条
│   │   ├── tool_window_button.dart      # 工具窗口按钮
│   │   ├── tool_window_panel.dart       # 工具窗口面板基类
│   │   ├── structure_window.dart        # 结构窗口
│   │   ├── diagram_window.dart          # 图表窗口
│   │   ├── log_window.dart              # 日志窗口
│   │   ├── output_window.dart           # 输出窗口
│   │   ├── properties_window.dart       # 属性窗口
│   │   └── sql_preview_window.dart      # SQL预览窗口
│   └── status_bar/
│       └── status_bar.dart              # 状态栏
│       └── status_item.dart             # 状态项组件
├── providers/
│   ├── workspace_provider.dart          # 工作区状态
│   ├── layout_provider.dart             # 布局状态
│   ├── tool_window_provider.dart        # 工具窗口状态
│   └── editor_tabs_provider.dart        # 编辑器标签状态
├── models/
│   ├── tool_window_config.dart          # 工具窗口配置
│   ├── workspace_layout.dart            # 布局模型
│   ├── editor_tab_info.dart             # 标签信息
│   └── view_mode.dart                   # 视图模式
└── services/
    └── layout_persistence_service.dart  # 布局持久化
```

### 5.2 状态管理模型

```dart
/// 工具窗口配置 (参考 IDEA)
class ToolWindowConfig {
  final String id;
  final String title;
  final IconData icon;
  final ToolWindowAnchor anchor;      // LEFT, RIGHT, BOTTOM
  final ToolWindowMode mode;          // DOCKED, FLOATING, AUTO_HIDE
  final String shortcut;              // 如 "Alt+7"
  final bool canClose;
  final bool canFloat;
  final bool canDock;
  final double defaultWidth;
  final double defaultHeight;
  final int order;                    // 在 strip 中的顺序
}

/// 工具窗口锚点位置
enum ToolWindowAnchor {
  left,
  right,
  bottom,
}

/// 工具窗口模式
enum ToolWindowMode {
  hidden,       // 仅显示 strip 图标
  docked,       // 固定显示
  floating,     // 浮动窗口
  windowed,     // 浮动置顶
  autoHide,     // 自动隐藏
}

/// 工具窗口状态
class ToolWindowState {
  final Map<String, ToolWindowConfig> configs;
  final String? activeWindowId;       // 当前激活的工具窗口
  final Map<String, ToolWindowMode> modes; // 每个窗口的当前模式
  final Map<String, double> widths;   // 每个窗口的宽度
  final Map<String, double> heights;  // 每个窗口的高度
  final Map<String, ToolWindowAnchor> anchors; // 当前锚点位置
}

/// 编辑器标签信息
class EditorTabInfo {
  final String id;
  final String title;
  final IconData icon;
  final EditorTabType type;
  final String? moduleId;
  final String? entityId;
  final bool isModified;              // 已修改标记
  final bool isPinned;                // 固定标记
  final int group;                    // 标签组 (分屏)
}

/// 布局状态 (参考 IDEA)
class WorkspaceLayoutState {
  // 工具窗口
  final ToolWindowState toolWindows;

  // 编辑器
  final List<EditorTabInfo> tabs;
  final int activeTabIndex;
  final bool hasSplit;                // 是否分屏
  final Axis splitDirection;          // 分屏方向

  // 项目视图
  final double projectViewWidth;
  final bool projectViewVisible;
  final ViewMode projectViewMode;     // 当前视图模式

  // 全局
  final bool statusBarVisible;
  final bool toolbarVisible;

  // 项目特定
  final String? projectId;            // 布局属于哪个项目
}
```

### 5.3 核心组件实现示例

#### 工具窗口条

```dart
class ToolWindowStrip extends ConsumerWidget {
  final ToolWindowAnchor anchor;

  const ToolWindowStrip({required this.anchor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tdTheme = TDTheme.of(context);
    final toolWindows = ref.watch(toolWindowProvider);
    final windowsForAnchor = toolWindows.getWindowsForAnchor(anchor);

    if (anchor == ToolWindowAnchor.bottom) {
      return _buildBottomStrip(tdTheme, windowsForAnchor, ref);
    } else {
      return _buildSideStrip(tdTheme, windowsForAnchor, ref);
    }
  }

  Widget _buildBottomStrip(
    TDThemeData tdTheme,
    List<ToolWindowConfig> windows,
    WidgetRef ref,
  ) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: tdTheme.bgColorSecondaryContainer,
        border: Border(top: BorderSide(color: tdTheme.componentBorderColor)),
      ),
      child: Row(
        children: [
          // 左侧工具窗口按钮
          ...windows.where((w) => w.order < 50).map((w) =>
            ToolWindowButton(
              config: w,
              isActive: ref.watch(toolWindowProvider).activeWindowId == w.id,
              onTap: () => ref.read(toolWindowProvider.notifier).toggle(w.id),
            ),
          ),

          Spacer(),

          // 右侧工具窗口按钮
          ...windows.where((w) => w.order >= 50).map((w) =>
            ToolWindowButton(
              config: w,
              isActive: ref.watch(toolWindowProvider).activeWindowId == w.id,
              onTap: () => ref.read(toolWindowProvider.notifier).toggle(w.id),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideStrip(
    TDThemeData tdTheme,
    List<ToolWindowConfig> windows,
    WidgetRef ref,
  ) {
    return Container(
      width: 48,
      color: tdTheme.bgColorContainer,
      child: Column(
        children: windows.map((w) =>
          ToolWindowButton(
            config: w,
            isActive: ref.watch(toolWindowProvider).activeWindowId == w.id,
            isVertical: true,
            onTap: () => ref.read(toolWindowProvider.notifier).toggle(w.id),
          ),
        ).toList(),
      ),
    );
  }
}
```

#### 工具窗口按钮 (带快捷键徽章)

```dart
class ToolWindowButton extends ConsumerWidget {
  final ToolWindowConfig config;
  final bool isActive;
  final bool isVertical;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tdTheme = TDTheme.of(context);

    return Tooltip(
      message: '${config.title} (${config.shortcut})',
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: isVertical ? 48 : null,
          height: isVertical ? 40 : 32,
          padding: EdgeInsets.symmetric(horizontal: isVertical ? 4 : 12),
          decoration: BoxDecoration(
            color: isActive ? tdTheme.brandLightColor : null,
            border: isActive ? Border(
              bottom: BorderSide(color: tdTheme.brandNormalColor, width: 2),
            ) : null,
          ),
          child: isVertical
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(config.icon, size: 20,
                    color: isActive ? tdTheme.brandNormalColor : tdTheme.textColorSecondary),
                  if (config.shortcut.contains('Alt+'))
                    TDText(
                      config.shortcut.replaceAll('Alt+', ''),
                      font: tdTheme.fontMarkExtraSmall,
                      textColor: isActive ? tdTheme.brandNormalColor : tdTheme.textColorSecondary,
                    ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(config.icon, size: 16,
                    color: isActive ? tdTheme.brandNormalColor : tdTheme.textColorSecondary),
                  SizedBox(width: 4),
                  TDText(
                    config.title,
                    font: tdTheme.fontMarkExtraSmall,
                    textColor: isActive ? tdTheme.brandNormalColor : tdTheme.textColorSecondary,
                  ),
                  if (config.shortcut.contains('Alt+'))
                    Container(
                      margin: EdgeInsets.only(left: 4),
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: tdTheme.bgColorSecondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: TDText(
                        config.shortcut.replaceAll('Alt+', ''),
                        font: tdTheme.fontMarkExtraSmall,
                        textColor: tdTheme.textColorSecondary,
                      ),
                    ),
                ],
              ),
        ),
      ),
    );
  }
}
```

#### 项目视图面板 (参考 IDEA Project View)

```dart
class ProjectViewPanel extends ConsumerStatefulWidget {
  final double width;
  final bool visible;

  @override
  ConsumerState<ProjectViewPanel> createState() => _ProjectViewPanelState();
}

class _ProjectViewPanelState extends ConsumerState<ProjectViewPanel> {
  final TextEditingController _searchController = TextEditingController();
  ViewMode _viewMode = ViewMode.modules;

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);
    final layoutState = ref.watch(layoutProvider);

    if (!widget.visible) {
      return SizedBox.shrink();
    }

    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: tdTheme.bgColorContainer,
        border: Border(right: BorderSide(color: tdTheme.componentBorderColor)),
      ),
      child: Column(
        children: [
          // 标题栏 (参考 IDEA)
          _buildTitleBar(tdTheme),

          // 视图模式切换标签 (参考 IDEA 的 Project/Packages/Scope)
          _buildViewModeTabs(tdTheme),

          // 搜索过滤栏
          _buildSearchBar(tdTheme),

          // 项目树
          Expanded(
            child: ProjectTree(
              viewMode: _viewMode,
              filterText: _searchController.text,
              onSelect: _onNodeSelect,
              onDoubleTap: _onNodeDoubleTap,
            ),
          ),

          // 底部操作栏
          _buildActionBar(tdTheme),
        ],
      ),
    );
  }

  Widget _buildTitleBar(TDThemeData tdTheme) {
    return Container(
      height: 32,
      padding: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tdTheme.componentBorderColor)),
      ),
      child: Row(
        children: [
          TDText('Project', font: tdTheme.fontTitleSmall),
          Spacer(),
          // 折叠按钮
          TDButton(
            icon: TDIcons.minus,
            size: TDButtonSize.extraSmall,
            type: TDButtonType.text,
            onTap: () => ref.read(layoutProvider.notifier).toggleProjectView(),
          ),
          // 设置按钮 (齿轮图标，参考 IDEA)
          TDButton(
            icon: TDIcons.setting,
            size: TDButtonSize.extraSmall,
            type: TDButtonType.text,
            onTap: _showViewOptions,
          ),
          // 关闭按钮
          TDButton(
            icon: TDIcons.close,
            size: TDButtonSize.extraSmall,
            type: TDButtonType.text,
            onTap: () => ref.read(layoutProvider.notifier).hideProjectView(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeTabs(TDThemeData tdTheme) {
    return Container(
      height: 28,
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: ViewMode.values.map((mode) =>
          TDText(
            mode.label,
            font: tdTheme.fontBodySmall,
            textColor: _viewMode == mode ? tdTheme.brandNormalColor : tdTheme.textColorSecondary,
            onTap: () => setState(() => _viewMode = mode),
          ),
        ).toList(),
      ),
    );
  }

  void _showViewOptions() {
    // 参考 IDEA 的齿轮菜单
    showTDPopupMenu(
      context: context,
      position: Offset(0, 32),
      items: [
        TDPopupMenuItem(value: 'flatten', icon: TDIcons.view_list, label: '展平模块'),
        TDPopupMenuItem(value: 'autoscroll', icon: TDIcons.location, label: '自动滚动到源'),
        TDPopupMenuItem(value: 'show_excluded', icon: TDIcons.view, label: '显示排除项'),
      ],
      onSelected: (value) => _handleViewOption(value),
    );
  }
}
```

---

## 六、迁移实施计划

### 6.1 分阶段实施

| 阶段 | 任务 | 预计工时 | 依赖 |
|------|------|---------|------|
| **Phase 1** | 实现工具窗口基础设施 | 2-3 天 | 无 |
| **Phase 2** | 重构项目视图组件 | 1-2 天 | Phase 1 |
| **Phase 3** | 重构编辑器标签系统 | 1-2 天 | Phase 1 |
| **Phase 4** | 实现各个工具窗口面板 | 2-3 天 | Phase 1 |
| **Phase 5** | 完善快捷键系统 | 1 天 | Phase 1-4 |
| **Phase 6** | 布局持久化和恢复 | 1 天 | Phase 1-5 |
| **Phase 7** | 测试和优化 | 1-2 天 | Phase 1-6 |

### 6.2 兼容策略

- 保留旧版 `WorkspaceView` 作为备选
- 提供设置选项切换布局风格
- 布局配置独立存储，不影响原有数据

---

## 七、附录

### 7.1 参考资料汇总

| 资源 | 链接 | 内容 |
|------|------|------|
| IDEA Interface Guide | https://www.jetbrains.com/help/idea/guided-tour-around-the-intellij-idea-interface.html | 整体界面介绍 |
| Tool Windows Guide | https://www.jetbrains.com/help/idea/tool-windows.html | 工具窗口详细文档 |
| Editor Tabs Guide | https://www.jetbrains.com/help/idea/using-editor-tabs.html | 标签页管理 |
| Project Tool Window | https://www.jetbrains.com/help/idea/project-tool-window.html | 项目视图详细文档 |
| New UI Introduction | https://blog.jetbrains.com/idea/2023/03/introducing-the-new-ui-in-intellij-idea/ | 2023新版UI介绍 |
| Tool Windows Plugin | https://plugins.jetbrains.com/docs/intellij/tool-windows.html | 插件开发角度的技术文档 |

### 7.2 设计对比总结

| 特性 | IDEA 实现 | Bkdmm 实现 | 差异说明 |
|------|-----------|-----------|---------|
| 工具窗口条 | 左/右/底部条 | 左/底部条 | 简化右侧条，合并到底部 |
| 工具窗口状态 | 6种状态 | 4种状态 | 简化 Windowed/Pinned |
| 标签分屏 | 支持 | 支持 | 相同实现 |
| 项目视图模式 | 6种模式 | 4种模式 | 简化 Problems/Tests |
| 快捷键徽章 | Alt+数字显示 | Alt+数字显示 | 相同实现 |
| 搜索过滤 | 支持 | 支持 | 相同实现 |
| 布局持久化 | 支持 | 支持 | 相同实现 |

---

**文档版本:** v2.0
**更新日期:** 2024-01-15
**基于:** IntelliJ IDEA 官方文档真实设计研究