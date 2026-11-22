# 媒体播放类接续自检清单

> 适用场景：音视频播放器等媒体场景。
> 代码示例：`assets/examples/PlaybackProgress.ets`
> 方案说明：`references/playback-progress-continuity.md`

---

## 一、基础接入前提（红线节）

> 如果项目尚未完成基础接入，先逐项完成。
> 配置模板：`assets/templates/module.md`；Ability 模板：`assets/templates/EntryAbility.ets`
> ⚠️ 本节为红线项：任何情况下不得以其他文档（reference/示例注释）表述为由降级、跳过或放宽；违反即步骤 5 自检不通过。

- [ ] `module.json5` 目标 UIAbility 已添加 `"continuable": true`
- [ ] `onContinue(wantParam)` 已实现，可迁移页面返回 `AGREE`，不可迁移返回 `REJECT`
- [ ] `onCreate(want)` / `onNewWant(want)` 中处理 `launchReason === CONTINUATION` 分支
- [ ] **数据流方向红线**：源端只做 `AppStorage → wantParam` 导出；目标端只做 `want.parameters → AppStorage` 落地（迁移数据唯一来源）；目标端恢复**禁止**读同端 AppStorage 同 key 充当数据源——`setOrCreate(k, AppStorage.get(k) ?? v)` 式自循环会让迁移数据永不落地，且编译/静态检查全过，仅表现为对端"正常打开空白/初始页"
- [ ] 目标端页面恢复已按路由方式接线：Router（默认）→ `onCreate`/`onNewWant` 执行完成前**同步**调用 `restoreWindowStage()`（须 try/catch 兜底）；禁用页面栈迁移（Navigation/按需）→ `onWindowStageRestore` 中 `loadContent` 加载播放页
- [ ] `onWindowStageRestore` 仅当 `onWindowStageCreate` 有启动必要的初始化时才添加并镜像执行；系统页面栈恢复时不 `loadContent`（无初始化时整段省略）
- [ ] Navigation 路由项目：已在 `onContinue` 设置 `SUPPORT_CONTINUE_PAGE_STACK_KEY = false`

---

## 二、媒体素材来源与数据通道（先分支再设计）

> **先确认素材来源**：在线流 / 本地文件 / 两者混合——不同来源走完全不同的数据通道，选错通道是本场景最高频失败（❌ 只传文件名/URI 引用对端必读不到文件，与 SKILL.md Common Mistakes、data-migration-strategies 方式三口径一致）。

### 2-A 在线媒体（AVPlayer/Video 播放在线流）

→ 只传播放进度 + 播放状态 + 内容标识，目标端从同一进度重新拉流（**不传文件内容**）：

- [ ] **内容标识**：export 记录媒体 ID / URL / 查询参数（目标端据此重新拉取）
- [ ] **播放进度**：export 记录秒级精度 `currentTime`
- [ ] **时间单位口径（秒 ↔ 毫秒换算，真机 debug 实证高频错）**：采集与恢复两端换算正确——**AVPlayer 全链路毫秒**（`seek` 官方参数名即 `timeMs`，`currentTime` / `on('timeUpdate')` 同为毫秒时间基），**ArkUI Video 组件全链路秒**（`onUpdate` 的 `PlaybackInfo.time`、`onPrepared` 的 `PreparedInfo.duration`、`setCurrentTime` 官方单位均为 s）；迁移通道统一为**秒**（方案 §2 状态模型口径）：AVPlayer 采集端 ÷1000、恢复端 `seek(秒 × 1000)`，Video 组件直接用秒。❌ AVPlayer 毫秒值未 ÷1000 当秒传输、恢复时再 ×1000（溢出时长→跳至片尾/seek 越界）；秒值直接传 `avPlayer.seek()`（缺 ×1000 → 恢复到 ≈ 开头，形似"从头播放"）
- [ ] **时间戳冻结（防两端重叠）**：`onContinue` 先置暂停标志（页面立即 `pause()`）再取**最后一次上报**的 `currentTime` 作交接值（勿读播放器属性——`pause()` 异步可能滞后）；上报节流 200–500ms（成因与两种思路分析见 `references/playback-progress-continuity.md` §3-B）
- [ ] **播放状态**：export 记录播放/暂停状态
- [ ] 目标端从冻结点重新拉流并 seek 到对应位置（与源端内容**无重叠**）
- [ ] 目标端恢复播放/暂停状态与源端一致

### 2-B 本地文件（相册视频/本地音乐等落盘媒体）

→ 走**文件资产迁移**（`references/data-migration-strategies.md` 方式三；完整条目同 `checklist-edit-progress.md` §五，此处为播放场景必核子集）：

