/**
 * HarmonyOS 应用与系统未成年人模式联动完整示例
 * 
 * 功能说明：
 * 1. 查询系统未成年人模式状态
 * 2. 订阅系统未成年人模式变更事件
 * 3. 获取年龄段信息并实现内容分级
 * 4. 缓存状态信息避免重复调用
 * 
 * API版本：HarmonyOS 5.0.0(12)
 * 系统能力：SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection
 */

import { minorsProtection } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';
import { UIAbility, AbilityConstant, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

const TAG = 'MinorsProtectionExample';
const DOMAIN = 0x0000;

// 缓存未成年人模式状态和年龄段信息
class MinorsModeCache {
  private static instance: MinorsModeCache;
  private minorsProtectionMode: boolean = false;
  private ageGroup: minorsProtection.AgeGroup | null = null;
  
  static getInstance(): MinorsModeCache {
    if (!MinorsModeCache.instance) {
      MinorsModeCache.instance = new MinorsModeCache();
    }
    return MinorsModeCache.instance;
  }
  
  setMinorsMode(mode: boolean): void {
    this.minorsProtectionMode = mode;
  }
  
  getMinorsMode(): boolean {
    return this.minorsProtectionMode;
  }
  
  setAgeGroup(group: minorsProtection.AgeGroup | undefined): void {
    if (group) {
      this.ageGroup = { lowerAge: group.lowerAge, upperAge: group.upperAge };
    } else {
      this.ageGroup = null;
    }
  }
  
  getAgeGroup(): minorsProtection.AgeGroup | null {
    return this.ageGroup;
  }
  
  clearCache(): void {
    this.minorsProtectionMode = false;
    this.ageGroup = null;
  }
}

// 订阅者管理
let subscriber: commonEventManager.CommonEventSubscriber | null = null;

/**
 * 订阅系统未成年人模式公共事件
 * 推荐在UIAbility的onCreate生命周期中调用
 */
function subscribeMinorsModeEvents(): void {
  try {
    const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: [
        commonEventManager.Support.COMMON_EVENT_MINORSMODE_ON,
        commonEventManager.Support.COMMON_EVENT_MINORSMODE_OFF
      ]
    };
    
    commonEventManager.createSubscriber(subscribeInfo)
      .then((commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
        subscriber = commonEventSubscriber;
        
        commonEventManager.subscribe(subscriber, 
          (error: BusinessError, data: commonEventManager.CommonEventData) => {
            if (error) {
              hilog.error(DOMAIN, TAG, `Failed to subscribe event. Code: ${error.code}, message: ${error.message}`);
              return;
            }
            
            if (data.event === commonEventManager.Support.COMMON_EVENT_MINORSMODE_ON) {
              hilog.info(DOMAIN, TAG, 'Received MINORSMODE_ON event');
              handleMinorsModeOnEvent();
            } else if (data.event === commonEventManager.Support.COMMON_EVENT_MINORSMODE_OFF) {
              hilog.info(DOMAIN, TAG, 'Received MINORSMODE_OFF event');
              handleMinorsModeOffEvent();
            }
          });
        
        hilog.info(DOMAIN, TAG, 'Successfully subscribed to minors mode events');
      })
      .catch((error: BusinessError) => {
        hilog.error(DOMAIN, TAG, `Failed to create subscriber. Code: ${error.code}, message: ${error.message}`);
      });
  } catch (error) {
    hilog.error(DOMAIN, TAG, `Exception in subscribeMinorsModeEvents: ${error.message}`);
  }
}

/**
 * 处理未成年人模式开启事件
 */
function handleMinorsModeOnEvent(): void {
  // 获取最新的未成年人模式状态和年龄段信息
  getMinorsProtectionStatus();
}

/**
 * 处理未成年人模式关闭事件
 */
function handleMinorsModeOffEvent(): void {
  const cache = MinorsModeCache.getInstance();
  cache.clearCache();
  
  // 关闭应用的未成年人模式，展示内容不做限制
  applyNoContentFilter();
  hilog.info(DOMAIN, TAG, 'Minors mode turned off, no content filter applied');
}

/**
 * 查询未成年人模式状态（同步方式）
 */
