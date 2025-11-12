#!/bin/bash

# Redis Proxy 使用示例脚本

set -e

echo "Redis Proxy 使用示例"
echo "===================="

# 检查 redis-proxy 是否存在
if ! command -v redis-proxy &> /dev/null; then
    echo "错误: redis-proxy 未找到，请先安装或构建项目"
    echo "构建命令: cargo build --release"
    exit 1
fi

echo ""
echo "1. 基本使用示例"
echo "----------------"
echo "使用配置文件启动代理:"
echo "redis-proxy --config examples/basic.toml"
echo ""

echo "2. 命令行参数示例"
echo "----------------"
echo "使用命令行参数启动代理:"
echo "redis-proxy --redis-host 127.0.0.1 --redis-port 6379 --listen 127.0.0.1:6379"
echo ""

echo "3. 带认证的示例"
echo "----------------"
echo "代理需要认证的 Redis:"
echo "redis-proxy --config examples/authenticated.toml"
echo "或者:"
echo "redis-proxy --redis-host redis.example.com --redis-user app_user --redis-password secure_password --listen 127.0.0.1:6379"
echo ""

echo "4. SSL 连接示例"
echo "----------------"
echo "代理 SSL Redis:"
echo "redis-proxy --config examples/ssl.toml"
echo "或者:"
echo "redis-proxy --redis-host secure-redis.example.com --redis-ssl --redis-user secure_user --redis-password very_secure_password --listen 127.0.0.1:6379"
echo ""

echo "5. Docker 示例"
echo "----------------"
echo "使用 Docker 运行 (只暴露到本地):"
echo "docker run -d --name redis-proxy -p 127.0.0.1:6379:6379 -v \$(pwd)/examples/basic.toml:/app/config.toml your-username/redis-proxy:latest"
echo ""

echo "6. 测试连接"
echo "----------------"
echo "启动代理后，可以使用 redis-cli 测试连接:"
echo "redis-cli -h 127.0.0.1 -p 6379"
echo "然后执行 Redis 命令，如: PING, SET key value, GET key"
echo ""

echo "注意事项:"
echo "- 默认配置只允许本地连接 (127.0.0.1),这是最安全的配置"
echo "- 如需远程访问,请参考 docs/security.md 了解安全配置"
echo "- 确保目标 Redis 服务器可访问"
echo "- 检查防火墙和网络配置"
echo "- 代理端口不要与其他服务冲突"
