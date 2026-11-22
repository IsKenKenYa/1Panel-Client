/**
 * 示例：UIAbility 生命周期管理文件接续接入模式
 *
 * 用途：展示 EntryAbility.ets 中接入应用接续的标准模式。
 *   源端 onContinue 保存状态；目标端 onCreate / onNewWant 恢复数据，
 *   并在方法执行完成前同步调用 restoreWindowStage() 触发页面恢复；
 *   onWindowStageRestore() 按需镜像 onWindowStageCreate() 的初始化。
 *   本文件是跨场景通用的基础模板，具体场景的状态导出/恢复逻辑由对应的场景示例提供。
 *
 * 特别注意：
 *   - 迁移启动（冷/热启动）都会在 onCreate()/onNewWant() 执行完后触发
 *     onWindowStageRestore()，不执行 onWindowStageCreate()。
 *   - onWindowStageCreate() 中有启动必要的初始化时，才需要在 onWindowStageRestore()
 *     中执行同样的初始化（镜像原则）；没有初始化则整段省略该回调（最小侵入）。
 *   - 使用系统页面栈恢复（仅 Router 支持，默认开启）时，必须在 onCreate()/onNewWant()
 *     执行完成前调用 restoreWindowStage()，触发带页面栈的页面恢复。
 *
 * 使用方式：把本文件中的关键代码段复制到项目的 EntryAbility.ets 中，
 *   按项目实际情况调整（如页面路径、状态字段名等）。
 *
 * 配套文件：
 *   - 模块设置修改：assets/templates/module.md
 *   - 场景示例：assets/examples/UIProgress.ets 等
 *   - API 详情：references/api-reference.md（§2.4 onWindowStageRestore / §3.2 restoreWindowStage）
 */

import { AbilityConstant, UIAbility, Want, wantConstant } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'EntryAbility';

export default class EntryAbility extends UIAbility {
  // 页面栈是否走系统恢复：源端未设置 SUPPORT_CONTINUE_PAGE_STACK_KEY 时默认 true
  // （Router 默认迁移页面栈）；源端设为 false（Navigation 必设 / Router 按需）时
  // 目标端读回 false，改为手动加载落地页。
  private isPageStackMigrated: boolean = true;
  // restoreWindowStage 失败兜底标记（该接口可抛异常，见 api-reference §3.2）
  private isWindowRestoreFailed: boolean = false;

  // ============================================================
  // 源端：onContinue —— 保存当前状态，返回结果码
  // ============================================================

  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
    try {
      // 1. 收集页面状态（由 PageStateRegistry 统一管理，见 UIProgress.ets）
      //    轻量场景：序列化为 JSON 字符串走 want.parameters（保持 < 100KB）
      //    复杂/可变场景：改用 DDO，wantParam 只放 sessionId
      //    见 references/data-migration-strategies.md
      // const states = PageStateRegistry.getInstance().exportAll();
      // wantParam['pageStates'] = PageStateCodec.serialize(states);

      // 2. 可选：控制迁移后源端是否退出（默认退出）
      //    设为 false 可保留源端应用
      //    见 assets/examples/SourceProgress.ets
      // wantParam[wantConstant.Params.SUPPORT_CONTINUE_SOURCE_EXIT_KEY] = false;

      // 3. 可选：禁用系统页面栈迁移（Navigation 项目必须设置；
      //    Router 项目默认由系统恢复页面栈，无需设置）
      //    见 assets/examples/NavigationContinuity.ets
      // wantParam[wantConstant.Params.SUPPORT_CONTINUE_PAGE_STACK_KEY] = false;

      return AbilityConstant.OnContinueResult.AGREE;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'onContinue failed: %{public}s', JSON.stringify(err));
      return AbilityConstant.OnContinueResult.REJECT;
    }
  }

  // ============================================================
  // 目标端：onCreate / onNewWant —— 恢复数据并触发页面恢复
  // ============================================================

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.restoreOnContinuation(want, launchParam);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.restoreOnContinuation(want, launchParam);
  }

  /**
   * CONTINUATION 分支公共逻辑。
   * ⚠️ restoreWindowStage() 必须在 onCreate()/onNewWant() 执行完成前、
   *    同步方法体中调用；放进异步回调（Promise/回调函数）会导致迁移后页面加载失败。
   */
  private restoreOnContinuation(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    if (launchParam.launchReason !== AbilityConstant.LaunchReason.CONTINUATION) {
      return;
    }

    // 1. 目标端收到迁移后应主动将状态设为 ACTIVE，确保可再次迁回，保证迁移连续性
    this.context.setMissionContinueState(AbilityConstant.ContinueState.ACTIVE)
      .then(() => {
        hilog.info(DOMAIN, TAG, 'Succeeded in setting continue state to ACTIVE.');
      });

    // 2. 暂存迁移数据到 AppStorage，页面在 aboutToAppear 中读取并恢复
    //    ⚠️ 数据流方向：目标端 want.parameters → AppStorage ，
    // const json = want.parameters?.['pageStates'] as string;
    // if (json !== undefined) {
    //   AppStorage.setOrCreate('migratedPageStates', json);
    // }

    // 3. 读回页面栈迁移开关（源端设置了 SUPPORT_CONTINUE_PAGE_STACK_KEY 才有值）
    const flag: Object | undefined = want.parameters?.[wantConstant.Params.SUPPORT_CONTINUE_PAGE_STACK_KEY];
    if (typeof flag === 'boolean') {
      this.isPageStackMigrated = flag as boolean;
    }

    // 4. 触发页面恢复（在 onCreate/onNewWant 执行完成前同步调用）
    //    - Router（默认系统页面栈恢复）：恢复带页面栈的页面，此后不要在
    //      onWindowStageRestore 中 loadContent；
    //    - 禁用页面栈迁移（Navigation/按需）：同样先调用本接口，
    //      落地页改在 onWindowStageRestore 中 loadContent；
    //    - 本接口可抛异常：try/catch 兜底，失败置标记，由
    //      onWindowStageRestore 中兜底 loadContent，避免对端白屏。
    try {
      this.context.restoreWindowStage(new LocalStorage());
    } catch (err) {
      this.isWindowRestoreFailed = true;
      hilog.error(DOMAIN, TAG, 'restoreWindowStage failed: %{public}s', JSON.stringify(err));
    }
  }

  // ============================================================
  // 目标端：onWindowStageRestore —— 迁移启动时替代 onWindowStageCreate 触发
  // ============================================================

  // 【最小侵入】仅当 onWindowStageCreate() 中存在启动必要的初始化时才保留本回调，
  // 并镜像执行同样的初始化（官方口径，避免迁移后异常）；onWindowStageCreate()
  // 无初始化、且系统页面栈恢复可用（Router 默认）时，整段删除本回调。
  onWindowStageRestore(windowStage: window.WindowStage): void {
    // 1. 镜像 onWindowStageCreate() 中的初始化（如有），例如窗口属性设置：
    // this.setupWindow(windowStage);

    // 2. 条件式手动加载：仅当迁移数据标记显示系统不会/不应恢复页面栈
    //    （isPageStackMigrated = false，Navigation 必设/Router 按需），或
    //    restoreWindowStage 失败兜底时，才 loadContent 落地页，注意将页面名称Index替换为实际名称；
    //    若走 restoreWindowStage 自动恢复，无需进行该加载
    if (!this.isPageStackMigrated || this.isWindowRestoreFailed) {
      windowStage.loadContent('pages/Index', (err) => {
        if (err.code) {
          hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, TAG, 'Succeeded in loading the content.');
      });
      return;
    }
}
