# Redis Proxy

<div align="center">

[![Crates.io](https://img.shields.io/crates/v/redis-proxy.svg)](https://crates.io/crates/redis-proxy)
[![Documentation](https://docs.rs/redis-proxy/badge.svg)](https://docs.rs/redis-proxy)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://github.com/your-username/redis-proxy/workflows/CI/badge.svg)](https://github.com/your-username/redis-proxy/actions)
[![codecov](https://codecov.io/gh/your-username/redis-proxy/branch/main/graph/badge.svg)](https://codecov.io/gh/your-username/redis-proxy)

一个用 Rust 编写的高性能 Redis 代理，支持动态配置和透明转发。

[功能特性](#功能特性) •
[快速开始](#快速开始) •
[安装](#安装) •
[配置](#配置) •
[示例](#示例) •
[贡献](#贡献)

</div>

---

## 🚀 功能特性

- **🔒 安全代理** - 屏蔽真实 Redis 连接信息，提升安全性
- **⚡ 高性能** - 基于 Tokio 的异步 I/O，支持高并发
- **🔧 灵活配置** - 支持配置文件和命令行参数
- **🔐 认证支持** - 支持 Redis 用户名/密码认证
- **🐳 容器化** - 提供 Docker 镜像，便于部署
- **📊 透明转发** - 完全透明的 Redis 协议转发

## 📦 安装

### 从 Crates.io 安装

```bash
cargo install redis-proxy
```

### 从源码构建

```bash
git clone https://github.com/your-username/redis-proxy.git
cd redis-proxy
cargo build --release
```

### 使用 Docker

```bash
docker pull your-username/redis-proxy:latest
```

## 🚀 快速开始

### 基本使用

1. **创建配置文件** `config.toml`：

```toml
[redis]
host = "127.0.0.1"
port = 6379
user = ""
password = ""
ssl = false

[proxy]
listen = "0.0.0.0:6380"
```

2. **启动代理**：

```bash
redis-proxy --config config.toml
```

3. **连接代理**：

```bash
redis-cli -h 127.0.0.1 -p 6380
```

### 命令行使用

```bash
# 使用命令行参数
redis-proxy --redis-host 192.168.1.100 --redis-port 6379 --listen 0.0.0.0:6380

# 查看帮助
redis-proxy --help
```

## ⚙️ 配置

### 配置文件

#### Redis 配置
- `redis.host`：Redis 服务器地址
- `redis.port`：Redis 服务器端口
- `redis.user`：Redis 用户名（可选）
- `redis.password`：Redis 密码（可选）
- `redis.ssl`：是否启用 SSL 连接

#### 代理配置
- `proxy.listen`：代理监听地址和端口

### 命令行参数

| 参数 | 说明 |
|------|------|
| `--config` | 配置文件路径 |
| `--redis-host` | Redis 主机地址 |
| `--redis-port` | Redis 端口 |
| `--redis-user` | Redis 用户名 |
| `--redis-password` | Redis 密码 |
| `--redis-ssl` | 启用 SSL 连接 |
| `--listen` | 代理监听地址和端口 |

> 💡 命令行参数优先级高于配置文件

## 🐳 Docker 部署

### 使用预构建镜像

```bash
# 拉取镜像
docker pull your-username/redis-proxy:latest

# 运行容器
docker run -d \
  --name redis-proxy \
  -p 6380:6380 \
  -v $(pwd)/config.toml:/app/config.toml \
  your-username/redis-proxy:latest
```

### 构建自定义镜像

```bash
# 构建镜像
docker build -t my-redis-proxy .

# 运行容器
docker run -d \
  --name my-redis-proxy \
  -p 6380:6380 \
  my-redis-proxy \
  --redis-host 192.168.1.100 \
  --redis-port 6379 \
  --listen 0.0.0.0:6380
```

## 📚 示例

### 基本代理

```bash
# 代理本地 Redis
redis-proxy --redis-host 127.0.0.1 --redis-port 6379 --listen 0.0.0.0:6380
```

### 带认证的 Redis

```bash
# 代理需要认证的 Redis
redis-proxy \
  --redis-host redis.example.com \
  --redis-port 6379 \
  --redis-user myuser \
  --redis-password mypassword \
  --listen 0.0.0.0:6380
```

### 使用配置文件

```toml
# config.toml
[redis]
host = "redis-cluster.internal"
port = 6379
user = "app_user"
password = "secure_password"
ssl = true

[proxy]
listen = "0.0.0.0:6380"
```

```bash
redis-proxy --config config.toml
```

## 🔧 开发

### 前置要求

- Rust 1.70.0+
- Git

### 本地开发

```bash
# 克隆仓库
git clone https://github.com/your-username/redis-proxy.git
cd redis-proxy

# 运行测试
cargo test

# 运行项目
cargo run -- --help

# 构建发布版本
cargo build --release
```

### 代码质量

```bash
# 格式化代码
cargo fmt

# 检查代码
cargo clippy

# 运行所有检查
cargo test && cargo clippy && cargo fmt --check
```

## 🤝 贡献

我们欢迎各种形式的贡献！请查看 [贡献指南](CONTRIBUTING.md) 了解详情。

### 快速贡献

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'feat: add amazing feature'`)
4. 推送分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

- [Tokio](https://tokio.rs/) - 异步运行时
- [Clap](https://clap.rs/) - 命令行参数解析
- [Serde](https://serde.rs/) - 序列化框架

## 📞 支持

- 📖 [文档](https://docs.rs/redis-proxy)
- 🐛 [问题反馈](https://github.com/your-username/redis-proxy/issues)
- 💬 [讨论](https://github.com/your-username/redis-proxy/discussions)

---

<div align="center">

**[⬆ 回到顶部](#redis-proxy)**

Made with ❤️ by the Redis Proxy community

</div>