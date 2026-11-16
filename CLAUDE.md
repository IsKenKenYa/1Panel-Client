# CLAUDE.md

本文件为 Claude Code 提供项目补充说明。**强制规则见 `AGENTS.md`，其中「最高优先级执行规则」优先于本文全部内容**。每次用户消息提到 AGENTS.md 时，必须重新阅读 `AGENTS.md` 全文。

## 项目概述

**1Panel Client** 是一个跨平台 Flutter 应用，提供对 1Panel Linux 服务器管理面板的移动、桌面与浏览器访问。

Flutter Web 复用 Dart 业务核心与 MDUI3，通过 Cloudflare 分发静态资源，接受 HTTP/HTTPS 面板地址并要求面板 CORS 授权。HTTP 由用户确认传输风险，仍受浏览器混合内容和局域网权限限制。浏览器凭据使用 Web Crypto AES-GCM 加密保存在 IndexedDB；本地密码仅检查非空与确认一致，成功后提交自动填充上下文并阻止密码表单网络提交；用户也可以选择浏览器密钥。读取或解密失败时保留数据并报告错误。浏览器日志不记录网络正文和查询参数。Web 门禁为 `flutter test --platform chrome test/web/`、`pnpm build:web` 与 `pnpm check:web`，完整规则见 `AGENTS.md`「Flutter Web 浏览器轨道」。

### 已完成能力
- AI 管理模块（Ollama 模型、GPU 监控、域名绑定）
- 完整 API 覆盖：33 个 V2 API 模块，425+ 端点
- 数据模型：60+ 模型文件，含 JSON 序列化
- 多服务器支持，API Key 认证
- 核心基础设施：日志（自动 IP 掩码）、i18n（EN/ZH）、导航、Material Design 3
- 容器管理、数据库管理、文件管理、网站管理、Dashboard 实时监控
- Shell 架构：自适应壳 + 模块切换 + 服务器感知导航
- HarmonyOS 平台适配（Flutter-OH bridge + HUKS 安全存储 + 原生下载器）
- 统一消息提示系统（SnackBarUtils，替换 272 处内联调用）
- 33 个功能模块完整覆盖

## 开发命令

```bash
flutter pub get                              # 安装依赖
flutter run                                  # 调试运行
flutter analyze                              # 静态分析
flutter test                                 # 全部测试
flutter test test/<file>_test.dart           # 单个测试
flutter test --coverage                      # 覆盖率
flutter packages pub run build_runner build  # 代码生成
flutter build apk --release                  # Android APK
flutter build ios --release                  # iOS（仅 macOS）
```

测试门禁：`dart run test/scripts/test_runner.dart unit|integration|ui|all`

## 日常分支与提交

- 默认在当前分支直接修改与提交，新建分支必须得到用户明确同意；详见 `AGENTS.md`「分支、发布与 CI」。
- 提交消息遵循 Conventional Commits 且必须包含 `scope`，一次任务涉及多个模块时按模块或类别分别提交。
- 每次改动完成后自动执行完整测试闭环并迭代到门禁全部通过，详见 `AGENTS.md`「每次改动后的全自动测试闭环（强制）」。

## 实时功能规划

- 当前功能批次的唯一计划入口是 `docs/development/modules/阶段总计划.md`。
- 开工前登记范围、上游前端行为对照、接口定义关键字、验收标准与门禁；完成后在同一条目回写实际交付、残留和命令结果。
- 强制规则以 `AGENTS.md`「模块适配与原生UI工作流」为准；旧的独立工作流文档已退役，不得重新引用。

## 架构概览

```
├── Presentation Layer (UI)
│   ├── Pages (Screens)     # lib/pages/
│   └── Widgets            # lib/shared/widgets/
├── Business Logic Layer (ViewModels/Providers)
│   ├── State Management   # Provider pattern with ChangeNotifier
│   └── Use Cases         # Feature-specific business logic
├── Data Access Layer (Repositories/Services)
│   ├── API Services       # lib/api/v2/ (type-safe with Retrofit)
│   └── Data Models        # lib/data/models/
└── Infrastructure Layer
    ├── Network Client     # Dio-based HTTP client
    ├── Storage           # Secure storage + SharedPreferences
    └── Core Services      # lib/core/services/
```

### 当前目录结构

```
lib/
├── api/v2/              # Retrofit API 客户端
├── config/              # 应用配置
├── core/                # 核心服务（config, i18n, network, services）
├── data/                # 数据层（models, repositories）
├── features/            # 33 个功能模块
│   ├── ai/ apps/ auth/ backups/ commands/ containers/
│   ├── cronjobs/ dashboard/ databases/ files/ firewall/
│   ├── groups/ host_assets/ logs/ monitoring/ onboarding/
│   ├── openresty/ operations/ operations_center/ orchestration/
│   ├── processes/ runtimes/ script_library/ security/
│   ├── security_gateway/ server/ settings/ shell/ ssh/
│   ├── terminal/ toolbox/ websites/
├── shared/              # 共享组件（constants, widgets）
└── main.dart
```

