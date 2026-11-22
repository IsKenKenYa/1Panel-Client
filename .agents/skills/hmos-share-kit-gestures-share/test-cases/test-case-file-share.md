# 用例：仅文件分享接入

## 目标

在 `targetSdkVersion` ≥ `6.0.0(20)` 的工程中，仅接入隔空传送文件分享。

## 前置

- 工程 SDK 满足接入版本要求（或可升级到要求版本）
- 存在或可指定一个可分享页面
- 页面能提供至少一个文件 URI（或选中列表）
- 本 Skill `assets/file/` 可读

## 步骤

1. 加载 Skill `hmos-share-kit-gestures-share`
2. 用 [test-prompts.md](test-prompts.md) 场景 1 触发
3. 完成引导问答（类型=仅文件；确认文件数量、可分享范围、uri 获取方式、utd、可选字段；或授权自决）
4. 检查管理类、业务类、生命周期接线
5. 静态检查与编译（环境具备时）；否则按 S16 诚实标明

## 本场景重点标准

见 [acceptance-checklist.md](acceptance-checklist.md)：S1, S3, S4, S7, S8, S9, S10, S11, S14, S15, S16

## 通过标准

- [ ] 接入前已确认（或授权自决）文件数量、可分享范围、每条记录的 `uri` 获取方式、是否写入可选字段及其来源（S3, S4, S14）
- [ ] 引导提问中无 App Linking / 域名 / 落地页 / `applinking.json` / 签名与 AGC 等链接项；已指定仅文件时不再问分享类型（S8）
- [ ] 未把未确认的裸沙箱 path 直接当作 SharedRecord.`uri`（S4）
- [ ] 未确认的可选字段未写入；仅当确认可能多文件时实现 `addRecord`；禁止臆造无业务依据的 `selected*`（S14）
- [ ] 拷贝来源为 `assets/file/`；业务类无链接取数；管理类无 LINK / HYPERLINK / `example.com`；无 App Linking 强制改码（S9）
- [ ] 管理类与业务类落在开发者确认的位置；不另起工程（S11）
- [ ] 存在单例管理类，使用 `{ windowId }` 注册 `gesturesShare`；show 注册 / hide 注销；`enable(context, provider)` 两参数（S10）
- [ ] `getFileShareData` 返回 `SharedData | undefined`（对照模板）；无内容时 `canShare()===false` 或返回 `undefined`，管理类 `reject(NO_CONTENT_ERROR)`（S4）
- [ ] 手势回调内无下载或重 IO；可分享数据在监听前备好（S7）
- [ ] 完成报告含 S15 所列字段；人工清单含设备开关、双机联调等（S15, S6）
- [ ] 环境具备时编译通过；不具备时报告写明且不谎称通过（S16）
- [ ] 流程符合核验 → 确认 → 改码 → 检查 → 报告（S1）
