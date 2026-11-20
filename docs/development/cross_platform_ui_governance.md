# Cross-Platform UI Governance

## Summary

This document defines the platform UI strategies and shared Dart business core for 1Panel Client across native applications and browsers.

The goal is not to encourage arbitrary UI fragmentation. The goal is to enforce one shared non-UI Dart core, allow multiple governed design systems/themes, and apply explicit platform strategies without breaking architecture consistency.

## Current State

- The project currently uses `MaterialApp + ThemeData + dynamic_color`
- macOS already has a native shell implementation baseline; platform parity is still evolving
- Render mode and theme preferences already exist, but cross-platform strategy mapping needs stronger governance
- Platform folders exist, but native parity and fallback evidence are not yet complete across all non-web targets
- Shared non-UI layers are still overwhelmingly Dart-based, including API access, models, providers, repositories, and infrastructure services
- The `桌面端适配` branch is a runnable desktop implementation branch and should be treated as valuable implementation reference material, not as an automatic replacement for the default baseline policy

## Default UI Rule

### Baseline

- Non-web target platforms are Android, iOS, iPadOS, macOS, Windows, Linux, and HarmonyOS
- The project supports multiple design systems and multiple theme profiles under central governance
- MDUI3 is the mandatory, always-available baseline across target platforms and must not be treated as a backup-only path
- Apple (iOS/iPadOS/macOS) and Windows must keep a native UI track in parallel with the MDUI3 baseline
- Flutter Web uses the shared Dart business core and MDUI3, with static distribution and browser-local persistence
- Shared non-UI layers must remain Dart-first and shared across platforms unless a hard system limitation requires otherwise

### Why this is the default

- Different platforms have different UX priorities, so strategy must be platform-specific instead of one global native-first rule
- MDUI3 guarantees cross-platform continuity while native tracks can evolve without breaking shared delivery
- Shared Dart non-UI layers prevent duplicated business logic across design systems and UI stacks

## Design Systems

The project may support multiple design systems over time, but they must be governed explicitly.

### Approved design-system families

- **Material Design 3**: primary shared delivery path in current Android/Linux scope and general fallback system
- **Apple-style system**: allowed for Apple-native screens or Apple-priority visual modes
- **Fluent / WinUI3-style system**: allowed for Windows-native screens or Windows-priority visual modes

### Governance rule

A design system is not just a set of colors. A design system includes:

- visual tokens
- component behaviors
- motion style
- navigation patterns
- spacing and typography rules

No page may introduce an unregistered design system ad hoc.

## Theme System

The app should distinguish between **design systems** and **theme profiles**.

### Design system

The structural visual language:

- MD3
- Apple-style
- Fluent-style

### Theme profile

The end-user selectable appearance layer:

- light
- dark
- dynamic color
- brand seed color
- future user-selectable style presets

### Theme rule

User-facing theme switching is supported conceptually, but theme switching must remain centrally controlled.

The app should not allow individual pages to invent custom theming logic outside the shared theme system.

## Flutter Web

- Web 使用当前 Dart State、Service、Repository、API 与 MDUI3；宽度变化复用既有自适应导航。
- Cloudflare Workers Static Assets 仅保存公开应用文件。面板请求与凭据直接由浏览器发送到用户面板。
- 公开来源 `https://1pc.iskenkenya.com` 接受 HTTP/HTTPS 面板地址，并在面板或用户控制的反向代理中明确授权该来源。HTTP 需要用户确认传输风险；支持 Local Network Access 的 Chrome/Edge 可授权访问局域网 HTTP，Safari 尚不支持同类豁免。公网 HTTP 仍受混合内容检查，HTTPS 需要浏览器信任的证书。
- 浏览器 WebSocket 无法附加 1Panel 的认证请求头。当前终端与依赖此认证的实时接口需要使用面板自身的网页入口；静态分发服务不转发此类通信。
- IndexedDB 保存 AES-GCM 加密凭据。本地密码模式使用 PBKDF2-SHA256、600000 次迭代、随机 16 字节 salt；密钥在当前页面内存中。每次加密生成随机 12 字节 IV，使用存储键名作为附加认证数据。
- 用户可以选择浏览器密钥模式；不可导出的 CryptoKey 通过 IndexedDB structured clone 保存，使用当前浏览器的人可以直接打开数据。两种模式都受当前来源脚本的权限约束。
- 本地密码仅检查非空与确认一致。密码管理器通过标准自动填充与表单提交接收保存提示；表单阻止网络提交。是否保存或同步由用户的浏览器及密码管理器设置决定。
- 请求使用 HMAC-SHA256 签名与秒级时间戳，API Key 保留在本地。HTTP 没有传输加密，签名在服务端有效窗口内仍可能被重放。浏览器网络日志不保存正文、查询参数或签名。
- 设置和服务器列表保存在当前来源的浏览器存储。普通关闭或刷新保留数据；隐私浏览、清除网站数据、浏览器空间回收会影响保存。`navigator.storage.persist()` 请求持久存储，浏览器可以拒绝授权。密码遗失时无法解密原凭据。
- 文件选择按文件读取，浏览器保存通过 Blob 下载；预览使用内存中的字节与临时 Blob URL，页面销毁时释放预览 URL。PDF.js 在打开 PDF 时加载，passkeys SDK 与 PDF.js 使用本地发布资源。浏览器日志最多保留当前页面的 2000 行，可通过现有入口导出。

