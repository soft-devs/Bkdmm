# TDesign Flutter 主题定制

## 主题配置

可通过 JSON 文件配置主题样式（颜色、字体尺寸、字体样式、圆角、阴影）。

### 方式一：JSON 配置

直接使用 JSON 格式定义主题属性：

```dart
String themeConfig = '''
{
  "myTheme": {
    "color": {
      "brandNormalColor": "#D7B386"
    },
    "font": {
      "fontBodyMedium": {
        "size": 40,
        "lineHeight": 55
      }
    }
  }
}
''';

MaterialApp(
  theme: ThemeData(
    extensions: [TDThemeData.fromJson('myTheme', themeConfig)!],
  ),
  // ...
)
```

> 所有可用的主题键值请参考 [td_default_theme.dart](https://github.com/Tencent/tdesign-flutter/blob/develop/tdesign-component/lib/src/theme/td_default_theme.dart)

### 方式二：主题生成器（推荐）

如果你不想自定义太多颜色，但是想要拥有好看的自定义主题，"主题生成器"是个不错的选择。

#### 步骤

1. **生成**：进入 [TDesign 主题生成器](https://tdesign.tencent.com/vue/custom-theme)，点击下方的主题生成器，在右边生成器里选择想要的颜色，点击下载。

2. **转换**：此时你得到一个 `theme.css` 文件，将该文件放到 `tdesign-component/example/shell/theme/` 文件夹下，修改该文件夹下的 `css2JsonTheme.dart` 为你自己的文件名、主题名和输出路径，即可得到一个 `theme.json` 文件。

3. **应用**：将主题 JSON 加载进 `TDTheme`，美观的自定义主题就设置完成了。

```dart
// 开启多套主题功能
TDTheme.needMultiTheme();

var jsonString = await rootBundle.loadString('assets/theme.json');
var _themeData = TDThemeData.fromJson('green', jsonString);
// ...
MaterialApp(
  title: 'TDesign Flutter Example',
  theme: ThemeData(
    extensions: [_themeData]
  ),
  home: MyHomePage(title: 'TDesign Flutter 组件库'),
);
```

## 深色模式

通过"主题生成器"生成的主题配置文件，默认支持暗色模式相关色值。

```dart
// 开启多套主题功能
TDTheme.needMultiTheme();
// ...
// MaterialApp 中设置三个属性如下，如果有自定义主题属性，可以通过 copyWith() 方法修改。
// 注：主题切换需要业务自己实现，比如使用 Provider，具体可参考 tdesign-flutter/tdesign-component/example/lib/component_test/dark_test.dart
MaterialApp(
  theme: _themeData.systemThemeDataLight,
  darkTheme: _themeData.systemThemeDataDark,
  themeMode: themeModeProvider.themeMode,
  // ...
)
```

## 主题颜色

### 品牌色

| 颜色名称 | 说明 |
|---------|------|
| brandNormalColor | 品牌主色 |
| brandColor | 品牌色系列 |

### 功能色

| 颜色名称 | 说明 |
|---------|------|
| successColor | 成功色 |
| warningColor | 警告色 |
| errorColor | 错误色 |
| infoColor | 信息色 |

### 灰度色

| 颜色名称 | 说明 |
|---------|------|
| fontGyColor1 | 深灰字体1 |
| fontGyColor2 | 深灰字体2 |
| fontGyColor3 | 深灰字体3 |
| fontGyColor4 | 深灰字体4 |
| bgColor | 背景色 |
| bgColor1 | 背景色1 |
| bgColor2 | 背景色2 |

## 字体规范

### 字体大小

```dart
TDTheme.of(context).fontBodyLarge  // 大号正文
TDTheme.of(context).fontBodyMedium // 中号正文
TDTheme.of(context).fontBodySmall  // 小号正文
TDTheme.of(context).fontHeadline   // 标题
TDTheme.of(context).fontTitle      // 标题
TDTheme.of(context).fontSubtitle   // 副标题
```

### 圆角

```dart
TDTheme.of(context).radiusDefault  // 默认圆角
TDTheme.of(context).radiusSmall    // 小圆角
TDTheme.of(context).radiusLarge    // 大圆角
```

### 阴影

```dart
TDTheme.of(context).shadowDefault  // 默认阴影
TDTheme.of(context).shadowSmall    // 小阴影
TDTheme.of(context).shadowLarge    // 大阴影
```