/**
 * EntryAbility集成示例
 * 
 * 本示例演示如何在EntryAbility中集成功耗事件订阅功能。
 */

import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BatteryUsageWatcher } from './watcher/BatteryUsageWatcher';

const TAG = 'EntryAbility';
const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private batteryUsageWatcher: BatteryUsageWatcher | null = null;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'Ability onCreate');

    // 初始化并订阅功耗事件
    this.initBatteryUsageWatcher();
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onDestroy');

    // 取消订阅并释放资源
    this.cleanupBatteryUsageWatcher();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageCreate');

    // 设置主窗口
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, `Failed to load content: ${JSON.stringify(err)}`);
        return;
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading content');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'Ability onBackground');
  }

  /**
   * 初始化功耗事件订阅器
   */
  private initBatteryUsageWatcher(): void {
    try {
      this.batteryUsageWatcher = new BatteryUsageWatcher();

      // 设置功耗数据接收回调
      this.batteryUsageWatcher.onBatteryUsageReceived = (data) => {
        hilog.info(DOMAIN, TAG, `Received battery usage data for ${data.bundleName}`);
        // 在这里可以添加自定义的数据处理逻辑
      };

      // 订阅功耗事件
      const success = this.batteryUsageWatcher.subscribe();

      if (success) {
        hilog.info(DOMAIN, TAG, 'Battery usage watcher initialized successfully');
      } else {
        hilog.error(DOMAIN, TAG, 'Failed to initialize battery usage watcher');
      }

    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to initialize battery usage watcher: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 清理功耗事件订阅器
   */
  private cleanupBatteryUsageWatcher(): void {
    if (this.batteryUsageWatcher) {
      this.batteryUsageWatcher.unsubscribe();
      this.batteryUsageWatcher = null;
      hilog.info(DOMAIN, TAG, 'Battery usage watcher cleaned up');
    }
  }
}

/**
 * 使用说明
 * 
 * 1. 将BatteryUsageWatcher类文件放在 entry/src/main/ets/watcher/ 目录下
 * 2. 将此文件替换原有的 EntryAbility.ets 文件
 * 3. 在module.json5中确保已声明必要的权限（本示例无需特殊权限）
 * 4. 编译运行应用
 * 
 * module.json5 配置示例：
 * {
 *   "module": {
 *     "name": "entry",
 *     "type": "entry",
 *     "description": "$string:module_desc",
 *     "mainElement": "EntryAbility",
 *     "deviceTypes": [
 *       "phone",
 *       "tablet",
 *       "2in1"
 *     ],
 *     "deliveryWithInstall": true,
 *     "installationFree": false,
 *     "pages": "$profile:main_pages",
 *     "abilities": [
 *       {
 *         "name": "EntryAbility",
 *         "srcEntry": "./ets/entryability/EntryAbility.ets",
 *         "description": "$string:EntryAbility_desc",
 *         "icon": "$media:layered_image",
 *         "label": "$string:EntryAbility_label",
 *         "startWindowIcon": "$media:startIcon",
 *         "startWindowBackground": "$color:start_window_background",
 *         "exported": true,
 *         "skills": [
 *           {
 *             "entities": [
 *               "entity.system.home"
 *             ],
 *             "actions": [
 *               "action.system.home"
 *             ]
 *           }
 *         ]
 *       }
 *     ]
 *   }
 * }
 */