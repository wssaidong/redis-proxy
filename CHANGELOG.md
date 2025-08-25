# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of Redis Proxy
- High-performance async TCP forwarding
- Redis authentication support
- Configuration file and command-line argument support
- Docker support
- Comprehensive documentation and examples

### Changed

### Deprecated

### Removed

### Fixed

### Security

## [0.1.0] - 2025-01-XX

### Added
- **Core Features**
  - High-performance Redis proxy with async I/O
  - Transparent Redis protocol forwarding
  - Support for Redis authentication (username/password)
  - SSL/TLS connection support
  
- **Configuration**
  - TOML configuration file support
  - Command-line argument override
  - Flexible Redis and proxy settings
  
- **Deployment**
  - Docker container support
  - Multi-platform binaries (Linux, macOS, Windows)
  - systemd service configuration
  
- **Documentation**
  - Comprehensive README with examples
  - Configuration guide
  - Deployment guide
  - Contributing guidelines
  - Code of conduct
  
- **Development**
  - CI/CD pipeline with GitHub Actions
  - Automated testing and code quality checks
  - Security vulnerability scanning
  - Multi-platform builds and releases

### Technical Details
- Built with Rust 2021 edition
- Uses Tokio for async runtime
- Clap for command-line parsing
- Serde for configuration serialization
- TOML for configuration format

[Unreleased]: https://github.com/your-username/redis-proxy/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/your-username/redis-proxy/releases/tag/v0.1.0
