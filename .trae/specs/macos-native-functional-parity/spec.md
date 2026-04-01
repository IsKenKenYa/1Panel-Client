# macOS Native Functional Parity Spec

## Why
在前面的改造中，我们已经成功将 macOS 的原生 UI 层升级为了真正的 macOS 设计语言（液态玻璃、原生 Table、NavigationSplitView 等）。但是，目前的原生 UI 只包含了基本的数据拉取和展示逻辑（Read-only），而对应的 Dart 端（MDUI3）包含了大量完整的交互功能（增删改查、弹窗、操作菜单）。我们需要确保原生 UI 在遵循原生设计规范的同时，**功能逻辑必须与 MDUI3 完全对齐**，确保应用不仅“好看”且“能用”。

## What Changes
- **功能对齐**：为 macOS 原生端的各个模块补充缺失的操作交互（Actions）。
- **原生交互逻辑**：不强行复刻 MDUI3 的 Floating Action Button 或 Material Dialog，而是采用 macOS 系统的右键菜单（Context Menu）、工具栏按钮（Toolbar）、原生弹窗（Sheet / Alert）来触发这些操作。
- **Dart 通信补充**：扩展现有的 `ChannelManager`，使其支持除了 `getXXX` 之外的增删改查及执行操作的通道方法（如 `deleteFile`, `restartContainer`, `installApp` 等）。

## Impact
- Affected specs: macOS 真原生适配规范。
- Affected code:
  - `macos/Runner/UI/Modules/` 下的所有 SwiftUI 视图及 ViewModel。
  - `macos/Runner/UI/Core/ChannelManager.swift`（支持更多操作类型）。
  - （视情况）Dart 端的 `NativeChannelManager` 补充接收相关操作请求并调用对应的 Provider/Service 方法的逻辑。

## ADDED Requirements
### Requirement: macOS Native 功能完整性
The macOS native UI SHALL provide the same level of functionality (CRUD operations, state toggling) as the Dart MDUI3 implementation, adapted into macOS-native interaction patterns.

#### Scenario: Success case
- **WHEN** a user right-clicks a file in the macOS native FilesView
- **THEN** a native context menu appears with options to Rename, Delete, Download, etc., which successfully call the underlying Dart services.

## MODIFIED Requirements
### Requirement: Channel 通信扩展
The `ChannelManager` MUST support triggering state-mutating actions (POST/PUT/DELETE equivalents) to the Dart engine.

## REMOVED Requirements
None.
