/**
 * 多网状态监听示例
 * 
 * 本示例演示如何订阅多网状态变化事件，获取多网链路的状态信息
 * 
 * 权限要求：ohos.permission.LINKTURBO
 * API版本：6.0.0(20)及以上
 * 系统能力：SystemCapability.Communication.NetworkBoost.Core
 */

import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { connection } from '@kit.NetworkKit';

/**
 * 多网状态管理器
 * 负责订阅多网状态变化，并根据状态调整业务策略
 */
export class MultiPathStateListener {
  private stateCallback: ((data: netHandover.MultiPathStateInfo) => void) | null = null;
  private isSubscribed: boolean = false;

  /**
   * 初始化多网状态监听
   * 订阅多网状态变化事件
   */
  async initialize(): Promise<void> {
    try {
      // 定义状态变化回调函数
      this.stateCallback = (data: netHandover.MultiPathStateInfo) => {
        this.handleMultiPathStateChange(data);
      };

      // 订阅多网状态变化
      netHandover.on('multiPathStateChange', this.stateCallback);
      this.isSubscribed = true;
      
      console.info('[MultiPathStateListener] 订阅多网状态变化成功');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[MultiPathStateListener] 订阅失败: code=${error.code}, message=${error.message}`);
      this.handleSubscribeError(error);
    }
  }

  /**
   * 处理多网状态变化回调
   * @param data 多网状态信息
   */
  private handleMultiPathStateChange(data: netHandover.MultiPathStateInfo): void {
    console.info(`[MultiPathStateListener] ===== 多网状态变化 =====`);
    console.info(`[MultiPathStateListener] 多网状态: ${this.getMultiPathStateString(data.multiPathState)}`);
    console.info(`[MultiPathStateListener] 变化原因: ${this.getChangeCauseString(data.cause)}`);
    console.info(`[MultiPathStateListener] NetHandle ID: ${data.netHandle.netId}`);
    console.info(`[MultiPathStateListener] 链路状态: ${this.getPathStateString(data.pathState)}`);
    console.info(`[MultiPathStateListener] 链路类型: ${this.getPathTypeString(data.pathType)}`);

    // 根据多网状态执行业务逻辑
    this.handleMultiPathState(data.multiPathState);

    // 根据变化原因执行业务逻辑
    this.handleStateChangeCause(data.cause, data);
  }

  /**
   * 处理多网状态
   * @param state 多网状态
   */
  private handleMultiPathState(state: netHandover.MultiPathState): void {
    switch (state) {
      case netHandover.MultiPathState.MULTIPATH_IDLE:
        console.info('[MultiPathStateListener] 多网处于空闲状态，可以使用requestMultiPath发起多网请求');
        // 业务逻辑：更新UI，提示用户可以发起多网请求
        break;
        
      case netHandover.MultiPathState.MULTIPATH_CREATING:
        console.info('[MultiPathStateListener] 多网正在建立中，请等待');
        // 业务逻辑：显示加载状态
        break;
        
      case netHandover.MultiPathState.MULTIPATH_CREATED:
        console.info('[MultiPathStateListener] 多网已建立，可以开始使用多网传输数据');
        // 业务逻辑：开始多网数据传输
        this.startMultiPathTransmission();
        break;
        
      case netHandover.MultiPathState.MULTIPATH_RELEASING:
        console.info('[MultiPathStateListener] 多网正在释放中，请等待');
        // 业务逻辑：暂停数据传输，准备切换到单网模式
        break;
        
      default:
        console.warn(`[MultiPathStateListener] 未知的多网状态: ${state}`);
    }
  }

  /**
   * 处理状态变化原因
   * @param cause 变化原因
   * @param data 多网状态信息
   */
  private handleStateChangeCause(
    cause: netHandover.MultiPathChangeCause,
    data: netHandover.MultiPathStateInfo
  ): void {
    switch (cause) {
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_REQUEST_NORMAL:
        console.info('[MultiPathStateListener] 正常发起多网请求');
        break;
        
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_NORMAL:
        console.info('[MultiPathStateListener] 正常释放多网请求');
        break;
        
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_NETWORK:
        console.warn('[MultiPathStateListener] 网络原因释放多网，建议检查网络连接');
        // 业务逻辑：提示用户网络异常
        break;
        
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_USER_REFUSED:
        console.warn('[MultiPathStateListener] 用户操作开关释放多网');
        // 业务逻辑：提示用户多网功能已关闭
        break;
        
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_NO_QUOTA:
        console.warn('[MultiPathStateListener] 配额耗尽释放多网，建议使用单网模式');
        // 业务逻辑：切换到单网模式
        break;
        
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_POWER_CONSUMPTION:
        console.warn('[MultiPathStateListener] 功耗原因释放多网');
        // 业务逻辑：降低功耗，优化应用性能
        break;
        
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_INSUFFICIENT_TRAFFIC:
        console.warn('[MultiPathStateListener] 流量不足释放多网');
        // 业务逻辑：提示用户流量不足
        break;
        
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_CONFLICT:
        console.warn('[MultiPathStateListener] 场景冲突释放多网');
        // 业务逻辑：处理场景冲突，例如语音通话期间
        break;
        
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_SYS_FUSING:
        console.error('[MultiPathStateListener] 应用使用不规范，系统强制释放多网');
        // 业务逻辑：记录日志，优化多网使用策略
        break;
        
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_SYS_DEFAULT:
        console.warn('[MultiPathStateListener] 系统网络状态变化释放多网');
        // 业务逻辑：处理系统网络变化
        break;
        
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_SUSPEND_ENTER:
        console.warn('[MultiPathStateListener] 多网进入挂起状态，链路无法传输数据');
        // 业务逻辑：暂停数据传输，使用单网模式
        break;
        
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_SUSPEND_LEAVE:
        console.info('[MultiPathStateListener] 多网退出挂起状态，链路可以恢复数据传输');
        // 业务逻辑：恢复多网数据传输
        break;
        
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_CONN_PROPERTIES_UPDATE:
        console.info('[MultiPathStateListener] 多网链路连接属性更新，例如IP地址更新');
        // 业务逻辑：更新链路信息，可能需要重建连接
        break;
        
      default:
        console.info(`[MultiPathStateListener] 状态变化原因: ${cause}`);
    }
  }

  /**
   * 开始多网数据传输
   */
  private startMultiPathTransmission(): void {
    console.info('[MultiPathStateListener] 开始使用多网传输数据');
    // 业务逻辑：实现多网数据传输
  }

  /**
   * 获取多网状态字符串
   */
  private getMultiPathStateString(state: netHandover.MultiPathState): string {
    switch (state) {
      case netHandover.MultiPathState.MULTIPATH_IDLE:
        return 'IDLE (空闲)';
      case netHandover.MultiPathState.MULTIPATH_CREATING:
        return 'CREATING (建立中)';
      case netHandover.MultiPathState.MULTIPATH_CREATED:
        return 'CREATED (已建立)';
      case netHandover.MultiPathState.MULTIPATH_RELEASING:
        return 'RELEASING (释放中)';
      default:
        return `UNKNOWN (${state})`;
    }
  }

  /**
   * 获取变化原因字符串
   */
  private getChangeCauseString(cause: netHandover.MultiPathChangeCause): string {
    const causeMap: Record<number, string> = {
      0: 'REQUEST_NORMAL (正常请求)',
      50: 'RELEASE_NORMAL (正常释放)',
      51: 'RELEASE_NETWORK (网络原因)',
      52: 'RELEASE_USER_REFUSED (用户拒绝)',
      53: 'RELEASE_NO_QUOTA (配额耗尽)',
      54: 'RELEASE_POWER_CONSUMPTION (功耗原因)',
      55: 'RELEASE_INSUFFICIENT_TRAFFIC (流量不足)',
      56: 'RELEASE_CONFLICT (场景冲突)',
      57: 'RELEASE_SYS_FUSING (系统熔断)',
      99: 'RELEASE_SYS_DEFAULT (系统默认)',
      100: 'SUSPEND_ENTER (进入挂起)',
      101: 'SUSPEND_LEAVE (退出挂起)',
      102: 'CONN_PROPERTIES_UPDATE (连接属性更新)',
    };
    return causeMap[cause] || `UNKNOWN (${cause})`;
  }

  /**
   * 获取链路状态字符串
   */
  private getPathStateString(state: netHandover.PathState): string {
    switch (state) {
      case netHandover.PathState.PATH_IDLE:
        return 'IDLE (空闲)';
      case netHandover.PathState.PATH_CONNECTED:
        return 'CONNECTED (已连接)';
      case netHandover.PathState.PATH_SUSPENDED:
        return 'SUSPENDED (挂起)';
      default:
        return `UNKNOWN (${state})`;
    }
  }

  /**
   * 获取链路类型字符串
   */
  private getPathTypeString(pathType: number): string {
    // PathType引用的是netQuality.PathType
    const pathTypeMap: Record<number, string> = {
      0: 'UNKNOWN (未知)',
      1: 'WIFI (WiFi网络)',
      2: 'CELLULAR (蜂窝网络)',
      3: 'ETHERNET (以太网)',
    };
    return pathTypeMap[pathType] || `UNKNOWN (${pathType})`;
  }

  /**
   * 处理订阅错误
   */
  private handleSubscribeError(error: BusinessError): void {
    switch (error.code) {
      case 201:
        console.error('[MultiPathStateListener] 权限校验失败，请检查是否申请了ohos.permission.LINKTURBO权限');
        // 业务逻辑：提示用户授权
        break;
        
      case 401:
        console.error('[MultiPathStateListener] 参数检查失败，传入的回调函数无效');
        // 业务逻辑：检查回调函数
        break;
        
      case 801:
        console.error('[MultiPathStateListener] 设备不支持该API');
        // 业务逻辑：降级为单网模式
        break;
        
      case 1013600001:
        console.error('[MultiPathStateListener] 内部处理异常，请稍后重试');
        // 业务逻辑：延迟重试
        break;
        
      case 1013600002:
        console.error('[MultiPathStateListener] 系统处理异常，请检查网络管理服务是否正常');
        // 业务逻辑：提示用户检查系统状态
        break;
        
      default:
        console.error(`[MultiPathStateListener] 订阅失败，未知错误: code=${error.code}`);
    }
  }

  /**
   * 销毁监听器
   * 取消订阅多网状态变化
   */
  async destroy(): Promise<void> {
    if (!this.isSubscribed) {
      console.warn('[MultiPathStateListener] 未订阅多网状态变化');
      return;
    }

    try {
      if (this.stateCallback) {
        // 取消指定回调
        netHandover.off('multiPathStateChange', this.stateCallback);
        console.info('[MultiPathStateListener] 取消订阅多网状态变化成功');
      }
      this.isSubscribed = false;
      this.stateCallback = null;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[MultiPathStateListener] 取消订阅失败: code=${error.code}, message=${error.message}`);
    }
  }

  /**
   * 取消所有订阅
   */
  async unsubscribeAll(): Promise<void> {
    try {
      netHandover.off('multiPathStateChange');
      this.isSubscribed = false;
      this.stateCallback = null;
      console.info('[MultiPathStateListener] 取消所有订阅成功');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[MultiPathStateListener] 取消所有订阅失败: code=${error.code}, message=${error.message}`);
    }
  }
}

/**
 * 使用示例
 */
export async function multiPathStateListenerExample(): Promise<void> {
  // 创建监听器实例
  const listener = new MultiPathStateListener();
  
  try {
    // 初始化监听器
    await listener.initialize();
    console.info('[Example] 多网状态监听器已启动');
    
    // 业务运行期间，监听器会自动接收多网状态变化回调
    // ...
    
    // 业务结束时，销毁监听器
    // await listener.destroy();
  } catch (error) {
    console.error('[Example] 初始化失败:', error);
  }
}