# 规则索引（Rules Index）

> 规则清单已从最新部署（commandline-tools **26.0.1.272**）提取：
> - C++：cpp-agent `base_rules.json` → 27 条（见 [cpp-rules.md](./cpp-rules.md)）
> - ArkTS：homeflow `config/checkerConfig.json` → 23 条（见 [arkts-rules.md](./arkts-rules.md)）
> 提取脚本参考 `scripts/extract-rules.js`（可对任意部署目录重新生成本文档）。

## 规则分类

| 语言/引擎 | 规则文档 | 规则来源 | 数量 |
|-----------|----------|----------|------|
| C++（cpp-agent） | [cpp-rules.md](./cpp-rules.md) | cpp-agent `base_rules.json` | 27 |
| ArkTS（homeflow） | [arkts-rules.md](./arkts-rules.md) | homeflow `config/checkerConfig.json` | 23 |

两类规则当前均属于 **ResourceLeak（内存/资源泄漏）检查器**：C++ 为 API 配对类（alloc/release、on/off），ArkTS 为资源/监听器释放类（NotRelease / NotOff）。

## 规则在 CLI 中的落点

- **C++ 规则**：由 cpp-agent 加载 `base_rules.json` 执行；CLI 侧通过 `--compileCommandsDir`（compile_commands.json）提供编译上下文，`--no-cpp` 关闭。
- **ArkTS 规则**：由 homeflow 执行；规则配置文件通过 `-c/--config` 传入。未传 `-c` 时使用 homeflow 自带 `checkerConfig.json`，23 条规则全开；仅在传入 `-c` 时按白名单语义，未列出的规则自动补充为 `skip: true`。

## 从 SARIF 中识别规则

SARIF `run.results[]` 的 `ruleId` 字段即规则 ID；`ruleIndex` 可关联 `run.tool.driver.rules[]` 获取规则说明（`shortDescription` / `fullDescription`）。解读 merged.sarif 时按 ruleId 聚合命中即可。

## 版本差异提示

- 规则清单随部署版本变化（26.0.1.210 → 26.0.1.272 期间规则有增删）。答疑时若用户规则 ID 不在本文档，先确认其部署版本。
- 规则中文说明/触发模式可查引擎自带文档（cpp: `cpp-agent/document/*.md`；arkts: homeflow `document/checker/ResourceLeak/*.md`）。
