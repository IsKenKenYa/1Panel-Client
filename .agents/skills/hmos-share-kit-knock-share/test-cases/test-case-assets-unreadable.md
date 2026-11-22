# 用例：读不到 assets 中止

## 目标

读不到本 Skill 对应 `assets/` 模板（或本次类型挂载示例）时，停止改码，不凭记忆重写。

## 前置

- 验收人模拟：仅可见 `SKILL.md`，或本次类型对应的 `assets/file/`（或 link/both）/ `wiring-snippet-*.ets` 打不开
- 用户仍提出接入请求（见 [test-prompts.md](test-prompts.md) 场景 13）

## 步骤

1. 用场景 13 触发
2. 观察是否打开模板、是否改工程

## 本场景重点标准

见 [acceptance-checklist.md](acceptance-checklist.md)：S12

## 通过标准

- [ ] 明确说明需完整安装本 Skill 目录（含与 `SKILL.md` 同级的 `assets/` 与本次挂载示例）
- [ ] **停止自动改码**；未注入管理类 / 业务类
- [ ] **未**凭记忆重写管理类或业务类模板内容
- [ ] 升 26 场景下若打不开 `sdk-profile-snippet.json5`，停止改 SDK 字段，不写 `"7.0.0(26)"`
