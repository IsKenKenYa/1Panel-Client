/**
 * 多网状态监听完整应用示例
 * 
 * 本示例演示如何在一个完整的场景中使用多网状态监听功能
 * 场景：视频直播应用，根据多网状态自动调整传输策略
 * 
 * 权限要求：ohos.permission.LINKTURBO
 * API版本：6.0.0(20)及以上
 * 系统能力：SystemCapability.Communication.NetworkBoost.Core
 */

import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { connection } from '@kit.NetworkKit';

/**
 * 视频直播管理器
 * 根据多网状态调整直播推流策略
 */
export class VideoLiveManager {
  private stateListener: MultiPathStateListener | null = null;
  private isLiveStreaming: boolean = false;
  private currentPathCount: number = 1; // 当前网络链路数量
  private transmitStrategy: 'single' | 'multi' = 'single';

  /**
   * 初始化直播管理器
   */
  async initialize(): Promise<void> {
    console.info('[VideoLiveManager] 初始化视频直播管理器');
    
    // 初始化多网状态监听
    this.stateListener = new MultiPathStateListener((data) => {
      this.handleMultiPathStateChange(data);
    });
    
    await this.stateListener.initialize();
    console.info('[VideoLiveManager] 多网状态监听初始化成功');
  }

  /**
   * 开始直播
   */
  async startLiveStream(): Promise<void> {
    if (this.isLiveStreaming) {
      console.warn('[VideoLiveManager] 直播已在进行中');
      return;
    }

    console.info('[VideoLiveManager] 开始直播推流');
    this.isLiveStreaming = true;

    // 根据当前多网状态选择传输策略
    if (this.currentPathCount > 1) {
      await this.startMultiPathTransmission();
    } else {
      await this.startSinglePathTransmission();
    }
  }

  /**
   * 停止直播
   */
  async stopLiveStream(): Promise<void> {
    if (!this.isLiveStreaming) {
      console.warn('[VideoLiveManager] 直播未在进行');
      return;
    }

    console.info('[VideoLiveManager] 停止直播推流');
    this.isLiveStreaming = false;
    
    // 停止推流
    await this.stopTransmission();
  }

  /**
   * 处理多网状态变化
   */
  private handleMultiPathStateChange(data: netHandover.MultiPathStateInfo): void {
    console.info(`[VideoLiveManager] 多网状态变化: state=${data.multiPathState}, cause=${data.cause}`);

    // 根据多网状态调整推流策略
    switch (data.multiPathState) {
      case netHandover.MultiPathState.MULTIPATH_CREATED:
        // 多网已建立，可以切换到多网传输
        this.currentPathCount = 2;
        if (this.isLiveStreaming && this.transmitStrategy === 'single') {
          this.upgradeToMultiPath();
        }
        break;

      case netHandover.MultiPathState.MULTIPATH_IDLE:
      case netHandover.MultiPathState.MULTIPATH_RELEASING:
        // 多网释放，切换到单网传输
        this.currentPathCount = 1;
        if (this.isLiveStreaming && this.transmitStrategy === 'multi') {
          this.downgradeToSinglePath();
        }
        break;

      case netHandover.MultiPathState.MULTIPATH_CREATING:
        // 多网建立中，保持当前策略
        console.info('[VideoLiveManager] 多网正在建立中，保持当前传输策略');
        break;

      case netHandover.PathState.PATH_SUSPENDED:
        // 多网挂起，切换到单网
        if (this.isLiveStreaming && this.transmitStrategy === 'multi') {
          console.warn('[VideoLiveManager] 多网挂起，切换到单网传输');
          this.downgradeToSinglePath();
        }
        break;
    }

    // 处理特殊情况
    if (data.cause === netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_NO_QUOTA) {
      console.warn('[VideoLiveManager] 配额耗尽，降低推流质量');
      this.reduceStreamQuality();
    }
  }

  /**
   * 升级到多网传输
   */
  private async upgradeToMultiPath(): Promise<void> {
    console.info('[VideoLiveManager] 升级到多网传输');
    
    try {
      // 暂停单网推流
      await this.pauseSinglePathStream();
      
      // 初始化多网推流
      await this.initializeMultiPathStream();
      
      // 开始多网推流
      await this.startMultiPathStream();
      
      this.transmitStrategy = 'multi';
      console.info('[VideoLiveManager] 多网传输已启动');
    } catch (error) {
      console.error('[VideoLiveManager] 升级到多网传输失败:', error);
      // 降级回单网
      await this.downgradeToSinglePath();
    }
  }

  /**
   * 降级到单网传输
   */
  private async downgradeToSinglePath(): Promise<void> {
    console.info('[VideoLiveManager] 降级到单网传输');
    
    try {
      // 暂停多网推流
      await this.pauseMultiPathStream();
      
      // 切换到单网推流
      await this.startSinglePathTransmission();
      
      this.transmitStrategy = 'single';
      console.info('[VideoLiveManager] 单网传输已启动');
    } catch (error) {
      console.error('[VideoLiveManager] 降级到单网传输失败:', error);
    }
  }

