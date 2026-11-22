/**
 * 示例：Router 路由页面栈接续
 *
 * 用途：展示 Router 路由项目的页面栈接续实现。
 *   Router 路由系统自动恢复页面栈，只需补充自定义状态到 wantParam。
 *   参考官方 OxHornCampus 示例项目的 want.parameters 迁移模式。
 *
 * 核心特点：
 *   - 系统自动恢复页面栈（仅 Router 路由支持），无需手动重建
 *   - 只需在 wantParam 中补充自定义状态（如滚动位置、Tab 索引等）
 *   - 目标端 onCreate / onNewWant 执行完成前同步调用 restoreWindowStage()，
 *     触发带页面栈的页面恢复
 *   - onWindowStageRestore 仅镜像 onWindowStageCreate 的初始化（如有），
 *     不要 loadContent（会破坏已恢复的页面栈）
 *
 * ⚠️ 数据流方向红线（各 checklist §一）：源端只 AppStorage → wantParam；
 *    目标端只 want.parameters → AppStorage，禁止 setOrCreate(k, AppStorage.get(k) ?? v)
 *    式同端自循环（迁移数据永不落地，仅表现为对端打开空白/初始页）。
 *
 * 对比：Navigation 路由需手动重建，见 NavigationContinuity.ets
 *
 * 使用方式：把本文件中的关键代码复制到项目的 EntryAbility.ets 中按需修改。
 *   ⚠️ 页面侧代码为 V1 装饰器写法（@StorageLink）；@ComponentV2 页面不支持，
 *   改造规则见 references/state-decorator-migration.md
 *
 * 配套文件：
 *   - Navigation 路由示例：assets/examples/NavigationContinuity.ets
 *   - Ability 接线：assets/templates/EntryAbility.ets
 *   - 方案说明：references/navigation-continuity.md
 */

import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN = 0x0000;
const TAG = 'EntryAbility';
const FORMAT = '%{public}s';

// ============================================================
// 完整的 Router 路由接续示例（参考 OxHornCampus 官方项目）
// ============================================================

export default class EntryAbility extends UIAbility {
  private storage: LocalStorage = new LocalStorage();
  // restoreWindowStage 失败兜底标记（该接口可抛异常，见 api-reference §3.2）
  private isWindowRestoreFailed: boolean = false;

  // ============================================================
  // 源端：onContinue —— 采集自定义状态
  // ============================================================

  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
    hilog.info(DOMAIN, TAG, FORMAT, 'onContinue');
    // ⚠️ Router 路由系统自动迁移页面栈，无需设置 SUPPORT_CONTINUE_PAGE_STACK_KEY
    // 只需补充自定义状态（页面栈由系统自动恢复）
    wantParam['offsetSum'] = AppStorage.get<number>('offsetSum') as number;
    wantParam['bottomTabIndex'] = AppStorage.get<number>('bottomTabIndex') as number;
    wantParam['currentZoneId'] = AppStorage.get<number>('currentZoneId') as number;
    wantParam['imageHeight'] = AppStorage.get<number>('imageHeight') as number;
    wantParam['searchInput'] = AppStorage.get<string>('searchInput') as string;
    return AbilityConstant.OnContinueResult.AGREE;
  }

  // ============================================================
  // 目标端：onCreate —— 冷启动时恢复
  // ============================================================

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, FORMAT, 'onCreate');
    this.restoringData(want, launchParam);
  }

  // ============================================================
  // 目标端：onNewWant —— 热启动时恢复
  // ============================================================

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, FORMAT, 'onNewWant');
    this.restoringData(want, launchParam);
  }

  // ============================================================
  // 公共恢复逻辑
  // ============================================================

  private restoringData(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 判断是否为接续启动
    if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION
        && want?.parameters !== undefined) {
      // 恢复自定义状态到 AppStorage
      AppStorage.setOrCreate<number>('offsetSum', want.parameters['offsetSum'] as number);
      AppStorage.setOrCreate<number>('bottomTabIndex', want.parameters['bottomTabIndex'] as number);
      AppStorage.setOrCreate<number>('currentZoneId', want.parameters['currentZoneId'] as number);
      AppStorage.setOrCreate<number>('imageHeight', want.parameters['imageHeight'] as number);
      AppStorage.setOrCreate<string>('searchInput', want.parameters['searchInput'] as string);
      // 设置接续标记，页面据此触发恢复逻辑
      AppStorage.setOrCreate<string>('isContinuation', 'true');
      // Router 路由：restoreWindowStage 触发带页面栈的页面恢复
      // ⚠️ 官方约束：必须在 onCreate()/onNewWant() 执行完成前、同步方法体中调用，
      //    放进异步回调（Promise/回调函数）会导致迁移后页面加载失败。
      //    本接口可抛异常：失败置标记，onWindowStageRestore 中兜底 loadContent。
      this.storage = new LocalStorage();
      try {
        this.context.restoreWindowStage(this.storage);
      } catch (err) {
        this.isWindowRestoreFailed = true;
        hilog.error(DOMAIN, TAG, FORMAT, `restoreWindowStage failed: ${JSON.stringify(err)}`);
      }
    }
  }

  // ============================================================
  // 目标端：onWindowStageRestore
  // ============================================================

  onWindowStageRestore(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, FORMAT, 'onWindowStageRestore');
    // Router 路由：页面栈已由 restoreWindowStage 自动恢复，不要 loadContent
    // （重复加载会破坏已恢复的栈）。本回调按镜像原则使用：仅当 onWindowStageCreate
    // 中有启动必要的初始化时才需要（此处镜像其全屏窗口属性设置）；
    // onWindowStageCreate 无初始化时整段省略本回调（最小侵入）。
    // 兜底：restoreWindowStage 抛异常（isWindowRestoreFailed）时页面栈未恢复，
    // loadContent 加载根页，避免对端白屏。
    if (this.isWindowRestoreFailed) {
      windowStage.loadContent('pages/Index', (err) => {
        if (err.code) {
          hilog.error(DOMAIN, TAG, FORMAT, `Fallback loadContent failed: ${err.code}`);
        }
      });
      return;
    }
    windowStage.getMainWindow((err: BusinessError, data: window.Window) => {
      if (err.code) return;
      data.setWindowLayoutFullScreen(true);
    });
  }

  // ============================================================
  // 正常启动路径（非接续）
  // ============================================================

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, FORMAT, 'onWindowStageCreate');
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, FORMAT, `Failed to load content: ${err.code}`);
        return;
      }
      hilog.info(DOMAIN, TAG, FORMAT, 'Succeeded in loading the content.');
    });
  }
}

// ============================================================
// 页面侧：滚动位置恢复示例
// ============================================================

/*
 * 【页面 IntroductionPage.ets】
 *
 *   @StorageLink('offsetSum') offsetSum: number = 0;
 *   @StorageLink('isContinuation') isContinuation: string = 'false';
 *   private scrollerForList: Scroller = new Scroller();
 *
 *   aboutToAppear(): void {
 *     if (this.isContinuation === 'true') {
 *       // 接续恢复：延迟到布局完成后滚动到目标位置
 *       // scrollBy 带 duration 可实现平滑滚动
 *       this.scrollerForList.scrollBy(0, this.offsetSum);
 *       AppStorage.set<string>('isContinuation', 'false');
 *     }
 *   }
 *
 *   // 滚动时实时记录位置（供 onContinue 采集）
 *   onScroll(): void {
 *     this.offsetSum = this.scrollerForList.currentOffset().yOffset;
 *   }
 */
