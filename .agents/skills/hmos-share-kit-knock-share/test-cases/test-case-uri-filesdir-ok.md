# 用例：对照 — 文件本就在 filesDir

## 目标

宿主预置文件本就在 `filesDir` 时，允许用其作为发送来源；说明并非禁止 `filesDir`，只禁止来源不是它时套用。

## 前置

- 类型含文件；开发者明确当前页预置文件已在 `filesDir`

## 步骤

1. 用 [test-prompts.md](test-prompts.md) 场景 11 触发
2. 检查是否允许使用 `filesDir` 及说明是否正确

## 本场景重点标准

见 [acceptance-checklist.md](acceptance-checklist.md)：S4

## 通过标准

- [ ] 发送可以使用 `filesDir`（来源经确认）
- [ ] 说明「并非禁止 `filesDir`，只禁止来源不是它时套用」（S4）
- [ ] 未把其他接收默认目录错误套到无关发送路径
