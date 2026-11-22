---
inclusion: auto
---

# 开发工作流

> **强制规则以 `AGENTS.md` 为准**，其中「最高优先级执行规则」优先于本文全部内容。每次用户消息提到 AGENTS.md 时，必须重新阅读 `AGENTS.md` 全文。
>
> - 默认在当前分支直接修改与提交，新建分支必须得到用户明确同意；提交消息遵循 Conventional Commits 且必须包含 `scope`，按模块或类别分别提交。详见 `AGENTS.md`「分支、发布与 CI」与「提交与合并请求规范」。
> - 每次改动完成后自动执行完整测试闭环（理解需求 → 测试用例设计 → 自动化测试基线准备 → 功能开发 → 单元测试 → 集成测试 → 文档与基线回写 → 提交），迭代到门禁全部通过后按模块提交，未提交视同闭环未完成。详见 `AGENTS.md`「每次改动后的全自动测试闭环（强制）」。
> - 开工前检索 `.agents/skills/`，与任务相关的技能必须使用，官方技能（Flutter/Dart、Android、HarmonyOS、Apple 官方集）优先；Dart & Flutter MCP server 配置在 `.mcp.json`。详见 `AGENTS.md`「技能与 MCP 工具（强制）」。

## 实时功能规划（强制）

- Flutter Web 复用 Dart 业务核心与 MDUI3，通过 Cloudflare 分发静态资源，浏览器直连具有 CORS 授权的 HTTP/HTTPS 面板。HTTP 需要用户确认风险，仍受浏览器混合内容和局域网权限限制。凭据使用 Web Crypto AES-GCM 与 IndexedDB；本地密码仅检查非空与确认一致，成功后提交自动填充上下文并阻止表单网络提交。浏览器日志不记录网络正文与查询参数，解密失败时保留数据。请求签名统一复用 `OnePanelAuthHeaders` 的 HMAC-SHA256。Web 专项门禁：`flutter test --platform chrome test/web/`、`pnpm build:web`、`pnpm check:web`。

- 功能批次状态唯一维护在 `docs/development/modules/阶段总计划.md`；不要在模块计划、审计报告或聊天记录中维护第二份“当前状态”。
- 开始前登记范围、前端行为对照、Swagger 关键字、验收和门禁；完成后回写交付、残留、验证命令与结果日期。
- 计划状态使用 `planned`、`in_progress`、`blocked`、`verified`、`deferred`。`verified` 必须附可重复命令，`deferred` 必须记录重新评估条件。
- 模块与原生 UI 强制规则以 `AGENTS.md` 为准；`docs/模块适配专属工作流.md` 与 `docs/原生UI适配专属工作流.md` 已退役，不得引用。

## 问题修复流程（强制）

### 0. 文档创建前检查（必须）
```bash
# 在创建任何文档前，先搜索是否已有相似文档
rg --files -g '*.md' -g '!docs/OpenSource/**'
rg '关键词' -g '*.md' -g '!docs/OpenSource/**'

# 优先更新现有文档，禁止为单个功能创建新文档
# 禁止为单个 bug/功能创建独立文档
# Bug 修复说明写在 test/bugfix/*_test.dart 注释中
```

### 1. 问题确认
```bash
# 查看错误日志，定位问题
flutter run  # 观察运行时错误
flutter analyze  # 检查静态分析错误
```

### 2. 文件修改前检查（必须）
```bash
# 检查文件是否已存在，在原文件上修改，不创建副本
ls -lh lib/path/to/file.dart

# 检查文件大小（行数）
wc -l lib/path/to/file.dart

# 禁止创建 *_fixed.dart、*_v2.dart、*_new.dart 等副本
# 只有文件达到 1000 LOC 时才按职责分成多个文件
```

### 3. 查阅接口定义
- API 问题：查看 `docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json`
- 前端行为：参考 `docs/OpenSource/1Panel/frontend/src/`
- **禁止修改** `docs/OpenSource/1Panel/**` 下任何文件

### 4. 编写测试
```bash
# 在 test/bugfix/ 创建回归测试
# 文件名：{issue_description}_test.dart
# 在测试文件注释中说明问题和修复方案，无需单独文档
```

