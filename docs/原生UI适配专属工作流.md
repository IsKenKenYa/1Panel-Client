# 原生UI适配专属工作流

本文档定义非 Web 平台的原生 UI 适配流程，用于与《模块适配专属工作流》并行执行。

本工作流面向两类目标：
- 平台原生体验增强（Native UI Enhancement）
- AI Agent 自动化适配与强门禁验证（AI-Agent Driven Delivery with Hard Gates）

---

## 0. 适用范围与文档关系

### 0.1 适用范围

- 目标平台：Android、iOS、iPadOS、macOS、Windows、Linux、HarmonyOS（目标阶段）
- 当前不适配范围：Web

### 0.2 与其他文档关系

- 模块 API 与业务链路适配：`docs/模块适配专属工作流.md`
- 跨平台治理总纲：`docs/development/cross_platform_ui_governance.md`
- 仓库硬规则：`AGENTS.md`
- 流程细则：`CLAUDE.md`

> 说明：本工作流不替代模块工作流，两者并行且互为门禁。

---

## 1. 强制原则（Mandatory Rules）

### 1.1 双轨基线（Dual-Track Baseline）

- MDUI3 是全平台可用 UI 基线，必须持续可运行，不得降级为“仅回退方案”。
- Apple（iOS/iPadOS/macOS）与 Windows 必须建设原生 UI 轨道。
- 原生轨道用于“锦上添花”，但不得削弱 MDUI3 通用基线可用性。

### 1.2 架构边界（Layer Boundary）

- 原生层只承载 Presentation 与平台能力接入。
- 共享业务核心保持 Dart 实现，不得分叉多套业务逻辑。
- 依赖方向必须保持：`Presentation -> State -> Service/Repository -> API/Infra`。

### 1.3 上游只读（Upstream Readonly）

- `docs/OpenSource/1Panel/**` 仅允许读取，不允许任何修改。
- 契约偏差必须通过客户端兼容处理，不得修改上游镜像。

### 1.4 强门禁阻断（Hard-Gate Blocking）

- 任一门禁失败，必须阻断推进。
- 禁止“带失败继续开发”或“先合并后补门禁”。

---

## 2. 平台策略矩阵（Platform Strategy Matrix）

| 平台 | MDUI3 基线 | 原生 UI 轨道 | 当前策略 | 例外策略 |
|------|------------|--------------|----------|----------|
| Android | 必须 | 可选 | 默认 Flutter Dart 渲染 MDUI3 | 原生实现需评审批准 |
| iOS / iPadOS | 必须 | 必须 | 强制建设 SwiftUI 轨道（Liquid Glass 视觉语义） | 无 |
| macOS | 必须 | 必须 | 强制建设 SwiftUI 轨道（Liquid Glass 视觉语义） | 无 |
| Windows | 必须 | 必须 | 强制建设 WinUI3/Fluent 轨道 | 无 |
| Linux | 必须 | 规划 | 当前以 MDUI3 交付，保留原生社区扩展路线 | 原生试点需单独立项 |
| HarmonyOS（目标） | 必须 | 规划 | 当前先保留 resolver/channel/provider 占位 | 原生实施按里程碑推进 |

---

## 3. 设计系统与主题双层模型

### 3.1 设计系统层（Design System Layer）

- MDUI3
- Apple 风格（SwiftUI/HIG）
- Fluent/WinUI3 风格

### 3.2 主题配置层（Theme Profile Layer）

- Light
- Dark
- Dynamic Color
- Brand Seed
- Future Community Presets

### 3.3 治理约束

- 页面不得私自定义未注册设计系统。
- 页面不得绕开统一主题控制器。
- 新增设计系统必须附带：平台范围、Token 映射、组件覆盖、回退策略。

---

## 4. AI Agent 自动化闭环

AI Agent 执行原生 UI 适配时，必须按以下顺序执行：

