#!/bin/bash

# Redis Proxy Static Binary Builder
# 构建 Linux amd64 静态二进制包

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目信息
PROJECT_NAME="redis-proxy"
VERSION=$(grep '^version' Cargo.toml | sed 's/version = "\(.*\)"/\1/')
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
PLATFORM="linux/amd64"

echo -e "${BLUE}=== Redis Proxy 静态二进制构建器 ===${NC}"
echo -e "${YELLOW}项目: ${PROJECT_NAME}${NC}"
echo -e "${YELLOW}版本: ${VERSION}${NC}"
echo -e "${YELLOW}平台: ${PLATFORM}${NC}"
echo -e "${YELLOW}构建时间: ${BUILD_DATE}${NC}"
echo ""

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker 未安装或不在 PATH 中${NC}"
    exit 1
fi

# 检查 Docker 是否运行
if ! docker info &> /dev/null; then
    echo -e "${RED}错误: Docker 守护进程未运行${NC}"
    exit 1
fi

# 创建输出目录
OUTPUT_DIR="target/static"
mkdir -p "${OUTPUT_DIR}"

echo -e "${BLUE}步骤 1: 构建静态二进制 Docker 镜像${NC}"

# 构建 Docker 镜像
docker build \
    --platform="${PLATFORM}" \
    -f Dockerfile.static \
    -t "${PROJECT_NAME}:static-${VERSION}" \
    -t "${PROJECT_NAME}:static-latest" \
    --build-arg BUILD_DATE="${BUILD_DATE}" \
    --build-arg VERSION="${VERSION}" \
    .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Docker 镜像构建成功${NC}"
else
    echo -e "${RED}✗ Docker 镜像构建失败${NC}"
    exit 1
fi

echo -e "${BLUE}步骤 2: 提取静态二进制文件${NC}"

# 创建临时容器并提取二进制文件
CONTAINER_ID=$(docker create "${PROJECT_NAME}:static-${VERSION}")

# 提取二进制文件
docker cp "${CONTAINER_ID}:/redis-proxy" "${OUTPUT_DIR}/redis-proxy-${VERSION}-linux-amd64"

# 提取配置文件
docker cp "${CONTAINER_ID}:/config.toml" "${OUTPUT_DIR}/config.toml"

# 清理临时容器
docker rm "${CONTAINER_ID}" > /dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 二进制文件提取成功${NC}"
else
    echo -e "${RED}✗ 二进制文件提取失败${NC}"
    exit 1
fi

echo -e "${BLUE}步骤 3: 验证二进制文件${NC}"

BINARY_PATH="${OUTPUT_DIR}/redis-proxy-${VERSION}-linux-amd64"

# 检查文件是否存在
if [ ! -f "${BINARY_PATH}" ]; then
    echo -e "${RED}✗ 二进制文件不存在: ${BINARY_PATH}${NC}"
    exit 1
fi

# 设置执行权限
chmod +x "${BINARY_PATH}"

# 获取文件信息
FILE_SIZE=$(ls -lh "${BINARY_PATH}" | awk '{print $5}')
FILE_TYPE=$(file "${BINARY_PATH}")

echo -e "${GREEN}✓ 二进制文件验证完成${NC}"
echo -e "${YELLOW}文件路径: ${BINARY_PATH}${NC}"
echo -e "${YELLOW}文件大小: ${FILE_SIZE}${NC}"
echo -e "${YELLOW}文件类型: ${FILE_TYPE}${NC}"

echo -e "${BLUE}步骤 4: 创建发布包${NC}"

# 创建发布目录
RELEASE_DIR="${OUTPUT_DIR}/release-${VERSION}"
mkdir -p "${RELEASE_DIR}"

# 复制文件到发布目录
cp "${BINARY_PATH}" "${RELEASE_DIR}/redis-proxy"
cp "${OUTPUT_DIR}/config.toml" "${RELEASE_DIR}/"
cp README.md "${RELEASE_DIR}/" 2>/dev/null || echo "README.md not found, skipping"
cp LICENSE "${RELEASE_DIR}/" 2>/dev/null || echo "LICENSE not found, skipping"

# 创建启动脚本
cat > "${RELEASE_DIR}/start.sh" << 'EOF'
#!/bin/bash
# Redis Proxy 启动脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

echo "启动 Redis Proxy..."
echo "配置文件: config.toml"
echo "日志级别: INFO"
echo ""

exec ./redis-proxy --config config.toml
EOF

chmod +x "${RELEASE_DIR}/start.sh"

# 创建 tar.gz 包
ARCHIVE_NAME="${PROJECT_NAME}-${VERSION}-linux-amd64.tar.gz"
cd "${OUTPUT_DIR}"
tar -czf "${ARCHIVE_NAME}" -C "release-${VERSION}" .
cd - > /dev/null

echo -e "${GREEN}✓ 发布包创建完成${NC}"
echo -e "${YELLOW}发布包: ${OUTPUT_DIR}/${ARCHIVE_NAME}${NC}"

echo ""
echo -e "${GREEN}=== 构建完成 ===${NC}"
echo -e "${YELLOW}输出目录: ${OUTPUT_DIR}${NC}"
echo -e "${YELLOW}二进制文件: ${BINARY_PATH}${NC}"
echo -e "${YELLOW}发布包: ${OUTPUT_DIR}/${ARCHIVE_NAME}${NC}"
echo ""
echo -e "${BLUE}使用方法:${NC}"
echo -e "1. 解压发布包: tar -xzf ${OUTPUT_DIR}/${ARCHIVE_NAME}"
echo -e "2. 运行程序: ./redis-proxy --config config.toml"
echo -e "3. 或使用启动脚本: ./start.sh"
echo ""
echo -e "${BLUE}Docker 镜像:${NC}"
echo -e "镜像标签: ${PROJECT_NAME}:static-${VERSION}"
echo -e "运行命令: docker run -p 6380:6380 ${PROJECT_NAME}:static-${VERSION}"
