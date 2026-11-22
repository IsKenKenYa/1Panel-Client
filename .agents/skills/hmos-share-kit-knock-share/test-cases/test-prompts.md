# 测试提示词

人验收时按场景加载 Skill，使用下列提示词，对照 [acceptance-checklist.md](acceptance-checklist.md) 与对应 `test-case-*.md` 勾选。

## 场景 1：仅文件分享接入

**提示词**：

```
请使用 hmos-share-kit-knock-share，帮我在当前工程接入碰一碰传送文件。
只要发送，不要电脑端应用内接收，也不要精准碰一碰。
挂载页面是 pages/Detail，分享当前页已选中的本地文件 URI 列表。
```

**预期输出**：

- 前置检测记录当前 SDK，**不要未问精准就按 20 中止或把文件侧升到 20**
- 已指定仅文件 → 不要再问 Q1；已指定不要电脑接收/精准 → 不要再问 Q7/Q8；Q8=no 时目标 **API 22+**，当前 <22 须确认升 22
- 提问中无 App Linking、域名、HYPERLINK、`gesturesShare`、接收目录、组件 id
- 拷贝 **`assets/file/`** 的 `KnockShareManager` / Provider（无 `getLinkShareData` / 无 HYPERLINK）
- 接线只打开 `wiring-snippet-file.ets`，不打开 link/both 示例
- `enable(ctx, provider)`；不拷 `KnockRectUtil`
- 静态检查与编译（环境具备时）；完成报告与人工清单
- 用例：[test-case-file-share.md](test-case-file-share.md)

## 场景 2：仅链接（App Linking，配置未就绪）

**提示词**：

```
请接入碰一碰链接分享（App Linking）。挂载页是 pages/VideoPlay。
域名是 share.myapp.com，参数 videoIndex，落地页是 pages/VideoPlay。
签名和 applinking.json 我还没配好。
```

**预期输出**：

- 已指定仅链接 → 不要再问 Q1；只问本类型必问项
- **提问中不得出现** 文件数量、文件 uri、`dataReceive`、精准命中、组件 id
- 拷贝 **`assets/link/`**，无 `getFileShareData`、无 `dataReceive`
- 接线只打开 `wiring-snippet-link.ets`
- 未就绪的签名/域名列入人工清单，不把接入标为域名已完成
- 不把 `assets/applinking.json` 拷进工程
- 用例：[test-case-link-share.md](test-case-link-share.md)

## 场景 3：SDK 过低须先定目标再升级

**提示词**：`请接入碰一碰传送文件。`（工程视为 5.0.0(12)）

**预期输出**：

- 已指定仅文件 → 不要再问 Q1
- **先问 Q8**（是否接入精准碰一碰），不要夹杂 Q3/Q7
- Q8 = yes → 确认升级到 **API 26+**，写入 `"26.0.0"`（对照 `sdk-profile-snippet.json5`）；Q8 = no → 确认升级到 **API 22+**，写入 `"6.0.2(22)"`
- 未获升级确认前不改 `build-profile.json5`、不注入 Manager
- 拒绝升 26 但同意 22 → 只做文件发送，不接线精准；**不要**改按 20 发送；**不要**写成 `"7.0.0(26)"`
- 用例：[test-case-unsupported-sdk.md](test-case-unsupported-sdk.md)

**提示词（仅链接 + 低 SDK）**：`请接入碰一碰链接分享。`（工程视为 5.0.0(12)）

**预期输出**：不问 Q8；确认升到 API 20+；拒绝则停止改码。对照同一用例文件。

### 场景 3b：含文件未问精准不得按 20 一刀切

**提示词**：`接入碰一碰文件分享。`（工程视为 6.0.0(20)）

**预期输出**：

- 未说明 Q8 → **先问是否精准碰一碰**
- 若选精准且当前是 API 20 → 确认升到 **API 26+** 并写入 `"26.0.0"`，不要直接说「SDK 不够，该项停止」，不要写 `"7.0.0(26)"`
- 若选不精准且当前是 API 20 → 确认升到 **API 22+** 并写入 `"6.0.2(22)"`，不要停留在 20
- 用例：[test-case-unsupported-sdk.md](test-case-unsupported-sdk.md)

