/**
 * 网络场景识别回调完整示例代码
 * 功能：订阅网络场景识别信息变化，处理不同网络场景和数传策略建议
 */

import { netQuality } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 网络场景管理类
 */
class NetworkSceneManager {
  private isSubscribed: boolean = false;
  private callback: (list: Array<netQuality.NetworkScene>) => void;

  constructor() {
    this.callback = this.handleNetworkSceneChange.bind(this);
  }

  /**
   * 订阅网络场景识别信息
   */
  subscribe(): void {
    if (this.isSubscribed) {
      console.warn('Already subscribed to network scene change');
      return;
    }

    try {
      netQuality.on('netSceneChange', this.callback);
      this.isSubscribed = true;
      console.info('[NetworkSceneManager] Successfully subscribed to netSceneChange');
    } catch (err) {
      const error = err as BusinessError;
      console.error('[NetworkSceneManager] Failed to subscribe to netSceneChange');
      console.error(`  Error code: ${error.code}, Message: ${error.message}`);
      
      // 错误处理
      this.handleSubscribeError(error);
    }
  }

  /**
   * 取消订阅网络场景识别信息
   */
  unsubscribe(): void {
    if (!this.isSubscribed) {
      console.warn('[NetworkSceneManager] Not subscribed, no need to unsubscribe');
      return;
    }

    try {
      netQuality.off('netSceneChange', this.callback);
      this.isSubscribed = false;
      console.info('[NetworkSceneManager] Successfully unsubscribed from netSceneChange');
    } catch (err) {
      const error = err as BusinessError;
      console.error('[NetworkSceneManager] Failed to unsubscribe from netSceneChange');
      console.error(`  Error code: ${error.code}, Message: ${error.message}`);
    }
  }

  /**
   * 取消所有订阅（不指定 callback）
   */
  unsubscribeAll(): void {
    try {
      netQuality.off('netSceneChange');
      this.isSubscribed = false;
      console.info('[NetworkSceneManager] Successfully unsubscribed all callbacks from netSceneChange');
    } catch (err) {
      const error = err as BusinessError;
      console.error('[NetworkSceneManager] Failed to unsubscribe all callbacks');
      console.error(`  Error code: ${error.code}, Message: ${error.message}`);
    }
  }

  /**
   * 网络场景变化回调处理函数
   */
  private handleNetworkSceneChange(list: Array<netQuality.NetworkScene>): void {
    console.info(`[NetworkSceneManager] Received network scene change, count: ${list.length}`);
    
    if (list.length === 0) {
      console.warn('[NetworkSceneManager] Network scene list is empty');
      return;
    }

    // 处理每个路径的网络场景信息
    list.forEach((sceneInfo: netQuality.NetworkScene, index: number) => {
      console.info(`[NetworkSceneManager] Processing scene info [${index}]`);
      this.processSceneInfo(sceneInfo);
    });
  }

  /**
   * 处理单个网络场景信息
   */
  private processSceneInfo(sceneInfo: netQuality.NetworkScene): void {
    // 1. 处理路径类型
    const pathTypeStr = this.getPathTypeString(sceneInfo.pathType);
    console.info(`  Path type: ${pathTypeStr}`);

    // 2. 处理场景类型
    const sceneStr = this.getSceneString(sceneInfo.scene);
    console.info(`  Scene: ${sceneStr}`);
    this.handleScene(sceneInfo.scene);

    // 3. 处理数传策略建议
    if (sceneInfo.recommendedAction) {
      const actionStr = this.getRecommendedActionString(sceneInfo.recommendedAction);
      console.info(`  Recommended action: ${actionStr}`);
      this.handleRecommendedAction(sceneInfo.recommendedAction);
    }

    // 4. 处理弱信号预测信息
    if (sceneInfo.weakSignalPrediction) {
      this.handleWeakSignalPrediction(sceneInfo.weakSignalPrediction);
    }
  }

  /**
   * 处理场景类型
   */
  private handleScene(scene: netQuality.Scene): void {
    switch (scene) {
      case 'normal':
        console.info('[NetworkSceneManager] Network is normal - resume default strategy');
        // 正常场景：恢复默认策略
        this.resumeNormalStrategy();
        break;
      
      case 'congestion':
        console.warn('[NetworkSceneManager] Network is congested - reduce data rate');
        // 拥塞场景：降低发包速率、降低码率
        this.handleCongestion();
        break;
      
      case 'frequentHandover':
        console.warn('[NetworkSceneManager] Network is frequent handover - pause critical operations');
        // 频繁切换场景：缓存数据、暂停关键操作
        this.handleFrequentHandover();
        break;
      
      case 'weakSignal':
        console.error('[NetworkSceneManager] Network is weak signal - use conservative strategy');
        // 弱信号场景：大幅降低码率、增加缓存
        this.handleWeakSignal();
        break;
      
      default:
        console.warn('[NetworkSceneManager] Unknown scene type:', scene);
        break;
    }
  }

  /**
   * 处理数传策略建议
   */
  private handleRecommendedAction(action: netQuality.RecommendedAction): void {
    switch (action) {
      case 'doCaching':
        console.info('[NetworkSceneManager] Execute caching strategy');
        this.executeCaching();
        break;
      
      case 'suspendData':
        console.warn('[NetworkSceneManager] Suspend data transmission');
        this.suspendDataTransmission();
        break;
      
      case 'decreaseData':
        console.info('[NetworkSceneManager] Decrease data transmission rate');
        this.decreaseDataRate();
        break;
      
      case 'increaseData':
        console.info('[NetworkSceneManager] Increase data transmission rate');
        this.increaseDataRate();
        break;
      
      case 'keepData':
        console.info('[NetworkSceneManager] Keep current data transmission rate');
        // 保持当前策略不变
        break;
      
      default:
        console.warn('[NetworkSceneManager] Unknown recommended action:', action);
        break;
    }
  }