```dart
/// 回归测试：{Bug 简述}
/// 
/// 问题：{问题描述}
/// 错误：{错误信息}
/// 修复：{修复方案}
/// 
/// 相关文件：
/// - lib/data/models/{file}.dart
/// - lib/data/repositories/{file}.dart
void main() {
  // 测试代码
}
```

### 5. 修复代码（在原文件上修改）
- 遵守分层：`UI -> Provider -> Service/Repository -> API`
- 文件大小：逻辑 ≤500 LOC，UI ≤800 LOC，硬上限 1000 LOC
- 使用 `appLogger`，禁止 `print()`
- **在原文件上修改，不创建 *_fixed.dart、*_v2.dart 等副本**
- 只有达到 1000 LOC 时才按职责分成多个文件

### 6. 验证修复
```bash
flutter test test/bugfix/{file}_test.dart  # 运行回归测试
flutter analyze  # 静态分析
dart run test/scripts/test_runner.dart unit  # 单元测试
# API/网络改动：
dart run test/scripts/test_runner.dart integration
# HarmonyOS/OHOS 平台能力、存储、文件、下载、日志、媒体或构建配置改动：
hflutter build hap --release
```

### 7. 热重启应用
```bash
# 模型/API 改动必须热重启（Hot Restart），不是热重载（Hot Reload）
# IDE: Ctrl+Shift+F5 (Win/Linux) 或 Cmd+Shift+F5 (macOS)
# 或完全重新构建：
flutter clean && flutter pub get && flutter run
```

## 新功能开发流程（强制）

### 1. 理解需求
- 明确能力边界
- 确认依赖关系
- 定义验收条件

### 2. 设计测试用例
- 单元测试：Provider/Service/Repository
- 集成测试：API 调用
- UI 测试：交互流程

### 3. 实现功能
```
lib/features/{module}/
├── {module}_provider.dart      # 状态管理
├── {module}_service.dart       # 业务逻辑（可选）
├── {module}_page.dart          # UI 页面
└── widgets/                    # 子组件
    └── {component}_widget.dart

lib/data/
├── models/{module}_models.dart      # 数据模型
└── repositories/{module}_repository.dart  # 数据仓库

lib/api/v2/{module}_v2.dart     # API 客户端
```

### 4. 运行测试
```bash
flutter test test/features/{module}/  # 功能测试
dart run test/scripts/test_runner.dart unit  # 单元测试
dart run test/scripts/test_runner.dart integration  # 集成测试（API 改动）
dart run test/scripts/test_runner.dart ui  # UI 测试（UI 改动）
```

## 代码生成

### 何时需要
- 新增/修改 `@JsonSerializable` 模型
- 新增/修改 Retrofit API 客户端

### 执行命令
```bash
flutter packages pub run build_runner build  # 一次性生成
flutter packages pub run build_runner watch  # 监听模式
```

## 分层依赖规则

```
✅ 正确：
UI (Page/Widget)
  ↓
Provider (State)
  ↓
Service/Repository (Business Logic)
  ↓
API Client (lib/api/v2/)

❌ 错误：
UI → API Client (跨层调用)
Widget.build() 内写业务逻辑
```

## 日志使用

```dart
import 'core/services/logger/logger_service.dart';

// ✅ 正确
appLogger.dWithPackage('module.component', '调试信息');
appLogger.iWithPackage('module.component', '操作成功');
appLogger.eWithPackage('module.component', '操作失败', error: e, stackTrace: st);

// ❌ 错误
print('调试信息');  // 禁止
debugPrint('调试信息');  // 禁止
```

## 文件大小检查

```bash
# 检查文件行数（排除空行和注释）
find lib -name "*.dart" ! -name "*.g.dart" ! -name "*.freezed.dart" -exec wc -l {} + | sort -rn | head -20

# 超过阈值必须分成多个文件：
# - 逻辑文件：500 LOC（推荐），1000 LOC（硬上限）
# - UI 文件：800 LOC（推荐），1000 LOC（硬上限）
```

## 提交前检查清单

```bash
# 1. 静态分析
flutter analyze

# 2. 单元测试
dart run test/scripts/test_runner.dart unit

# 3. 集成测试（API/网络改动）
dart run test/scripts/test_runner.dart integration

# 4. UI 测试（UI 改动）
dart run test/scripts/test_runner.dart ui

# 5. 原生 UI 门禁（如适用）
# Windows:
dotnet build windows/runner/native_host/OnePanelNativeHost/OnePanelNativeHost.csproj -c Debug
# Apple (macOS 环境):
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug
# HarmonyOS/OHOS:
hflutter build hap --release
# 或使用完整 Flutter-OH 路径：
/Volumes/FanXiangMac/DevTools/Flutter_HMOS/flutter_flutter/bin/flutter build hap --release
```