function getMinorsProtectionStatusSync(): void {
  if (!canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
    hilog.warn(DOMAIN, TAG, 'System capability not supported');
    return;
  }
  
  try {
    if (!minorsProtection.supportMinorsMode()) {
      hilog.warn(DOMAIN, TAG, 'Device does not support minors mode');
      return;
    }
    
    const minorsProtectionInfo: minorsProtection.MinorsProtectionInfo = 
      minorsProtection.getMinorsProtectionInfoSync();
    
    const minorsProtectionMode: boolean = minorsProtectionInfo.minorsProtectionMode;
    hilog.info(DOMAIN, TAG, `Minors protection mode: ${minorsProtectionMode}`);
    
    const cache = MinorsModeCache.getInstance();
    cache.setMinorsMode(minorsProtectionMode);
    
    if (minorsProtectionMode) {
      const ageGroup: minorsProtection.AgeGroup | undefined = minorsProtectionInfo.ageGroup;
      if (ageGroup) {
        hilog.info(DOMAIN, TAG, `Age group: [${ageGroup.lowerAge}, ${ageGroup.upperAge})`);
        cache.setAgeGroup(ageGroup);
        applyContentFilterByAgeGroup(ageGroup.lowerAge, ageGroup.upperAge);
      }
    } else {
      cache.setAgeGroup(undefined);
      applyNoContentFilter();
    }
  } catch (error) {
    hilog.error(DOMAIN, TAG, `Failed to get minors mode status. Code: ${error.code}, Message: ${error.message}`);
    handleMinorsModeError(error);
  }
}

/**
 * 查询未成年人模式状态（异步方式）
 */
async function getMinorsProtectionStatus(): Promise<void> {
  if (!canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
    hilog.warn(DOMAIN, TAG, 'System capability not supported');
    return;
  }
  
  try {
    if (!minorsProtection.supportMinorsMode()) {
      hilog.warn(DOMAIN, TAG, 'Device does not support minors mode');
      return;
    }
    
    const minorsProtectionInfo: minorsProtection.MinorsProtectionInfo = 
      await minorsProtection.getMinorsProtectionInfo();
    
    const minorsProtectionMode: boolean = minorsProtectionInfo.minorsProtectionMode;
    hilog.info(DOMAIN, TAG, `Minors protection mode: ${minorsProtectionMode}`);
    
    const cache = MinorsModeCache.getInstance();
    cache.setMinorsMode(minorsProtectionMode);
    
    if (minorsProtectionMode) {
      const ageGroup: minorsProtection.AgeGroup | undefined = minorsProtectionInfo.ageGroup;
      if (ageGroup) {
        hilog.info(DOMAIN, TAG, `Age group: [${ageGroup.lowerAge}, ${ageGroup.upperAge})`);
        cache.setAgeGroup(ageGroup);
        applyContentFilterByAgeGroup(ageGroup.lowerAge, ageGroup.upperAge);
      }
    } else {
      cache.setAgeGroup(undefined);
      applyNoContentFilter();
    }
  } catch (error) {
    hilog.error(DOMAIN, TAG, `Failed to get minors mode status. Code: ${error.code}, Message: ${error.message}`);
    handleMinorsModeError(error);
  }
}

/**
 * 根据年龄段应用内容过滤
 * 年龄段范围：[0,3)、[3,8)、[8,12)、[12,16)、[16,18)
 */
function applyContentFilterByAgeGroup(lowerAge: number, upperAge: number): void {
  hilog.info(DOMAIN, TAG, `Applying content filter for age group [${lowerAge}, ${upperAge})`);
  
  // 实现内容分级逻辑
  // 根据年龄段过滤不适宜的内容
  // 可以使用预定义的内容分级标签或数据库
  
  switch (upperAge) {
    case 3:
      // 婴幼儿内容（0-3岁）
      hilog.info(DOMAIN, TAG, 'Applying infant content filter');
      break;
    case 8:
      // 学龄前儿童内容（3-8岁）
      hilog.info(DOMAIN, TAG, 'Applying preschool content filter');
      break;
    case 12:
      // 学龄儿童内容（8-12岁）
      hilog.info(DOMAIN, TAG, 'Applying school-age content filter');
      break;
    case 16:
      // 青少年内容（12-16岁）
      hilog.info(DOMAIN, TAG, 'Applying teenager content filter');
      break;
    case 18:
      // 大龄青少年内容（16-18岁）
      hilog.info(DOMAIN, TAG, 'Applying young adult content filter');
      break;
    default:
      hilog.warn(DOMAIN, TAG, `Unknown age group: [${lowerAge}, ${upperAge})`);
      applyNoContentFilter();
  }
}

/**
 * 应用无内容过滤（未成年人模式关闭）
 */
function applyNoContentFilter(): void {
  hilog.info(DOMAIN, TAG, 'No content filter applied');
  // 展示所有内容，不做限制
}

