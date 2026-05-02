# 仓库开发规范

## 项目结构与模块组织
- 业务源码位于 `lib/`，核心目录包括：
  - `lib/api/v2/`：Retrofit API 客户端
  - `lib/core/`：基础设施与核心服务
  - `lib/data/`：数据模型与仓库
  - `lib/features/`：业务功能模块
  - `lib/pages/`：页面容器
  - `lib/shared/`：共享组件与常量
- 平台目录位于 `android/`、`ios/`、`macos/`、`windows/`、`linux/`、`web/`。
- 测试目录位于 `test/`，覆盖目录位于 `coverage/`。
- 结构规则：当同一功能模块达到 2 个及以上文件时，必须建立独立子目录（例如 `lib/core/auth/`）。

## 1Panel 只读与适配基线（强制）
- `docs/OpenSource/1Panel/**` 为上游镜像与参考资料，整个目录只读。
- 禁止直接或间接修改 `docs/OpenSource/1Panel/**` 下任何文件，包括 `frontend/`、`core/`、`agent/` 等子目录。
- 模块能力设计必须参考 1Panel Web 前端行为与交互语义，在客户端完成高保真功能还原。
- 在能力还原基础上允许客户端增强，增强方向至少包含：多机统一管理、MFA（多因素认证）等移动端价值能力。
- 当 Swagger、注解、路由与真实返回不一致时：
  - 必须通过客户端 API 测试确认真实行为并在客户端兼容；
  - 严禁通过修改 `docs/OpenSource/1Panel/**` 来“修复契约”。

## 架构与分层（强制）
- 共享业务核心必须由 Dart 实现，原生层只承载 UI 容器与平台能力接入。
- 强制六层划分：
  - 状态层：默认 Provider，连接 UI 与业务逻辑（`lib/features/*/providers/`）
  - 服务层：业务规则与数据加工（`lib/core/services/` 或业务模块 `*_service.dart`）
  - 仓库层：数据单一事实来源（`lib/data/repositories/`）
  - 模型层：实体与请求响应结构（`lib/data/models/`）
  - API/基础设施层：外部通信、存储、平台交互（`lib/api/v2/`、`lib/core/network/`、`lib/core/storage/`、`lib/core/channel/`）
  - 核心配置层：路由、主题、国际化、全局配置（`lib/core/`）
- 依赖方向仅允许：`Presentation -> State -> Service/Repository -> API/Infra`。
- UI 层禁止直接调用 `lib/api/v2/`，必须通过 Service/Repository。
- 业务逻辑禁止写在 Widget `build()` 或原生 UI 控制器内。
- 状态管理默认 Provider，其他模式需评审通过。

## 跨平台 UI 治理（非 Web，强制）
- 适配范围：Android、iOS、iPadOS、macOS、Windows、Linux、HarmonyOS（目标平台）；Web 不在当前适配范围。
- MDUI3 是全平台可用基线，必须持续可运行，不得降级为“仅回退方案”。
- Apple（iOS/iPadOS/macOS）与 Windows 必须建设原生 UI 轨道，同时保留 MDUI3 通用轨道。
- 允许并鼓励多设计系统与多主题，但必须走统一注册中心与主题控制，禁止页面私自定义独立体系。
- 设计系统与主题是两层概念：
  - 设计系统：MDUI3、Apple 风格、Fluent/WinUI3 等
  - 主题配置：浅色、深色、动态色、品牌色、用户自定义方案
- 平台策略：
  - Windows：强制建设 Fluent/WinUI3 原生轨道
  - iOS/iPadOS/macOS：强制建设 SwiftUI 原生轨道，视觉方向适配 Liquid Glass 风格
  - Android：Dart MDUI3 为默认落地路径；原生实现仅允许经评审批准后引入
  - Linux：当前阶段以 Dart MDUI3 交付为主，原生容器能力按社区扩展路线规划
  - HarmonyOS：纳入目标平台并规划原生里程碑，当前阶段允许 `UiTarget`/Channel/Provider 占位并保持共享业务在 Dart 层
- 无论使用何种 UI 体系，共享业务逻辑都必须复用同一套 Dart State/Service/Repository/API，不得分叉为多套业务实现。
- 原生 UI 同样必须遵守 `Presentation -> State -> Service/Repository -> API/Infra`，不得跨层直接访问 API。
- 桌面缓存模块页必须禁用非当前页 Hero；带 `FloatingActionButton` 的页面必须显式设置 `heroTag` 或显式禁用 Hero。
- 禁止可变 widget 自引用包装链（例如反复重写 `content` 并在后续 builder 中引用当前 `content`）。
- 桌面模块切换必须留在统一壳内，普通切换不得再次 `push` 完整壳或首页。
- 桌面 `Scaffold` / `AppBar` / `NavigationRail` / 壳内容区默认必须使用 `surface` 或 `surfaceContainer*`，禁止整页透明背景。

## 文件规模与拆分规则（严格）
- 所有代码文件（文档与 Swagger 产物除外）硬上限为 `1000 LOC`，超出必须拆分。
- 推荐阈值：
  - 逻辑文件（Provider/ViewModel/Service/Repository/Model/Utils）建议不超过 `500 LOC`
  - UI 文件（Page/复合 Widget）建议不超过 `800 LOC`
