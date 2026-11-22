# 用例：电脑接收对齐发送类型标识

## 目标

开启电脑端应用内接收时，接收能力声明与发送侧类型标识一致。

## 前置

- 类型含文件；开发者要电脑接收（Q7=yes）
- 本 Skill `assets/file/` 或 `both/` 可读

## 步骤

1. 用 [test-prompts.md](test-prompts.md) 场景 9 触发
2. 检查 `getReceiveCapabilities` 与发送 `utd`
3. 核对完成报告与人工清单

## 本场景重点标准

见 [acceptance-checklist.md](acceptance-checklist.md)：S18, S15

## 通过标准

- [ ] 实现 `getReceiveCapabilities`，其中类型标识（`utd`）与 `getFileShareData` 一致（S18）
- [ ] 单次最多接收文件数不超过 5（`maxSupportedCount`）（S18）
- [ ] 列表插入使用 `runScopedTask` 或 `AppStorage` 等 UI 线程安全方式
- [ ] 仅 Q7、未开 Q8 时不问坐标落点，但仍能更新已确认的数据源
- [ ] 人工清单含：同账号、电脑停在已注册页、碰应用窗口（S15 / S6）
