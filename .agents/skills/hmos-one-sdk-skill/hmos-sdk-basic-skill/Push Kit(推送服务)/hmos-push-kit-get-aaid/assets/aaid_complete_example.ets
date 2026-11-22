/**
 * AAID完整业务示例
 * 本示例演示在实际业务场景中如何使用AAID
 * 包括：初始化检查、获取AAID、错误处理、重试机制、业务集成
 */

import { AAID } from '@kit.PushKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'AAID_Complete_Example';

/**
 * AAID管理器类
 * 封装AAID相关的所有操作
 */
class AAIDManager {
  private aaid: string | null = null;
  private maxRetries: number = 3;
  private retryDelay: number = 1000;
  
  /**
   * 初始化AAID
   * @returns Promise<string> AAID字符串
   */
  async initialize(): Promise<string> {
    try {
      hilog.info(DOMAIN, TAG, 'Initializing AAID...');
      
      // 检查设备支持
      if (!this.isDeviceSupported()) {
        throw new Error('Device not supported');
      }
      
      // 获取AAID
      this.aaid = await this.getAAIDWithRetry();
      
      hilog.info(DOMAIN, TAG, 'AAID initialized successfully: %{public}s', this.aaid);
      return this.aaid;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to initialize AAID: %{public}s', e.message);
      throw e;
    }
  }
  
  /**
   * 获取当前AAID
   * @returns string | null AAID字符串
   */
  getCurrentAAID(): string | null {
    return this.aaid;
  }
  
  /**
   * 刷新AAID
   * @returns Promise<string> 新的AAID
   */
  async refreshAAID(): Promise<string> {
    try {
      hilog.info(DOMAIN, TAG, 'Refreshing AAID...');
      
      // 删除旧的AAID
      await this.deleteAAID();
      
      // 获取新的AAID
      this.aaid = await this.getAAIDWithRetry();
      
      hilog.info(DOMAIN, TAG, 'AAID refreshed: %{public}s', this.aaid);
      return this.aaid;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to refresh AAID: %{public}s', e.message);
      throw e;
    }
  }
  
  /**
   * 检查设备是否支持AAID
   * @returns boolean 是否支持
   */
  private isDeviceSupported(): boolean {
    // 这里可以添加设备类型和版本检查逻辑
    // 简化示例，默认返回true
    return true;
  }
  
  /**
   * 获取AAID（带重试机制）
   * @returns Promise<string> AAID字符串
   */
  private async getAAIDWithRetry(): Promise<string> {
    let lastError: BusinessError | null = null;
    
    for (let i = 0; i < this.maxRetries; i++) {
      try {
        const aaid = await AAID.getAAID();
        hilog.info(DOMAIN, TAG, 'Got AAID on attempt %{public}d', i + 1);
        return aaid;
      } catch (err) {
        lastError = err as BusinessError;
        hilog.warn(DOMAIN, TAG, 'Attempt %{public}d failed: %{public}s', i + 1, lastError.message);
        
        // 参数错误不需要重试
        if (lastError.code === 401) {
          throw lastError;
        }
        
        // 等待后重试
        if (i < this.maxRetries - 1) {
          await new Promise<void>(resolve => setTimeout(resolve, this.retryDelay));
        }
      }
    }
    
    throw lastError!;
  }
  
  /**
   * 删除AAID
   * @returns Promise<void>
   */
  private async deleteAAID(): Promise<void> {
    try {
      await AAID.deleteAAID();
      hilog.info(DOMAIN, TAG, 'AAID deleted successfully');
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to delete AAID: %{public}s', e.message);
      throw e;
    }
  }
}

/**
 * 业务场景1：应用启动时获取AAID
 */
async function scenario1_AppLaunch(): Promise<void> {
  hilog.info(DOMAIN, TAG, '=== Scenario 1: App Launch ===');
  
  const manager = new AAIDManager();
  
  try {
    const aaid = await manager.initialize();
    hilog.info(DOMAIN, TAG, 'App launched with AAID: %{public}s', aaid);
    
    // 可以将AAID存储到应用状态管理中
    // 或者上传到服务器进行注册
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN, TAG, 'Failed to get AAID on app launch: %{public}s', e.message);
    
    // 降级处理：使用自定义ID
    const customId = generateCustomAppId();
    hilog.warn(DOMAIN, TAG, 'Using custom ID as fallback: %{public}s', customId);
  }
}

