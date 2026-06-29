# 数据模型详细字段说明

## Entity (数据表)

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | String | ✓ | 表唯一标识，UUID格式 |
| title | String | ✓ | 表代码，英文命名如 `user_info` |
| chnname | String | ✓ | 表中文名，如 `用户信息表` |
| remark | String? | | 表备注说明 |
| fields | List\<Field\> | | 字段列表，默认空数组 |
| indexes | List\<Index\> | | 索引列表，默认空数组 |
| createdAt | DateTime | ✓ | 创建时间 |
| updatedAt | DateTime | ✓ | 更新时间 |

## Field (字段)

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | String | ✓ | 字段唯一标识 |
| name | String | ✓ | 字段名，如 `user_id` |
| chnname | String | ✓ | 字段中文名 |
| type | String | ✓ | 数据类型，如 `INT`, `VARCHAR(255)` |
| pk | bool | | 是否主键，默认false |
| allowNull | bool | | 是否允许NULL，默认true |
| autoIncrement | bool | | 是否自增，默认false |
| defaultValue | String? | | 默认值 |
| remark | String? | | 字段备注 |

## Index (索引)

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | String | ✓ | 索引唯一标识 |
| name | String | ✓ | 索引名 |
| fields | List\<String\> | ✓ | 索引字段名列表 |
| unique | bool | | 是否唯一索引，默认false |

## Module (模块)

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | String | ✓ | 模块唯一标识 |
| name | String | ✓ | 模块代码，英文命名 |
| chnname | String | ✓ | 模块中文名 |
| description | String? | | 模块描述 |
| entities | List\<Entity\> | | 数据表列表 |
| graphCanvas | GraphCanvas | ✓ | 关系图画布 |
| createdAt | DateTime | ✓ | 创建时间 |
| updatedAt | DateTime | ✓ | 更新时间 |

## GraphCanvas (关系图画布)

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| nodes | List\<GraphNode\> | | 图节点列表 |
| scale | double | | 缩放比例，默认1.0 |
| offsetX | double | | X偏移量 |
| offsetY | double | | Y偏移量 |

## GraphNode (图节点)

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| entityId | String | ✓ | 关联的实体ID |
| x | double | ✓ | X坐标 |
| y | double | ✓ | Y坐标 |

## Project (项目)

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | String | ✓ | 项目唯一标识 |
| name | String | ✓ | 项目名称 |
| description | String? | | 项目描述 |
| version | String | | 项目版本，默认 `1.0.0` |
| modules | List\<Module\> | | 模块列表 |
| dataTypeDomains | DataTypeDomains | ✓ | 数据类型配置 |
| profile | Profile | ✓ | 项目配置 |
| versionHistory | List\<VersionSnapshot\>? | | 版本历史 |
| createdAt | DateTime | ✓ | 创建时间 |
| updatedAt | DateTime | ✓ | 更新时间 |

## DataTypeDomains (数据类型域)

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| datatype | Map\<String, DataType\> | ✓ | 数据类型映射表 |

## DataType (数据类型)

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | String | ✓ | 类型名称 |
| chnname | String | ✓ | 类型中文名 |
| apply | Map\<String, String\> | | 数据库类型映射 |

## Profile (项目配置)

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| defaultDatabase | String? | | 默认数据库类型 |
| defaultFields | DefaultFields | | 默认字段配置 |

## ProjectHistory (项目历史)

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | String | ✓ | 项目名称 |
| path | String | ✓ | 项目文件路径 |
| lastOpened | DateTime | ✓ | 最后打开时间 |
