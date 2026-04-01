# Update Architecture and macOS Rules Spec

## Why
用户进一步明确了跨平台原生 UI 和 Dart 架构层的详细规范。要求将 macOS 端开发目标具体化为“主要针对 macOS 26 进行适配，稍微适配 macOS 15（至少能打开）”，并要求将项目中 Dart 实现的六大核心架构层（状态管理、服务与业务逻辑、数据仓库、数据模型、API与基础设施、核心配置与全局支持层）的详细定义与指引写入全局规则文件。

## What Changes
- 将 macOS 目标适配版本（针对 macOS 26 设计，兼容 macOS 15）的说明写入 `.trae/rules/ui_rules.md`。
- 将用户提供的六大核心架构层（State, Service, Repository, Model, API/Infra, Core/Config）的详细中文说明、代码位置示例和职责限制，完整写入 `AGENTS.md` 和 `.trae/rules/project_rules.md` 中，以供后续所有 Agent 与开发人员遵循。

## Impact
- Affected specs: 架构分层规范，平台适配策略。
- Affected code:
  - `AGENTS.md`
  - `.trae/rules/ui_rules.md`
  - `.trae/rules/project_rules.md`

## ADDED Requirements
### Requirement: Dart 核心架构六层详细规范
The system SHALL document the exact responsibilities, technology choices (e.g., Provider for State), and code locations for the six core Dart layers in the project rules.

#### Scenario: Success case
- **WHEN** a new feature is being planned or implemented
- **THEN** the AI agent and developer can reference the detailed guidelines to know exactly where to place state management, service logic, and repository files.

### Requirement: macOS 平台明确的兼容基线
The system SHALL document that the macOS native UI primarily targets macOS 26 design paradigms (like Liquid Glass) while maintaining minimum compatibility with macOS 15.

## MODIFIED Requirements
### Requirement: 跨平台 UI 规范更新
The UI rules SHALL clearly state that non-Android/Web platforms use true native UI and authentic interactions, but retain the option to switch to Dart-rendered MDUI3 for unified visual style.

## REMOVED Requirements
None.
