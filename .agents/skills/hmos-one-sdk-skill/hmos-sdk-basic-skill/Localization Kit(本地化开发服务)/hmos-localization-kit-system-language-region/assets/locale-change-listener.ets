/**
 * 监听系统语言地区变化事件 - 专注监听功能示例
 */

import { i18n } from '@kit.LocalizationKit';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';

/**
 * 系统语言地区变化监听器
 */
export class LocaleChangeListener {
  private subscriber: commonEventManager.CommonEventSubscriber | null = null;
  private onLocaleChangeCallback: ((language: string, region: string, locale: Intl.Locale) => void) | null = null;

  /**
   * 设置语言地区变化回调
   */
  public setOnLocaleChangeCallback(callback: (language: string, region: string, locale: Intl.Locale) => void): void {
    this.onLocaleChangeCallback = callback;
  }

  /**
   * 开始监听
   */
  public startListening(): Promise<boolean> {
    return new Promise<boolean>((resolve, reject) => {
      // 创建订阅配置
      let subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
        events: [commonEventManager.Support.COMMON_EVENT_LOCALE_CHANGED]
      };

      // 创建订阅者
      commonEventManager.createSubscriber(subscribeInfo)
        .then((commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
          console.info('[LocaleChangeListener] 成功创建订阅者');
          this.subscriber = commonEventSubscriber;

          // 订阅事件
          commonEventManager.subscribe(this.subscriber, (err, data) => {
            if (err) {
              console.error(`监听回调错误，错误码: ${err.code}, 错误信息: ${err.message}`);
              return;
            }

            console.info('[LocaleChangeListener] 系统语言地区发生变化');
            this.handleLocaleChangeEvent();
          });

          resolve(true);
        })
        .catch((err: BusinessError) => {
          console.error(`创建订阅者失败，错误码: ${err.code}, 错误信息: ${err.message}`);
          reject(err);
        });
    });
  }

  /**
   * 处理语言地区变化事件
   */
  private handleLocaleChangeEvent(): void {
    try {
      let newLanguage = i18n.System.getSystemLanguage();
      let newRegion = i18n.System.getSystemRegion();
      let newLocale = i18n.System.getSystemLocaleInstance();

      console.info(`语言变化: ${newLanguage}`);
      console.info(`地区变化: ${newRegion}`);
      console.info(`区域变化: ${newLocale.toString()}`);

      // 调用回调函数
      if (this.onLocaleChangeCallback) {
        this.onLocaleChangeCallback(newLanguage, newRegion, newLocale);
      }

    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`处理语言变化失败，错误码: ${err.code}, 错误信息: ${err.message}`);
    }
  }

  /**
   * 停止监听
   */
  public stopListening(): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      if (!this.subscriber) {
        console.warn('[LocaleChangeListener] 订阅者不存在，无需取消订阅');
        resolve();
        return;
      }

      commonEventManager.unsubscribe(this.subscriber)
        .then(() => {
          console.info('[LocaleChangeListener] 成功取消订阅');
          this.subscriber = null;
          resolve();
        })
        .catch((err: BusinessError) => {
          console.error(`取消订阅失败，错误码: ${err.code}, 错误信息: ${err.message}`);
          reject(err);
        });
    });
  }

  /**
   * 检查监听状态
   */
  public isListening(): boolean {
    return this.subscriber !== null;
  }
}

/**
 * 使用示例1：基本监听
 */
export function basicListenerExample(): void {
  let listener = new LocaleChangeListener();

  // 设置回调函数
  listener.setOnLocaleChangeCallback((language, region, locale) => {
    console.info(`回调触发 - 语言: ${language}, 地区: ${region}, 区域: ${locale.toString()}`);
    
    // 在此处执行应用语言切换逻辑
    // 例如：重新加载资源、更新UI等
  });

  // 开始监听
  listener.startListening()
    .then((success) => {
      if (success) {
        console.info('监听已启动');
      }
    })
    .catch((err: BusinessError) => {
      console.error(`监听启动失败: ${err.message}`);
    });

  // 注意：在实际应用中需要在退出时停止监听
  // listener.stopListening();
}

/**
 * 使用示例2：在UI组件中使用
 */
export class UILocaleComponent {
  private listener: LocaleChangeListener = new LocaleChangeListener();
  private currentLanguage: string = '';

  public initialize(): void {
    // 获取当前语言
    this.currentLanguage = i18n.System.getSystemLanguage();
    console.info(`初始语言: ${this.currentLanguage}`);

    // 设置监听回调
    this.listener.setOnLocaleChangeCallback((language, region, locale) => {
      this.onLocaleChanged(language, region, locale);
    });

    // 开始监听
    this.listener.startListening()
      .then((success) => {
        console.info(`UI组件监听状态: ${success}`);
      })
      .catch((err) => {
        console.error(`UI组件监听失败: ${err.message}`);
      });
  }

  private onLocaleChanged(language: string, region: string, locale: Intl.Locale): void {
    console.info(`UI组件检测到语言变化: ${this.currentLanguage} -> ${language}`);
    this.currentLanguage = language;

    // 更新UI组件显示
    this.updateUI(locale);
  }

  private updateUI(locale: Intl.Locale): void {
    console.info('更新UI组件显示');
    // 在此处实现实际的UI更新逻辑
  }

  public cleanup(): void {
    this.listener.stopListening()
      .then(() => {
        console.info('UI组件监听已停止');
      })
      .catch((err) => {
        console.error(`UI组件停止监听失败: ${err.message}`);
      });
  }
}

/**
 * 使用示例3：多监听器协调
 */
export class MultiLocaleListeners {
  private listeners: LocaleChangeListener[] = [];

  public addListener(listener: LocaleChangeListener): void {
    this.listeners.push(listener);
  }

  public startAllListeners(): Promise<boolean[]> {
    let promises: Promise<boolean>[] = [];
    
    this.listeners.forEach((listener) => {
      promises.push(listener.startListening());
    });

    return Promise.all(promises);
  }

  public stopAllListeners(): Promise<void[]> {
    let promises: Promise<void>[] = [];
    
    this.listeners.forEach((listener) => {
      promises.push(listener.stopListening());
    });

    return Promise.all(promises);
  }
}

/**
 * 使用示例4：监听失败后的恢复
 */
export class ResilientLocaleListener {
  private listener: LocaleChangeListener = new LocaleChangeListener();
  private retryCount: number = 0;
  private maxRetries: number = 3;

  public startListeningWithRetry(): Promise<boolean> {
    return this.tryStartListening();
  }

  private tryStartListening(): Promise<boolean> {
    return this.listener.startListening()
      .then((success) => {
        console.info('监听成功启动');
        return success;
      })
      .catch((err: BusinessError) => {
        this.retryCount++;
        console.error(`监听启动失败（第${this.retryCount}次）: ${err.message}`);

        if (this.retryCount < this.maxRetries) {
          console.info('尝试重新启动监听...');
          return this.tryStartListening();
        } else {
          console.error('监听启动失败，已达最大重试次数');
          throw err;
        }
      });
  }
}