#!/bin/bash

# 快速构建 Linux amd64 静态二进制

set -e

echo "🚀 开始构建 Redis Proxy 静态二进制..."

# 构建 Docker 镜像
docker build --platform=linux/amd64 -f Dockerfile.static -t redis-proxy:static .

# 创建输出目录
mkdir -p target/static

# 提取二进制文件
CONTAINER_ID=$(docker create redis-proxy:static)
docker cp "${CONTAINER_ID}:/redis-proxy" target/static/redis-proxy
docker rm "${CONTAINER_ID}"

# 设置执行权限
chmod +x target/static/redis-proxy

echo "✅ 构建完成!"
echo "📁 二进制文件位置: target/static/redis-proxy"
echo "📊 文件大小: $(ls -lh target/static/redis-proxy | awk '{print $5}')"

# 验证是否为静态链接
echo "🔍 验证静态链接:"
file target/static/redis-proxy
