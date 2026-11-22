# 用例：仅链接不混文件/接收

## 目标

仅链接接入时，提问与实现均不含文件发送、电脑接收与精准命中。

## 前置

- 提示词已指定仅链接（可用场景 2）
- 本 Skill `assets/link/` 与 `wiring-snippet-link.ets` 可读

## 步骤

1. 用 [test-prompts.md](test-prompts.md) 场景 7（或场景 2）触发
2. 检查提问与工程改动

## 本场景重点标准

见 [acceptance-checklist.md](acceptance-checklist.md)：S8, S9, S21

## 通过标准

- [ ] 提问中无文件数量、文件 uri、`dataReceive`、精准命中、组件 id（S8）
- [ ] 拷贝来源 `assets/link/`；无 `getFileShareData`、无 `dataReceive`、无 `KnockRectUtil`（S9）
- [ ] 接线只打开 `wiring-snippet-link.ets`，不打开 file/both（S21）
