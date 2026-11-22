/**
 * 示例：媒体播放场景接续数据处理（播放类）
 *
 * 用途：展示音视频播放器页面的接续实现模式。
 *   只传播放进度（秒级精度）+ 播放状态 + 内容标识，目标端从同进度重新拉流。
 *
 * 核心组件：
 *   1. AVPlayer 播放状态采集 —— currentTime / isPlaying
 *   2. AppStorage —— 中转迁移数据
 *   3. 目标端 seek 恢复 —— 重新拉流后 seek 到对应位置
 *
 * ⚠️ 关键原则：
 *   - 只传元数据（videoId + currentTime + isPlaying），不传媒体内容
 *   - 触发即冻结：onContinue 先置暂停标志（页面 pause()），交接值取最后一次
 *     上报的 currentTime（勿读播放器属性）——防两端内容重叠数秒（方案 §3-B）
 *   - seek 时机须在播放器准备完成后（stateChange 回调中判断）
 *   - 播放状态（play/pause）须在 seek 完成后恢复
 *
 * 使用方式：把本文件中的关键代码复制到项目中按需修改。
 *   ⚠️ 页面侧代码为 V1 装饰器写法（@StorageLink）；@ComponentV2 页面不支持，
 *   改造规则见 references/state-decorator-migration.md
 *
 * 配套文件：
 *   - Ability 接线：assets/templates/EntryAbility.ets
 *   - 方案说明：references/playback-progress-continuity.md
 */

import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;

// ============================================================
// 1. 源端 onContinue：触发即冻结 + 采集播放元数据
// ============================================================

/*
 * 【EntryAbility.ets】
 *
 *   onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
 *     // ① 触发即冻结：置暂停标志，页面 @Watch 立即 pause()（冻结后续 timeUpdate）
 *     AppStorage.setOrCreate('continuationPause', 'true');
 *     // ② 只传内容标识 + 播放进度 + 播放状态；交接值取「最后一次上报」的
 *     //    currentTime——勿读 avPlayer.currentTime（pause() 异步可能滞后）
 *     wantParam['videoId'] = AppStorage.get<string>('videoId') as string;
 *     wantParam['currentTime'] = AppStorage.get<number>('currentTime') as number;
 *     wantParam['isPlaying'] = AppStorage.get<boolean>('isPlaying') as boolean;
 *     wantParam['playlistId'] = AppStorage.get<string>('playlistId') as string;
 *     return AbilityConstant.OnContinueResult.AGREE;
 *   }
 */

// ============================================================
// 2. 目标端 onCreate：恢复播放元数据
// ============================================================

/*
 *   onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
 *     if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION
 *         && want?.parameters !== undefined) {
 *       AppStorage.setOrCreate<string>('videoId', want.parameters['videoId'] as string);
 *       AppStorage.setOrCreate<number>('currentTime', want.parameters['currentTime'] as number);
 *       AppStorage.setOrCreate<boolean>('isPlaying', want.parameters['isPlaying'] as boolean);
 *       AppStorage.setOrCreate<string>('playlistId', want.parameters['playlistId'] as string);
 *       AppStorage.setOrCreate<string>('isContinuation', 'true');
 *       // 在 onCreate 执行完成前同步调用，触发页面恢复（onNewWant 中同样处理；
 *       // 禁止放进异步回调，否则迁移后页面加载失败。可抛异常：try/catch 兜底，
  *       // 失败置标记，onWindowStageRestore 中兜底 loadContent（见模板 EntryAbility.ets））
 *       this.context.restoreWindowStage(new LocalStorage());
 *     }
 *   }
 *
 *   // 仅当 onWindowStageCreate() 有启动必要的初始化时才需要本回调（镜像执行）。
 *   // 页面栈迁移被禁用时（Navigation / SUPPORT_CONTINUE_PAGE_STACK_KEY=false）
 *   // 在此 loadContent 播放页；Router 默认（系统页面栈恢复）时不要 loadContent。
 *   onWindowStageRestore(windowStage: window.WindowStage): void {
 *     if (!this.isPageStackMigrated) {
 *       windowStage.loadContent('pages/Player');
 *     }
 *   }
 */

