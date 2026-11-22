/**
 * 应用入口示例：初始化地址越界事件订阅
 * 在EntryAbility的onCreate中调用订阅初始化函数
 */

import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

// 导入订阅初始化函数
import { 
  initializeAddressSanitizerWatcher, 
  cleanupAddressSanitizerWatcher 
} from '../common/address_sanitizer_watcher_example';

export default class EntryAbility extends UIAbility {
  /**
   * 应用创建时初始化订阅
   */
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'EntryAbility', 'Ability onCreate.');
    
    // 初始化地址越界事件订阅
    initializeAddressSanitizerWatcher();
  }

  /**
   * 应用销毁时清理订阅
   */
  onDestroy(): void {
    hilog.info(0x0000, 'EntryAbility', 'Ability onDestroy.');
    
    // 清理地址越界事件订阅
    cleanupAddressSanitizerWatcher();
  }

  /**
   * 窗口阶段创建
   */
  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, 'EntryAbility', 'Ability onWindowStageCreate.');

    // 设置主窗口内容
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'EntryAbility', 
          `Failed to load content. Code: ${err.code}, Message: ${err.message}`);
        return;
      }
      hilog.info(0x0000, 'EntryAbility', 'Succeeded in loading content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(0x0000, 'EntryAbility', 'Ability onWindowStageDestroy.');
  }

  onForeground(): void {
    hilog.info(0x0000, 'EntryAbility', 'Ability onForeground.');
  }

  onBackground(): void {
    hilog.info(0x0000, 'EntryAbility', 'Ability onBackground.');
  }
}