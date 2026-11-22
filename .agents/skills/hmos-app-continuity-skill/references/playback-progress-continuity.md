# 播放类接续方案说明

> 数据来源：HarmonyOS 官方文档（bpta-continue-cast、bpta-continue-data）
> 最后同步：2026-09

---

## 1. 方案原理

播放类接续按**素材来源**分两条路线，先分支再设计（自检分支见 `assets/checklists/checklist-playback-progress.md` §二）：

- **在线媒体**（本文主线）：只传播放元数据，不传媒体内容。目标端根据元数据从同一位置重新拉流并 seek。
- **本地文件**（相册视频/本地音乐）：元数据走 want/轻量 JSON，**文件本体必须走文件资产迁移**（Asset 根属性 `flatAssets()` 展平，或 API 20+ `setAssets` + `on('progressChanged')` 等落盘）——❌ 只传路径/URI 引用对端必读不到文件；完整方案见 `references/data-migration-strategies.md` 方式三与 `references/edit-progress-continuity.md`（资产时序与对端落盘规则同编辑场景）。

**在线媒体播放数据流：**

```
源端                                    目标端
─────                                   ─────
AVPlayer 播放中                          onCreate / onNewWant
  ↓                                       ↓
onContinue()                             want.parameters → AppStorage
  videoId: 'vid_001'                       restoreWindowStage()（同步调用，
  currentTime: 1425 (秒)                     触发页面恢复）
  isPlaying: true                          ↓
  playlistId: 'pl_001'                  页面 aboutToAppear()
  返回 AGREE                               根据 videoId 重新拉流
                                            seek(currentTime)
                                            isPlaying ? play() : pause()
```

> 播放页落地方式按路由方式二选一：**Router（默认）** 页面栈由 `restoreWindowStage()` 自动恢复，`onWindowStageRestore` 仅镜像 `onWindowStageCreate` 的初始化（如有），不 `loadContent`；**Navigation / 按需迁移**（`SUPPORT_CONTINUE_PAGE_STACK_KEY = false`）在 `onWindowStageRestore()` 中 `loadContent('pages/Player')` 加载播放页。

**数据通道选型**：播放元数据通常 < 1KB，使用 `want.parameters` 即可。

---

## 2. 状态模型

播放类接续需传递以下状态：

| 状态 | 类型 | 说明 |
|------|------|------|
| **内容标识** | string | 视频 ID / URL / 查询参数（目标端据此重新拉取） |
| **播放进度** | number | 秒级精度 `currentTime`（不传文件内容） |
| **播放状态** | boolean | 播放/暂停（`isPlaying`） |
| **播放列表** | string（可选） | 播放列表 ID（目标端加载同一列表） |
| **当前曲目索引** | number（可选） | 播放列表中的当前项 |

---

## 3. 源端：onContinue 中采集

> **⚠️ 触发即暂停（一项措施、双重收益）**：`onContinue` 中 `await save(targetDevice)` 会拉长迁移关键路径——期间 AVPlayer 仍在消费资源，源端退出时可能触发竞态；且若源端继续播放，交接窗口内推进的进度会导致**两端内容重叠数秒**（§3-B）。**先 `pause()` 冻结、再采集状态/持久化**（Promise 版 onContinue 见 api-reference §2.1，API 18+；同步版先置暂停标志后返回 AGREE）。完整时序与成因分析见 §3-B。

```typescript
onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
  // 在线视频：只传内容标识 + 播放进度 + 播放状态
  wantParam['videoId'] = AppStorage.get<string>('videoId') as string;
  wantParam['currentTime'] = AppStorage.get<number>('currentTime') as number;
  wantParam['isPlaying'] = AppStorage.get<boolean>('isPlaying') as boolean;
  wantParam['playlistId'] = AppStorage.get<string>('playlistId') as string;
  return AbilityConstant.OnContinueResult.AGREE;
}
```

**页面侧实时维护 AppStorage：**