// ============================================================
// 3. 页面侧：恢复播放
// ============================================================

/*
 * 【页面 Player.ets】
 *
 *   @Entry
 *   @Component
 *   struct PlayerPage {
 *     @StorageLink('videoId') videoId: string = '';
 *     @StorageLink('currentTime') currentTime: number = 0;
 *     @StorageLink('isPlaying') isPlaying: boolean = false;
 *     @StorageLink('isContinuation') isContinuation: string = 'false';
 *     private avPlayer: AVPlayer = new AVPlayer();
 *
 *     // 触发接续即冻结：响应 Ability 在 onContinue 中置的标志
 *     // （V1 用 @StorageProp+@Watch；V2 用 @Monitor 手动绑定，见 state-decorator-migration）
 *     @StorageProp('continuationPause') @Watch('onPauseForMigration') continuationPause: string = '';
 *     onPauseForMigration(): void {
 *       if (this.continuationPause === 'true') {
 *         this.avPlayer.pause();  // 冻结后续 timeUpdate；最后一次上报值即交接点
 *       }
 *     }
 *
 *     aboutToAppear(): void {
 *       // 接续恢复
 *       if (this.isContinuation === 'true') {
 *         // 监听播放器状态变化
 *         this.avPlayer.on('stateChange', (state: string) => {
 *           if (state === 'paused') {
 *             // 准备好后 seek 到迁移进度（AVPlayer seek 单位为毫秒）
 *             this.avPlayer.seek(this.currentTime * 1000);
 *           }
 *           if (state === 'completed' && this.isPlaying) {
 *             // seek 完成后恢复播放
 *             this.avPlayer.play();
 *           }
 *         });
 *         // 加载视频源（根据 videoId 构建 URL）
 *         this.avPlayer.src = this.buildVideoUrl(this.videoId);
 *         this.avPlayer.prepare();
 *         AppStorage.set<string>('isContinuation', 'false');
 *       }
 *     }
 *
 *     // 播放进度变化时实时更新 AppStorage（节流）
 *     onTimeUpdate(event: { time: number }): void {
 *       AppStorage.set<number>('currentTime', Math.floor(event.time));
 *     }
 *
 *     // 播放/暂停状态变化时实时更新 AppStorage
 *     onPlayStateChange(isPlaying: boolean): void {
 *       AppStorage.set<boolean>('isPlaying', isPlaying);
 *     }
 *
 *     build() {
 *       Column() {
 *         Video({
 *           src: this.videoUrl,
 *           controller: this.avPlayer
 *         })
 *           .width('100%')
 *           .height('100%')
 *       }
 *     }
 *   }
 */

// ============================================================
// 4. 实时流接续（可选）
// ============================================================

/*
 * 【实时流场景（音视频通话/直播）】
 *
 * 与在线播放不同：转移流通道（分布式播控）而非重连。
 *
 *   onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
 *     // 传递流标识 / 播放进度，目标端接管流通道
 *     wantParam['streamId'] = AppStorage.get<string>('streamId') as string;
 *     wantParam['streamType'] = AppStorage.get<string>('streamType') as string;
 *     return AbilityConstant.OnContinueResult.AGREE;
 *   }
 *
 * ⚠️ 实时流接续需要应用侧与流媒体 SDK 配合，
 *    不可行时至少有降级路径（如提示用户手动重连）。
 */

// ============================================================
// 5. 进度反馈与过渡 UI（可选）
// ============================================================

/*
 * 【迁移过渡 UI】
 *
 * 源端：
 *   onContinue 中可设置 AppStorage 标记，页面显示"正在迁移…"
 *
 * 目标端：
 *   aboutToAppear 中检测接续标记，显示"正在恢复…"加载态
 *   seek + play 完成后移除过渡 UI
 *
 * 失败/取消：
 *   统一关闭过渡 UI 并清理临时数据
 */
