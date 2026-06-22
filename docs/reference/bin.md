# Bin - 构建/启动脚本

## 概述

构建和启动脚本模块，控制Webpack编译和Electron启动流程。

## 文件结构

```
bin/
├── build.js  # 生产构建脚本
└── start.js  # 开发启动脚本
```

## start.js - 开发启动脚本

### 功能流程

```
设置NODE_ENV=development
    ↓
加载webpack.dev.config.js
    ↓
创建WebpackDevServer (localhost:3005)
    ↓
启动开发服务器
    ↓
spawn子进程启动Electron
```

### 关键代码

```javascript
// 启动开发服务器
devServer.listen(3005, 'localhost', () => {
  // 启动Electron
  childProcess.spawn('npm', ['run', 'electron'], {
    shell: true,
    env: process.env,
    stdio: 'inherit'
  });
});
```

### 端口配置

- WebpackDevServer: `localhost:3005`
- Electron加载: `http://localhost:3005/index.html`

## build.js - 生产构建脚本

### 功能流程

```
设置NODE_ENV=production
    ↓
加载webpack.pro.config.js
    ↓
执行Webpack编译
    ↓
输出到build目录
```

### 输出目录结构

```
build/
├── index.html     # 入口HTML
├── index.js       # 主JS
├── style.css      # 样式文件
├── jar/           # Java连接器
└── ...            # 其他资源
```

## npm scripts映射

| npm命令 | 脚本 | 说明 |
|---------|------|------|
| npm run start | bin/start.js | 开发模式启动 |
| npm run build | bin/build.js | 生产构建 |
| npm run electron | electron ./src/main | 启动Electron |

## 已知坑点

1. **子进程启动**: Electron以子进程方式启动，关闭Electron会触发父进程退出
2. **环境变量**: 需在脚本开头设置NODE_ENV
3. **编译错误**: webpack编译失败会输出错误信息但不退出
4. **热更新**: 开发环境代码变更自动刷新Electron界面