# 数据结构

## HomeViewState

HomeView的内部状态：

| 字段 | 类型 | 说明 |
|------|------|------|
| _isCreating | bool | 是否正在创建项目 |

## QuickActionCard参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| icon | IconData | ✓ | 图标 |
| label | String | ✓ | 标题 |
| description | String | ✓ | 描述 |
| tdTheme | TDThemeData | ✓ | 主题数据 |
| onTap | VoidCallback? | | 点击回调 |

## HistoryListTile参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| history | ProjectHistory | ✓ | 历史记录数据 |
| onTap | VoidCallback | | 点击回调 |
| onDelete | VoidCallback | | 删除回调 |
| onFavorite | VoidCallback? | | 收藏回调 |