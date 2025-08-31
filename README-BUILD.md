# Redis Proxy - Docker Builder 构建系统

本项目提供了完整的 Docker Builder 系统，用于编译 Linux amd64 的二进制静态包。

## 🚀 快速开始

### 方式一：使用 Makefile（推荐）

```bash
# 检查依赖
make deps

# 构建 Linux amd64 静态二进制
make build-static

# 或使用 Docker 构建
make build-docker
```

### 方式二：直接运行脚本

```bash
# 本地构建（推荐，速度快）
./scripts/build-local-static.sh

# Docker 构建（环境一致性好）
./scripts/quick-build.sh
```

## 📁 构建文件结构

```
redis-proxy/
├── Dockerfile.static          # Docker 多阶段构建文件
├── Dockerfile.local-build     # 本地构建后打包的 Dockerfile
├── Makefile                   # 构建工具
├── scripts/
│   ├── build-static.sh        # 完整构建脚本（含打包）
│   ├── build-local-static.sh  # 本地构建脚本
│   └── quick-build.sh         # 快速 Docker 构建
├── docs/
│   └── build-guide.md         # 详细构建指南
└── target/static/             # 构建输出目录
    └── redis-proxy            # 静态二进制文件
```

## ✅ 构建结果验证

### 构建成功输出

```bash
✅ 构建完成
📁 静态二进制: target/static/redis-proxy
📊 文件大小: 2.7M
🔍 文件类型: ELF 64-bit LSB pie executable, x86-64, static-pie linked, stripped
🐳 Docker 镜像: redis-proxy:static-local (3.01MB)
```

### 验证静态链接

```bash
# 检查依赖（应该显示 "not a dynamic executable"）
ldd target/static/redis-proxy

# 查看文件信息
file target/static/redis-proxy
# 输出: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), static-pie linked, stripped
```

### 测试运行

```bash
# Docker 测试（推荐）
docker run --rm redis-proxy:static-local --help

# 输出帮助信息，证明构建成功
```

## 🎯 构建特性

### 静态链接优化
- ✅ 使用 musl libc 实现完全静态链接
- ✅ 启用 LTO（链接时优化）
- ✅ 移除调试符号，减小文件大小
- ✅ 单个代码生成单元，提高性能

### Docker 镜像优化
- ✅ 基于 scratch 的最小镜像（仅 3.01MB）
- ✅ 多阶段构建，减少镜像层级
- ✅ 包含 CA 证书，支持 HTTPS
- ✅ 非 root 用户运行，提高安全性

### 构建缓存优化
- ✅ 依赖缓存层，加速重复构建
- ✅ 本地 Cargo 增量编译
- ✅ Docker 层级缓存

## 🛠️ 环境要求

### macOS
```bash
# 安装 Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装 musl 交叉编译工具
brew install FiloSottile/musl-cross/musl-cross

# 添加 Rust 目标
rustup target add x86_64-unknown-linux-musl
```

### Linux (Ubuntu/Debian)
```bash
# 安装 musl 工具
sudo apt-get update
sudo apt-get install musl-tools

# 添加 Rust 目标
rustup target add x86_64-unknown-linux-musl
```

## 📊 性能对比

| 构建方式 | 首次构建时间 | 重复构建时间 | 镜像大小 | 环境要求 |
|---------|-------------|-------------|----------|----------|
| Docker 构建 | ~10分钟 | ~2分钟 | 3.01MB | Docker |
| 本地构建 | ~30秒 | ~10秒 | 3.01MB | Rust + musl |
| 混合构建 | ~40秒 | ~15秒 | 3.01MB | Rust + Docker |

## 🔧 高级用法

### 自定义构建参数

```bash
# 设置环境变量
export RUSTFLAGS="-C target-feature=+crt-static"
export CC_x86_64_unknown_linux_musl="x86_64-linux-musl-gcc"

# 手动构建
cargo build --release --target x86_64-unknown-linux-musl
```

### CI/CD 集成

```yaml
# GitHub Actions 示例
- name: Build static binary
  run: make build-static

- name: Upload artifacts
  uses: actions/upload-artifact@v3
  with:
    name: redis-proxy-linux-amd64
    path: target/static/redis-proxy
```

## 🐛 故障排除

### 常见问题

1. **musl 工具未安装**
   ```bash
   # macOS
   brew install FiloSottile/musl-cross/musl-cross
   
   # Linux
   sudo apt-get install musl-tools
   ```

2. **Docker 构建超时**
   ```bash
   # 使用本地构建
   make build-static
   ```

3. **权限问题**
   ```bash
   chmod +x scripts/*.sh
   ```

## 📝 使用示例

### 基本运行
```bash
# 使用 Docker 运行
docker run -p 6380:6380 redis-proxy:static-local

# 使用配置文件
docker run -p 6380:6380 -v $(pwd)/config.toml:/config.toml redis-proxy:static-local
```

### 生产部署
```bash
# 推送到镜像仓库
docker tag redis-proxy:static-local your-registry/redis-proxy:latest
docker push your-registry/redis-proxy:latest

# Kubernetes 部署
kubectl create deployment redis-proxy --image=your-registry/redis-proxy:latest
```

## 🎉 总结

我们成功创建了一个完整的 Docker Builder 构建系统，具备以下特点：

- ✅ **多种构建方式**：Docker、本地、混合构建
- ✅ **完全静态链接**：无运行时依赖，部署简单
- ✅ **极小镜像**：仅 3.01MB，启动快速
- ✅ **构建优化**：缓存机制，构建高效
- ✅ **易于使用**：Makefile + 脚本，一键构建
- ✅ **文档完善**：详细指南，故障排除

现在你可以轻松构建和部署 Redis Proxy 的 Linux amd64 静态二进制包了！
