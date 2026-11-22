/**
 * 错误处理示例
 * 本示例展示如何正确处理穿戴设备信息查询过程中可能出现的各种错误
 */

import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

export class DeviceInfoErrorHandler {
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  /**
   * 错误类型定义
   */
  enum ErrorType {
    NETWORK_ERROR = 'NETWORK_ERROR',
    PERMISSION_DENIED = 'PERMISSION_DENIED',
    DEVICE_NOT_CONNECTED = 'DEVICE_NOT_CONNECTED',
    SERVICE_NOT_APPLIED = 'SERVICE_NOT_APPLIED',
    ACCOUNT_ERROR = 'ACCOUNT_ERROR',
    PRIVACY_NOT_AGREED = 'PRIVACY_NOT_AGREED',
    CAPABILITY_NOT_SUPPORTED = 'CAPABILITY_NOT_SUPPORTED',
    INTERNAL_ERROR = 'INTERNAL_ERROR',
    UNKNOWN_ERROR = 'UNKNOWN_ERROR'
  }

  /**
   * 错误信息映射
   */
  private getErrorInfo(errorCode: number): { type: string, message: string, solution: string } {
    switch (errorCode) {
      case 401:
        return {
          type: ErrorType.PERMISSION_DENIED,
          message: '参数错误',
          solution: '检查传入参数是否正确'
        };
      
      case 801:
        return {
          type: ErrorType.CAPABILITY_NOT_SUPPORTED,
          message: '能力不支持',
          solution: '当前设备不支持此功能，仅支持Phone/Tablet'
        };
      
      case 1008500001:
        return {
          type: ErrorType.NETWORK_ERROR,
          message: '网络错误',
          solution: '检查网络连接状态，稍后重试'
        };
      
      case 1008500002:
        return {
          type: ErrorType.DEVICE_NOT_CONNECTED,
          message: '未绑定设备',
          solution: '先在华为健康应用中绑定设备'
        };
      
      case 1008500003:
        return {
          type: ErrorType.DEVICE_NOT_CONNECTED,
          message: '设备断开连接',
          solution: '重新连接设备'
        };
      
      case 1008500004:
        return {
          type: ErrorType.SERVICE_NOT_APPLIED,
          message: '应用未申请Wear Engine服务',
          solution: '在开发者联盟申请接入Wear Engine服务'
        };
      
      case 1008500005:
        return {
          type: ErrorType.PERMISSION_DENIED,
          message: '华为账号未授权',
          solution: '在华为健康应用中授权设备标识符权限'
        };
      
      case 1008500006:
        return {
          type: ErrorType.PRIVACY_NOT_AGREED,
          message: '用户隐私未同意',
          solution: '引导用户同意隐私协议'
        };
      
      case 1008500007:
        return {
          type: ErrorType.CAPABILITY_NOT_SUPPORTED,
          message: '设备能力不支持',
          solution: '查询设备能力后再调用相应功能'
        };
      
      case 1008500008:
        return {
          type: ErrorType.ACCOUNT_ERROR,
          message: '用户未登录华为账号',
          solution: '提示用户登录华为账号'
        };
      
      case 1008500009:
        return {
          type: ErrorType.ACCOUNT_ERROR,
          message: '获取账号信息失败',
          solution: '稍后重试或重新登录'
        };
      
      case 1008500010:
        return {
          type: ErrorType.PERMISSION_DENIED,
          message: '设备ID无效',
          solution: '使用正确的设备randomId'
        };
      
      case 1008509999:
        return {
          type: ErrorType.INTERNAL_ERROR,
          message: '内部错误',
          solution: '联系技术支持或稍后重试'
        };
      
      default:
        return {
          type: ErrorType.UNKNOWN_ERROR,
          message: `未知错误: ${errorCode}`,
          solution: '查看日志或联系技术支持'
        };
    }
  }

