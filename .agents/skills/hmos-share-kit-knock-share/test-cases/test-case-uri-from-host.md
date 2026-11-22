# 用例：发送 URI 跟宿主来源

## 目标

发送 URI 来自宿主真实来源；不把接收默认目录套成发送根路径。

## 前置

- 类型含文件；URI 来源由 Agent 读工程确认
- 本 Skill `assets/file/` 可读

## 步骤

1. 用 [test-prompts.md](test-prompts.md) 场景 10 触发
2. 检查 URI 接线与完成报告

## 本场景重点标准

见 [acceptance-checklist.md](acceptance-checklist.md)：S4, S15, S20

## 通过标准

- [ ] 先读宿主现有 URI 字段 / path / 文件就绪回调，再接线（S4）
- [ ] **不**把 Q7 的 `filesDir`（或接收默认目录）当成发送默认根路径（S4）
- [ ] 完成报告写明发送 URI 在宿主中的来源（S15）
- [ ] `canShare()` 不按设备类型 / 2in1 关闭（S20）
- [ ] 若开启精准：未命中回退全量取数（S20）
