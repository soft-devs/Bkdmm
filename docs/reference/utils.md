# Utils - 工具函数库

## 概述

核心工具函数库，提供JSON文件操作、代码生成、数据库版本管理、数据升级等关键功能。

## 工具文件索引

| 文件 | 用途 | 关键函数 |
|------|------|----------|
| json.js | JSON文件读写 | fileExist, readFilePromise, saveFilePromise |
| json2code.js | 代码生成引擎 | **核心**，doT模板渲染 |
| dbversionutils.js | 数据库版本对比 | compareTable, getVersionChanges |
| basedataupgrade.js | 数据升级 | upgrade (老版本数据迁移) |
| array.js | 数组操作 | moveArrayPosition |
| string.js | 字符串操作 | compareStringVersion |
| uuid.js | UUID生成 | uuid |
| listener.js | 窗口监听 | addOnResize |
| update.js | 版本更新检查 | getVersion, getCurrentVersion |

## 核心函数API

### json.js - 文件操作

```javascript
import {
  fileExist,
  readFilePromise,
  saveFilePromise,
  fileExistPromise,
  writeFile,
} from '../utils/json';

// 判断文件是否存在
fileExist(filePath); // → boolean

// 异步读取JSON文件
readFilePromise(filePath).then(data => {}).catch(err => {});

// 异步保存JSON文件
saveFilePromise(jsonObject, filePath).then(() => {}).catch(err => {});

// 文件不存在时创建
fileExistPromise(filePath, true, defaultData).then(data => {});

// 写入任意数据
writeFile(filePath, dataBuffer).then(() => {});
```

**函数清单**:
| 函数 | 同步/异步 | 说明 |
|------|-----------|------|
| fileExist | 同步 | 检查文件存在 |
| readFileSync | 同步 | 读取JSON |
| readFilePromise | Promise | 读取JSON |
| readFileCall | 回调 | 读取JSON |
| saveFileSync | 同步 | 保存JSON |
| saveFilePromise | Promise | 保存JSON |
| saveFileCall | 回调 | 保存JSON |
| fileExistPromise | Promise | 检查/创建文件 |
| deleteJsonFile | 同步 | 删除单个文件 |
| deleteDirectoryFile | 同步 | 删除目录及文件 |
| deleteDirPromise | Promise | 删除目录 |
| getFilesByDirSync | 同步 | 获取目录文件列表 |
| getFilesByDirPromise | Promise | 获取目录文件列表 |

### json2code.js - 代码生成

**核心功能**: 使用doT模板引擎生成SQL/Java代码

```javascript
// 内置模板变量转换函数
camel(str, firstUpper)    // 驼峰转换: user_name → userName/UserName
underline(str, upper)     // 下划线转换: userName → user_name/USER_NAME
upperCase(str)            // 大写
lowerCase(str)            // 小写
join(...args, delimiter)  // 拼接

// 模板数据结构
{
  entity: {
    title: '表代码',
    chnname: '表中文名',
    fields: [{ name, type, chnname, remark }],
    indexes: [{ name, fields, type }]
  },
  datatype: [数据类型映射列表],
  database: { code: 'MYSQL', type: '...' }
}
```

**生成流程**:
1. 读取数据表实体定义
2. 获取数据类型映射(根据数据库类型)
3. 应用doT模板渲染
4. 输出SQL/Java代码

### dbversionutils.js - 版本对比

**用途**: 对比新旧版本数据表，生成变更记录

```javascript
// 变更类型
{
  type: 'table' | 'field' | 'index',
  name: '表名.字段名.属性',
  opt: 'add' | 'delete' | 'update',
  changeData: '旧值=>新值'
}

// 核心函数
compareTable(currentTable, checkTable)  // 对比单个表
getVersionChanges(currentData, checkData) // 对比整个项目
```

**对比维度**:
- 表属性变更(title/chnname)
- 字段增删改
- 索引增删改

### array.js - 数组操作

```javascript
import { moveArrayPosition } from '../utils/array';

// 移动数组元素位置
moveArrayPosition(array, fromIndex, toIndex);
```

### string.js - 字符串操作

```javascript
import { compareStringVersion } from '../utils/string';

// 版本号比较
compareStringVersion('2.1.6', '2.1.5'); // → true (新版本更大)
```

### uuid.js - UUID生成

```javascript
import { uuid } from '../utils/uuid';

uuid(); // → 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
```

### listener.js - 窗口监听

```javascript
import { addOnResize } from '../utils/listener';

// 注册窗口大小变化回调
addOnResize(callback);
```

### update.js - 版本更新

```javascript
import { getVersion, getCurrentVersion } from '../utils/update';

// 获取最新版本信息(远程)
getVersion(callback);

// 获取当前版本
getCurrentVersion(); // → { version: '2.1.6' }
```

### basedataupgrade.js - 数据升级

```javascript
import { upgrade } from '../utils/basedataupgrade';

// 自动升级老版本项目数据
upgrade(dataSource, (newData, changed) => {
  if (changed) {
    saveProject(newData);
  }
});
```

## 函数依赖关系

```
json.js ←─────────────────────────────────────┐
    │                                         │
dbversionutils.js (依赖json.js) ←─────────────┤
    │                                         │
json2code.js (独立) ←──────────────────────────┤
    │                                         │
basedataupgrade.js (独立) ←────────────────────┤
    │                                         │
array.js, string.js, uuid.js (独立) ←──────────┤
    │                                         │
listener.js (独立) ←───────────────────────────┤
    │                                         │
update.js (独立) ←─────────────────────────────┘
```

## 已知坑点

1. **json.js路径处理**: Windows使用`\\`分隔，需转换为`/`
2. **json2code模板变量**: 模板中必须使用`{{=it.xxx}}`语法
3. **dbversionutils对比**: 仅对比字段名和类型，不对比注释
4. **文件操作异步**: 所有Promise版本需要正确处理异常
5. **数据升级**: 升级后需手动保存项目文件

## 详细文档

- [api-json.md](api-json.md) - 文件操作详细API
- [api-json2code.md](api-json2code.md) - 代码生成详细说明
- [api-dbversion.md](api-dbversion.md) - 版本对比详细说明