```typescript
// 播放进度变化时更新（节流：建议 200–500ms——秒级进度语义不变，
// 交接残差亚秒级，见 §3-B）
onTimeUpdate(event: { time: number }): void {
  AppStorage.set<number>('currentTime', Math.floor(event.time));
}

// 播放/暂停状态变化时更新
onPlayStateChange(isPlaying: boolean): void {
  AppStorage.set<boolean>('isPlaying', isPlaying);
}

// 触发接续即冻结：响应 Ability 在 onContinue 中置的标志（V1 用 @StorageProp+@Watch，
// V2 用 @Monitor 手动绑定，见 references/state-decorator-migration.md）
@StorageProp('continuationPause') @Watch('onPauseForMigration') continuationPause: string = '';
onPauseForMigration(): void {
  if (this.continuationPause === 'true') {
    this.player.pause();   // 冻结后续 timeUpdate；最后一次上报值即交接点
  }
}
```

### 3-B 时间戳冻结：防两端播放重叠（真机反馈实证）

**成因**：时间戳捕获点 ≠ 实际交接点。`onContinue` 在触发瞬间捕获 `currentTime`（T0），此后实际迁移还要经历：本地大文件经 Asset/setAssets 异步传输（秒级～数十秒）→ 目标端页面加载 → 等文件落盘（progress=100）→ 建 AVPlayer → `seek(T0)` → play；在线场景也有拉流+缓冲（1–3s）。若源端在窗口内**继续播放**，源端已推进到 T0+Δ（Δ = 窗口时长），目标端却从 T0 起播 → **两端内容重叠 Δ 秒**。本质：交接窗口不受应用控制，且源端状态在窗口内持续演进。

**思路一：触发接续即暂停（推荐基线，确定性解决）**

```typescript
onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
  // ① 触发即冻结：置暂停标志，页面 @Watch 立即 player.pause()（冻结后续 timeUpdate）
  AppStorage.setOrCreate('continuationPause', 'true');
  // ② 交接值取「最后一次上报」的 currentTime——勿读 avPlayer.currentTime 属性
  //    （pause() 是异步的，属性值可能滞后；页面侧 onTimeUpdate 维护的值即冻结点）
  wantParam['currentTime'] = AppStorage.get<number>('currentTime') as number;
  // ③ 文件资产场景：冻结之后再持久化/save——AVPlayer 不再消费资源，退出竞态同解
  // ...
  return AbilityConstant.OnContinueResult.AGREE;
}
```

- **能解决**：冻结点 = 捕获点 = 目标端起点——窗口时长不再影响正确性（表现为"迁移中暂停"，目标端就绪后从冻结点续播，无重叠、无跳变）。
- **精度**：交接值与真实冻结点差 ≤ 一个上报间隔；节流 200–500ms 时残差亚秒级。
- **边界（遗留）**：迁移被拒绝/取消时源端停在暂停态——**无系统回调通知源端失败**，恢复策略（超时自动续播 / 提示用户手动播放）属产品决策，须与用户确认并在方案中写明。

**思路二：源端退出前再记录一次（按字面不可行；DDO 变体可作可选补充）**

- want.parameters 通道：`onContinue` 返回后 wantParam **不可变** → 无法事后更新，该通道不成立。
- "退出前"没有应用可见的可靠钩子：迁移完成/源端退出时机由系统控制；`onDestroy` 中写 DDO 时会话可能已在拆除，不可靠。
- 即使实现"最后一次写入"，仍与目标端读取存在竞态：目标端已按旧值起播则需二次 seek（可见跳变）——窗口只能缩小、**不能闭合**。
- **可行变体（仅 DDO 通道，类投屏体验）**：若产品明确要求源端在交接窗口内继续播放，把 `currentTime` 放进 DDO 并节流连续更新（~1s）直至退出：热启动目标端可跟随 `on('change')` 对齐，冷启动读最后同步值。**残余重叠 ≤ 同步间隔，无法归零**；大文件传输期间高频属性同步与文件传输的带宽争用需真机验证（遗留）。

**结论**：基线方案 = 思路一（触发即冻结：`continuationPause` 标志 + 最后上报值）；思路二按字面不可行，DDO 实时跟随变体仅在产品明确要求源端继续播放时作为补充并接受亚秒级残余。

---

## 4. 目标端：恢复播放

### 4.1 Ability 侧

