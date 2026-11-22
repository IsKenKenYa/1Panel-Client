/**
 * 定时轮询降级方案 - 当监听事件订阅失败时使用
 */

import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 定时轮询系统语言地区变化
 */
export class LocalePollingFallback {
  private pollTimer: number | null = null;
  private lastSystemLanguage: string = '';
  private lastSystemRegion: string = '';
  private onLocaleChangeCallback: ((language: string, region: string) => void) | null = null;
  private isPolling: boolean = false;

  /**
   * 设置语言地区变化回调
   */
  public setOnLocaleChangeCallback(callback: (language: string, region: string) => void): void {
    this.onLocaleChangeCallback = callback;
  }

  /**
   * 启动定时轮询
   * @param intervalMs 轮询间隔（毫秒），默认30秒
   */
  public startPolling(intervalMs: number = 30000): void {
    if (this.isPolling) {
      console.warn('[LocalePollingFallback] 已在轮询中，无需重复启动');
      return;
    }

    console.info(`[LocalePollingFallback] 启动定时轮询，间隔: ${intervalMs}ms`);

    // 获取当前语言地区作为基准
    try {
      this.lastSystemLanguage = i18n.System.getSystemLanguage();
      this.lastSystemRegion = i18n.System.getSystemRegion();
      console.info(`初始语言: ${this.lastSystemLanguage}, 初始地区: ${this.lastSystemRegion}`);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`获取初始语言地区失败: ${err.message}`);
      this.lastSystemLanguage = 'zh-Hans';
      this.lastSystemRegion = 'CN';
    }

    // 启动定时器
    this.pollTimer = setInterval(() => {
      this.checkLocaleChange();
    }, intervalMs);

    this.isPolling = true;
  }

  /**
   * 检查语言地区变化
   */
  private checkLocaleChange(): void {
    try {
      let currentLanguage = i18n.System.getSystemLanguage();
      let currentRegion = i18n.System.getSystemRegion();

      // 判断语言是否变化
      if (currentLanguage !== this.lastSystemLanguage) {
        console.info(`[LocalePollingFallback] 检测到语言变化: ${this.lastSystemLanguage} -> ${currentLanguage}`);
        this.lastSystemLanguage = currentLanguage;
        
        // 触发回调
        this.triggerCallback(currentLanguage, currentRegion);
      }

      // 判断地区是否变化
      if (currentRegion !== this.lastSystemRegion) {
        console.info(`[LocalePollingFallback] 检测到地区变化: ${this.lastSystemRegion} -> ${currentRegion}`);
        this.lastSystemRegion = currentRegion;
        
        // 触发回调
        this.triggerCallback(currentLanguage, currentRegion);
      }

    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`[LocalePollingFallback] 检查语言地区失败: ${err.message}`);
    }
  }

  /**
   * 触发回调函数
   */
  private triggerCallback(language: string, region: string): void {
    if (this.onLocaleChangeCallback) {
      try {
        this.onLocaleChangeCallback(language, region);
      } catch (error) {
        console.error('[LocalePollingFallback] 回调函数执行失败');
      }
    }
  }

  /**
   * 停止定时轮询
   */
  public stopPolling(): void {
    if (!this.isPolling) {
      console.warn('[LocalePollingFallback] 未在轮询中，无需停止');
      return;
    }

    if (this.pollTimer) {
      clearInterval(this.pollTimer);
      this.pollTimer = null;
    }

    this.isPolling = false;
    console.info('[LocalePollingFallback] 定时轮询已停止');
  }

  /**
   * 获取轮询状态
   */
  public isPollingActive(): boolean {
    return this.isPolling;
  }

  /**
   * 获取当前语言
   */
  public getCurrentLanguage(): string {
    return this.lastSystemLanguage;
  }

  /**
   * 获取当前地区
   */
  public getCurrentRegion(): string {
    return this.lastSystemRegion;
  }
}

/**
 * 使用示例1：基本轮询
 */