## Native UI Strategy

Native UI is governed by platform strategy and mandatory-track requirements for selected platforms.

### Apple platforms

SwiftUI-native pages are mandatory for iOS, iPadOS, and macOS track construction.
Visual direction should align with Liquid-Glass-like system aesthetics where appropriate.

Examples may include settings, onboarding, or system-integration-heavy flows.

#### Shared Swift Package

iOS and macOS share presentation-layer building blocks through the local package `shared/apple_ui` (`AppleSharedUI`), declared with `platforms: [.iOS(.v16), .macOS(.v13)]`.

- Package contents: semantic colors (`Tokens/SemanticColors.swift`), shared components (`LoadingView`, `InfoLine`, `StatusBadge`/`StatusPalette`, `TimestampFormat`, `ErrorView`, `EmptyStateView`), and shared state (`DataChannel`, `TranslationsProviding`, `ContainerSummary`, `ContainerListLoader`).
- The package must not import Flutter. Each app target keeps its own `ChannelManager` and `TranslationsManager` and bridges them through `IOSDataChannel` / `MacOSDataChannel` and a `TranslationsProviding` conformance.
- Localization reaches shared components through `EnvironmentValues.translationsProvider`, injected once by the shell root view on each platform.
- Platform shells that genuinely differ stay in the app targets: list containers (`List` versus `Table`), navigation containers (`NavigationStack`/`TabView` versus `NavigationSplitView`), presentation idioms (`sheet`, `swipeActions`) and platform-only modules.
- Screen-level source files live in each app target; the shared package only holds code used by both platforms.
- Gate commands: `xcodebuild -scheme AppleSharedUI -destination 'generic/platform=iOS Simulator' build`, `xcodebuild -scheme AppleSharedUI -destination 'generic/platform=macOS' build`, plus `flutter build ios --simulator --debug --no-pub`, `flutter build macos --debug --no-pub` and the two `xcodebuild test` runs for `RunnerTests`.

### Windows

Native WinUI3 / Fluent pages are mandatory on Windows track construction.

### Android

Android defaults to Dart-rendered MDUI3 in the current phase.
Native pages are optional pilot paths and require explicit architecture review approval.

### Linux

Linux may deliver with Dart-rendered MDUI3 first in the current phase.
Native container capability can be introduced incrementally.

### HarmonyOS

HarmonyOS is a first-class target platform. Current delivery keeps the shared Dart state/service/repository/API core and fills platform capability gaps through project-owned Dart facades backed by ArkTS bridge code.

Mandatory constraints:

- native and MDUI3 modes must share the same Dart non-UI core
- no duplicated business rules between native and MDUI3 presentation stacks
- platform-native UX enhancements must preserve shared state/service/repository contracts
- business/UI code must call platform capabilities through reviewed facades such as `PlatformFileService`, `PlatformDiagnosticsService`, `PlatformDownloadService`, and `PlatformMediaService`
- ArkTS bridge code may own file picker/save, URL/file opening, downloads, log export, media preview, terminal I/O, and biometric system integration, but must not own 1Panel business rules

## HarmonyOS Platform Bridge

HarmonyOS platform capability work is handled through an explicit bridge boundary:

- Flutter channel: `onepanel/ohos_platform`
- ArkTS plugin directory: `ohos/entry/src/main/ets/plugins/`
- Flutter-side facade directory: `lib/core/platform/services/`
- the bridge can implement platform abilities that Flutter plugins do not support reliably on OHOS
- platform bridge changes must keep `hflutter build hap --release` green before merge

## Page Categories

Every screen should conceptually fall into one of these categories:

### 1. Shared Flutter Screens

- implemented fully in Flutter
- use the shared MDUI3 baseline design system
- preferred as cross-platform baseline implementation

### 2. Platform-Adaptive Flutter Screens

- still implemented in Flutter
- adapt tokens, navigation, spacing, motion, or interaction by platform
- preferred when native shells are unavailable or still under parity implementation

### 3. Platform-Native Screens

- implemented in SwiftUI, WinUI3, Fluent-native, or exceptional Kotlin/Compose
- preferred for non-web targets once shared Dart non-UI contracts are in place
- must preserve application layering and shared business logic contracts

## Native Bridge Boundaries

Native UI does not change architectural boundaries.

### Mandatory rules

- Native UI must not directly call `lib/api/v2/`
- Native UI must not own core business logic
- Native UI must consume shared state/service/repository boundaries through controlled bridges
- Presentation still flows into State, then Service/Repository, then API/Infra
- API clients, shared models, repositories, providers, and most application services should continue to be implemented in Dart unless there is a hard platform restriction

### Practical implication