```typescript
onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION
      && want?.parameters !== undefined) {
    AppStorage.setOrCreate<string>('videoId', want.parameters['videoId'] as string);
    AppStorage.setOrCreate<number>('currentTime', want.parameters['currentTime'] as number);
    AppStorage.setOrCreate<boolean>('isPlaying', want.parameters['isPlaying'] as boolean);
    AppStorage.setOrCreate<string>('playlistId', want.parameters['playlistId'] as string);
    AppStorage.setOrCreate<string>('isContinuation', 'true');
    // 在 onCreate 执行完成前同步调用，触发页面恢复（onNewWant 中同样处理；
    // 禁止放进异步回调，否则迁移后页面加载失败）
    this.context.restoreWindowStage(new LocalStorage());
  }
}

// 仅当 onWindowStageCreate() 有启动必要的初始化时才需要本回调（镜像执行）。
// 页面栈迁移被禁用时（Navigation / SUPPORT_CONTINUE_PAGE_STACK_KEY = false）
// 在此 loadContent 播放页；Router 默认（系统页面栈恢复）时不要 loadContent。
onWindowStageRestore(windowStage: window.WindowStage): void {
  if (!this.isPageStackMigrated) {
    windowStage.loadContent('pages/Player');
  }
}
```

### 4.2 页面侧

```typescript
@StorageLink('isContinuation') isContinuation: string = 'false';
@StorageLink('currentTime') currentTime: number = 0;
@StorageLink('isPlaying') isPlaying: boolean = false;

aboutToAppear(): void {
  if (this.isContinuation === 'true') {
    // 重新拉流并 seek 到对应位置
    this.avPlayer.on('stateChange', (state: string) => {
      if (state === 'paused') {
        // 准备好后 seek
        this.avPlayer.seek(this.currentTime * 1000); // AVPlayer seek 单位为毫秒
      }
      if (state === 'completed' && this.isPlaying) {
        this.avPlayer.play();
      }
    });
    AppStorage.set<string>('isContinuation', 'false');
  }
}
```

**要点：**
- 目标端从同一进度**重新拉流**，不传文件内容
- seek 时机须在播放器准备完成后（`stateChange` 回调中判断）
- 播放状态（play/pause）须在 seek 完成后恢复

---

## 5. 实时流接续

实时流（音视频通话、直播）与在线播放不同：**转移流通道而非重连**。

| 场景 | 接续方式 |
|------|---------|
| 在线视频/音乐 | 传播放元数据，目标端重新拉流 |
| 音视频通话 | 转移流通道（分布式播控），目标端接管 |
| 直播 | 传播放列表 ID + 进度，目标端重新拉流 |

**实时流接续要点：**
- 传递流标识 / 播放进度，目标端接管流通道
- 不可行时至少有降级路径（如提示用户手动重连）
- 需要应用侧与流媒体 SDK 配合

---

## 6. 进度反馈与过渡 UI

| 阶段 | 源端 | 目标端 |
|------|------|--------|
| 迁移中 | "正在迁移…" 提示 | — |
| 恢复中 | — | "正在恢复…" 加载态 |
| 完成 | 退出（默认）或保留 | 移除过渡 UI，开始播放 |
| 失败/取消 | 提示"接续未完成"，清理临时数据 | 降级到首页或播放列表页 |

> 源端处理按垂类推荐与用户确认（`assets/checklists/confirm-scene-inventory.md` §附录 B）：**影音娱乐 / 儿童垂类官方建议"应用按需适配"**，须与用户确认后落地；**听书/直播垂类默认退出，重听书/直播场景可选"不退出，暂停"（听书）/"不退出"（直播）**；其余默认退出。

---

## 7. 性能与主线程

- `onContinue` 中不做耗时操作（播放元数据本身很轻量）
- 如需序列化大对象，使用异步版本 `onContinue`（API 18+）
- 迁移 UI（进度/过渡）不阻塞主线程渲染

---

## 关联资源

- 代码示例：`assets/examples/PlaybackProgress.ets`
- 自检清单：`assets/checklists/checklist-playback-progress.md`
- 数据迁移选型：`references/data-migration-strategies.md`
- API 详情：`references/api-reference.md`