## 场景 4：未说明类型时先只问 Q1

**提示词**：`接入碰一碰。`

**预期输出**：

- 本轮**只问 Q1**（仅文件 / 仅链接 / 两者）
- 不要附带文件 uri / App Linking / 电脑接收
- 答清前不改码
- 用例：[test-case-guide-unspecified.md](test-case-guide-unspecified.md)

## 场景 5：已有文件，增量补链接

**提示词**：`工程已有碰一碰文件分享，请再接入链接分享。`

**预期输出**：

- 检测到已有 Manager（含旧名 `KnockFileShareManager`）
- 用 `assets/both/` 升级；补 `getLinkShareData`；`enable` 改为带 `KnockShareMode`
- 不问整份 Q3；避免第二套监听
- 用例：[test-case-incremental-both.md](test-case-incremental-both.md)

## 场景 6：仅文件不得混入链接 stub

**提示词**：同场景 1。

**预期输出**：

- 无 `getLinkShareData`、无 HYPERLINK、无 `example.com`、无 App Linking 改码
- 接线只读 `wiring-snippet-file.ets`
- 用例：[test-case-file-no-link-stub.md](test-case-file-no-link-stub.md)

## 场景 7：仅链接不得混入文件/电脑接收

**提示词**：同场景 2。

**预期输出**：

- 无 `getFileShareData`、无 `dataReceive`、无 `KnockRectUtil`、无文件 uri 提问
- 接线只读 `wiring-snippet-link.ets`
- 用例：[test-case-link-no-file.md](test-case-link-no-file.md)

## 场景 8：仅询问概念

**提示词**：`碰一碰传文件和传链接有什么区别？`

**预期输出**：

- 可说明差异；未要求接入则不改工程
- 用例：[test-case-no-integration-request.md](test-case-no-integration-request.md)

## 场景 9：电脑接收必须对齐发送类型标识

**提示词**：

```
接入碰一碰分享文件，挂载多文件页。要电脑端应用内接收。
```

**预期输出**：

- Q7=yes 时实现 `getReceiveCapabilities`，类型标识（`utd`）与 `getFileShareData` 一致
- 单次最多接收文件数不超过 5（`maxSupportedCount`）
- 列表插入使用 `runScopedTask` 或 `AppStorage`
- 仅 Q7、未开 Q8 时不问坐标落点，但仍要能更新已确认的数据源
- 人工清单含：同账号、电脑停在已注册页、碰应用窗口
- 用例：[test-case-pc-receive-utd.md](test-case-pc-receive-utd.md)

## 场景 10：发送 URI 跟宿主来源，不套默认目录

**提示词**：`接入碰一碰分享文件。URI 怎么来由你看工程。`

**预期输出**：

- 先读宿主现有 URI 字段 / path / 文件就绪回调，再接线
- 不把 Q7 的 `filesDir` 当成发送默认根路径
- 完成报告写明发送 URI 在宿主中的来源
- `canShare()` 不按 2in1 关闭；若开精准则未命中回退全量
- 用例：[test-case-uri-from-host.md](test-case-uri-from-host.md)

## 场景 11：对照 — 文件本就在 filesDir

**提示词**：`接入碰一碰分享文件。当前页预置文件已在 filesDir。`

**预期输出**：

- 发送可以使用 `filesDir`
- 说明并非禁止 `filesDir`，只禁止来源不是它时套用
- 用例：[test-case-uri-filesdir-ok.md](test-case-uri-filesdir-ok.md)

## 场景 12：电脑接收 + 精准时按实际 UI 问落点

**提示词**：

```
接入碰一碰分享文件。要电脑端应用内接收，也要精准碰一碰。
```

**预期输出**：