/**
 * 业务场景2：推送服务注册前获取AAID
 */
async function scenario2_PushServiceRegistration(): Promise<void> {
  hilog.info(DOMAIN, TAG, '=== Scenario 2: Push Service Registration ===');
  
  const manager = new AAIDManager();
  
  try {
    const aaid = await manager.initialize();
    hilog.info(DOMAIN, TAG, 'Got AAID for push registration: %{public}s', aaid);
    
    // 这里可以继续进行推送服务的注册流程
    // 例如：await pushService.register(aaid);
    
    hilog.info(DOMAIN, TAG, 'Push service registered successfully');
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN, TAG, 'Push service registration failed: %{public}s', e.message);
  }
}

/**
 * 业务场景3：用户隐私保护 - 重置AAID
 */
async function scenario3_PrivacyProtection(): Promise<void> {
  hilog.info(DOMAIN, TAG, '=== Scenario 3: Privacy Protection ===');
  
  const manager = new AAIDManager();
  
  try {
    // 先初始化获取当前AAID
    await manager.initialize();
    const oldAaid = manager.getCurrentAAID();
    hilog.info(DOMAIN, TAG, 'Old AAID: %{public}s', oldAaid);
    
    // 用户选择重置AAID（隐私保护场景）
    const newAaid = await manager.refreshAAID();
    hilog.info(DOMAIN, TAG, 'New AAID after privacy reset: %{public}s', newAaid);
    
    // 通知服务器AAID已更新
    // await notifyServerAAIDChanged(oldAaid, newAaid);
    
    hilog.info(DOMAIN, TAG, 'Privacy protection: AAID has been reset');
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN, TAG, 'Failed to reset AAID: %{public}s', e.message);
  }
}

/**
 * 业务场景4：设备信息上报
 */
async function scenario4_DeviceInfoReport(): Promise<void> {
  hilog.info(DOMAIN, TAG, '=== Scenario 4: Device Info Report ===');
  
  const manager = new AAIDManager();
  
  try {
    const aaid = await manager.initialize();
    
    // 构建设备信息对象
    const deviceInfo = {
      aaid: aaid,
      timestamp: Date.now(),
      deviceType: getDeviceType(),
      appVersion: getAppVersion()
    };
    
    hilog.info(DOMAIN, TAG, 'Device info prepared: %{public}s', JSON.stringify(deviceInfo));
    
    // 上报到服务器
    // await reportDeviceInfo(deviceInfo);
    
    hilog.info(DOMAIN, TAG, 'Device info reported successfully');
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN, TAG, 'Failed to report device info: %{public}s', e.message);
  }
}

/**
 * 生成自定义应用ID（降级方案）
 * @returns string 自定义ID
 */
function generateCustomAppId(): string {
  const timestamp = Date.now();
  const random = Math.random().toString(36).substring(2, 15);
  return `custom_${timestamp}_${random}`;
}

/**
 * 获取设备类型
 * @returns string 设备类型
 */
function getDeviceType(): string {
  // 简化示例，实际应用中需要从系统API获取
  return 'Phone';
}

/**
 * 获取应用版本
 * @returns string 应用版本
 */
function getAppVersion(): string {
  // 简化示例，实际应用中需要从配置文件获取
  return '1.0.0';
}

// 主函数：运行所有场景示例
async function main(): Promise<void> {
  hilog.info(DOMAIN, TAG, 'Starting AAID complete example...');
  
  try {
    // 场景1：应用启动
    await scenario1_AppLaunch();
    
    // 场景2：推送服务注册
    await scenario2_PushServiceRegistration();
    
    // 场景3：隐私保护
    await scenario3_PrivacyProtection();
    
    // 场景4：设备信息上报
    await scenario4_DeviceInfoReport();
    
    hilog.info(DOMAIN, TAG, 'All scenarios completed successfully');
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN, TAG, 'Error in main: %{public}s', e.message);
  }
}

// 导出类和函数
export { 
  AAIDManager, 
  scenario1_AppLaunch, 
  scenario2_PushServiceRegistration, 
  scenario3_PrivacyProtection,
  scenario4_DeviceInfoReport 
};

// 执行主函数
main();