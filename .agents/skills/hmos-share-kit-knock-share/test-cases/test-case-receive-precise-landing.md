# 用例：电脑接收 + 精准问落点

## 目标

电脑接收与精准均为是时，先读实际 UI 再确认接收落点（含自定义）。

## 前置

- 类型含文件；Q7=yes 且 Q8=yes
- 本 Skill `assets/file/`（或 both）、`KnockRectUtil.ets` 可读

## 步骤

1. 用 [test-prompts.md](test-prompts.md) 场景 12 触发
2. 观察提问顺序与落点确认
3. 核对完成报告

## 本场景重点标准

见 [acceptance-checklist.md](acceptance-checklist.md)：S19, S20, S15

## 通过标准

- [ ] Q8 第一轮只问是否精准，不夹杂接收落点（S19 前置）
- [ ] Q7 与 Q8 都 yes 之后：先读挂载页并陈述实际结构，再推导插入位置选项且含**自定义**（S19）
- [ ] 不套用某种布局的现成选项表；未确认不把接收项 push 到末尾（S19）
- [ ] 精准未命中回退全量取数（S20）
- [ ] 完成报告写明读到的 UI 与所选落点（S15）