- Q8 第一轮只问是否精准，不要夹杂接收落点
- Q7 与 Q8 都 yes 之后：先读挂载页并陈述实际结构，再从该结构推导插入位置选项，且含 **自定义**
- 不要套用某种布局的现成选项表；不要未确认就把接收项 push 到末尾
- 完成报告写明读到的 UI 与所选落点
- 用例：[test-case-receive-precise-landing.md](test-case-receive-precise-landing.md)

## 场景 13：读不到 assets 中止

**提示词**：`请接入碰一碰传送文件。`（验收时模拟：本次类型 `assets/` 或挂载示例不可读）

**预期输出**：

- 说明需完整安装本 Skill 目录
- **停止改码**；不凭记忆重写 Manager/Provider
- 用例：[test-case-assets-unreadable.md](test-case-assets-unreadable.md)

## 场景 14：无构建环境

**提示词**：同场景 1（验收时明确：当前环境无 HarmonyOS / DevEco 检查与构建能力）

**预期输出**：

- 仍可完成引导与改码（模板可读时）
- 完成报告「验证结果」写明未自动编译；人工清单含 IDE 编译
- **不得**宣称已编译通过
- 用例：[test-case-no-build-env.md](test-case-no-build-env.md)

## 场景 15：git 环境失败回滚

**提示词**：

```
请使用 hmos-share-kit-knock-share，帮我在当前工程接入碰一碰传送文件。
只要发送，不要电脑端应用内接收，也不要精准碰一碰。
挂载页面是 pages/Detail，分享当前页已选中的本地文件 URI 列表。
```

**验收操作**：

- 工程在 git 版控下，已 commit，工作区干净
- agent 走到变更写入阶段后，模拟失败（临时破坏 `assets/sdk-profile-snippet.json5` 或制造编译报错）

**预期输出**：

- 阶段 0 记录了 git 版控状态与基线快照
- 失败后执行 `git checkout` 还原本次会话改动的文件（先 `git status` 比对基线快照确认范围）
- 已拷入的资产文件若属于本次新增 → 一并还原
- 回滚后输出回滚原因 + 已还原文件清单 + 人工下一步建议
- 用例：[test-case-rollback-git.md](test-case-rollback-git.md)

## 场景 16：非 git 环境回滚 + 用户中途放弃

**提示词**：

```
请使用 hmos-share-kit-knock-share，帮我在当前工程接入碰一碰传送文件。
只要发送，不要电脑端应用内接收，也不要精准碰一碰。
挂载页面是 pages/Detail，分享当前页已选中的本地文件 URI 列表。
```

**验收操作**：

- 工程**不在** git 版控下（移除 .git 或 git 不可用）
- agent 走到变更写入阶段后，插入：`算了，不要改了`

**预期输出**：

- 阶段 0 记录了"非 git"结论与关键文件清单
- **未**执行 `git checkout`（因为非 git）
- 输出本次会话已改文件清单 + 每处改动摘要，供人工还原
- 已拷入的资产文件若属于本次新增 → 在清单中列出
- 回滚后输出回滚原因（用户放弃）+ 待还原文件清单 + 人工下一步建议
- 用例：[test-case-rollback-no-git.md](test-case-rollback-no-git.md)

## 场景 17：挂载冲突预检

**提示词**：

```
请使用 hmos-share-kit-knock-share，帮我在当前工程接入碰一碰传送文件。
只要发送，不要电脑端应用内接收，也不要精准碰一碰。
挂载页面是 pages/Detail，分享当前页已选中的本地文件 URI 列表。
```

**验收操作**：

- 目标页 `pages/Detail` 的 `onPageShow` 已有其它逻辑（如埋点上报 `this.reportPageShow()`)
- （可选子场景）目标页已有另一处 `on('knockShare')` 监听

**预期输出**：

- 阶段 4 挂载冲突预检检测到 `onPageShow` 已被占用
- **追加** `enable(...)` 到已有钩子，而非覆盖
- 若已有 `on('knockShare')` → 合并到同一 Manager，**未**新建第二套监听
- `onPageHide` 同理追加 `disable()` 而非覆盖
- 完成报告挂载点字段写明追加位置与原有钩子的关系
- 用例：[test-case-mount-conflict.md](test-case-mount-conflict.md)
