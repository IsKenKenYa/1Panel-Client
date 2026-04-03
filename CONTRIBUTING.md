# Contributing Guide

Thank you for contributing to 1Panel Client.

## Purpose

This guide helps contributors understand how to propose changes, prepare code, and submit pull requests that match the repository standards.

## Before You Start

- Read `AGENTS.md` first for mandatory repository rules.
- Read `CLAUDE.md` for project details, commands, and workflow context.
- Keep changes focused, incremental, and easy to review.
- Check whether the task belongs to `dev`, `main`, or a release tag workflow before changing CI or release-related files.

## Branch and Tag Strategy

- `dev` is the long-lived feature aggregation branch.
- `main` is the stable release baseline.
- Android APK publishing is tag-driven:
  - `debug-*` for internal alpha builds
  - `beta-*` for public beta builds
  - `pre-release-*` for candidate builds
  - `release-*` for stable builds from `main`
- Do not change release workflows casually. Treat branch and tag policy as repository governance.

## Development Setup

- Install Flutter and project dependencies with `flutter pub get`.
- Use Java 17 for Android builds.
- Keep local secrets out of the repository.
- If your change depends on generated localization or model files, regenerate them before submitting.

## Coding Rules

- Follow one-way dependency direction: `Presentation -> State -> Service/Repository -> API/Infra`.
- Do not call `lib/api/v2/` directly from UI code.
- Do not put business logic inside widget `build()` methods.
- Use `Provider` as the default state-management approach unless there is an explicit exception.
- Use `appLogger`; do not use `print()` or `debugPrint()`.
- Respect repository file-size rules and split large files when necessary.

## Testing Gate

Run the minimum required checks before opening a pull request:

- `flutter analyze`
- `dart run test/scripts/test_runner.dart unit`
- `dart run test/scripts/test_runner.dart integration` when touching API, network, or data-write behavior
- `dart run test/scripts/test_runner.dart ui` when touching UI

If you cannot run a required test, explain why in the pull request.

## Commit and Pull Request Rules

- Use Conventional Commits when writing commit messages.
- Keep pull requests small and scoped.
- Include a clear summary, motivation, testing results, and screenshots for UI changes.
- Update docs when behavior, standards, or release policy changes.
- Never include API keys, tokens, passwords, private IPs, or other secrets in code, logs, screenshots, or issues.

## Security and Sensitive Data

- Redact sensitive information before sharing logs.
- Avoid posting production data in issues or pull requests.
- Use GitHub Security Advisories for private vulnerability reporting whenever possible.

## License Notice

By contributing, you agree that your contributions are licensed under GPL-3.0 together with the rest of this repository.

---

# 贡献指南

感谢你为 1Panel Client 做出贡献。

## 目标

本文档用于帮助贡献者了解如何提出变更、准备代码以及提交符合仓库规范的 Pull Request。

## 开始前

- 先阅读 `AGENTS.md`，了解仓库的硬性规则。
- 再阅读 `CLAUDE.md`，了解项目细节、常用命令和工作流背景。
- 尽量保持改动聚焦、渐进、易于评审。
- 如涉及 CI 或发布文件，请先确认该改动属于 `dev`、`main` 还是 release tag 流程。

## 分支与标签策略

- `dev` 是长期维护的功能聚合分支。
- `main` 是稳定正式发布基线。
- Android APK 使用 tag 驱动发布：
  - `debug-*` 用于内部 alpha 构建
  - `beta-*` 用于公开 beta 构建
  - `pre-release-*` 用于候选构建
  - `release-*` 用于从 `main` 产出的正式构建
- 不要随意修改发布工作流，分支和 tag 策略应视为仓库治理规则的一部分。

## 开发环境

- 使用 `flutter pub get` 安装依赖。
- Android 构建使用 Java 17。
- 本地 secrets 不得进入仓库。
- 如果改动依赖生成文件（如本地化或模型生成），请在提交前重新生成。

## 编码规范

- 严格遵循单向依赖：`Presentation -> State -> Service/Repository -> API/Infra`。
- UI 层不得直接调用 `lib/api/v2/`。
- Widget `build()` 内不得编写业务逻辑。
- 默认使用 `Provider` 进行状态管理，除非有明确例外。
- 使用 `appLogger`，禁止使用 `print()` 和 `debugPrint()`。
- 遵守仓库文件大小规则，必要时主动拆分大文件。

## 测试门禁

在发起 Pull Request 前，至少执行以下检查：

- `flutter analyze`
- `dart run test/scripts/test_runner.dart unit`
- 涉及 API、网络或数据写入时执行 `dart run test/scripts/test_runner.dart integration`
- 涉及 UI 时执行 `dart run test/scripts/test_runner.dart ui`

如果无法执行某项必需测试，请在 Pull Request 中明确说明原因。

## 提交与 Pull Request 规范

- 提交信息使用 Conventional Commits。
- Pull Request 尽量保持小而清晰。
- PR 需要包含明确的摘要、背景、测试结果，以及 UI 改动的截图。
- 行为、规范或发布策略变更时，必须同步更新文档。
- 代码、日志、截图、Issue 中不得包含 API Key、Token、密码、内网 IP 或其他敏感信息。

## 安全与敏感信息

- 分享日志前先进行脱敏。
- 不要在 Issue 或 Pull Request 中贴生产数据。
- 私密漏洞优先通过 GitHub Security Advisories 报告。

## 许可证说明

提交贡献即表示你同意这些贡献与仓库其余内容一起遵循 GPL-3.0 许可证。
