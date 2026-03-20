# 1Panel Open Source App Documentation

Welcome to the 1Panel Open Source App documentation. This documentation site provides comprehensive guides for users, developers, and contributors.

---

## Documentation Structure

This documentation follows the standard docs site structure compatible with Docusaurus, VitePress, and MkDocs.

```
docs/
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

### Features

- Real-time server monitoring (CPU, Memory, Disk)
- Docker container management
- File management with built-in editor
- Database management (MySQL, PostgreSQL, Redis)
- Website and SSL certificate management
- System log viewing
- Multi-server support
- Secure API authentication

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
- [GitHub Repository](https://github.com/yourusername/1PanelOpenSourceApp)

---

## License

This documentation is licensed under the same license as the project. See the main repository for details.

---

*Last updated: 2025-01-12*