export function basicPollingExample(): void {
  let polling = new LocalePollingFallback();

  // 设置回调
  polling.setOnLocaleChangeCallback((language, region) => {
    console.info(`轮询检测到变化 - 语言: ${language}, 地区: ${region}`);
    
    // 执行应用语言切换逻辑
  });

  // 启动轮询（每30秒检查一次）
  polling.startPolling(30000);

  // 注意：在应用退出时停止轮询
  // polling.stopPolling();
}

/**
 * 使用示例2：监听失败后启动轮询
 */
export class HybridLocaleMonitor {
  private pollingFallback: LocalePollingFallback = new LocalePollingFallback();

  public initialize(): void {
    // 尝试启动监听（假设监听失败）
    this.startMonitoringWithFallback();
  }

  private startMonitoringWithFallback(): void {
    // 在实际场景中，这里应该先尝试监听事件
    // 如果监听失败，则启动轮询降级方案
    console.info('[HybridLocaleMonitor] 监听事件订阅失败，启动轮询降级方案');

    this.pollingFallback.setOnLocaleChangeCallback((language, region) => {
      this.handleLocaleChange(language, region);
    });

    this.pollingFallback.startPolling(30000);
  }

  private handleLocaleChange(language: string, region: string): void {
    console.info(`[HybridLocaleMonitor] 检测到变化 - 语言: ${language}, 地区: ${region}`);
    
    // 执行应用逻辑
    this.updateAppLanguage(language);
  }

  private updateAppLanguage(language: string): void {
    console.info(`[HybridLocaleMonitor] 更新应用语言为: ${language}`);
    // 实际应用逻辑
  }

  public cleanup(): void {
    this.pollingFallback.stopPolling();
  }
}

/**
 * 使用示例3：自定义轮询间隔
 */
export function customIntervalPollingExample(): void {
  let polling = new LocalePollingFallback();

  polling.setOnLocaleChangeCallback((language, region) => {
    console.info(`变化检测 - 语言: ${language}, 地区: ${region}`);
  });

  // 启动轮询，每10秒检查一次（高频轮询）
  polling.startPolling(10000);

  console.info(`轮询状态: ${polling.isPollingActive()}`);
  console.info(`当前语言: ${polling.getCurrentLanguage()}`);
  console.info(`当前地区: ${polling.getCurrentRegion()}`);
}

/**
 * 使用示例4：在Ability生命周期中使用
 */
export class PollingAbilityExample {
  private polling: LocalePollingFallback = new LocalePollingFallback();

  public onCreate(): void {
    console.info('Ability onCreate - 启动轮询');

    this.polling.setOnLocaleChangeCallback((language, region) => {
      console.info(`Ability检测到语言变化: ${language}, ${region}`);
    });

    this.polling.startPolling(30000);
  }

  public onDestroy(): void {
    console.info('Ability onDestroy - 停止轮询');
    this.polling.stopPolling();
  }

  public onForeground(): void {
    console.info('Ability onForeground');
    // 可以在进入前台时调整轮询间隔
    if (this.polling.isPollingActive()) {
      console.info('轮询已在运行');
    } else {
      this.polling.startPolling(15000); // 前台时使用更短的间隔
    }
  }

  public onBackground(): void {
    console.info('Ability onBackground');
    // 可以在进入后台时调整轮询间隔或停止轮询
    this.polling.stopPolling();
  }
}

/**
 * 使用示例5：轮询性能监控
 */
export class MonitoredPollingFallback extends LocalePollingFallback {
  private checkCount: number = 0;
  private changeCount: number = 0;

  protected checkLocaleChange(): void {
    this.checkCount++;
    super.checkLocaleChange();
    
    // 记录性能数据
    if (this.checkCount % 10 === 0) {
      console.info(`[MonitoredPolling] 已检查${this.checkCount}次，检测到变化${this.changeCount}次`);
    }
  }

  protected triggerCallback(language: string, region: string): void {
    this.changeCount++;
    super.triggerCallback(language, region);
  }

  public getStatistics(): { checks: number; changes: number } {
    return {
      checks: this.checkCount,
      changes: this.changeCount
    };
  }
}