# Config - Webpack构建配置

## 概述

Webpack构建配置模块，管理开发和生产环境的打包配置。

## 文件结构

```
config/
├── webpack.dev.config.js  # 开发环境配置
└── webpack.pro.config.js # 生产环境配置
```

## 开发环境配置 (webpack.dev.config.js)

### 入口配置

```javascript
entry: {
  index: ['babel-polyfill', './src/index']
}
```

### 输出配置

```javascript
output: {
  path: './build',
  filename: '[name].js'
}
```

### Loaders配置

| Loader | 文件类型 | 说明 |
|--------|----------|------|
| babel-loader | .js/.jsx/.tsx | ES6+转译 |
| json-loader | .json | JSON文件导入 |
| eslint-loader | .js/.jsx/.tsx | 代码检查 |
| css-loader | .css | CSS处理 |
| less-loader | .less | Less编译 |
| url-loader | 图片/字体 | 资源内联 |

### 插件配置

| 插件 | 说明 |
|------|------|
| HtmlWebpackPlugin | 生成index.html |
| ExtractTextPlugin | 提取CSS到单独文件 |
| ScriptExtHtmlPlugin | 脚本加载属性配置 |

### 开发服务器

```javascript
// bin/start.js
devServer: {
  contentBase: './public',
  port: 3005,
  hot: true
}
```

## 生产环境配置 (webpack.pro.config.js)

与开发配置的主要差异：

| 配置项 | 开发环境 | 生产环境 |
|--------|----------|----------|
| devtool | cheap-module-eval-source-map | (无) |
| 代码压缩 | 无 | UglifyJsPlugin |
| CSS压缩 | 无 | OptimizeCssAssetsPlugin |
| source-map | 无 | 生成 |

## 环境变量

| 变量 | 值 | 说明 |
|------|-----|------|
| NODE_ENV | development | 开发模式 |
| NODE_ENV | production | 生产模式 |

**使用方式**:
```javascript
if (process.env.NODE_ENV === 'development') {
  // 开发模式逻辑
}
```

## 构建流程

### 开发构建

```
npm run start
    ↓
设置NODE_ENV=development
    ↓
启动WebpackDevServer (port:3005)
    ↓
启动Electron
    ↓
热更新监听
```

### 生产构建

```
npm run build
    ↓
设置NODE_ENV=production
    ↓
Webpack打包
    ↓
输出到build目录
    ↓
electron-builder打包安装包
```

## 已知坑点

1. **Node __dirname**: 需显式配置 `node: { __dirname: true }`
2. **Electron路径**: 生产环境需使用 `app.asar.unpacked` 路径访问JAR
3. **Autoprefixer**: 浏览器兼容配置在loader中
4. **热更新**: 开发环境使用webpack-dev-server