- [ ] 文件已实际写入 `distributedFilesDir`（迁移前逐一校验存在；构建失败记日志跳过该文件，不中断迁移）
- [ ] 每个 `commonType.Asset` 以**根属性**进 DDO：source 必须是 `flatAssets()` 展平结果（`attachments0..N`）；资产数组整体作根属性不受官方支持
- [ ] 对端复制路径用**对端本地** `distributedFilesDir + '/' + asset.name` 拼接；**禁止使用 `asset.path`**（那是源端设备绝对路径）
- [ ] 对端先复制到本地 `filesDir` 再交给 AVPlayer 播放（脱离分布式文件生命周期）
- [ ] **时间戳冻结**：同 2-A——本地文件传输窗口更长（秒级～数十秒），源端不冻结则两端内容**必然重叠**（`onContinue` 置暂停标志 + 取最后上报值，见 `references/playback-progress-continuity.md` §3-B）
- [ ] 对端用 `on('progressChanged')`（API 20+）或轮询等待文件落盘（progress = 100）**再**复制/播放，避免 restored 时文件未达
- [ ] 运行端 API 20+ 且资产数量动态时，评估改用框架托管的 `setAssets`（须先于 `setSessionId`，数量 1–50，见 api-reference §4.8）
- [ ] ⚠️ **文件迁移无法靠编译验证**：真机双端实测前，报告中本地文件恢复必须标记为**未验证项**

### 2-C 混合（播放列表含在线 + 本地）

- [ ] 按条目类型分别走 2-A / 2-B 通道，列表本身（ID + 类型 + 当前索引）走轻量 JSON
- [ ] 本地条目全部通过 2-B 的资产校验后再 `AGREE`，否则跳过该条目并记日志

---

## 三、实时流接续（如适用）

> 实时流（音视频通话、直播）→ 转移流通道（分布式播控）而非重连。

- [ ] 明确流通道转移实现（若使用播放器，传递流标识/播放进度）
- [ ] 不可行时至少有降级路径（如提示用户手动重连）

---

## 四、进度反馈与过渡 UI

- [ ] 源端迁移过程有"正在迁移…"提示（或依赖系统转场动画 + 应用侧配合）
- [ ] 目标端恢复过程有"正在恢复…"过渡（加载态，防白屏）
- [ ] 恢复完成后移除过渡 UI
- [ ] 迁移中途取消/失败时过渡 UI 正常关闭，不残留

---

## 五、性能与主线程

- [ ] 大对象序列化不在主线程阻塞执行（异步或分片）
- [ ] 迁移 UI（进度/过渡）不阻塞主线程渲染
- [ ] `onContinue` 中耗时操作使用异步形式（API 18+ 支持 Promise 版 onContinue）
- [ ] want.parameters 传输数据 < 100KB

---

## 六、资源清理（防泄漏，⚠️ 时序安全优先于释放卫生）

> **DDO 回调红线（同 SKILL.md 硬约束）**：`on()` 回调（`'status'`/`'change'`/`'progressChanged'`）内**禁止** `off()` / `setSessionId('')` / 丢弃 DDO 引用 / 大 I/O（如大文件复制）。收到 restored/progress=100 只置标志位；注销与销毁**延后**到回调排空后执行（`setTimeout` ≥ 数秒或 onDestroy），模式见 `references/api-reference.md` §4.7"延后收尾"。泄漏是可量的、崩溃是致命的——不要为防泄漏在回调内即时收尾。

- [ ] **会话内保引用**：源端与对端 DDO 均以**成员变量持有到 onDestroy**（对端半途丢弃引用会触发对象同步销毁，是崩溃链路的一环）
- [ ] `on('status')` / `on('progressChanged')` 等回调内只置标志/记录状态，重副作用（复制/解码/播放启动）交由后续事件循环执行
- [ ] 注销（`off` + `setSessionId('')`）在回调之外、**延后数秒**或 `onDestroy` 中统一执行（延后收尾模式见 api-reference §4.7）
- [ ] 迁移取消时清理未完成的临时数据
- [ ] 连续迁移无监听泄漏、无 UI 残留（验收分层见 §七：尽力项）

---

## 七、双设备实测步骤（分层验收）

> **必须项**（全部通过才算闭环）：1–5。
> **尽力项**（有条件时执行，未执行列为未验证项）：6。
> **仅一台真机时**：双端步骤无法构成验证——转入人工并上报，禁止在 start_app/verify_ui 等单端动作上空转。

1. **在线视频接续**：A 播放中（记录秒级进度）→ 接续到 B → B 从**冻结点**继续播放（不重新开始、**与源端内容无重叠**——源端已触发即暂停），播放/暂停状态一致
2. **音乐播放接续**：A 播放某曲目 → 接续到 B → B 播放同一曲目同一位置（无重叠）
3. **本地文件接续**（2-B 场景）：A 播放本地媒体 → 接续到 B → B 端文件实际到达（progress=100）、从冻结点继续播放（**传输窗口内源端已冻结，无重叠**）
4. **实时流接续**（如适用）：A 音视频通话/直播中 → 接续到 B → 验证流通道转移而非重新拉流
5. **过程与取消**：迁移时双端有可见过渡、结束正确移除；中途取消 → 双端状态一致（源端不残留"迁移中"，目标端无残留 UI）；全程**无 jscrash**（faultlog 检查）
6. **内存泄漏回归（尽力项）**：连续迁移 5 次，验证无 DDO 监听泄漏、无 UI 残留——达成方式是**延后统一注销**（§六），不是在到达回调里即时注销

