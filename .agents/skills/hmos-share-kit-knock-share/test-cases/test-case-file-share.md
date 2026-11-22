# 用例：仅文件分享接入

## 目标

SDK 6.0.2(22)+（不要精准）或 API 26+（要精准），仅接入碰一碰文件发送。

## 前置

- 本 Skill `assets/file/` 与 `wiring-snippet-file.ets` 可读
- 提示词已指定仅文件；可指定不要电脑接收 / 不要精准

## 步骤

1. 用 [test-prompts.md](test-prompts.md) 场景 1 触发
2. 核对提问隔离、资产包、挂载示例、完成报告

## 本场景重点标准

见 [acceptance-checklist.md](acceptance-checklist.md)：S1,S2,S3,S4,S7,S8,S9,S10,S11,S14,S15,S16,S21

## 通过标准

- [ ] 已指定仅文件时不再问 Q1；已指定不要电脑接收/精准则不再问 Q7/Q8；未说明精准时先问 Q8，再确认 API **22+** / **26+**（S2, S3）
- [ ] 提问无 App Linking / 域名 / HYPERLINK / `gesturesShare`（S8）
- [ ] 已确认（或自决）文件数量、可分享范围、**URI 宿主来源**、类型标识（`utd`）、可选字段（S4, S14）
- [ ] 发送 URI 与宿主真实来源一致；完成报告写明来源（S4, S15）
- [ ] 拷贝来源 `assets/file/`；无 `getLinkShareData`；接线只读 `wiring-snippet-file.ets`（S9, S21）
- [ ] `enable(context, provider)`；未开 Q7/Q8 时无 `dataReceive` / 无 `KnockRectUtil`
- [ ] 可分享页显示时注册、离开时注销；注入目录经确认（S10, S11）
- [ ] 数据在监听前备好；回调内无下载或重 IO（S7）
- [ ] Provider 对照挂载示例（推荐 class；取数失败返回 undefined）
- [ ] 有构建则编译通过；完成报告与人工清单齐全（S15, S16）
