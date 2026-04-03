# Security Policy

## Supported Versions

Security fixes are prioritized for actively maintained branches, current release tags, and supported preview channels that are still under active development.

## Reporting a Vulnerability

Please do **not** disclose vulnerabilities publicly before triage and confirmation.

Preferred reporting channels:

- GitHub Security Advisories
- GitHub Issues only when private advisory reporting is unavailable

## What to Include

Please include as much of the following as possible:

- affected version, commit, branch, or tag
- reproduction steps
- impact and severity assessment
- scope of exposure
- optional mitigation ideas or workarounds

## Response Expectations

We aim to:

- acknowledge reports as soon as practical
- validate and triage severity
- prioritize high-impact fixes
- coordinate disclosure timing responsibly
- credit reporters when appropriate and safe

## Disclosure Policy

- Do not open a public issue for an unpatched vulnerability if private reporting is available.
- Do not publish exploit details before maintainers complete triage.
- Give maintainers reasonable time to investigate, reproduce, and prepare a fix.

## Secure Development Notes

- Never log API keys, passwords, tokens, or private credentials.
- Use `appLogger` instead of `print` or `debugPrint`.
- Review dependency updates before merging.
- Follow least-privilege principles for permissions, tokens, and CI secrets.
- Redact IPs, usernames, access paths, and infrastructure details before sharing logs externally.

---

# 安全政策

## 支持版本

安全修复优先覆盖仍在维护的分支、当前发布标签，以及仍处于活跃开发中的预览渠道版本。

## 漏洞报告方式

在完成初步确认和分级前，请**不要**公开披露漏洞。

优先使用以下方式报告：

- GitHub Security Advisories
- 如无法使用私密 advisory，再使用 GitHub Issues

## 报告应包含的信息

请尽量提供以下信息：

- 受影响的版本、提交、分支或 tag
- 复现步骤
- 影响范围与严重程度判断
- 暴露面说明
- 可选的缓解思路或临时规避方案

## 响应目标

我们会尽力做到：

- 尽快确认已收到报告
- 完成漏洞验证与严重性分级
- 优先处理高影响问题
- 负责任地协调披露时间
- 在合适且安全的前提下鸣谢报告者

## 披露原则

- 如果可以私密报告，请不要为未修复漏洞直接创建公开 Issue。
- 在维护者完成初步分析前，不要公开 exploit 细节。
- 请给维护者合理时间完成调查、复现与修复准备。

## 安全开发要求

- 禁止记录 API Key、密码、Token 或其他私密凭证。
- 统一使用 `appLogger`，不要使用 `print` 或 `debugPrint`。
- 依赖升级需经过审查后再合并。
- 权限、令牌与 CI secrets 需遵守最小权限原则。
- 对外分享日志前，请脱敏 IP、用户名、访问路径和基础设施细节。
