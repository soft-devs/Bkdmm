# Provider状态结构详解

## ProjectState

| 字段 | 类型 | 说明 |
|------|------|------|
| project | Project? | 当前加载的项目 |
| projectPath | String? | 项目文件路径 |
| isDirty | bool | 是否有未保存更改，默认false |
| isLoading | bool | 是否正在加载/保存，默认false |
| error | String? | 错误信息 |
| lastSavedAt | DateTime? | 最后保存时间 |
| lastAutoSavedAt | DateTime? | 最后自动保存时间 |
| statistics | ProjectStatistics? | 项目统计信息 |
| recentProjects | List\<ProjectHistory\> | 最近打开的项目列表 |

**计算属性**:
- `hasProject` - 是否有项目加载
- `canSave` - 是否可以保存
- `canSaveAs` - 是否可以另存为
- `hasValidPath` - 路径是否有效

## ProjectStatistics

| 字段 | 类型 | 说明 |
|------|------|------|
| moduleCount | int | 模块数量 |
| entityCount | int | 实体(表)数量 |
| fieldCount | int | 字段数量 |
| indexCount | int | 索引数量 |

## AppSettings

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| themeMode | String | 'system' | 主题模式 |
| accentColor | Color? | null | 强调色 |
| editorFontSize | double | 14.0 | 编辑器字体大小 |
| showLineNumbers | bool | true | 显示行号 |
| enableCodeCompletion | bool | true | 代码补全 |
| autoSaveInterval | int | 60 | 自动保存间隔(秒) |
| defaultDatabase | String? | null | 默认数据库类型 |
| defaultFieldsRevision | bool | false | 默认添加revision字段 |
| defaultFieldsCreatedBy | bool | false | 默认添加created_by字段 |
| defaultFieldsCreatedTime | bool | false | 默认添加created_time字段 |
| defaultFieldsUpdatedBy | bool | false | 默认添加updated_by字段 |
| defaultFieldsUpdatedTime | bool | false | 默认添加updated_time字段 |

## ProjectSettings

| 字段 | 类型 | 说明 |
|------|------|------|
| inheritDefaultDatabase | bool | 是否继承全局数据库设置，默认true |
| inheritDefaultFields | bool | 是否继承全局字段设置，默认true |
| defaultDatabase | String? | 项目默认数据库(不继承时有效) |
| defaultFieldsRevision | bool? | 项目revision字段配置 |
| defaultFieldsCreatedBy | bool? | 项目created_by字段配置 |
| defaultFieldsCreatedTime | bool? | 项目created_time字段配置 |
| defaultFieldsUpdatedBy | bool? | 项目updated_by字段配置 |
| defaultFieldsUpdatedTime | bool? | 项目updated_time字段配置 |

## ProjectHistory

| 字段 | 类型 | 说明 |
|------|------|------|
| name | String | 项目名称 |
| path | String | 项目文件路径 |
| lastOpened | DateTime | 最后打开时间 |