/**
 * EntryAbility示例
 * 展示如何在应用启动和退出时管理事件观察者
 */

import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import hilog from '@ohos.hilog';
import testNapi from 'libentry.so';

const LOG_TAG = 'EntryAbility';
const LOG_DOMAIN = 0xFF00;

export default class EntryAbility extends UIAbility {
  /**
   * 应用创建时调用
   * 在此注册事件观察者，开始监听应用终止事件
   */
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Ability onCreate');
    
    // 注册事件观察者
    try {
      testNapi.registerWatcher();
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Event watcher registered successfully');
      
      // 查看观察者状态
      const status = testNapi.getWatcherStatus();
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Watcher status: %{public}s', status.message);
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to register watcher: %{public}s', error.message);
    }
    
    // 可选：触发内存泄漏测试（仅用于测试，不要在生产环境使用）
    // testNapi.leak();
  }

  /**
   * 应用销毁时调用
   * 在此移除并销毁事件观察者，释放资源
   */
  onDestroy(): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Ability onDestroy');
    
    // 移除观察者
    try {
      testNapi.removeWatcher();
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Event watcher removed successfully');
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to remove watcher: %{public}s', error.message);
    }
    
    // 销毁观察者
    try {
      testNapi.destroyWatcher();
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Event watcher destroyed successfully');
      
      // 确认观察者已销毁
      const status = testNapi.getWatcherStatus();
      if (status.isNull) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Watcher is null, cleanup complete');
      }
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to destroy watcher: %{public}s', error.message);
    }
  }

  /**
   * 窗口舞台创建时调用
   */
  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Ability onWindowStageCreate');
    
    // 设置主窗口
    windowStage.getMainWindow((err, windowClass) => {
      if (err.code) {
        hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to obtain the main window. Cause: %{public}s', 
          err.message);
        return;
      }
      
      // 设置窗口内容
      windowStage.loadContent('pages/Index', (err, data) => {
        if (err.code) {
          hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to load the content. Cause: %{public}s', 
            err.message);
          return;
        }
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Succeeded in loading the content. Data: %{public}s', 
          JSON.stringify(data));
      });
    });
  }

  /**
   * 窗口舞台销毁时调用
   */
  onWindowStageDestroy(): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Ability onWindowStageDestroy');
  }

  /**
   * 应用进入前台时调用
   */
  onForeground(): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Ability onForeground');
  }

  /**
   * 应用进入后台时调用
   */
  onBackground(): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Ability onBackground');
  }
}

/**
 * 使用建议：
 * 
 * 1. 观察者生命周期管理：
 *    - onCreate中注册观察者
 *    - onDestroy中移除并销毁观察者
 *    - 避免在onForeground/onBackground中频繁注册/移除
 * 
 * 2. 错误处理：
 *    - 使用try-catch捕获可能的异常
 *    - 记录操作日志，便于排查问题
 * 
 * 3. 测试场景：
 *    - 仅在测试环境使用leak()接口
 *    - 生产环境不要触发内存泄漏
 * 
 * 4. 事件处理：
 *    - 终止事件在应用下次启动时上报
 *    - 应用被终止后，重新打开应用查看日志
 *    - 日志中包含终止原因、时间、前后台状态等信息
 */