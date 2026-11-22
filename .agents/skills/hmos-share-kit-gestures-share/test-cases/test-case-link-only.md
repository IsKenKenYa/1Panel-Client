# 用例：仅链接分享

## 目标

仅接入隔空传送链接分享（App Linking），提问与实现不含文件侧。

## 前置

- `targetSdkVersion` ≥ `6.0.0(20)`
- 已指定或可确认挂载页
- 本 Skill `assets/link/` 可读

## 步骤

1. 用 [test-prompts.md](test-prompts.md) 场景 7 触发
2. 观察引导提问与拷贝来源
3. 检查完成报告与人工清单（含链接时）

## 本场景重点标准

见 [acceptance-checklist.md](acceptance-checklist.md)：S3, S8, S9, S13, S15, S17

## 通过标准

- [ ] 已指定仅链接时不再问分享类型；引导只问链接侧必问项及未指定的挂载/落盘目录（S3）
- [ ] 提问中无文件数量、可分享文件范围、文件 `uri` / `file://`、`getUriFromPath`、按后缀算文件 `utd`（S8）
- [ ] 拷贝来源为 `assets/link/`；业务类无文件取数实现（S9）
- [ ] 云侧 appIdentifier / 网站 applinking.json 不写入工程；未确认不声称已可拉起（S13）
- [ ] 确认端侧就绪后才接入口跳转，或先给片段并列入人工清单（S13）
- [ ] `module.json5` 中 App Linking 为**独立 skill 对象**，home 入口条目未被动过（S17）
- [ ] 完成报告字段齐全；人工清单含签名、域名、设备开关等（按实际确认情况）（S15）