/**
 * 错误处理
 */
function handleMinorsModeError(error: BusinessError): void {
  switch (error.code) {
    case 1001502009:
      hilog.error(DOMAIN, TAG, 'Internal error occurred');
      // 可以尝试重新调用或提示用户
      break;
    case 1009900002:
      hilog.error(DOMAIN, TAG, 'Minors mode is not enabled');
      // 提示用户开启系统未成年人模式
      break;
    case 1009900003:
      hilog.error(DOMAIN, TAG, 'User canceled the operation');
      // 用户取消，无需特殊处理
      break;
    case 1009900005:
      hilog.warn(DOMAIN, TAG, 'Minors mode is already on');
      // 已开启，无需重复操作
      break;
    case 1009900006:
      hilog.warn(DOMAIN, TAG, 'Minors mode is already off');
      // 已关闭，无需重复操作
      break;
    case 1009900007:
      hilog.error(DOMAIN, TAG, 'Unsupported account');
      // 提示用户账号不支持
      break;
    case 1009900011:
      hilog.error(DOMAIN, TAG, 'Service not available');
      // 提示用户服务不可用，稍后重试
      break;
    default:
      hilog.error(DOMAIN, TAG, `Unknown error: ${error.code}`);
      // 使用降级方案
      fallbackMinorsModeHandling();
  }
}

/**
 * 降级处理方案
 */
function fallbackMinorsModeHandling(): void {
  const cache = MinorsModeCache.getInstance();
  const cachedMode = cache.getMinorsMode();
  const cachedAgeGroup = cache.getAgeGroup();
  
  if (cachedMode && cachedAgeGroup) {
    hilog.info(DOMAIN, TAG, 'Using cached minors mode status');
    applyContentFilterByAgeGroup(cachedAgeGroup.lowerAge, cachedAgeGroup.upperAge);
  } else {
    hilog.warn(DOMAIN, TAG, 'No cached data, applying no content filter');
    applyNoContentFilter();
  }
}

/**
 * 取消订阅公共事件
 * 推荐在UIAbility的onDestroy生命周期中调用
 */
function unsubscribeMinorsModeEvents(): void {
  if (subscriber) {
    commonEventManager.unsubscribe(subscriber)
      .then(() => {
        hilog.info(DOMAIN, TAG, 'Successfully unsubscribed from minors mode events');
        subscriber = null;
      })
      .catch((error: BusinessError) => {
        hilog.error(DOMAIN, TAG, `Failed to unsubscribe. Code: ${error.code}, message: ${error.message}`);
      });
  }
}

/**
 * UIAbility生命周期示例
 */
export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'EntryAbility onCreate');
    
    // 订阅系统未成年人模式事件
    subscribeMinorsModeEvents();
    
    // 查询当前未成年人模式状态
    getMinorsProtectionStatusSync();
  }
  
  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'EntryAbility onDestroy');
    
    // 取消订阅
    unsubscribeMinorsModeEvents();
    
    // 清空缓存
    MinorsModeCache.getInstance().clearCache();
  }
  
  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, 'EntryAbility onWindowStageCreate');
    
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, `Failed to load content. Code: ${err.code}, message: ${err.message}`);
        return;
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading content');
    });
  }
}

/**
 * 使用示例（在自定义组件中）
 */
@Entry
@Component
struct MinorsProtectionPage {
  private minorsModeCache: MinorsModeCache = MinorsModeCache.getInstance();
  
  aboutToAppear(): void {
    // 在自定义组件生命周期中查询状态
    getMinorsProtectionStatusSync();
  }
  
  build() {
    Column() {
      Text('未成年人模式状态')
        .fontSize(20)
        .margin({ top: 20, bottom: 10 })
      
      Text(this.minorsModeCache.getMinorsMode() ? '已开启' : '已关闭')
        .fontSize(18)
        .margin({ bottom: 10 })
      
      if (this.minorsModeCache.getMinorsMode() && this.minorsModeCache.getAgeGroup()) {
        Text(`年龄段: [${this.minorsModeCache.getAgeGroup()?.lowerAge}, ${this.minorsModeCache.getAgeGroup()?.upperAge})`)
          .fontSize(18)
          .margin({ bottom: 10 })
      }
      
      Button('查询状态（同步）')
        .onClick(() => {
          getMinorsProtectionStatusSync();
        })
        .margin({ top: 10 })
      
      Button('查询状态（异步）')
        .onClick(() => {
          getMinorsProtectionStatus();
        })
        .margin({ top: 10 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}