/**
 * 示例：Web UI 页面接续（UI 浏览类）
 *
 * 用途：展示 Web 组件页面的接续实现模式。
 *   Web 组件只传 URL + WebController 状态，H5 内部状态需 H5 侧配合。
 *   滚动位置按官方模式实现（示例库 HarmonyOS_Samples/continue-progress，
 *   文档《常见接续最佳实践》"Web 浏览进度接续"）：经 runJavaScript 读写 H5 scrollTop。
 *
 * 核心组件：
 *   1. WebController —— 控制 Web 组件（loadUrl、getUrl、runJavaScript 等）
 *   2. AppStorage —— 中转迁移数据（webUrl、webScrollOffset）
 *
 * ⚠️ 限制：
 *   - H5 内部 JS 状态（如 SPA 路由状态）无法自动迁移
 *   - 需要 H5 侧配合：URL 参数编码 / postMessage 协议
 *   - 滚动恢复必须在 onPageEnd 之后再延时执行（onPageEnd ≠ 内容高度就绪，
 *     立即执行会被钳制到当前内容高度，表现为停留顶部——真机反馈高频失败）
 *
 * 使用方式：把本文件中的关键代码复制到项目的页面文件中按需修改。
 *   ⚠️ 页面侧代码为 V1 装饰器写法（@StorageLink）；@ComponentV2 页面不支持，
 *   改造规则见 references/state-decorator-migration.md
 *
 * 配套文件：
 *   - Ability 接线：assets/templates/EntryAbility.ets
 *   - 方案说明：references/ui-progress-continuity.md
 */

import { webview } from '@kit.ArkWeb';
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;

// ============================================================
// 1. 页面侧：Web 组件 + 状态采集/恢复
// ============================================================

/*
 * 【页面 WebPage.ets】
 *
 *   @Entry
 *   @Component
 *   struct WebPage {
 *     // Web 控制器
 *     private webController: webview.WebviewController = new webview.WebviewController();
 *     // 接续标记
 *     @StorageLink('isContinuation') isContinuation: string = 'false';
 *     // 迁移来的 URL 与滚动偏移
 *     @StorageLink('migratedWebUrl') migratedWebUrl: string = '';
 *     @StorageLink('migratedWebScrollOffset') migratedWebScrollOffset: number = -1;
 *     // 默认 URL
 *     @State currentUrl: string = 'https://developer.huawei.com';
 *     // 待恢复的滚动偏移（aboutToAppear 记录，onPageEnd 延时消费）
 *     private pendingScrollOffset: number = -1;
 *     // 节流时间戳（live URL 采集用）
 *     private lastUrlRefreshMs: number = 0;
 *
 *     aboutToAppear(): void {
 *       // 接续恢复：加载迁移来的带 #fragment 完整 URL（H5 自行锚点定位）
 *       if (this.isContinuation === 'true' && this.migratedWebUrl !== '') {
 *         this.currentUrl = this.migratedWebUrl;
 *         // 记录待恢复偏移，由 onPageEnd 延时恢复；
 *         // ❌ 此处禁止恢复滚动——页面尚未加载（loadUrl 异步生效）
 *         this.pendingScrollOffset = this.migratedWebScrollOffset;
 *         AppStorage.set<string>('isContinuation', 'false');
 *       }
 *     }
 *
 *     // ⚠️ live URL 持续追踪（三管采集，勿只记入参 URL）：
 *     //    #section 锚点跳转不触发任何加载回调，一次性采集会让迁移数据
 *     //    停在旧地址、目标端把偏移打到另一篇文档（真机反馈实证）。
 *     build() {
 *       Column() {
 *         Web({ src: this.currentUrl, controller: this.webController })
 *           // ① onLoadIntercept：主框架导航即时捕获（仅观察，不拦截）
 *           .onLoadIntercept((event) => {
 *             AppStorage.set<string>('currentWebUrl', this.webController.getUrl());
 *             return false;
 *           })
 *           // ② 滚动事件节流 getUrl()（如 500ms）：兜底捕获 #fragment 变化
 *           .onScroll((event) => {
 *             const now: number = Date.now();
 *             if (now - this.lastUrlRefreshMs > 500) {
 *               this.lastUrlRefreshMs = now;
 *               AppStorage.set<string>('currentWebUrl', this.webController.getUrl());
 *             }
 *           })
 *           // ②-B 滚动偏移采集（官方 continue-progress 模式）：手指抬起时经
 *           //    runJavaScript 读取 H5 scrollTop 实时写入 AppStorage。
 *           //    ❌ 只迁移 URL 不采集偏移——目标端无从恢复滚动位置
 *           .onTouch(async (event: TouchEvent) => {
 *             if (event.type === TouchType.Up) {
 *               const result = await this.webController.runJavaScript(
 *                 'javascript:document.documentElement.scrollTop');
 *               AppStorage.setOrCreate<number>('currentWebScrollOffset', Number(result));
 *             }
 *           })
 *           // ③ onPageEnd：URL 校准 + 滚动位置延时恢复
 *           .onPageEnd(async () => {
 *             AppStorage.set<string>('currentWebUrl', this.webController.getUrl());
 *             if (this.pendingScrollOffset >= 0) {
 *               const offset: number = this.pendingScrollOffset;
 *               this.pendingScrollOffset = -1;
 *               // ⚠️ onPageEnd 只代表主文档加载完成，懒加载内容/H5 渲染高度
 *               //    常未就绪——立即恢复会被钳制到当前内容高度（停留顶部，
 *               //    真机反馈高频失败）。须延时 ≥300ms 再恢复；更稳做法：
 *               //    先 runJavaScript 校验可滚高度足够，不足则短间隔重试。
 *               //    按实际 H5 滚动容器调整选择器：整页 documentElement，
 *               //    内层容器 getElementById(...)（官方示例为 productList）
 *               setTimeout(() => {
 *                 this.webController.runJavaScript(
 *                   'javascript:document.documentElement.scrollTop = ' + offset);
 *               }, 500);
 *             } else {
 *               // 非恢复分支：加载结束后校准一次当前偏移（保证 onContinue 时最新）
 *               const result = await this.webController.runJavaScript(
 *                 'javascript:document.documentElement.scrollTop');
 *               AppStorage.setOrCreate<number>('currentWebScrollOffset', Number(result));
 *             }
 *           })
 *           .javaScriptAccess(true)
 *           .domStorageAccess(true)
 *           .width('100%')
 *           .height('100%')
 *       }
 *       .width('100%')
 *       .height('100%')
 *     }
 *   }
 */