  /**
   * 处理getConnectedDevices错误
   */
  handleGetDevicesError(error: BusinessError): void {
    let errorInfo = this.getErrorInfo(error.code);
    
    console.error(`[${errorInfo.type}] ${errorInfo.message}`);
    console.error(`Solution: ${errorInfo.solution}`);
    console.error(`Original error: Code=${error.code}, Message=${error.message}`);

    // 根据错误类型执行降级方案
    this.executeFallbackStrategy(errorInfo.type, errorInfo.solution);
  }

  /**
   * 处理能力查询错误
   */
  handleCapabilityQueryError(error: BusinessError, capabilityName: string): void {
    let errorInfo = this.getErrorInfo(error.code);
    
    console.error(`[${errorInfo.type}] Failed to query ${capabilityName}`);
    console.error(`Message: ${errorInfo.message}`);
    console.error(`Solution: ${errorInfo.solution}`);

    this.executeFallbackStrategy(errorInfo.type, errorInfo.solution);
  }

  /**
   * 处理SN查询错误
   */
  handleSNQueryError(error: BusinessError): void {
    let errorInfo = this.getErrorInfo(error.code);
    
    console.error(`[${errorInfo.type}] Failed to query device SN`);
    console.error(`Message: ${errorInfo.message}`);
    console.error(`Solution: ${errorInfo.solution}`);

    // SN查询失败的特殊处理
    if (error.code === 1008500005) {
      console.warn('需要用户在华为健康应用中授权设备标识符权限');
      this.guideUserToAuthorizeSN();
    } else {
      this.executeFallbackStrategy(errorInfo.type, errorInfo.solution);
    }
  }

  /**
   * 执行降级策略
   */
  private executeFallbackStrategy(errorType: string, solution: string): void {
    switch (errorType) {
      case ErrorType.NETWORK_ERROR:
        // 降级方案：使用缓存数据或提示用户稍后重试
        console.warn('Fallback: Using cached data or retry later');
        this.retryWithDelay(3000);
        break;
      
      case ErrorType.DEVICE_NOT_CONNECTED:
        // 降级方案：提示用户连接设备
        console.warn('Fallback: Prompt user to connect device');
        this.promptUserToConnectDevice();
        break;
      
      case ErrorType.PERMISSION_DENIED:
        // 降级方案：提示用户授权
        console.warn('Fallback: Guide user to authorize permission');
        this.guideUserToAuthorize();
        break;
      
      case ErrorType.SERVICE_NOT_APPLIED:
        // 降级方案：提示开发者申请服务
        console.warn('Fallback: Developer should apply for Wear Engine service');
        this.notifyDeveloperToApplyService();
        break;
      
      case ErrorType.ACCOUNT_ERROR:
        // 降级方案：提示用户登录
        console.warn('Fallback: Prompt user to login HUAWEI ID');
        this.promptUserToLogin();
        break;
      
      case ErrorType.PRIVACY_NOT_AGREED:
        // 降级方案：引导用户同意隐私协议
        console.warn('Fallback: Guide user to agree privacy policy');
        this.guideUserToAgreePrivacy();
        break;
      
      case ErrorType.CAPABILITY_NOT_SUPPORTED:
        // 降级方案：跳过该功能或使用替代方案
        console.warn('Fallback: Skip this capability or use alternative solution');
        this.skipOrUseAlternative();
        break;
      
      case ErrorType.INTERNAL_ERROR:
        // 降级方案：记录日志并联系技术支持
        console.warn('Fallback: Log error and contact support');
        this.logErrorAndContactSupport();
        break;
      
      default:
        console.warn('Fallback: Unknown error, check logs');
        this.checkLogsForDetails();
    }
  }

  /**
   * 带延迟的重试机制
   */
  private retryWithDelay(delayMs: number): void {
    console.info(`Will retry after ${delayMs}ms`);
    // 实际实现中可以使用定时器
    // setTimeout(() => { retryOperation(); }, delayMs);
  }

