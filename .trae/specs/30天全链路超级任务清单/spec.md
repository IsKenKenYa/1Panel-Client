# 30天全链路超级任务清单 Spec

## Why
为了避免后续上下文过长导致流程遗忘，本规格将 30 天实施路线固化为可持续执行的超大任务系统。

本规格覆盖两条主线并行推进：
- 模块 API 适配与契约一致性收口
- 原生 UI 轨道建设与硬门禁落地

目标不是生成一次性计划，而是沉淀一份可反复执行、可勾选追踪、可交接复用的实施底稿。

## What Changes
- 新增中文命名规格目录：.trae/specs/30天全链路超级任务清单
- 新增 3 份持久化执行文档：
  - spec.md：目标、边界、要求
  - tasks.md：30 天超大任务清单（含依赖）
  - checklist.md：周级与发布级验收清单
- 将流程约束显式化：
  - API -> Repository/Service -> State -> UI -> Test -> Docs 链路同步
  - 文档一致性门禁（AGENTS、CLAUDE、跨平台治理、模块工作流、原生工作流）
  - 失败阻断策略（任一门禁失败禁止推进）

## Impact
- Affected specs:
  - docs/模块适配专属工作流.md
  - docs/原生UI适配专属工作流.md
  - docs/development/cross_platform_ui_governance.md
- Affected code and scripts:
  - docs/development/modules/check_module_client_coverage.py
  - docs/development/modules/check_module_api_updates.py
  - test/scripts/test_runner.dart
  - windows/runner/native_host/OnePanelNativeHost
  - ios/Runner
  - macos/Runner

## Scope
### In Scope
- 30 天实施路线的任务颗粒度拆分
- 每日执行项、每周里程碑、依赖关系
- API 覆盖收口、契约偏差修复、测试矩阵补齐
- Windows 原生轨道建设、Apple 原生轨道治理
- CI 硬门禁接入与文档同步门禁

### Out of Scope
- docs/OpenSource/1Panel 任何修改
- Web 端适配
- 无需求依据的大规模 UI 改版

## ADDED Requirements
### Requirement: 30天执行工单可追踪
The system SHALL maintain a day-by-day executable backlog for 30 days with explicit completion status.

### Requirement: 链路同步强制化
The system SHALL require same-batch synchronization for API, service, state, UI, tests, and docs whenever endpoint contract changes.

### Requirement: API覆盖日检查
The system SHALL run module coverage and baseline drift checks at least once per day during active implementation.

### Requirement: 原生轨道双线推进
The system SHALL推进 Windows 原生轨道建设，并同步治理 Apple 原生轨道结构化拆分与语义对齐。

### Requirement: 门禁失败阻断
The system SHALL stop progression when any required gate fails.

### Requirement: 文档一致性守卫
The system SHALL keep AGENTS、CLAUDE、跨平台治理文档、模块工作流、原生工作流在策略变更时同批更新。

## MODIFIED Requirements
### Requirement: 计划维护方式
由口头计划改为文件化计划；执行必须以 tasks.md 与 checklist.md 为准，避免会话上下文依赖。

## REMOVED Requirements
### Requirement: 无状态计划推进
Reason: 无状态推进在长会话中容易丢步骤与依赖关系。
Migration: 统一改为规格目录下持久化任务推进与勾选追踪。
