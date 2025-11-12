# 部署指南

本文档介绍如何在不同环境中部署 Redis Proxy。

## 本地部署

### 从源码构建

```bash
# 克隆仓库
git clone https://github.com/your-username/redis-proxy.git
cd redis-proxy

# 构建项目
cargo build --release

# 运行
./target/release/redis-proxy --config config.toml
```

### 从 Crates.io 安装

```bash
# 安装
cargo install redis-proxy

# 运行
redis-proxy --config config.toml
```

## Docker 部署

### 使用预构建镜像

```bash
# 拉取镜像
docker pull your-username/redis-proxy:latest

# 运行容器 (只暴露到本地,推荐)
docker run -d \
  --name redis-proxy \
  -p 127.0.0.1:6379:6379 \
  -v $(pwd)/config.toml:/app/config.toml \
  your-username/redis-proxy:latest

# 或者暴露到所有接口 (需要配合防火墙使用)
# docker run -d \
#   --name redis-proxy \
#   -p 6379:6379 \
#   -v $(pwd)/config.toml:/app/config.toml \
#   your-username/redis-proxy:latest
```

### 使用 Docker Compose

创建 `docker-compose.yml`：

```yaml
version: '3.8'

services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    command: redis-server --requirepass mypassword

  redis-proxy:
    image: your-username/redis-proxy:latest
    ports:
      # 只暴露到本地 (推荐)
      - "127.0.0.1:6379:6379"
      # 或暴露到所有接口 (需要配合防火墙)
      # - "6379:6379"
    depends_on:
      - redis
    command: >
      --redis-host redis
      --redis-port 6379
      --redis-password mypassword
      --listen 0.0.0.0:6379
```

启动服务：

```bash
docker-compose up -d
```

## Kubernetes 部署

### 基本部署

创建 `redis-proxy-deployment.yaml`：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-proxy
  labels:
    app: redis-proxy
spec:
  replicas: 3
  selector:
    matchLabels:
      app: redis-proxy
  template:
    metadata:
      labels:
        app: redis-proxy
    spec:
      containers:
      - name: redis-proxy
        image: your-username/redis-proxy:latest
        ports:
        - containerPort: 6379
        args:
        - "--redis-host"
        - "redis-service"
        - "--redis-port"
        - "6379"
        - "--listen"
        - "0.0.0.0:6379"
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: redis-proxy-service
spec:
  selector:
    app: redis-proxy
  ports:
  - protocol: TCP
    port: 6379
    targetPort: 6379
  type: LoadBalancer
```

部署：

```bash
kubectl apply -f redis-proxy-deployment.yaml
```

### 使用 ConfigMap

创建配置：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: redis-proxy-config
data:
  config.toml: |
    [redis]
    host = "redis-service"
    port = 6379
    user = ""
    password = ""
    ssl = false

    [proxy]
    listen = "0.0.0.0:6379"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-proxy
spec:
  replicas: 3
  selector:
    matchLabels:
      app: redis-proxy
  template:
    metadata:
      labels:
        app: redis-proxy
    spec:
      containers:
      - name: redis-proxy
        image: your-username/redis-proxy:latest
        ports:
        - containerPort: 6379
        args:
        - "--config"
        - "/app/config.toml"
        volumeMounts:
        - name: config-volume
          mountPath: /app/config.toml
          subPath: config.toml
      volumes:
      - name: config-volume
        configMap:
          name: redis-proxy-config
```

## 系统服务部署

### systemd 服务

创建 `/etc/systemd/system/redis-proxy.service`：

```ini
[Unit]
Description=Redis Proxy
After=network.target

[Service]
Type=simple
User=redis-proxy
Group=redis-proxy
ExecStart=/usr/local/bin/redis-proxy --config /etc/redis-proxy/config.toml
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

启用和启动服务：

```bash
# 创建用户
sudo useradd -r -s /bin/false redis-proxy

# 创建配置目录
sudo mkdir -p /etc/redis-proxy
sudo cp config.toml /etc/redis-proxy/
sudo chown -R redis-proxy:redis-proxy /etc/redis-proxy

# 复制二进制文件
sudo cp target/release/redis-proxy /usr/local/bin/
sudo chmod +x /usr/local/bin/redis-proxy

# 启用服务
sudo systemctl daemon-reload
sudo systemctl enable redis-proxy
sudo systemctl start redis-proxy

# 检查状态
sudo systemctl status redis-proxy
```

## 负载均衡部署

### 使用 Nginx

配置 `/etc/nginx/sites-available/redis-proxy`：

```nginx
upstream redis_proxy {
    server 127.0.0.1:6379;
    server 127.0.0.1:6381;
    server 127.0.0.1:6382;
}

server {
    listen 6379;
    proxy_pass redis_proxy;
    proxy_timeout 1s;
    proxy_responses 1;
}
```

### 使用 HAProxy

配置 `/etc/haproxy/haproxy.cfg`：

```
global
    daemon

defaults
    mode tcp
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend redis_frontend
    bind *:6379
    default_backend redis_proxy_backend

backend redis_proxy_backend
    balance roundrobin
    server proxy1 127.0.0.1:6379 check
    server proxy2 127.0.0.1:6381 check
    server proxy3 127.0.0.1:6382 check
```

## 监控和日志

### 日志配置

设置环境变量控制日志级别：

```bash
export RUST_LOG=redis_proxy=info
redis-proxy --config config.toml
```

### 健康检查

创建健康检查脚本：

```bash
#!/bin/bash
# health-check.sh

PROXY_HOST="127.0.0.1"
PROXY_PORT="6379"

if timeout 5 bash -c "</dev/tcp/$PROXY_HOST/$PROXY_PORT"; then
    echo "Redis Proxy is healthy"
    exit 0
else
    echo "Redis Proxy is not responding"
    exit 1
fi
```

### Prometheus 监控

虽然当前版本不直接支持 Prometheus 指标，但可以通过日志监控：

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'redis-proxy-logs'
    static_configs:
      - targets: ['localhost:9090']
```

## 安全考虑

1. **网络安全**：
   - 使用防火墙限制访问
   - 考虑使用 VPN 或私有网络
   - 启用 SSL/TLS 连接

2. **访问控制**：
   - 限制代理服务的运行用户权限
   - 使用强密码和用户认证
   - 定期轮换密码

3. **监控**：
   - 监控异常连接和流量
   - 设置告警机制
   - 定期检查日志

## 故障排除

常见问题和解决方案：

1. **连接被拒绝**：
   - 检查 Redis 服务器是否运行
   - 验证网络连接和防火墙设置
   - 确认认证信息正确

2. **性能问题**：
   - 检查系统资源使用情况
   - 监控网络延迟
   - 考虑增加代理实例

3. **配置错误**：
   - 验证配置文件语法
   - 检查参数值的有效性
   - 查看启动日志中的错误信息
