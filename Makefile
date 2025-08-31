# Redis Proxy Makefile
# 用于构建 Linux amd64 静态二进制包

.PHONY: help build build-static build-docker clean test install deps

# 默认目标
help:
	@echo "Redis Proxy 构建工具"
	@echo ""
	@echo "可用命令:"
	@echo "  make build         - 构建本地二进制"
	@echo "  make build-static  - 构建 Linux amd64 静态二进制"
	@echo "  make build-docker  - 使用 Docker 构建静态二进制"
	@echo "  make clean         - 清理构建文件"
	@echo "  make test          - 运行测试"
	@echo "  make install       - 安装依赖"
	@echo "  make deps          - 检查依赖"

# 构建本地二进制
build:
	@echo "🔨 构建本地二进制..."
	cargo build --release

# 构建静态二进制（本地）
build-static: deps
	@echo "🔨 构建 Linux amd64 静态二进制..."
	@chmod +x scripts/build-local-static.sh
	@./scripts/build-local-static.sh

# 使用 Docker 构建静态二进制
build-docker:
	@echo "🐳 使用 Docker 构建静态二进制..."
	@chmod +x scripts/quick-build.sh
	@./scripts/quick-build.sh

# 清理构建文件
clean:
	@echo "🧹 清理构建文件..."
	cargo clean
	rm -rf target/static
	docker rmi redis-proxy:static redis-proxy:static-local 2>/dev/null || true

# 运行测试
test:
	@echo "🧪 运行测试..."
	cargo test

# 安装依赖
install:
	@echo "📦 安装依赖..."
	@if [[ "$$OSTYPE" == "darwin"* ]]; then \
		if command -v brew >/dev/null 2>&1; then \
			echo "安装 musl 交叉编译工具..."; \
			brew install FiloSottile/musl-cross/musl-cross; \
		else \
			echo "请先安装 Homebrew"; \
			exit 1; \
		fi \
	elif [[ "$$OSTYPE" == "linux-gnu"* ]]; then \
		echo "请运行: sudo apt-get install musl-tools"; \
	fi
	rustup target add x86_64-unknown-linux-musl

# 检查依赖
deps:
	@echo "🔍 检查依赖..."
	@if ! command -v rustc >/dev/null 2>&1; then \
		echo "❌ Rust 未安装"; \
		echo "请安装: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"; \
		exit 1; \
	fi
	@if ! rustup target list --installed | grep -q "x86_64-unknown-linux-musl"; then \
		echo "📦 安装 musl 目标..."; \
		rustup target add x86_64-unknown-linux-musl; \
	fi
	@if [[ "$$OSTYPE" == "darwin"* ]]; then \
		if ! command -v x86_64-linux-musl-gcc >/dev/null 2>&1; then \
			echo "❌ musl-cross 未安装"; \
			echo "请运行: make install"; \
			exit 1; \
		fi \
	elif [[ "$$OSTYPE" == "linux-gnu"* ]]; then \
		if ! command -v musl-gcc >/dev/null 2>&1; then \
			echo "❌ musl-tools 未安装"; \
			echo "请运行: sudo apt-get install musl-tools"; \
			exit 1; \
		fi \
	fi
	@echo "✅ 所有依赖已就绪"