- 单一逻辑/架构文件不得承担 3 个及以上功能域（职责上限为 2 个）。
- LOC 统计口径为非空非注释行，`*.g.dart`、`*.freezed.dart` 不计入。

## 自动化研发流程（强制）
- 所有模块开发必须按照以下自动化闭环执行，不得跳步：
  1. 需求拆解（明确能力边界、依赖、验收条件）
  2. 测试用例设计（单测、集成、UI/交互、契约偏差用例）
  3. 自动化测试基线准备（脚本、夹具、环境变量、门禁）
  4. 功能开发实现（按分层架构落地）
  5. 单元测试执行与修复
  6. 集成测试执行与修复（涉及 API/网络/数据写入时为必跑项）
  7. 文档与基线回写（模块文档、分析基线、兼容策略）
- 任一步骤失败必须回到对应步骤修复后再继续，不允许“带失败推进”。

## 构建、测试与开发命令
- `flutter pub get`：安装依赖
- `flutter run`：调试运行
- `flutter analyze`：静态分析
- `flutter test`：执行全部测试
- `flutter test test/<file>_test.dart`：执行单个测试文件
- `flutter test --coverage`：生成覆盖率报告
- `flutter packages pub run build_runner build`：生成模型与 Retrofit 代码
- `flutter build apk --release` / `flutter build appbundle` / `flutter build ios --release`：发布构建

## 编码风格与命名规范
- Dart 使用 2 空格缩进，启用 `flutter_lints`。
- 文件命名使用小写下划线。
- 后缀规范：`_page.dart`、`_widget.dart`、`_service.dart`、`_model.dart`、`_repository.dart`。
- 日志规则：禁止使用 `print()` 或 `debugPrint()`，统一使用 `lib/core/services/logger_service.dart` 中的 `appLogger`。

## 测试规范与门禁
- 测试文件以 `_test.dart` 结尾，按功能归档到 `test/` 子目录。
- Bug 修复必须补充回归测试。
- 提交前必须可运行 `flutter analyze`。
- 提交前必须可运行 `dart run test/scripts/test_runner.dart unit`。
- 涉及 API/网络或数据写入时，必须运行 `dart run test/scripts/test_runner.dart integration`。
- 涉及 UI 改动时，必须运行 `dart run test/scripts/test_runner.dart ui`。
- 涉及 Windows 原生 UI 轨道改动时，必须运行 `dotnet build windows/runner/native_host/OnePanelNativeHost/OnePanelNativeHost.csproj -c Debug`。
- 涉及 Apple 原生 UI 轨道改动时，必须在 macOS/CI 环境运行 `xcodebuild`（iOS + macOS）构建门禁并附结果。
- 原生 UI 适配门禁失败必须阻断推进，不允许“带失败继续”。
- 回归基线使用 `dart run test/scripts/test_runner.dart all`。

## Skills 与 MCP 使用
- 重大架构决策、关键约定、通用踩坑必须写入 `agent-memory-mcp`（`decision` / `pattern`）。
- 实施前应先执行 `memory_search` 检索既有结论，避免重复决策。
- 规范变更必须同步更新 `AGENTS.md` 与 `CLAUDE.md`。
- 涉及跨平台 UI 或原生扩展策略变更时，必须同步更新 `docs/development/cross_platform_ui_governance.md`、`docs/模块适配专属工作流.md`、`docs/原生UI适配专属工作流.md`。

## 提交与合并请求规范
- 提交信息遵循 Conventional Commits，例如：`feat(scope): ...`、`fix(scope): ...`、`chore: ...`、`refactor: ...`。
- PR 需保持小步提交；大改动先开 issue 对齐范围。
- PR 必须包含：变更说明、测试结果、UI 变更截图（如适用）。
- 严禁在 issue、日志、截图中泄露密钥与敏感信息。

## 发布分支与 CI
- 长期主干分支：`dev-v2`，对标 1Panel 服务端 `dev-v2` 的单主干策略。
- `main` 分支计划移除，所有功能集成、稳定验证与发布准备均围绕 `dev-v2` 展开。
- Android APK 使用 tag 驱动发布：`debug-*`、`beta-*`、`pre-release-*`、`v*`。
- tag 来源约束：
  - `debug` / `beta` / `pre-release` / `v*` 均必须来自 `dev-v2`
- 渠道映射：
  - `debug -> Alpha`
  - `beta -> Beta（公开预览）`
  - `pre-release -> Pre-Release`
  - `v* -> Release`
- 版本号策略：
  - 当前默认仍采用客户端自身语义化版本，如 `v0.6.0`
  - 与 1Panel V2 版本号同步的方案暂缓实施，需在功能与服务端版本真正对齐后再评估，例如 `v2.1.0-client`

## 安全与配置说明
- API 访问使用 1Panel API Key，禁止提交密钥或令牌。
- 分享日志或复现步骤时必须脱敏 IP、用户名、凭据。