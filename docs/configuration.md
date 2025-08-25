# 配置指南

Redis Proxy 支持通过配置文件和命令行参数进行配置。命令行参数的优先级高于配置文件。

## 配置文件

配置文件使用 TOML 格式，包含两个主要部分：`redis` 和 `proxy`。

### 基本结构

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

### Redis 配置

| 参数 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `host` | String | "127.0.0.1" | Redis 服务器地址 |
| `port` | u16 | 6379 | Redis 服务器端口 |
| `user` | String | "" | Redis 用户名（可选） |
| `password` | String | "" | Redis 密码（可选） |
| `ssl` | Boolean | false | 是否启用 SSL/TLS 连接 |

### 代理配置

| 参数 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `listen` | String | "0.0.0.0:6380" | 代理监听地址和端口 |

## 命令行参数

所有配置都可以通过命令行参数覆盖：

```bash
redis-proxy [OPTIONS]
```

### 可用参数

| 参数 | 描述 |
|------|------|
| `-c, --config <CONFIG>` | 配置文件路径 |
| `--redis-host <REDIS_HOST>` | Redis 主机地址 |
| `--redis-port <REDIS_PORT>` | Redis 端口 |
| `--redis-user <REDIS_USER>` | Redis 用户名 |
| `--redis-password <REDIS_PASSWORD>` | Redis 密码 |
| `--redis-ssl` | 启用 SSL 连接 |
| `--listen <LISTEN>` | 代理监听地址和端口 |
| `-h, --help` | 显示帮助信息 |
| `-V, --version` | 显示版本信息 |

## 配置示例

### 1. 本地 Redis

```toml
[redis]
host = "127.0.0.1"
port = 6379

[proxy]
listen = "0.0.0.0:6380"
```

### 2. 远程 Redis 带认证

```toml
[redis]
host = "redis.example.com"
port = 6379
user = "myuser"
password = "mypassword"

[proxy]
listen = "0.0.0.0:6380"
```

### 3. SSL Redis

```toml
[redis]
host = "secure-redis.example.com"
port = 6380
user = "secure_user"
password = "secure_password"
ssl = true

[proxy]
listen = "0.0.0.0:6380"
```

## 环境变量

虽然不直接支持环境变量，但可以通过脚本结合命令行参数使用：

```bash
#!/bin/bash
redis-proxy \
  --redis-host "${REDIS_HOST:-127.0.0.1}" \
  --redis-port "${REDIS_PORT:-6379}" \
  --redis-user "${REDIS_USER}" \
  --redis-password "${REDIS_PASSWORD}" \
  --listen "${PROXY_LISTEN:-0.0.0.0:6380}"
```

## 配置验证

启动时，Redis Proxy 会验证配置并显示当前使用的配置：

```
INFO Starting Redis Proxy
INFO Configuration: Config { redis: RedisConfig { host: "127.0.0.1", port: 6379, user: "", password: "", ssl: false }, proxy: ProxyConfig { listen: "0.0.0.0:6380" } }
```

## 最佳实践

1. **安全性**：
   - 不要在配置文件中明文存储密码
   - 使用环境变量或密钥管理系统
   - 限制配置文件的访问权限

2. **网络**：
   - 确保代理端口不与其他服务冲突
   - 考虑使用非标准端口提高安全性
   - 配置防火墙规则

3. **监控**：
   - 监控代理服务的运行状态
   - 检查日志文件中的错误信息
   - 设置健康检查

4. **性能**：
   - 根据负载调整系统资源
   - 监控网络延迟和吞吐量
   - 考虑使用多个代理实例进行负载均衡
