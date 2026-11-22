# 用例：挂载冲突预检

## 目标

目标页已有其它 knockShare 监听或生命周期钩子已被占用时，合并或追加而非覆盖或新建第二套。

## 前置

- 本 Skill `assets/file/` 可读
- 目标页 `pages/Detail` 已有 `onPageShow` 钩子（如埋点上报）
- （可选子场景）目标页已有另一处 `on('knockShare')` 监听
- 用户提出接入请求（见 [test-prompts.md](test-prompts.md) 场景 17）

## 步骤

1. 用场景 17 触发
2. 确认阶段 4 挂载冲突预检执行
3. 观察挂载行为

## 本场景重点标准

见 [acceptance-checklist.md](acceptance-checklist.md)：S5, S10, S24

## 通过标准

- [ ] 检测到 `onPageShow` 已有其它逻辑（如埋点）→ **追加** `enable(...)` 而非覆盖已有钩子（S24）
- [ ] 若已有 `on('knockShare')` 监听 → 合并到同一 Manager，**未**新建第二套监听（S5）
- [ ] `onPageHide` 同理追加 `disable()` 而非覆盖
- [ ] 完成报告挂载点字段写明追加位置与原有钩子的关系（S15）
