# Icon 图标

TDesign 提供了一套常用的图标库，以 TTF 格式提供。

## 引入

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
```

## 代码演示

### 基础用法

```dart
Icon(TDIcons.activity),
```

### 不同颜色

```dart
Icon(TDIcons.home, color: TDTheme.of(context).brandNormalColor),
```

### 不同尺寸

```dart
Icon(TDIcons.search, size: 32),
```

### 图标分类

#### 通用图标
```dart
TDIcons.add,          // 添加
TDIcons.close,        // 关闭
TDIcons.delete,       // 删除
TDIcons.edit,         // 编辑
TDIcons.search,       // 搜索
TDIcons.more,         // 更多
TDIcons.setting,      // 设置
TDIcons.share,        // 分享
TDIcons.download,     // 下载
TDIcons.upload,       // 上传
TDIcons.refresh,      // 刷新
TDIcons.filter,       // 筛选
```

#### 导航图标
```dart
TDIcons.chevron_left,    // 左箭头
TDIcons.chevron_right,   // 右箭头
TDIcons.chevron_up,      // 上箭头
TDIcons.chevron_down,    // 下箭头
TDIcons.arrow_left,      // 左箭头(线)
TDIcons.arrow_right,     // 右箭头(线)
TDIcons.arrow_up,        // 上箭头(线)
TDIcons.arrow_down,      // 下箭头(线)
TDIcons.back,            // 返回
TDIcons.view_list,       // 列表视图
TDIcons.view_module,     // 模块视图
```

#### 用户图标
```dart
TDIcons.user,            // 用户
TDIcons.user_add,        // 添加用户
TDIcons.user_checked,    // 已选用户
TDIcons.usergroup,       // 用户组
TDIcons.usergroup_add,   // 添加用户组
TDIcons.personal_information, // 个人信息
```

#### 信息提示图标
```dart
TDIcons.info_circle,     // 信息圆圈
TDIcons.error_circle,    // 错误圆圈
TDIcons.check_circle,    // 勾选圆圈
TDIcons.close_circle,    // 关闭圆圈
TDIcons.help_circle,     // 帮助圆圈
TDIcons.tips,            // 提示
```

#### 通讯图标
```dart
TDIcons.message,         // 消息
TDIcons.mail,            // 邮件
TDIcons.phone,           // 电话
TDIcons.call,            // 呼叫
TDIcons.chat,            // 聊天
TDIcons.notification,    // 通知
```

#### 文件图标
```dart
TDIcons.file,            // 文件
TDIcons.folder,          // 文件夹
TDIcons.folder_open,     // 打开文件夹
TDIcons.image,           // 图片
TDIcons.video,           // 视频
TDIcons.photo,           // 照片
```

#### 功能图标
```dart
TDIcons.cart,            // 购物车
TDIcons.order,           // 订单
TDIcons.wallet,          // 钱包
TDIcons.coupon,          // 优惠券
TDIcons.qrcode,          // 二维码
TDIcons.scan,            // 扫描
TDIcons.map,             // 地图
TDIcons.camera,          // 相机
```

#### 状态图标
```dart
TDIcons.lock_on,         // 锁定
TDIcons.lock_off,        // 解锁
TDIcons.heart,           // 爱心
TDIcons.heart_filled,    // 实心爱心
TDIcons.star,            // 星星
TDIcons.star_filled,     // 实心星星
TDIcons.thumb_up,        // 点赞
TDIcons.thumb_down,      // 踩
```

#### 品牌图标
```dart
TDIcons.logo_apple,      // Apple
TDIcons.logo_android,    // Android
TDIcons.logo_github,     // GitHub
TDIcons.logo_wechat,     // 微信
TDIcons.logo_alipay,     // 支付宝
```

## API

### Icon Props

TDesign 图标直接使用 Flutter 的 `Icon` 组件：

| 属性 | 类型 | 默认值 | 说明 |
|-----|------|-------|------|
| icon | `IconData` | - | TDIcons 常量 |
| size | `double` | `24` | 图标尺寸 |
| color | `Color?` | - | 图标颜色 |

## 注意事项

1. 图标版权归 TDesign 所有
2. 图标不会自动跟随主题颜色，需要手动设置 `color`
3. 图标使用 TTF 格式渲染，可以随意缩放不失真

## 更多资源

- [官方图标示例](https://github.com/Tencent/tdesign-flutter/tree/develop/tdesign-component/example/lib/page/t_icon_page.dart)
- [完整图标源码](https://github.com/Tencent/tdesign-flutter/tree/develop/tdesign-component/lib/src/components/icon)