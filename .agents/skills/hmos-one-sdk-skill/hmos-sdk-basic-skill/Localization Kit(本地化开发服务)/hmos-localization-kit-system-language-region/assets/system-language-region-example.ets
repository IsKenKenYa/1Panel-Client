/**
 * 系统语言与区域 - 完整示例
 * 
 * 本示例演示如何：
 * 1. 获取系统语言、地区、区域信息
 * 2. 监听系统语言地区变化事件
 * 3. 在应用退出时取消订阅
 * 4. 错误处理和降级方案
 */

import { i18n } from '@kit.LocalizationKit';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';

/**
 * 系统语言地区管理类
 */
export class SystemLocaleManager {
  private subscriber: commonEventManager.CommonEventSubscriber | null = null;
  private pollTimer: number | null = null;
  private lastSystemLanguage: string = '';
  private isListening: boolean = false;

  /**
   * 初始化并获取系统语言地区信息
   */
  public initialize(): void {
    console.info('[SystemLocaleManager] 初始化系统语言地区管理');
    
    // 获取当前系统语言地区信息
    this.displayCurrentLocaleInfo();
    
    // 启动监听
    this.startListening();
  }

  /**
   * 显示当前系统语言地区信息
   */
  private displayCurrentLocaleInfo(): void {
    try {
      let systemLanguage: string = i18n.System.getSystemLanguage();
      let systemRegion: string = i18n.System.getSystemRegion();
      let systemLocale: Intl.Locale = i18n.System.getSystemLocaleInstance();
      
      console.info(`当前系统语言: ${systemLanguage}`);
      console.info(`当前系统地区: ${systemRegion}`);
      console.info(`当前系统区域: ${systemLocale.toString()}`);
      
      // 显示Locale对象的详细信息
      console.info(`Locale语言: ${systemLocale.language}`);
      console.info(`Locale地区: ${systemLocale.region || '未设置'}`);
      console.info(`Locale脚本: ${systemLocale.script || '未设置'}`);
      
      // 保存当前语言用于后续监听对比
      this.lastSystemLanguage = systemLanguage;
      
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`获取系统语言地区失败，错误码: ${err.code}, 错误信息: ${err.message}`);
      this.handleGetLocaleError(err);
    }
  }

  /**
   * 启动监听系统语言地区变化
   */
  private startListening(): void {
    // 创建订阅配置
    let subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: [commonEventManager.Support.COMMON_EVENT_LOCALE_CHANGED]
    };

    // 创建订阅者
    commonEventManager.createSubscriber(subscribeInfo)
      .then((commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
        console.info('[SystemLocaleManager] 成功创建订阅者');
        this.subscriber = commonEventSubscriber;
        this.isListening = true;

        // 订阅事件
        this.subscribeToLocaleChange();
      })
      .catch((err: BusinessError) => {
        console.error(`创建订阅者失败，错误码: ${err.code}, 错误信息: ${err.message}`);
        // 启动降级方案：定时轮询
        this.startPollingFallback();
      });
  }

  /**
   * 订阅系统语言地区变化事件
   */
  private subscribeToLocaleChange(): void {
    if (!this.subscriber) {
      console.error('[SystemLocaleManager] 订阅者对象不存在');
      return;
    }

    commonEventManager.subscribe(this.subscriber, (err, data) => {
      if (err) {
        console.error(`订阅事件回调错误，错误码: ${err.code}, 错误信息: ${err.message}`);
        return;
      }

      console.info('[SystemLocaleManager] 系统语言、地区或区域发生变化');
      
      // 重新获取并显示系统语言地区信息
      this.handleLocaleChange();
    });
  }

  /**
   * 处理系统语言地区变化
   */
  private handleLocaleChange(): void {
    try {
      let newSystemLanguage = i18n.System.getSystemLanguage();
      let newSystemRegion = i18n.System.getSystemRegion();
      let newSystemLocale = i18n.System.getSystemLocaleInstance();

      console.info(`新系统语言: ${newSystemLanguage}`);
      console.info(`新系统地区: ${newSystemRegion}`);
      console.info(`新系统区域: ${newSystemLocale.toString()}`);

      // 判断语言是否发生变化
      if (newSystemLanguage !== this.lastSystemLanguage) {
        console.info(`系统语言从 ${this.lastSystemLanguage} 变为 ${newSystemLanguage}`);
        this.lastSystemLanguage = newSystemLanguage;
        
        // 触发应用语言切换逻辑
        this.updateAppLanguage(newSystemLanguage, newSystemLocale);
      }

    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`处理语言变化失败，错误码: ${err.code}, 错误信息: ${err.message}`);
    }
  }

  /**
   * 更新应用语言（示例逻辑）
   */
  private updateAppLanguage(language: string, locale: Intl.Locale): void {
    console.info(`[SystemLocaleManager] 更新应用语言为: ${language}`);
    
    // 示例：设置应用偏好语言
    try {
      i18n.System.setAppPreferredLanguage(language);
      console.info('应用偏好语言已设置');
      
      // 在此处添加应用语言切换的实际逻辑：
      // 1. 重新加载国际化资源文件
      // 2. 更新UI组件的文本显示
      // 3. 调整布局（如RTL语言的镜像布局）
      // 4. 更新日期、数字等格式化显示
      
      this.reloadResources(locale);
      this.updateUIComponents(locale);
      
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`设置应用偏好语言失败，错误码: ${err.code}, 错误信息: ${err.message}`);
    }
  }

  /**
   * 重新加载国际化资源（示例）
   */
  private reloadResources(locale: Intl.Locale): void {
    console.info(`[SystemLocaleManager] 重新加载资源，区域: ${locale.toString()}`);
    // 实际项目中在此处实现资源加载逻辑
  }

  /**
   * 更新UI组件（示例）
   */
  private updateUIComponents(locale: Intl.Locale): void {
    console.info(`[SystemLocaleManager] 更新UI组件，区域: ${locale.toString()}`);
    
    // 检查是否为RTL语言（如阿拉伯语、希伯来语）
    let isRTL = i18n.isRTL(locale.toString());
    if (isRTL) {
      console.info('检测到RTL语言，需要镜像布局');
      // 在此处实现RTL布局逻辑
    }
    
    // 实际项目中在此处实现UI更新逻辑
  }

  /**
   * 启动定时轮询降级方案
   */
  private startPollingFallback(): void {
    console.warn('[SystemLocaleManager] 监听订阅失败，启动定时轮询方案');
    
    // 每30秒轮询一次系统语言地区信息
    this.pollTimer = setInterval(() => {
      let currentSystemLanguage = i18n.System.getSystemLanguage();
      
      if (currentSystemLanguage !== this.lastSystemLanguage) {
        console.info(`[SystemLocaleManager] 检测到语言变化: ${this.lastSystemLanguage} -> ${currentSystemLanguage}`);
        this.lastSystemLanguage = currentSystemLanguage;
        
        // 执行语言切换逻辑
        this.handleLocaleChange();
      }
    }, 30000);
  }

  /**
   * 停止定时轮询
   */
  private stopPollingFallback(): void {
    if (this.pollTimer) {
      clearInterval(this.pollTimer);
      this.pollTimer = null;
      console.info('[SystemLocaleManager] 定时轮询已停止');
    }
  }

  /**
   * 处理获取语言地区错误
   */
  private handleGetLocaleError(err: BusinessError): void {
    switch (err.code) {
      case 401:
        console.error('参数错误，请检查API调用参数');
        break;
      case 890001:
        console.error('无效参数，参数验证失败');
        break;
      default:
        console.error('未知错误，使用默认语言地区');
        this.useDefaultLocale();
        break;
    }
  }

  /**
   * 使用默认语言地区设置
   */
  private useDefaultLocale(): void {
    console.warn('[SystemLocaleManager] 使用默认语言地区: zh-Hans-CN');
    this.lastSystemLanguage = 'zh-Hans';
    // 在此处设置应用的默认语言地区配置
  }

  /**
   * 停止监听并清理资源
   */
  public cleanup(): void {
    console.info('[SystemLocaleManager] 清理资源');

    // 停止定时轮询
    this.stopPollingFallback();

    // 取消事件订阅
    if (this.subscriber) {
      commonEventManager.unsubscribe(this.subscriber)
        .then(() => {
          console.info('[SystemLocaleManager] 成功取消订阅');
          this.subscriber = null;
          this.isListening = false;
        })
        .catch((err: BusinessError) => {
          console.error(`取消订阅失败，错误码: ${err.code}, 错误信息: ${err.message}`);
        });
    }
  }

  /**
   * 获取监听状态
   */
  public getListeningStatus(): boolean {
    return this.isListening;
  }

  /**
   * 获取当前系统语言
   */
  public getCurrentSystemLanguage(): string {
    return this.lastSystemLanguage || i18n.System.getSystemLanguage();
  }

  /**
   * 检查是否支持本地数字
   */
  public checkLocalDigitSupport(): void {
    try {
      let usingLocalDigit: boolean = i18n.System.getUsingLocalDigit();
      console.info(`系统是否使用本地数字: ${usingLocalDigit}`);
      
      if (usingLocalDigit) {
        console.info('当前语言支持本地数字显示');
        // 在此处实现本地数字格式化逻辑
      } else {
        console.info('当前语言使用阿拉伯数字');
      }
      
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`检查本地数字支持失败，错误码: ${err.code}, 错误信息: ${err.message}`);
    }
  }
}

/**
 * 使用示例
 */
export function demonstrateSystemLocale(): void {
  console.info('=== 系统语言与区域功能演示 ===');
  
  // 创建管理实例
  let localeManager = new SystemLocaleManager();
  
  // 初始化并获取语言地区信息
  localeManager.initialize();
  
  // 检查本地数字支持
  localeManager.checkLocalDigitSupport();
  
  // 显示监听状态
  console.info(`监听状态: ${localeManager.getListeningStatus()}`);
  
  // 注意：在实际应用中，需要在应用退出时调用cleanup()
  // localeManager.cleanup();
}

/**
 * EntryAbility中使用示例
 */
export class LocaleAbilityExample {
  private localeManager: SystemLocaleManager = new SystemLocaleManager();

  // 在onCreate中初始化
  public onCreate(): void {
    console.info('Ability onCreate');
    this.localeManager.initialize();
  }

  // 在onDestroy中清理
  public onDestroy(): void {
    console.info('Ability onDestroy');
    this.localeManager.cleanup();
  }
}