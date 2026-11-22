# 用例：仅链接分享接入（配置未就绪）

## 目标

SDK 6.0.0(20)+，仅接入碰一碰 App Linking 链接分享；签名/云侧未就绪时不声称完成。

## 前置

- 本 Skill `assets/link/` 与 `wiring-snippet-link.ets` 可读
- 提示词已指定仅链接，且声明签名 / applinking 未配好

## 步骤

1. 用 [test-prompts.md](test-prompts.md) 场景 2 触发
2. 核对提问隔离、资产包、云侧边界、人工清单

## 本场景重点标准

见 [acceptance-checklist.md](acceptance-checklist.md)：S1,S3,S6,S8,S9,S13,S15,S21

## 通过标准

- [ ] 已指定仅链接时不再问 Q1；只问本类型必问项（S3, S8）
- [ ] 提问无文件数量 / 文件 uri / `dataReceive` / 精准命中（S8）
- [ ] 拷贝来源 `assets/link/`；无 `getFileShareData`；接线只读 `wiring-snippet-link.ets`（S9, S21）
- [ ] 未确认域名时不写入生产 host 并宣称可直达（S13, S6）
- [ ] `appIdentifier` / `applinking.json` 不写入端侧工程（S13）
- [ ] 签名/域名未就绪列入人工清单；完成报告字段齐全（S6, S15）
