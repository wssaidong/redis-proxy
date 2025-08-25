# 贡献指南

感谢您对 Redis Proxy 项目的关注！我们欢迎各种形式的贡献。

## 如何贡献

### 报告问题

如果您发现了 bug 或有功能建议，请：

1. 检查 [Issues](https://github.com/your-username/redis-proxy/issues) 确保问题未被报告
2. 使用相应的 issue 模板创建新的 issue
3. 提供详细的描述和复现步骤

### 提交代码

1. **Fork 项目**
   ```bash
   git clone https://github.com/your-username/redis-proxy.git
   cd redis-proxy
   ```

2. **创建功能分支**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **进行开发**
   - 遵循现有的代码风格
   - 添加必要的测试
   - 确保所有测试通过

4. **提交更改**
   ```bash
   git add .
   git commit -m "feat: 添加新功能描述"
   ```

5. **推送分支**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **创建 Pull Request**
   - 使用清晰的标题和描述
   - 引用相关的 issues
   - 等待代码审查

## 开发环境设置

### 前置要求

- Rust 1.70.0 或更高版本
- Git

### 本地开发

1. 克隆仓库：
   ```bash
   git clone https://github.com/your-username/redis-proxy.git
   cd redis-proxy
   ```

2. 构建项目：
   ```bash
   cargo build
   ```

3. 运行测试：
   ```bash
   cargo test
   ```

4. 运行项目：
   ```bash
   cargo run -- --help
   ```

## 代码规范

### Rust 代码风格

- 使用 `cargo fmt` 格式化代码
- 使用 `cargo clippy` 检查代码质量
- 遵循 Rust 官方编码规范

### 提交信息规范

使用 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

- `feat:` 新功能
- `fix:` 修复 bug
- `docs:` 文档更新
- `style:` 代码格式调整
- `refactor:` 代码重构
- `test:` 测试相关
- `chore:` 构建过程或辅助工具的变动

### 示例

```
feat: 添加 SSL 连接支持

- 实现 Redis SSL 连接功能
- 添加 SSL 相关配置选项
- 更新文档和示例

Closes #123
```

## 测试

### 运行测试

```bash
# 运行所有测试
cargo test

# 运行特定测试
cargo test test_name

# 运行集成测试
cargo test --test integration_tests
```

### 添加测试

- 为新功能添加单元测试
- 为重要功能添加集成测试
- 确保测试覆盖率不降低

## 文档

- 更新相关的 README.md
- 为新功能添加使用示例
- 更新 API 文档注释

## 发布流程

项目维护者负责版本发布：

1. 更新版本号
2. 更新 CHANGELOG.md
3. 创建 Git 标签
4. 发布到 crates.io

## 获得帮助

如果您有任何问题：

- 查看现有的 [Issues](https://github.com/your-username/redis-proxy/issues)
- 创建新的 issue 寻求帮助
- 查看项目文档

## 行为准则

请阅读并遵守我们的 [行为准则](CODE_OF_CONDUCT.md)。

感谢您的贡献！🎉