  /**
   * 开始单网传输
   */
  private async startSinglePathTransmission(): Promise<void> {
    console.info('[VideoLiveManager] 使用单网传输');
    // 业务逻辑：初始化单网推流
    this.transmitStrategy = 'single';
  }

  /**
   * 开始多网传输
   */
  private async startMultiPathTransmission(): Promise<void> {
    console.info('[VideoLiveManager] 使用多网传输');
    // 业务逻辑：初始化多网推流
    this.transmitStrategy = 'multi';
  }

  /**
   * 停止传输
   */
  private async stopTransmission(): Promise<void> {
    console.info('[VideoLiveManager] 停止传输');
    // 业务逻辑：停止推流
    this.transmitStrategy = 'single';
  }

  /**
   * 暂停单网推流
   */
  private async pauseSinglePathStream(): Promise<void> {
    console.info('[VideoLiveManager] 暂停单网推流');
    // 业务逻辑：暂停单网推流
  }

  /**
   * 初始化多网推流
   */
  private async initializeMultiPathStream(): Promise<void> {
    console.info('[VideoLiveManager] 初始化多网推流');
    // 业务逻辑：初始化多网推流参数
  }

  /**
   * 开始多网推流
   */
  private async startMultiPathStream(): Promise<void> {
    console.info('[VideoLiveManager] 开始多网推流');
    // 业务逻辑：开始多网推流
  }

  /**
   * 暂停多网推流
   */
  private async pauseMultiPathStream(): Promise<void> {
    console.info('[VideoLiveManager] 暂停多网推流');
    // 业务逻辑：暂停多网推流
  }

  /**
   * 降低推流质量
   */
  private reduceStreamQuality(): void {
    console.info('[VideoLiveManager] 降低推流质量');
    // 业务逻辑：降低分辨率、帧率等
  }

  /**
   * 销毁直播管理器
   */
  async destroy(): Promise<void> {
    console.info('[VideoLiveManager] 销毁视频直播管理器');
    
    // 停止直播
    await this.stopLiveStream();
    
    // 销毁多网监听器
    if (this.stateListener) {
      await this.stateListener.destroy();
      this.stateListener = null;
    }
    
    console.info('[VideoLiveManager] 视频直播管理器已销毁');
  }
}

/**
 * 多网状态监听器（封装版）
 */
export class MultiPathStateListener {
  private stateCallback: ((data: netHandover.MultiPathStateInfo) => void) | null = null;
  private userCallback: ((data: netHandover.MultiPathStateInfo) => void) | null = null;
  private isSubscribed: boolean = false;

  constructor(callback: (data: netHandover.MultiPathStateInfo) => void) {
    this.userCallback = callback;
  }

  async initialize(): Promise<void> {
    try {
      this.stateCallback = (data: netHandover.MultiPathStateInfo) => {
        this.logMultiPathState(data);
        if (this.userCallback) {
          this.userCallback(data);
        }
      };

      netHandover.on('multiPathStateChange', this.stateCallback);
      this.isSubscribed = true;
      console.info('[MultiPathStateListener] 订阅成功');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[MultiPathStateListener] 订阅失败: code=${error.code}`);
      this.handleSubscribeError(error);
    }
  }

  private logMultiPathState(data: netHandover.MultiPathStateInfo): void {
    console.info(`[MultiPathStateListener] State: ${data.multiPathState}, Cause: ${data.cause}`);
  }

  private handleSubscribeError(error: BusinessError): void {
    switch (error.code) {
      case 201:
        console.error('[MultiPathStateListener] 权限校验失败');
        break;
      case 801:
        console.error('[MultiPathStateListener] 设备不支持');
        break;
      default:
        console.error(`[MultiPathStateListener] 未知错误: ${error.code}`);
    }
  }

  async destroy(): Promise<void> {
    if (!this.isSubscribed) {
      return;
    }

    try {
      if (this.stateCallback) {
        netHandover.off('multiPathStateChange', this.stateCallback);
      }
      this.isSubscribed = false;
      this.stateCallback = null;
      this.userCallback = null;
      console.info('[MultiPathStateListener] 取消订阅成功');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[MultiPathStateListener] 取消订阅失败: ${error.code}`);
    }
  }
}

/**
 * 完整应用示例
 */
export async function videoLiveExample(): Promise<void> {
  // 创建直播管理器
  const liveManager = new VideoLiveManager();
  
  try {
    // 初始化
    await liveManager.initialize();
    console.info('[Example] 直播管理器初始化成功');
    
    // 开始直播
    await liveManager.startLiveStream();
    console.info('[Example] 直播已开始');
    
    // 模拟直播过程（实际应用中这里会是业务逻辑）
    await new Promise<void>((resolve) => setTimeout(resolve, 10000));
    
    // 停止直播
    await liveManager.stopLiveStream();
    console.info('[Example] 直播已停止');
    
  } catch (error) {
    console.error('[Example] 应用错误:', error);
  } finally {
    // 销毁管理器
    await liveManager.destroy();
    console.info('[Example] 直播管理器已销毁');
  }
}