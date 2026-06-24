# Swiper 轮播图

用于展示多张图片或内容的轮播组件。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 基础用法

```dart
TDSwiper(
  children: [
    Container(color: Colors.red, child: Center(child: Text('1'))),
    Container(color: Colors.blue, child: Center(child: Text('2'))),
    Container(color: Colors.green, child: Center(child: Text('3'))),
  ],
),
```

### 自动播放

```dart
TDSwiper(
  autoplay: true,
  interval: 3000,
  children: [
    Image.network('url1'),
    Image.network('url2'),
  ],
),
```

### 自定义指示器

```dart
TDSwiper(
  indicator: TDSwiperIndicator(
    position: TDSwiperIndicatorPosition.bottomCenter,
  ),
  children: [...],
),
```

## API

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| children | `List<Widget>` | - | 子组件列表 |
| autoplay | `bool` | `false` | 是否自动播放 |
| interval | `int` | `3000` | 自动播放间隔(ms) |
| height | `double?` | - | 容器高度 |
| indicator | `Widget?` | - | 自定义指示器 |

> 完整 API 参考 [官方文档](https://tdesign.tencent.com/flutter/components/swiper)