If a native page is introduced, it should be treated as a presentation container, not as a separate business stack.
If native code is added, the burden of proof is on the native layer to justify why the same result cannot be achieved through Flutter UI adaptation plus shared Dart logic.

### Windows capability whitelist (Phase 2-3)

- Windows native bridge channel: `onepanel/windows_bridge`
- Bridge-owned capabilities currently enabled:
	- `windowCommands` (minimize / maximize / restore / close)
	- `alwaysOnTop` (toggle topmost)
- `tray` and `toast` are enabled in Phase 3 with explicit permission flags:
	- `toastPermissionGranted`
	- `trayPermissionGranted`
- Toast failure strategy:
	- if native toast path fails or toast permission is denied, fallback to tray balloon notification when tray permission is granted
- Declared but not enabled capabilities (must stay disabled until dedicated implementation and review):
	- `systemBackdrop`
	- `jumpList`
	- `fileAssociation`
- Boundary rule: Flutter side can only call whitelisted commands through `WindowsShellBridge`; arbitrary command names and direct native invocation are prohibited.
- Validation baseline: run `scripts/windows/run_windows_bridge_validation.ps1` for command return and window-state assertions.

## Desktop Shell Stability

Desktop shells keep modules alive longer than mobile shells, so UI stability rules must be stricter.

### Hero and FAB policy

- Cached module pages in desktop shells must disable Hero participation when inactive
- Pages using `FloatingActionButton` must set explicit `heroTag` values unless Hero is intentionally disabled
- Never rely on Flutter's default FAB hero tag in a desktop shell that can keep multiple pages alive simultaneously

### Recursive widget construction policy

- Do not reassign mutable widget variables and then feed the current value back into a child/builder path
- Prefer explicit staged variables such as `baseContent`, `interactiveContent`, and `draggableContent`
- Any desktop drag/drop or context-menu wrapping should be reviewed for self-referential widget composition

## Component and Token Governance

Before multiple design systems are implemented, the codebase should move toward semantic component and token abstraction.

### Required direction

- define semantic tokens before multiplying design systems
- map tokens by system instead of hardcoding page-level visual choices
- prefer reusable cross-platform component shells

### Prohibited pattern

- page-by-page isolated styling rules with no central mapping
- arbitrary per-page platform styling decisions without documentation

## Review Checklist

Any PR introducing a new visual system, native page, or platform-specific UI should answer:

1. Is Flutter adaptive UI insufficient here?
2. Which category is this page: shared, adaptive, or native?
3. Which design system does it belong to?
4. Which tokens/components are shared vs platform-specific?
5. Does it preserve `Presentation -> State -> Service/Repository -> API/Infra`?
6. What is the fallback or rollback plan?
7. Is the plan aligned with platform strategy mapping (Windows native, Apple native, Android/Linux MDUI3-first, HarmonyOS facade + ArkTS bridge)?
8. Does the change preserve the mandatory dual-track requirement (MDUI3 baseline + native track) for Apple and Windows?

## Roadmap

### Phase 1: Governance Baseline

- document the rules in `AGENTS.md`, `CLAUDE.md`, and this file
- treat platform strategy mapping + shared Dart business core as baseline
- require explicit parity checklist and fallback evidence per platform

### Phase 2: Theme Abstraction

- evolve the current theme system toward a governed `DesignSystem` + `ThemeProfile` model
- centralize token mapping
- keep existing `ThemeController` and `AppTheme` as the starting point

### Phase 3: Flutter Adaptive Layer

- use MDUI3 as shared rendering baseline for Android/Linux and controlled fallback for other targets
- adapt spacing, navigation patterns, and tokens by platform where beneficial
- use the `桌面端适配` branch as runnable implementation reference material where helpful, but keep governance decisions in this document and the mainline repository rules

### Phase 4: Native Pilot Screens

- maintain parity checklist for Apple and Windows mandatory native tracks
- continue incremental Linux native-shell exploration while keeping MDUI3 as the current delivery baseline
- keep the HarmonyOS facade + ArkTS bridge contract buildable and expand native capability coverage incrementally

### Phase 5: Multi-Theme User Selection

- expand user-facing theme/style selection on top of the governed design-system model
- avoid uncontrolled style proliferation

## Repository Rules Summary

This document is detailed guidance.

The hard rules live in:

- `AGENTS.md`
- `CLAUDE.md`

Any changes to cross-platform UI governance must update all three locations together.

Operational workflow references:

- `AGENTS.md` § 模块适配与原生UI工作流（持续活规范）

## 执行状态

| 里程碑 | 内容 | 状态 |
|--------|------|------|
| Windows 原生轨道 | Shell + Bridge + Data Rendering + Interaction | Day 12-16 已完成 |
| iOS 原生轨道 | 从单体拆分为 21 文件模块化结构 | Day 17-18 已完成 |
| macOS 原生轨道 | 与 iOS 语义对齐完成 | Day 19 已完成 |
| 双轨审计 | 16 项修复项已识别 | Day 20 已完成 |
| 渲染模式切换 | 全平台可用 | 已完成 |

> 最后更新：2026-05-08