  /**
   * 提示用户连接设备
   */
  private promptUserToConnectDevice(): void {
    console.info('User action required: Please connect your wearable device');
    // 可以弹出对话框或跳转到设备连接页面
  }

  /**
   * 引导用户授权
   */
  private guideUserToAuthorize(): void {
    console.info('User action required: Please authorize required permissions');
    // 可以跳转到权限授权页面
  }

  /**
   * 引导用户授权SN查询权限(特殊处理)
   */
  private guideUserToAuthorizeSN(): void {
    console.info('User action required: Please authorize device identifier permission in Huawei Health app');
    // 提供详细的授权引导流程
    console.info('Steps:');
    console.info('1. Open Huawei Health app');
    console.info('2. Go to device details page');
    console.info('3. Find and enable device identifier permission');
  }

  /**
   * 通知开发者申请服务
   */
  private notifyDeveloperToApplyService(): void {
    console.info('Developer action required: Please apply for Wear Engine service in Developer Alliance');
    // 提供申请链接或文档
  }

  /**
   * 提示用户登录华为账号
   */
  private promptUserToLogin(): void {
    console.info('User action required: Please login with HUAWEI ID');
    // 可以跳转到登录页面
  }

  /**
   * 引导用户同意隐私协议
   */
  private guideUserToAgreePrivacy(): void {
    console.info('User action required: Please agree to privacy policy');
    // 可以弹出隐私协议对话框
  }

  /**
   * 跳过不支持的能力或使用替代方案
   */
  private skipOrUseAlternative(): void {
    console.info('Action: Skip unsupported capability or use alternative solution');
    // 根据实际情况决定跳过或使用替代方案
  }

  /**
   * 记录错误并联系技术支持
   */
  private logErrorAndContactSupport(): void {
    console.info('Action: Error logged. Please contact technical support if issue persists');
    // 记录详细错误日志
  }

  /**
   * 检查日志详情
   */
  private checkLogsForDetails(): void {
    console.info('Action: Please check detailed logs for more information');
  }

  /**
   * 全局错误捕获示例
   */
  async safeQueryDeviceInfo(): Promise<void> {
    try {
      let deviceClient = wearEngine.getDeviceClient(this.context);
      let devices = await deviceClient.getConnectedDevices();
      
      if (devices.length > 0) {
        let device = devices[0];
        
        // 查询能力
        try {
          let p2pSupported = await device.isWearEngineCapabilitySupported(
            wearEngine.WearEngineCapability.P2P_COMMUNICATION
          );
          console.info(`P2P capability: ${p2pSupported}`);
        } catch (error) {
          this.handleCapabilityQueryError(error as BusinessError, 'P2P_COMMUNICATION');
        }
        
        // 查询SN
        try {
          let sn = await device.getSerialNumber();
          console.info(`Device SN: ${sn}`);
        } catch (error) {
          this.handleSNQueryError(error as BusinessError);
        }
      }
    } catch (error) {
      this.handleGetDevicesError(error as BusinessError);
    }
  }

  /**
   * 错误恢复策略示例
   */
  async queryWithRecovery(): Promise<void> {
    let retryCount = 0;
    let maxRetry = 3;
    
    while (retryCount < maxRetry) {
      try {
        let deviceClient = wearEngine.getDeviceClient(this.context);
        let devices = await deviceClient.getConnectedDevices();
        console.info('Query succeeded');
        return;
      } catch (error) {
        let err = error as BusinessError;
        
        // 网络错误可以重试
        if (err.code === 1008500001) {
          retryCount++;
          console.warn(`Retry ${retryCount}/${maxRetry} due to network error`);
          
          if (retryCount < maxRetry) {
            await this.delay(2000);
          } else {
            console.error('Max retry reached, giving up');
            this.handleGetDevicesError(err);
          }
        } else {
          // 其他错误不重试，直接处理
          this.handleGetDevicesError(err);
          return;
        }
      }
    }
  }

  /**
   * 延迟函数
   */
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}