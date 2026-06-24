# Avatar 头像

用于展示用户头像或品牌图标。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 基础用法

```dart
// 图片头像
TDAvatar(
  url: 'https://example.com/avatar.jpg',
),

// 文字头像
TDAvatar(
  text: '张',
),
```

### 不同尺寸

```dart
TDAvatar(
  url: 'https://example.com/avatar.jpg',
  size: TDAvatarSize.small,
),
TDAvatar(
  url: 'https://example.com/avatar.jpg',
  size: TDAvatarSize.medium,
),
TDAvatar(
  url: 'https://example.com/avatar.jpg',
  size: TDAvatarSize.large,
),
```

### 不同形状

```dart
// 圆形头像（默认）
TDAvatar(
  url: 'https://example.com/avatar.jpg',
  shape: TDAvatarShape.circle,
),

// 方形头像
TDAvatar(
  url: 'https://example.com/avatar.jpg',
  shape: TDAvatarShape.square,
),
```

### 带徽标

```dart
TDAvatar(
  url: 'https://example.com/avatar.jpg',
  badge: TDBadge(
    count: 3,
  ),
),
```

### 头像组

```dart
TDAvatarGroup(
  avatars: [
    TDAvatar(url: '...'),
    TDAvatar(url: '...'),
    TDAvatar(url: '...'),
    TDAvatar(text: '+5'),
  ],
),
```

### 带图标

```dart
TDAvatar(
  icon: TDIcons.user,
),
```

## API

### TDAvatar Props

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| url | `String?` | - | 图片地址 |
| text | `String?` | - | 文字内容 |
| icon | `IconData?` | - | 图标 |
| size | `TDAvatarSize` | `medium` | 尺寸 |
| shape | `TDAvatarShape` | `circle` | 形状 |
| badge | `TDBadge?` | - | 徽标 |

### TDAvatarSize

| 值 | 说明 |
|----|------|
| `small` | 小号 |
| `medium` | 中号（默认） |
| `large` | 大号 |

### TDAvatarShape

| 值 | 说明 |
|----|------|
| `circle` | 圆形（默认） |
| `square` | 方形 |

### TDAvatarGroup Props

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| avatars | `List<TDAvatar>` | - | 头像列表 |
| max | `int?` | - | 最大显示数量 |