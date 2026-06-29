# TabBar 标签栏

用于页面切换的底部导航栏。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 基础用法

```dart
class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: TDTabBar(
        currentIndex: _currentIndex,
        onChange: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        tabs: [
          TDTabBarItem(
            icon: TDIcons.home,
            text: '首页',
          ),
          TDTabBarItem(
            icon: TDIcons.app,
            text: '分类',
          ),
          TDTabBarItem(
            icon: TDIcons.user,
            text: '我的',
          ),
        ],
      ),
    );
  }
}
```

### 带徽标

```dart
TDTabBar(
  tabs: [
    TDTabBarItem(
      icon: TDIcons.home,
      text: '首页',
    ),
    TDTabBarItem(
      icon: TDIcons.message,
      text: '消息',
      badge: TDBadge(count: 5),
    ),
    TDTabBarItem(
      icon: TDIcons.user,
      text: '我的',
    ),
  ],
),
```

### 纯图标

```dart
TDTabBar(
  tabs: [
    TDTabBarItem(icon: TDIcons.home),
    TDTabBarItem(icon: TDIcons.app),
    TDTabBarItem(icon: TDIcons.user),
  ],
),
```

### 自定义颜色

```dart
TDTabBar(
  selectedColor: TDTheme.of(context).brandNormalColor,
  unselectedColor: Colors.grey,
  tabs: [
    TDTabBarItem(icon: TDIcons.home, text: '首页'),
    TDTabBarItem(icon: TDIcons.user, text: '我的'),
  ],
),
```

## API

### TDTabBar Props

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| tabs | `List<TDTabBarItem>` | - | 标签项列表 |
| currentIndex | `int` | `0` | 当前选中索引 |
| onChange | `ValueChanged<int>?` | - | 切换回调 |
| selectedColor | `Color?` | - | 选中颜色 |
| unselectedColor | `Color?` | - | 未选中颜色 |
| backgroundColor | `Color?` | - | 背景色 |

### TDTabBarItem

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| icon | `IconData` | - | 图标 |
| text | `String?` | - | 文字 |
| badge | `TDBadge?` | - | 徽标 |