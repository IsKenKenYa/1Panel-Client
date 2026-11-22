# 用例：文件 + 链接（配置未就绪）

## 目标

用户要文件与链接直达，但签名/域名未就绪时：可做发送侧骨架，不虚假宣称仓外完成。

## 前置

- `targetSdkVersion` ≥ `6.0.0(20)`
- 用户声明域名计划，但签名与网站 `applinking.json` 未完成
- 本 Skill `assets/both/` 可读

## 步骤

1. 用 [test-prompts.md](test-prompts.md) 场景 2 触发
2. 观察引导确认与改码范围
3. 检查报告中的人工清单与工程内是否误写云侧配置

## 本场景重点标准

见 [acceptance-checklist.md](acceptance-checklist.md)：S1, S3, S4, S6, S9, S13, S15, S17

## 通过标准

- [ ] 已指定两者时不再问分享类型；引导同时含文件侧与链接侧必问项（可分组）（S3）
- [ ] 文件侧 `uri` / `utd` 等已确认或授权自决（S4）
- [ ] 询问并记录域名 / query / 落地页；端侧 skills 与签名状态已**自动检测**并写入报告（S3, S13）
- [ ] 拷贝/升级为 `assets/both/`；业务类同时具备文件与链接取数（S9）
- [ ] 明确列出签名、域名验证、云侧 appIdentifier / 网站 applinking.json、设备开关等人工项（S6）
- [ ] 端侧工程未写入 appIdentifier，也未拷入 `applinking.json`（S13）
- [ ] 不声称「App Linking 已可联调成功」或域名关联已完成（S6）
- [ ] 未确认前不强制把入口跳转写成已可直达；确认后才合并 skills / Ability 或先给待改片段（S13）
- [ ] 已写入 skills 时，App Linking 为**独立 skill 对象**，未混入 home 入口条目（S17）
- [ ] 完成报告字段齐全（S15）
- [ ] 已改 ets 时静态检查 + 编译通过（环境具备时）；否则按 S16 标明
- [ ] 流程符合 S1
