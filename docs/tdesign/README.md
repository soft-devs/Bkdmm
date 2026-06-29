# TDesign Flutter 组件库文档

> 来源: [TDesign Flutter](https://github.com/Tencent/tdesign-flutter) | [官方文档](https://tdesign.tencent.com/flutter/getting-started)

## 简介

**TDesign Flutter** 是基于腾讯设计体系的跨平台 UI 组件库，使用 Flutter 框架开发，可快速构建美观、一致的移动端/Web 应用，提供丰富的预制组件和主题定制能力，支持 iOS、Android、Web 多端运行。

## 特性

- 提供遵循 TDesign 设计规范的 Flutter UI 组件库
- 支持根据 App 设计风格自定义主题
- 提供常用图标库，支持自定义替换
- 根据 TDesign 规范定义颜色组（可在 `TDColors` 中查看）
- 通过颜色值声明类实时预览默认颜色效果

## SDK 版本要求

```yaml
dart: ">=3.2.6 <4.0.0"
flutter: ">=3.16.0"
```

## 安装

### 添加依赖

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  tdesign_flutter: ^0.2.7
```

### 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 组件列表

### 基础组件
| 组件 | 说明 |
|------|------|
| [Button 按钮](./components/button.md) | 按钮组件 |
| [Divider 分割线](./components/divider.md) | 分割线组件 |
| [Fab 悬浮按钮](./components/fab.md) | 悬浮按钮组件 |
| [Icon 图标](./components/icon.md) | 图标组件 |
| [Link 链接](./components/link.md) | 链接组件 |
| [Text 文本](./components/text.md) | 文本组件 |

### 表单组件
| 组件 | 说明 |
|------|------|
| [Cascader 级联选择器](./components/cascader.md) | 级联选择器 |
| [Checkbox 复选框](./components/checkbox.md) | 复选框组件 |
| [Date_Time_Picker 日期时间选择器](./components/date_time_picker.md) | 日期时间选择 |
| [Form 表单](./components/form.md) | 表单组件 |
| [Input 输入框](./components/input.md) | 输入框组件 |
| [Picker 选择器](./components/picker.md) | 选择器组件 |
| [Radio 单选框](./components/radio.md) | 单选框组件 |
| [Rate 评分](./components/rate.md) | 评分组件 |
| [Search 搜索框](./components/search.md) | 搜索框组件 |
| [Slider 滑块](./components/slider.md) | 滑块组件 |
| [Stepper 步进器](./components/stepper.md) | 步进器组件 |
| [Switch 开关](./components/switch.md) | 开关组件 |
| [Textarea 多行文本](./components/textarea.md) | 多行文本框 |
| [Upload 上传](./components/upload.md) | 上传组件 |

### 数据展示
| 组件 | 说明 |
|------|------|
| [Avatar 头像](./components/avatar.md) | 头像组件 |
| [Badge 徽标](./components/badge.md) | 徽标组件 |
| [Calendar 日历](./components/calendar.md) | 日历组件 |
| [Cell 单元格](./components/cell.md) | 单元格组件 |
| [Collapse 折叠面板](./components/collapse.md) | 折叠面板 |
| [Empty 空状态](./components/empty.md) | 空状态组件 |
| [Footer 页脚](./components/footer.md) | 页脚组件 |
| [Image 图片](./components/image.md) | 图片组件 |
| [Image_Viewer 图片预览](./components/image_viewer.md) | 图片预览组件 |
| [Indexes 索引](./components/indexes.md) | 索引组件 |
| [Progress 进度条](./components/progress.md) | 进度条组件 |
| [Result 结果](./components/result.md) | 结果组件 |
| [Skeleton 骨架屏](./components/skeleton.md) | 骨架屏组件 |
| [Steps 步骤条](./components/steps.md) | 步骤条组件 |
| [Table 表格](./components/table.md) | 表格组件 |
| [Tag 标签](./components/tag.md) | 标签组件 |
| [Tree 树形控件](./components/tree.md) | 树形控件 |
| [Time_Counter 计时器](./components/time_counter.md) | 计时器组件 |

### 反馈组件
| 组件 | 说明 |
|------|------|
| [Action_Sheet 动作面板](./components/action_sheet.md) | 动作面板 |
| [Dialog 对话框](./components/dialog.md) | 对话框组件 |
| [Drawer 抽屉](./components/drawer.md) | 抽屉组件 |
| [Loading 加载](./components/loading.md) | 加载组件 |
| [Message 消息通知](./components/message.md) | 消息通知 |
| [Notice_Bar 公告栏](./components/notice_bar.md) | 公告栏组件 |
| [Popover 气泡弹出框](./components/popover.md) | 气泡弹出框 |
| [Popup 弹出层](./components/popup.md) | 弹出层组件 |
| [Pull_Down 下拉刷新](./components/refresh.md) | 下拉刷新 |
| [Toast 轻提示](./components/toast.md) | 轻提示组件 |

### 导航组件
| 组件 | 说明 |
|------|------|
| [Backtop 返回顶部](./components/backtop.md) | 返回顶部 |
| [Dropdown_Menu 下拉菜单](./components/dropdown_menu.md) | 下拉菜单 |
| [Indexs 索引](./components/indexes.md) | 索引组件 |
| [Navbar 导航栏](./components/navbar.md) | 导航栏组件 |
| [Sidebar 侧边导航](./components/sidebar.md) | 侧边导航 |
| [Tabbar 标签栏](./components/tabbar.md) | 标签栏组件 |
| [Tabs 选项卡](./components/tabs.md) | 选项卡组件 |

### 操作组件
| 组件 | 说明 |
|------|------|
| [Swipe_Cell 滑动操作](./components/swipe_cell.md) | 滑动操作组件 |
| [Swiper 轮播图](./components/swiper.md) | 轮播图组件 |

## 快速开始

### 主题配置

通过 `TDTheme.of(context)` 或 `TDTheme.defaultData()` 获取主题数据：

```dart
// 颜色
TDTheme.of(context).brandNormalColor

// 字体
TDTheme.defaultData().fontBodyLarge
```

### 图标使用

TDesign 图标为 TTF 格式：

```dart
Icon(TDIcons.activity)
```

## 相关链接

- [官方文档](https://tdesign.tencent.com/flutter/getting-started)
- [GitHub 仓库](https://github.com/Tencent/tdesign-flutter)
- [Pub.dev](https://pub.dev/packages/tdesign_flutter)
- [示例应用](https://github.com/Tencent/tdesign-flutter/tree/main/tdesign-component)