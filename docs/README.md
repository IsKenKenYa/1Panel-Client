# 1Panel Open Source App Documentation

Welcome to the 1Panel Open Source App documentation. This documentation site provides comprehensive guides for users, developers, and contributors.

---

## Documentation Structure

This documentation follows the standard docs site structure compatible with Docusaurus, VitePress, and MkDocs.

```
docs/
├── 模块适配专属工作流.md     # Module Adaptation Workflow (CN)
├── 原生UI适配专属工作流.md   # Native UI Adaptation Workflow (CN)
├── en/                    # English Documentation
│   ├── DEPLOY.md         # Deployment Guide
│   ├── GUIDE.md          # User Guide
│   └── TESTING.md        # Testing Guide
├── zh-CN/                # 中文文档
│   ├── DEPLOY.md         # 部署指南
│   ├── GUIDE.md          # 用户指南
│   └── TESTING.md        # 测试指南
├── 1PanelOpenAPI/        # API Documentation
│   └── 1PanelV1OpenAPI.json  # Legacy V1 OpenAPI Spec
├── OpenSource/           # Upstream source submodules
│   └── 1Panel/core/cmd/server/docs/swagger.json  # V2 Swagger/OpenAPI Spec
├── development/          # Development Documentation
└── README.md            # This file
```

---

## Quick Links

### For Users

- [Deployment Guide](en/DEPLOY.md) - How to build and deploy the app
- [User Guide](en/GUIDE.md) - Complete user manual
- [Testing Guide](en/TESTING.md) - Testing documentation

### For Developers

- [API Documentation](OpenSource/1Panel/core/cmd/server/docs/swagger.json) - 1Panel V2 API Swagger specification from the 1Panel submodule
- [Development Documentation](development/) - Technical architecture and development guides
- [模块适配专属工作流](模块适配专属工作流.md) - 模块 API 与业务链路适配工作流
- [原生UI适配专属工作流](原生UI适配专属工作流.md) - 原生 UI 适配与 AI Agent 强门禁工作流

### 中文文档

- [部署指南](zh-CN/DEPLOY.md) - 构建和部署应用
- [用户指南](zh-CN/GUIDE.md) - 完整用户手册
- [测试指南](zh-CN/TESTING.md) - 测试文档

---

## Language Selection

Choose your preferred language:

- [English](en/)
- [中文](zh-CN/)

---

## About 1Panel Open Source App

1Panel Open Source App is a Flutter-based mobile and desktop client for managing 1Panel servers. It provides a modern, intuitive interface for server management.

**Version**: 0.5.0-alpha.1+1

### Features

- **Dashboard**: Real-time server monitoring (CPU, Memory, Disk, Network)
- **Container Management**: Docker container lifecycle, logs, and statistics
- **File Management**: Built-in editor, recycle bin, transfer manager
- **Database Management**: MySQL, PostgreSQL, Redis with full operations
- **Website Management**: SSL certificates, batch operations, domain management
- **AI Management**: Ollama models, AI agent configuration, GPU monitoring
- **System Tools**: ClamAV, Fail2ban, FTP management
- **Runtime Management**: PHP extensions, Node modules, Supervisor
- **Backup & Restore**: Complete backup operations and recovery
- **Multi-server Support**: Switch between multiple 1Panel instances
- **Secure Authentication**: API key + timestamp (MD5 token)

### Supported Platforms

- **Mobile**: Android 6.0+, iOS 12.0+
- **Desktop**: Windows 10+, macOS 10.14+, Linux
- **Web**: Modern browsers

---

## Contributing to Documentation

We welcome contributions to improve our documentation!

### How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b docs/improvement`)
3. Make your changes
4. Submit a pull request

### Documentation Standards

- Use clear, concise language
- Include code examples where appropriate
- Keep formatting consistent
- Update table of contents when adding sections

---

## External Resources

- [1Panel Official Website](https://1panel.cn)
- [1Panel Documentation](https://1panel.cn/docs/)
- [Flutter Documentation](https://docs.flutter.dev)
- [GitHub Repository](https://github.com/IsKenKenYa/1Panel-Client)

---

## License

This documentation is licensed under the same license as the project. See the main repository for details.

---

*Last updated: 2026-03-30*
