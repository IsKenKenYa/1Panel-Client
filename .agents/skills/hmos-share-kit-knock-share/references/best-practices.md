# 碰一碰接入实践与陷阱

## 推荐做法

1. 仅在可分享界面监听；离开注销。
2. 预热 **已存在、可访问的文件 URI**（在该宿主文件就绪时写入 Provider）；回调内只组装并 `share` / `clarifyNonShare` / `reject`。
3. 2in1 绑 `windowId`；手机/平板用无 `windowId` 重载。
4. 按 Q1 拷贝 `file` / `link` / `both`；接线只打开对应的 `wiring-snippet-*.ets`。仅文件资产不得含链接 API；仅链接不得含 `dataReceive` / 精准命中。
5. 先定类型再提问：仅文件不问域名；仅链接不问文件 uri / 电脑接收 / 组件 id；未定类型先只问 Q1。**仅链接升 API 20+。含文件则先问是否精准碰一碰：不要精准 → 22+；要精准 → 26+。** 不要把文件侧落到 20，也不要未问精准就按 26 改 SDK。
6. 无内容用 `clarifyNonShare`（6.0.2+）；推荐返回 `undefined` 而非 throw；推荐 `class implements`（见挂载示例）。
7. 勾选优先于坐标（文件）；`apiAvailable('26.0.0')` 必须字面量。
8. 链接接收：Ability 只存非空 `want.uri`；host 交给 skills；导航跟宿主风格。
9. Q7=yes：`getReceiveCapabilities` 与发送 `utd` 一致。电脑停在已注册页并碰应用窗口。列表更新走 UI 线程。
10. Q7+Q8 都 yes：先读宿主实际 UI，再按该结构给接收落点选项（必须含自定义）。禁止套用某种布局的现成选项表。

## 常见陷阱

| 问题 | 处理 |
|------|------|
| 仅文件却打开了 `wiring-snippet-both` / HYPERLINK | 只读 `wiring-snippet-file.ets`，拷 `assets/file/` |
| 读不到 `assets/` 却凭记忆重写 | 停止改码；只以本 Skill `assets/` 为准 |
| 仅链接却问文件/电脑接收 | 仅链接禁止 Q3/Q7/Q8 |
| 未定类型一次抛完全表 | 先只问 Q1 |
| 含文件未问精准就改 SDK | 先 Q8：要精准 → 确认升 26+ 并写入 `"26.0.0"`；不要 → 确认升 **22+** 写入 `"6.0.2(22)"`。文件侧禁止用 20 |
| 26+ 仍写括号版本号 | 从 API 26.0.0 起用 SemVer；打开 `assets/sdk-profile-snippet.json5` 的 `fileApi26`。禁止 `"7.0.0(26)"` |
| `Invalid parameters for apiAvailable` | 必须字面量 `'26.0.0'` |
| 跳过引导直接改码 | 按已定类型问清必问项；除非授权自决 |
| 臆造 selected* | 按 Q3 确认的业务集合 collect URI |
| 裸 path 当 uri | path 须 getUriFromPath；须可访问 |
| 漏问 uri 从哪来 | 先读宿主现有字段/回调/path，再接线；勿默认已是 file:// |
| 套用默认沙箱目录 | 接收默认 filesDir ≠ 发送根路径；发送以宿主实际写入处为准 |
| 分享时用文件名猜 path | 在文件就绪时预热合法 URI |
| 2in1 上 canShare 写成 !is2in1() | 有内容就 true；精准由 Manager 先试再回退全量 |
| 精准未命中直接无内容 | getFileShareDataAt 未命中 → getFileShareData → 才 clarifyNonShare |
| 混用文件+链接一条 SharedData | 单次只能一种 |
| 把 `applinking.json` 拷进工程 | 仅云侧 |
| 宿主已有旧类名 `KnockFileShareManager` 再注入一套 | 增量升级为 `KnockShareManager` |
| 发送 `utd` 与 `dataReceive.capabilities` 不一致 | 系统回退文件管理，沙箱和列表都空；两边用同一套 utd |
| 电脑在首页或未 `enable(pcReceive)` 时碰 | `dataReceive` 未注册，文件进系统接收 |
| `onDataReceived` 直接改 `@State` 列表不刷新 | `runScopedTask` 或 `AppStorage` |
| 未读页面就按某种布局模板接线接收 | 先陈述实际结构（布局、数据源、项 id），再给从该结构推出的选项（含自定义） |
| 未确认就把接收项 `push` 到末尾却声称精准接收 | 要么按确认落点改已确认的数据源，要么报告写明仅追加 |

## 模板与宿主

接入以本 Skill `assets/` 为准；不要从宿主工程已有页面或媒体整份拷贝。读不到 `assets/` 就停止。

对改动的 `.ets` 做静态检查并编译工程；优先用当前环境已有的 HarmonyOS / DevEco 检查与构建能力（名称因宿主而异）。环境不具备时：报告中标明，并列入「请在 DevEco Studio 编译通过」。
