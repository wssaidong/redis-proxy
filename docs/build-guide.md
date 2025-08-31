# Redis Proxy 构建指南

本文档介绍如何使用 Docker Builder 编译 Linux amd64 的二进制静态包。

## 构建方式概览

我们提供了三种构建方式：

1. **Docker 构建** - 完全在 Docker 容器中构建（推荐用于 CI/CD）
2. **本地构建** - 在本地环境构建静态二进制
3. **混合构建** - 本地构建后打包到 Docker 镜像

## 方式一：Docker 构建（推荐）

### 特点
- ✅ 环境一致性好
- ✅ 无需本地安装 Rust 工具链
- ❌ 首次构建时间较长（需下载镜像）

### 使用方法

```bash
# 快速构建
make build-docker

# 或者直接运行脚本
./scripts/quick-build.sh

# 或者使用完整构建脚本
./scripts/build-static.sh
```

### 构建文件
- `Dockerfile.static` - 多阶段构建 Dockerfile
- `scripts/quick-build.sh` - 快速构建脚本
- `scripts/build-static.sh` - 完整构建脚本（包含打包）

## 方式二：本地构建

### 特点
- ✅ 构建速度快
- ✅ 便于调试
- ❌ 需要配置本地环境

### 环境要求

#### macOS
```bash
# 安装 Homebrew（如果未安装）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装 musl 交叉编译工具
brew install FiloSottile/musl-cross/musl-cross

# 添加 Rust 目标
rustup target add x86_64-unknown-linux-musl
```

#### Linux (Ubuntu/Debian)
```bash
# 安装 musl 工具
sudo apt-get update
sudo apt-get install musl-tools

# 添加 Rust 目标
rustup target add x86_64-unknown-linux-musl
```

### 使用方法

```bash
# 检查依赖
make deps

# 构建静态二进制
make build-static

# 或者直接运行脚本
./scripts/build-local-static.sh
```

## 方式三：混合构建

### 特点
- ✅ 结合了本地构建的速度和 Docker 的便携性
- ✅ 生成最小的 Docker 镜像

### 使用方法

```bash
# 先本地构建静态二进制
make build-static

# 然后构建 Docker 镜像
docker build -f Dockerfile.local-build -t redis-proxy:static-local .
```

## 输出文件

构建完成后，你将得到：

### 二进制文件
- `target/static/redis-proxy` - 静态链接的二进制文件
- `target/x86_64-unknown-linux-musl/release/redis-proxy` - 原始构建输出

### Docker 镜像
- `redis-proxy:static` - 使用 Docker 构建的镜像
- `redis-proxy:static-local` - 使用本地构建的镜像

### 发布包（完整构建）
- `target/static/redis-proxy-{version}-linux-amd64.tar.gz` - 发布包

## 验证构建结果

### 验证静态链接
```bash
# 检查二进制文件依赖（应该显示 "not a dynamic executable"）
ldd target/static/redis-proxy

# 查看文件信息
file target/static/redis-proxy
```

### 测试运行
```bash
# 直接运行
./target/static/redis-proxy --help

# Docker 运行
docker run --rm redis-proxy:static --help
```

## 构建选项

### 环境变量
- `RUSTFLAGS="-C target-feature=+crt-static"` - 启用静态链接
- `PKG_CONFIG_ALL_STATIC=1` - 强制静态链接所有库
- `CC_x86_64_unknown_linux_musl` - 指定交叉编译器

### Cargo 配置
项目已在 `Cargo.toml` 中配置了优化的 release 配置：
- `lto = true` - 链接时优化
- `codegen-units = 1` - 单个代码生成单元
- `panic = "abort"` - 减小二进制大小
- `strip = true` - 移除调试符号

## 故障排除

### 常见问题

1. **Cargo.lock 版本不兼容**
   ```bash
   # 更新 Cargo.lock
   cargo update
   ```

2. **musl 工具未安装**
   ```bash
   # macOS
   brew install FiloSottile/musl-cross/musl-cross
   
   # Linux
   sudo apt-get install musl-tools
   ```

3. **Docker 构建超时**
   ```bash
   # 使用本地构建方式
   make build-static
   ```

4. **权限问题**
   ```bash
   # 给脚本添加执行权限
   chmod +x scripts/*.sh
   ```

### 调试构建

```bash
# 详细输出
RUST_LOG=debug cargo build --release --target x86_64-unknown-linux-musl

# 检查链接器
echo $CC_x86_64_unknown_linux_musl

# 验证目标已安装
rustup target list --installed | grep musl
```

## 性能优化

### 构建缓存
- Docker 构建使用多阶段缓存
- 本地构建利用 Cargo 增量编译

### 二进制优化
- 启用 LTO（链接时优化）
- 移除调试符号
- 静态链接减少运行时依赖

## CI/CD 集成

### GitHub Actions 示例
```yaml
- name: Build static binary
  run: make build-docker

- name: Upload artifacts
  uses: actions/upload-artifact@v3
  with:
    name: redis-proxy-linux-amd64
    path: target/static/redis-proxy
```

### Docker Registry 推送
```bash
# 标记镜像
docker tag redis-proxy:static your-registry/redis-proxy:latest

# 推送镜像
docker push your-registry/redis-proxy:latest
```