门禁全绿后立即按「按模块或类别分组提交（强制）」提交本批次改动；多会话共用工作区时用显式文件路径 `git add`，禁止 `git add -A` 与 `git add -u`。

## HarmonyOS / OHOS 开发规则

- HarmonyOS 是一等目标平台，平台缺口通过 Dart facade + ArkTS bridge 补齐。
- HarmonyOS 构建需要单独的 Flutter-OH SDK，当前基线 `3.44.9+ohos-1.0.0`；官方 Flutter 为 `3.44.9`。环境准备、版本线、参考文档见 `docs/development/harmonyos_build_and_sideload.md`。
- 参与 HarmonyOS 开发必须自行安装 Flutter-OH 与 DevEco Studio 26.0.0，并配置 `DEVECO_SDK_HOME` 与 `hvigorw`、`ohpm`、`node`、`hdc` 路径；两套 SDK 不能共用同一份 `.dart_tool`。
- Flutter 侧优先使用 `PlatformFileService`、`PlatformDiagnosticsService`、`PlatformDownloadService`、`PlatformMediaService` 等 facade，禁止在 UI/业务层直接使用 `MethodChannel`。
- ArkTS bridge 位于 `ohos/entry/src/main/ets/plugins/`，通道名为 `onepanel/ohos_platform`。
- Windows 用户使用 Flutter-OH 的 `flutter.bat` 完整路径，不要求配置 `hflutter` shell 函数。
- 排障时必须优先保留仓库 `pubspec.lock`，避免第三方包升级后触发 `TargetPlatform.ohos` 编译错误。

## 常见问题快速修复

### 模型字段必填问题
```dart
// 问题：API 要求必填，但模型定义为可选
class Model {
  final String? field;  // ❌
}

// 修复：改为必填，提供默认值
class Model {
  final String field;  // ✅
  
  const Model({
    required this.field,  // ✅
  });
  
  factory Model.fromJson(Map<String, dynamic> json) {
    return Model(
      field: json['field'] as String? ?? '',  // ✅ null 转空字符串
    );
  }
}
```

### API 调用失败
1. 查看日志中的请求体和响应
2. 对比 `swagger.json` 中的接口定义
3. 参考 Web 前端的实际调用方式
4. 在客户端兼容差异，**不修改** swagger.json

### 热重载不生效
```bash
# 模型/API 改动需要热重启，不是热重载
# 或完全重新构建：
flutter clean
flutter pub get
flutter run
```

## 文档规范

### 允许的文档
- `README.md`、`AGENTS.md`、`CLAUDE.md`、`CHANGELOG.md`
- `.kiro/steering/*.md`（开发指导）
- `docs/development/cross_platform_ui_governance.md`（跨平台策略）
- `docs/OpenSource/1Panel/**`（上游参考，只读）

### 禁止的文档
- ❌ 为单个 bug 创建 `docs/bugfix/{issue}.md`
- ❌ 为单个功能创建 `docs/features/{feature}.md`
- ❌ 创建 `修复指南.md`、`开发说明.md` 等临时文档

### 信息记录位置
- **Bug 修复说明**：写在 `test/bugfix/*_test.dart` 注释中
- **Git 提交信息**：遵循 Conventional Commits
- **PR 描述**：变更说明、测试结果、截图
- **架构决策**：使用 `agent-memory-mcp` 记录（`decision`/`pattern`）

## 禁止事项

- ❌ 修改 `docs/OpenSource/1Panel/**` 下任何文件
- ❌ 为单个问题创建专门文档（用测试注释代替）
- ❌ 创建文件副本（*_fixed.dart、*_v2.dart、*_new.dart 等）
- ❌ UI 层直接调用 `lib/api/v2/`
- ❌ 使用 `print()` 或 `debugPrint()`
- ❌ 在 Widget `build()` 内写业务逻辑
- ❌ 文件超过 1000 LOC
- ❌ 单个文件承担 3 个以上功能域
- ❌ 跳过测试门禁直接提交
