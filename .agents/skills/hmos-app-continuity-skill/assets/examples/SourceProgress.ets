/**
 * 示例：源端应用保留不退出
 *
 * 用途：展示如何控制迁移后源端应用不退出（默认迁移后源端退出）。
 *   保留源端场景需配合并发写冲突策略，避免双端同时编辑互相覆盖。
 *
 * 核心做法：
 *   源端 onContinue 中设置 SUPPORT_CONTINUE_SOURCE_EXIT_KEY = false
 *
 * ⚠️ 注意事项：
 *   - 默认行为：迁移后源端退出（SUPPORT_CONTINUE_SOURCE_EXIT_KEY = true）
 *   - 各垂类推荐源端方案不同（多数编辑/浏览垂类推荐退出；影音/社媒/设计等
 *     "应用按需适配"；听书/直播类有专门的保留建议），见
 *     assets/checklists/confirm-scene-inventory.md §附录 B；保留源端须用户确认
 *   - 保留源端时，双端可能同时编辑同一数据，需要冲突策略
 *   - 目标端应在 onCreate/onNewWant 的 CONTINUATION 分支中设置 ACTIVE，
 *     保证迁移后的应用仍可再次被接续
 *
 * 使用方式：把本文件中的关键代码复制到项目的 EntryAbility.ets 中按需修改。
 *
 * 配套文件：
 *   - Ability 接线：assets/templates/EntryAbility.ets
 *   - API 详情：references/api-reference.md
 */

import { AbilityConstant, UIAbility, Want, wantConstant } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'EntryAbility';
const FORMAT = '%{public}s';

// ============================================================
// 并发写冲突策略（保留源端时必须考虑）
// ============================================================

/*
 * 【策略 A：乐观锁（版本号校验）】
 *
 * 适用场景：文档协作、金融数据
 *
 *   // 数据模型带版本号
 *   interface VersionedData {
 *     content: string;
 *     version: number;
 *   }
 *
 *   // 写入时比对版本号
 *   function updateData(newData: VersionedData): boolean {
 *     const current = AppStorage.get<VersionedData>('document');
 *     if (current && current.version >= newData.version) {
 *       // 冲突：本地版本更新，拒绝覆盖
 *       return false;
 *     }
 *     AppStorage.set('document', newData);
 *     return true;
 *   }
 */

/*
 * 【策略 B：后写者胜（接受覆盖）】
 *
 * 适用场景：简单表单、非关键数据
 *
 *   // 直接覆盖，不做版本比对
 *   function updateData(newData: any): void {
 *     AppStorage.set('formData', newData);
 *   }
 */

/*
 * 【策略 C：锁定模式（迁移期间禁止源端编辑）】
 *
 * 适用场景：支付、安全敏感场景
 *
 *   onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
 *     wantParam[wantConstant.Params.SUPPORT_CONTINUE_SOURCE_EXIT_KEY] = false;
 *     // 锁定源端编辑
 *     AppStorage.set<boolean>('isLocked', true);
 *     // 页面侧检测 isLocked，禁用输入控件
 *     return AbilityConstant.OnContinueResult.AGREE;
 *   }
 */

// ============================================================
// 完整的源端保留示例
// ============================================================

export default class EntryAbility extends UIAbility {
  // 页面栈是否走系统恢复（源端设 SUPPORT_CONTINUE_PAGE_STACK_KEY=false 时读回 false）
  private isPageStackMigrated: boolean = true;
  // restoreWindowStage 失败兜底标记（该接口可抛异常，见 api-reference §3.2）
  private isWindowRestoreFailed: boolean = false;

  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
    hilog.info(DOMAIN, TAG, FORMAT, 'onContinue: keeping source alive');
    // 迁移后保留源端
    wantParam[wantConstant.Params.SUPPORT_CONTINUE_SOURCE_EXIT_KEY] = false;
    // 采集状态
    wantParam['mainTitle'] = AppStorage.get<string>('mainTitle') as string;
    wantParam['textContent'] = AppStorage.get<string>('textContent') as string;
    return AbilityConstant.OnContinueResult.AGREE;
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, FORMAT, 'onCreate');
    if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
      // 目标端设置 ACTIVE，保证可再次接续
      this.context.setMissionContinueState(AbilityConstant.ContinueState.ACTIVE)
        .then(() => {
          hilog.info(DOMAIN, TAG, FORMAT, 'Set continue state to ACTIVE.');
        });
      // 恢复数据
      if (want?.parameters !== undefined) {
        AppStorage.setOrCreate<string>('mainTitle', want.parameters['mainTitle'] as string);
        AppStorage.setOrCreate<string>('textContent', want.parameters['textContent'] as string);
      }
      // 读回页面栈迁移开关，并在 onCreate 执行完成前同步调用 restoreWindowStage()
      // 触发页面恢复（Router 默认：带页面栈恢复；禁栈场景落地页在
      // onWindowStageRestore 中加载。禁止放进异步回调。
      // 本接口可抛异常：失败置标记，onWindowStageRestore 中兜底 loadContent）
      const flag: Object | undefined = want.parameters?.[wantConstant.Params.SUPPORT_CONTINUE_PAGE_STACK_KEY];
      if (typeof flag === 'boolean') {
        this.isPageStackMigrated = flag as boolean;
      }
      try {
        this.context.restoreWindowStage(new LocalStorage());
      } catch (err) {
        this.isWindowRestoreFailed = true;
        hilog.error(DOMAIN, TAG, FORMAT, `restoreWindowStage failed: ${JSON.stringify(err)}`);
      }
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index');
  }

  // 官方镜像原则：仅当 onWindowStageCreate() 中有启动必要的初始化时才需要本回调；
  // 页面栈迁移被禁用或 restoreWindowStage 失败兜底时 loadContent 落地页，
  // 系统页面栈恢复（Router 默认）时不要 loadContent（页面栈已由 restoreWindowStage 恢复）。
  onWindowStageRestore(windowStage: window.WindowStage): void {
    if (!this.isPageStackMigrated || this.isWindowRestoreFailed) {
      windowStage.loadContent('pages/Index');
    }
  }
}
