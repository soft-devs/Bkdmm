# Components - UI组件库

## 概述

自研UI组件库，封装常用交互组件。基于React 16.2开发，样式采用Less编写，部分组件(Icon)复用antd图标。

## 组件索引

| 组件 | 路径 | 用途 | 关键特性 |
|------|------|------|----------|
| Icon | icon/ | 图标显示 | font-awesome + antd图标 |
| Button | button/Button.js | 按钮操作 | primary/default样式 |
| Input | input/ | 文本输入 | 受控组件 |
| TextArea | textarea/ | 多行文本 | 受控组件 |
| Text | text/ | 文本显示 | 纯展示 |
| Checkbox | checkbox/ | 复选框 | 受控选中状态 |
| Radio | radio/ | 单选框 | 配合RadioGroup |
| RadioGroup | radiogroup/ | 单选组 | 管理多个Radio |
| Select | select/ | 下拉选择 | 受控选中项 |
| TreeSelect | treeselect/ | 树形选择 | 下拉树结构 |
| Tree | tree/Tree.js | 树形结构 | **核心组件**，支持搜索/拖拽/右键菜单 |
| TreeNode | tree/TreeNode.js | 树节点 | Tree子组件 |
| Tab | tab/Tab.js | 标签页 | TabPane容器 |
| TabPane | tab/TabPane.js | 标签面板 | Tab子组件 |
| SimpleTab | simpletab/ | 简易标签 | 轻量版Tab |
| Modal | modal/Modal.js | 模态框 | **核心组件**，支持拖拽/全屏 |
| Context | contextmenu/ | 右键菜单 | **核心组件**，动态菜单 |
| Message | message/ | 消息提示 | success/error/warning静态方法 |
| Code | code/ | 代码展示 | 语法高亮 |
| Editor | editor/ | 代码编辑器 | 基于ace editor |

## 核心组件API

### Modal 模态框

```javascript
import { Modal, openModal } from '../components';

// 静态方法
Modal.success({ title, message, width });  // 成功提示
Modal.error({ title, message, width });    // 错误提示
Modal.confirm({ title, message, onOk, onCancel, width }); // 确认对话框

// 命令式打开
openModal(<Component />, {
  title: '标题',
  onOk: (modal, com) => { modal.close(); },
  onCancel: (modal) => { modal.close(); },
  footer: [<Button key="ok">确定</Button>], // 自定义底部
  fullScreen: false,  // 是否全屏
});
```

**Props**:
| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| title | string | - | 标题 |
| onOk | function | - | 确定回调 |
| onCancel | function | - | 取消回调 |
| footer | array | [确定,取消] | 底部按钮 |
| fullScreen | boolean | false | 全屏模式 |
| autoFocus | boolean | false | 自动聚焦 |

### Tree 树形组件

```javascript
import { Tree } from '../components';
const TreeNode = Tree.TreeNode;

<Tree
  showSearch           // 显示搜索框
  onContextMenu={(e, value, checked) => {}}  // 右键菜单
  onDoubleClick={(value) => {}}              // 双击打开
  onDrop={(drop, drag) => {}}                // 拖拽排序
  onClick={(value) => {}}                    // 单击选中
>
  <TreeNode name="节点名" value="节点标识" realName="显示名">
    <TreeNode ... />
  </TreeNode>
</Tree>
```

**特性**:
- Shift+点击多选
- 拖拽节点排序
- 搜索过滤节点
- 右键菜单(支持自定义菜单项)

### Message 消息提示

```javascript
import { Message } from '../components';

Message.success({ title: '保存成功' });
Message.error({ title: '保存失败' });
Message.warning({ title: '警告信息' });
```

### Context 右键菜单

```javascript
import { Context } from '../components';

<Context
  menus={[{ name: '删除', key: 'delete', icon: <Icon /> }]}
  left={e.clientX}
  top={e.clientY}
  display={display}
  closeContextMenu={() => {}}
  onClick={(e, key, menu) => {}}
/>
```

### Tab 标签页

```javascript
import { Tab } from '../components';
const TabPane = Tab.TabPane;

<Tab
  show="当前激活key"
  tabs={[{ key, title, icon, value }]}
  onClose={(key) => {}}
  onClick={(key) => {}}
>
  <TabPane key="tab1" title="标签1" icon="fa-table">内容1</TabPane>
  <TabPane key="tab2" title="标签2">内容2</TabPane>
</Tab>
```

**特性**:
- 标签超出宽度自动折叠
- 支持关闭按钮
- 支持图标显示

## 组件依赖关系

```
Tree → TreeNode → Input(搜索)
Modal → Button
Tab → TabPane
Context → (无内部依赖)
Message → (工具函数utils.js)
```

## 样式规范

- 类名前缀: `pdman-`
- 样式文件: 各组件目录下 `style/index.less`
- 主题色: `#1A7DC4` (蓝色)

## 已知坑点

1. **Modal拖拽边界**: 拖拽时限制在视口内，但不限制负坐标
2. **Tree多选**: 使用Shift点击，而非Ctrl
3. **Tab折叠**: 折叠面板中的Tab需点击才能显示
4. **Icon类型**: 支持font-awesome类名和antd图标组件

## 详细文档

- [api-modal.md](api-modal.md) - Modal详细API
- [api-tree.md](api-tree.md) - Tree详细API
- [api-message.md](api-message.md) - Message详细API