## 日志系统（强制）

禁止 `print()` / `debugPrint()`，统一使用 `appLogger`：

```dart
import 'core/services/logger/logger_service.dart';

appLogger.dWithPackage('auth.service', '用户登录成功');
appLogger.eWithPackage('network.api', '请求失败', error: e, stackTrace: stackTrace);
```

**包命名**：小写点分，对应文件路径。`lib/features/dashboard/` → `features.dashboard`

**日志级别**：
- Debug：全级别（Trace, Debug, Info, Warning, Error, Fatal）
- Profile：Info, Warning, Error, Fatal
- Release：Warning, Error, Fatal

**隐私保护**：公网 IP 自动掩码为 `***.***.***.***`，内网 IP 保留。文件输出全模式启用。

## 认证系统

API 认证统一使用 HMAC-SHA256：`hmac_sha256(apiKey, '1panel:' + unixTimestamp)`，复用 `OnePanelAuthHeaders`，请求仅携带签名与时间戳。

支持多服务器配置，安全存储，默认服务器选择。

## CodeGraph

CodeGraph 通过 MCP Server 提供代码符号索引。当 `.codegraph/` 存在时，优先使用 CodeGraph 工具回答代码问题，不要委派给文件搜索子代理。

| MCP 工具 | 用途 |
|----------|------|
| `codegraph_context` | 构建任务相关上下文（搜索+节点+调用链 合一） |
| `codegraph_trace` | 追踪 X 到 Y 的调用路径 |
| `codegraph_explore` | 批量获取多个符号的源码 |
| `codegraph_search` | 按名称搜索符号 |
| `codegraph_callers` / `codegraph_callees` | 遍历调用流 |
| `codegraph_impact` | 分析修改影响范围 |

首次使用：`codegraph init -i` 初始化项目索引。

## graphify

项目知识图谱位于 `graphify-out/`（已 gitignore）。查询、路径、解释、增量更新等用法见 `AGENTS.md`。

## 工程技能（mattpocock/skills）

项目引入了 [mattpocock/skills](https://github.com/mattpocock/skills) 工程技能集，用于修复常见的 Agent 编码失败模式。安装：`npx skills@latest add mattpocock/skills`，然后运行 `/setup-matt-pocock-skills` 初始化。

### 工程技能
| 技能 | 用途 |
|------|------|
| `/grill-with-docs` | 开始前确认需求，挑战计划，更新领域术语和 ADR |
| `/tdd` | 红-绿-重构循环，垂直切片式开发 |
| `/diagnose` | 纪律性诊断循环：复现 → 最小化 → 假设 → 插桩 → 修复 → 回归测试 |
| `/to-prd` | 将当前对话上下文转为 PRD 并提交为 GitHub issue |
| `/to-issues` | 将计划/PRD 分成可独立领取的 GitHub issues |
| `/improve-codebase-architecture` | 发现代码库中的深层优化机会 |
| `/zoom-out` | 将代码放在整体系统上下文中解释 |
| `/triage` | 通过状态机对 issue 进行分类 |
| `/prototype` | 构建一次性原型验证设计 |

### 生产力技能
| 技能 | 用途 |
|------|------|
| `/grill-me` | 对计划或设计进行彻底访谈，直到每个决策分支都解决 |
| `/handoff` | 将当前对话压缩为交接文档，让另一个 Agent 继续 |
| `/caveman` | 超压缩沟通模式，减少 ~75% token 使用 |

## 常用开发流程

### 新增 API 端点
1. 更新 `lib/api/v2/` 中的 API 客户端
2. 在 `lib/data/models/` 添加数据模型
3. 运行代码生成：`flutter packages pub run build_runner build`
4. 创建 Repository 方法
5. 添加 Provider action
6. 更新 UI，处理 loading/error 状态
7. 回写 `docs/development/modules/阶段总计划.md` 的批次状态和验证证据

### 调试技巧
- Debug 模式获取完整日志
- 按包名过滤：`[feature.provider]`
- Dio 拦截器查看网络日志
- Flutter Inspector 调试 Widget

### 性能考虑
- 尽可能使用 `const` 构造函数
- `cached_network_image` 做图片缓存
- `shimmer` 做加载态
- 避免在 `build()` 中执行耗时操作

## 代码审查清单
- 分层依赖正确，UI 未直接调用 API
- 文件满足 500/800 推荐阈值与 1000 硬上限，职责不超过 2 个功能域
- 错误处理与日志完整，使用 `appLogger`
- 测试门禁通过（unit/integration/ui）
- 遵守 `docs/OpenSource/1Panel/**` 只读策略
- 规范变更已同步更新 `AGENTS.md` 与 `CLAUDE.md`