---

## 八、常见陷阱排查（现象 → 根因 → 修法）

| 现象 | 根因 | 修法 |
|------|------|------|
| 接续后视频从头播放 | 播放进度未传播、目标端未 seek，或时间单位混淆（见下行） | 传播秒级 `currentTime`，目标端按正确单位 seek（AVPlayer `×1000` 毫秒；Video 组件直接秒） |
| **接续后进度跳至片尾或 ≈ 开头（位置完全不对）** | **播放进度时间单位混淆（秒 vs 毫秒）**：AVPlayer 全链路毫秒（`seek(timeMs)`/`currentTime`/`on('timeUpdate')`），ArkUI Video 组件全链路秒（`onUpdate`/`onPrepared`/`setCurrentTime` 单位均为 s）——采集与恢复两端单位不一致或缺换算 | 迁移通道统一为秒：AVPlayer 采集端 ÷1000、恢复端 `seek(秒 × 1000)`；Video 组件直接用秒；逐环节核对 采集 → AppStorage → wantParam → 恢复 的单位一致（§2-A 单位口径项；真机 debug 实证） |
| 接续后播放/暂停状态不一致 | 播放状态未传播 | 传播播放状态（play/pause），目标端据此调用对应方法 |
| 本地大文件传输超时/卡死 | 只传了文件路径/URI 引用（对端**读不到文件**），或 restored 时文件未落盘即复制 | 走 Asset 根属性（`flatAssets()` 展平）或 `setAssets`（API 20+，先于 setSessionId）由框架实际传输文件；对端 `on('progressChanged')` 等 progress=100 再复制/播放。❌ 传引用对端必失败 |
| 迁移过程无任何反馈 | 只依赖系统转场，未做应用侧过渡 | 源端"迁移中"、目标端"恢复中"过渡 UI |
| 迁移取消后残留"迁移中" UI | 取消路径未关闭过渡 | 取消/失败回调统一关闭过渡 UI 并清理临时数据 |
| 连续迁移后内存/监听泄漏 | DDO `on('change')` 未 `off`，组网未退出 | 延后统一注销：回调之外 `setTimeout` ≥ 数秒或 `onDestroy` 中 `off` + `setSessionId('')`（api-reference §4.7 延后收尾；❌ 在到达回调里即时注销） |
| 迁移/恢复时 SIGSEGV（faultlog 含 libdistributeddataobject.z.so、napi_get_reference_value） | 在 `on()` 回调链内同步 `off()`/`setSessionId('')`/丢弃 DDO 引用——已排队回调命中悬垂 napi_ref | DDO 回调红线（SKILL.md 硬约束）：回调内只置标志，注销延后 ≥ 3s 或 onDestroy |
| 接续后两端播放内容**重叠数秒**（对端从旧位置重看一段） | `onContinue` 捕获 `currentTime` 后源端继续播放——文件传输/目标启动窗口（可达数十秒）内源端已推进，对端仍从捕获值起播 | 触发即冻结：`onContinue` 置暂停标志（页面 `pause()`）+ 取**最后一次上报值**作交接值（`references/playback-progress-continuity.md` §3-B；"退出前再记录"不可行：wantParam 不可变、无可靠退出钩子） |
| 源端 await save() 期间播放器仍在播、迁移完成时退出竞态 | `onContinue` 关键路径被 `await save(targetDevice)` 拉长（Navigation/文件资产场景），AVPlayer 仍消费资源 | `onContinue` 先 `pause()` 播放器再采集状态/持久化（见 `references/playback-progress-continuity.md` §3 注意项） |
| 实时流接续后重连而非转移 | 未实现流通道转移 | 传递流标识/播放进度，目标端接管流通道 |

---

## 九、故障取证清单（崩溃/异常时执行）

- [ ] 复现前 `hilog -r` 清缓冲 → 复现 → **立即**采集（长窗只拿到滚动后的旧噪声）
- [ ] faultlog 检索窗口以复现时刻为中心 ± 数分钟；`not_found / matched_count: 0` 先缩窗重试，仍无则请用户手贴 faultlog（可接受兜底）
- [ ] 崩溃栈按符号速查定位：`libdistributeddataobject.z.so` / `napi_get_reference_value` / `0x6b` 毒值 / `DeleteWatch watcher_ is null` / `JSOff delete all`
- [ ] `hdc list_targets` 与 `devecocli device list` 口径不一致时：以能实际执行命令的来源为准，报告中记录两边输出
- [ ] 缺第二台设备：按标准话术转人工上报，相关项列**未验证**，不在单端动作上空转
- [ ] **无日志不改码**：证据到位前不做猜测式修复（含把权限 WARN 当根因）