// ============================================================
// 2. Ability 侧：采集与恢复
// ============================================================

/*
 * 【EntryAbility.ets】
 *
 *   // 源端 onContinue：采集当前 Web 页面 URL 与滚动偏移
 *   onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
 *     // 页面侧实时写入 AppStorage 的最新值
 *     wantParam['webUrl'] = AppStorage.get<string>('currentWebUrl') as string;
 *     // ❌ 只传 URL 不传偏移——目标端无从恢复滚动位置
 *     wantParam['webScrollOffset'] = AppStorage.get<number>('currentWebScrollOffset') ?? -1;
 *     return AbilityConstant.OnContinueResult.AGREE;
 *   }
 *
 *   // 目标端 onCreate：恢复 URL/偏移并触发页面恢复
 *   onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
 *     if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION
 *         && want?.parameters !== undefined) {
 *       AppStorage.setOrCreate<string>('migratedWebUrl', want.parameters['webUrl'] as string);
 *       AppStorage.setOrCreate<number>('migratedWebScrollOffset',
 *         (want.parameters['webScrollOffset'] as number) ?? -1);
 *       AppStorage.setOrCreate<string>('isContinuation', 'true');
 *       // 在 onCreate 执行完成前同步调用，触发页面恢复（onNewWant 中同样处理；
 *       // 禁止放进异步回调，否则迁移后页面加载失败。可抛异常：try/catch 兜底，
 *       // 失败置标记，onWindowStageRestore 中兜底 loadContent（见模板 EntryAbility.ets））
 *       this.context.restoreWindowStage(new LocalStorage());
 *     }
 *   }
 *
 *   // 目标端 onWindowStageRestore：仅当 onWindowStageCreate() 有启动必要的初始化时
 *   // 才需要本回调（镜像执行）。页面栈迁移被禁用时（Navigation/按需）在此 loadContent
 *   // 落地页；Router 默认（系统页面栈恢复）时不要 loadContent（页面栈已恢复）。
 *   onWindowStageRestore(windowStage: window.WindowStage): void {
 *     if (!this.isPageStackMigrated) {
 *       windowStage.loadContent('pages/WebPage');
 *     }
 *   }
 */

// ============================================================
// 3. H5 侧协作方案（可选）
// ============================================================

/*
 * 【H5 内部状态同步方案】
 *
 * 如需迁移 H5 内部状态（如 SPA 路由、表单填写进度），需要 H5 侧配合：
 *
 * 方案 A：URL 参数编码
 *   - H5 将内部状态编码到 URL query 参数中
 *   - 原生侧只需传 URL，H5 重新加载后自行解析参数恢复状态
 *   - 适合：状态简单、可 URL 编码的场景
 *
 * 方案 B：postMessage 协议
 *   - 原生侧通过 webController.postMessage() 向 H5 发送恢复指令
 *   - H5 监听 message 事件，根据指令恢复内部状态
 *   - 适合：状态复杂、不适合 URL 编码的场景
 *
 * ⚠️ 无论哪种方案，原生侧都无法直接读取 H5 内部 JS 状态。
 *    不要把 H5 内部状态当原生状态直接序列化。
 */