  /**
   * 处理弱信号预测信息
   */
  private handleWeakSignalPrediction(prediction: netQuality.WeakSignalPrediction): void {
    console.info('[NetworkSceneManager] Weak signal prediction received');
    
    if (!prediction.isLastPredictionValid) {
      console.warn('[NetworkSceneManager] Prediction is invalid, ignore');
      return;
    }

    const startTime = prediction.startTime;
    const duration = prediction.duration;

    console.info(`  Will enter weak signal in ${startTime} seconds`);
    console.info(`  Will stay for ${duration} seconds`);

    if (startTime === 0 || duration === 0) {
      console.warn('[NetworkSceneManager] Invalid prediction values, ignore');
      return;
    }

    // 提前调整策略
    this.prepareForWeakSignal(startTime, duration);
  }

  /**
   * 错误处理
   */
  private handleSubscribeError(error: BusinessError): void {
    switch (error.code) {
      case 201:
        console.error('[NetworkSceneManager] Permission denied - apply for ohos.permission.GET_NETWORK_INFO');
        // 提示用户申请权限
        this.requestPermission();
        break;
      
      case 401:
        console.error('[NetworkSceneManager] Parameter check failed - verify callback function');
        // 参数校验失败，使用默认策略
        this.useDefaultStrategy();
        break;
      
      case 801:
        console.error('[NetworkSceneManager] Device does not support this API');
        // 设备不支持，使用默认策略
        this.useDefaultStrategy();
        break;
      
      default:
        console.error('[NetworkSceneManager] Unknown error:', error.message);
        this.useDefaultStrategy();
        break;
    }
  }

  /**
   * 业务策略方法（示例，实际业务中需要实现）
   */
  private resumeNormalStrategy(): void {
    console.info('[Strategy] Resume normal strategy: default bitrate, normal cache');
  }

  private handleCongestion(): void {
    console.info('[Strategy] Handle congestion: reduce bitrate to 50%, increase cache');
  }

  private handleFrequentHandover(): void {
    console.info('[Strategy] Handle frequent handover: pause live streaming, cache more data');
  }

  private handleWeakSignal(): void {
    console.info('[Strategy] Handle weak signal: reduce bitrate to 25%, maximize cache');
  }

  private executeCaching(): void {
    console.info('[Strategy] Execute caching: prefetch next 30s content');
  }

  private suspendDataTransmission(): void {
    console.info('[Strategy] Suspend data transmission: pause upload/download');
  }

  private decreaseDataRate(): void {
    console.info('[Strategy] Decrease data rate: reduce bitrate by 20%');
  }

  private increaseDataRate(): void {
    console.info('[Strategy] Increase data rate: increase bitrate by 20%');
  }

  private prepareForWeakSignal(startTime: number, duration: number): void {
    console.info(`[Strategy] Prepare for weak signal: increase cache in ${startTime}s, expect duration ${duration}s`);
    // 根据 startTime 和 duration 提前调整策略
    // 例如：在 startTime 秒内增加缓存，准备应对 duration 秒的弱信号
  }

  private requestPermission(): void {
    console.warn('[Strategy] Request permission from user');
    // 实际应用中需要引导用户授权
  }

  private useDefaultStrategy(): void {
    console.warn('[Strategy] Use default conservative strategy');
    // 使用保守的默认策略：较低码率、较大缓存
  }

  /**
   * 获取路径类型字符串
   */
  private getPathTypeString(pathType: netQuality.PathType): string {
    switch (pathType) {
      case 0: return 'CELLULAR_PRIMARY';
      case 1: return 'CELLULAR_SECONDARY';
      case 2: return 'WIFI_PRIMARY';
      case 3: return 'WIFI_SECONDARY';
      default: return 'UNKNOWN';
    }
  }

  /**
   * 获取场景类型字符串
   */
  private getSceneString(scene: netQuality.Scene): string {
    return scene;
  }

  /**
   * 获取数传策略建议字符串
   */
  private getRecommendedActionString(action: netQuality.RecommendedAction): string {
    if (typeof action === 'string') {
      return action;
    }
    return 'UNKNOWN';
  }
}

/**
 * 使用示例
 */
export function exampleUsage(): void {
  console.info('=== Network Scene Callback Example ===');

  // 创建网络场景管理器
  const manager = new NetworkSceneManager();

  // 订阅网络场景识别
  manager.subscribe();

  // 模拟业务运行一段时间
  setTimeout(() => {
    console.info('Business running for 30 seconds...');
  }, 30000);

  // 业务结束后取消订阅
  setTimeout(() => {
    console.info('Business finished, unsubscribe network scene');
    manager.unsubscribe();
  }, 60000);
}

/**
 * 测试入口
 */
@Entry
@Component
struct NetworkSceneTest {
  private manager: NetworkSceneManager = new NetworkSceneManager();

  build() {
    Column() {
      Text('Network Scene Callback Test')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 })

      Button('Subscribe')
        .fontSize(18)
        .margin({ top: 20 })
        .onClick(() => {
          this.manager.subscribe();
        })

      Button('Unsubscribe')
        .fontSize(18)
        .margin({ top: 10 })
        .onClick(() => {
          this.manager.unsubscribe();
        })

      Button('Unsubscribe All')
        .fontSize(18)
        .margin({ top: 10 })
        .onClick(() => {
          this.manager.unsubscribeAll();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}