1. 需求拆解（Requirement Decomposition）
2. 基线核对（Baseline Verification）
3. 方案设计（Design + Architecture Plan）
4. 实施改造（Implementation）
5. 自动化门禁验证（Hard Gates）
6. 文档回写（Documentation Sync）
7. 一致性复核（Consistency Review）

任何阶段失败必须返回前一阶段修复。

---

## 5. 强门禁矩阵（Hard Gate Matrix）

### 5.1 Flutter 通用门禁

```bash
flutter analyze
dart run test/scripts/test_runner.dart unit
```

### 5.2 条件门禁

- 涉及 API / 网络 / 数据写入：

```bash
dart run test/scripts/test_runner.dart integration
```

- 涉及 UI 变更：

```bash
dart run test/scripts/test_runner.dart ui
```

### 5.3 原生专项门禁

- Windows 原生轨道：

```bash
dotnet build windows/runner/native_host/OnePanelNativeHost/OnePanelNativeHost.csproj -c Debug
```

- Apple 原生轨道（CI/macOS 环境）：

```bash
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator build
xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner -configuration Debug build
```

### 5.4 文档一致性门禁

以下文档必须同批同步：
- `AGENTS.md`
- `CLAUDE.md`
- `docs/development/cross_platform_ui_governance.md`
- `docs/模块适配专属工作流.md`
- `docs/原生UI适配专属工作流.md`

任一缺失视为门禁失败。

---

## 6. 原生 UI 语义对齐检查（Semantic Parity Checklist）

### 6.1 必检项

- [ ] 入口语义一致（模块入口、导航层级一致）
- [ ] 主流程一致（创建、编辑、删除、批量操作行为一致）
- [ ] 错误反馈一致（失败提示、重试路径一致）
- [ ] 权限与危险操作一致（二次确认与权限提示一致）
- [ ] 国际化一致（中英文文案来源一致）
- [ ] 无跨层调用（原生 UI 不得直连 API）

### 6.2 平台专项

- [ ] Windows：窗口能力、托盘、通知能力符合白名单策略
- [ ] Apple：遵循 SwiftUI 与平台交互语义，不引入业务分叉
- [ ] Android：MDUI3 体验持续可用，原生例外有审批记录
- [ ] Linux/Harmony：里程碑状态与占位边界清晰可追踪

---

## 7. 失败回退策略（Fallback Policy）

### 7.1 技术回退

- 原生轨道构建失败时，必须保证 MDUI3 基线轨道可运行。
- 不得因为原生轨道问题阻断全平台交付。

### 7.2 流程回退

- 门禁失败必须回到对应阶段重做：
  - 实现问题 -> 回到实施改造
  - 策略冲突 -> 回到方案设计
  - 文档不同步 -> 回到文档回写

---

## 8. 交付物清单（Deliverables）

每次原生 UI 适配提交至少包含：

1. 代码改动（原生层 + Dart 共享层）
2. 自动化门禁结果
3. 语义对齐检查清单
4. 例外审批记录（如 Android 原生例外）
5. 文档同步记录（AGENTS / CLAUDE / 治理文档 / 工作流）

---

## 9. AI Agent 执行模板（Command Template）

### 9.1 标准执行模板

```bash
# 1) 通用门禁
flutter analyze
dart run test/scripts/test_runner.dart unit

# 2) 条件门禁（按改动范围执行）
dart run test/scripts/test_runner.dart integration
dart run test/scripts/test_runner.dart ui

# 3) 原生专项
dotnet build windows/runner/native_host/OnePanelNativeHost/OnePanelNativeHost.csproj -c Debug
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator build
xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner -configuration Debug build
```

### 9.2 非 macOS 环境说明

在非 macOS 环境无法执行 Apple 构建时，必须在变更说明中提供：
- 未执行原因
- CI 计划或代执行责任人
- 补验时间点

---

## 10. 版本信息

- 文档版本：1.0
- 最后更新：2026-04-20
- 维护者：Open1Panel 开发团队
