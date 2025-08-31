#!/bin/bash

# 本地构建 Linux amd64 静态二进制包

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Redis Proxy 本地静态构建 ===${NC}"

# 检查是否安装了 Rust
if ! command -v rustc &> /dev/null; then
    echo -e "${RED}错误: Rust 未安装${NC}"
    echo "请安装 Rust: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    exit 1
fi

# 检查是否安装了 musl 目标
echo -e "${YELLOW}步骤 1: 检查 musl 目标${NC}"
if ! rustup target list --installed | grep -q "x86_64-unknown-linux-musl"; then
    echo "安装 musl 目标..."
    rustup target add x86_64-unknown-linux-musl
fi

# 检查是否安装了 musl-tools (Linux) 或 musl-cross (macOS)
echo -e "${YELLOW}步骤 2: 检查构建工具${NC}"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if ! command -v musl-gcc &> /dev/null; then
        echo -e "${RED}错误: musl-tools 未安装${NC}"
        echo "请安装: sudo apt-get install musl-tools"
        exit 1
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v x86_64-linux-musl-gcc &> /dev/null; then
        echo -e "${YELLOW}安装 musl 交叉编译工具链...${NC}"
        if command -v brew &> /dev/null; then
            brew install FiloSottile/musl-cross/musl-cross
        else
            echo -e "${RED}错误: 需要 Homebrew 来安装 musl-cross${NC}"
            echo "请安装 Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
        fi
    fi
fi

# 设置环境变量
echo -e "${YELLOW}步骤 3: 设置构建环境${NC}"
export RUSTFLAGS="-C target-feature=+crt-static"
export CC_x86_64_unknown_linux_musl="x86_64-linux-musl-gcc"
export CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER="x86_64-linux-musl-gcc"

# 构建静态二进制
echo -e "${YELLOW}步骤 4: 构建静态二进制${NC}"
cargo build --release --target x86_64-unknown-linux-musl

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 静态二进制构建成功${NC}"
else
    echo -e "${RED}✗ 静态二进制构建失败${NC}"
    exit 1
fi

# 验证二进制文件
BINARY_PATH="target/x86_64-unknown-linux-musl/release/redis-proxy"
if [ ! -f "$BINARY_PATH" ]; then
    echo -e "${RED}✗ 二进制文件不存在: $BINARY_PATH${NC}"
    exit 1
fi

echo -e "${YELLOW}步骤 5: 验证二进制文件${NC}"
FILE_SIZE=$(ls -lh "$BINARY_PATH" | awk '{print $5}')
FILE_TYPE=$(file "$BINARY_PATH")

echo -e "${GREEN}✓ 二进制文件信息:${NC}"
echo -e "${YELLOW}文件路径: $BINARY_PATH${NC}"
echo -e "${YELLOW}文件大小: $FILE_SIZE${NC}"
echo -e "${YELLOW}文件类型: $FILE_TYPE${NC}"

# 检查是否为静态链接
if ldd "$BINARY_PATH" 2>/dev/null; then
    echo -e "${YELLOW}警告: 二进制文件可能不是完全静态链接${NC}"
else
    echo -e "${GREEN}✓ 确认为静态链接二进制文件${NC}"
fi

# 构建 Docker 镜像
echo -e "${YELLOW}步骤 6: 构建 Docker 镜像${NC}"
if command -v docker &> /dev/null; then
    docker build -f Dockerfile.local-build -t redis-proxy:static-local .
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Docker 镜像构建成功${NC}"
        
        # 创建输出目录并提取二进制文件
        mkdir -p target/static
        
        # 复制二进制文件到输出目录
        cp "$BINARY_PATH" target/static/redis-proxy
        chmod +x target/static/redis-proxy
        
        echo -e "${GREEN}=== 构建完成 ===${NC}"
        echo -e "${YELLOW}静态二进制: target/static/redis-proxy${NC}"
        echo -e "${YELLOW}Docker 镜像: redis-proxy:static-local${NC}"
        echo ""
        echo -e "${BLUE}使用方法:${NC}"
        echo -e "1. 直接运行: ./target/static/redis-proxy --config config.toml"
        echo -e "2. Docker 运行: docker run -p 6380:6380 redis-proxy:static-local"
    else
        echo -e "${RED}✗ Docker 镜像构建失败${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Docker 未安装，跳过镜像构建${NC}"
    echo -e "${GREEN}=== 构建完成 ===${NC}"
    echo -e "${YELLOW}静态二进制: $BINARY_PATH${NC}"
fi
