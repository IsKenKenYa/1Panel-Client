import { netHandover, HandoverInfo } from '@kit.NetworkBoostKit';
import { connection } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceKitKit';

const TAG = '[NetworkHandoverFallback]';
const DOMAIN = 0xFF00;

export class NetworkHandoverFallback {
  private useFallback: boolean = false;
  private networkCallback: connection.NetConnection | null = null;
  private handoverCallback: ((info: HandoverInfo) => void) | null = null;

  async initialize(): Promise<void> {
    try {
      // 检查API是否支持
      if (this.checkApiSupport()) {
        await this.subscribeWithBoostKit();
      } else {
        throw new Error('Network Boost Kit API not supported');
      }
    } catch (err) {
      hilog.warn(DOMAIN, TAG, `Network Boost Kit not available: ${(err as Error).message}`);
      hilog.info(DOMAIN, TAG, 'Falling back to basic network monitoring');
      this.useFallback = true;
      this.startBasicNetworkMonitor();
    }
  }

  private checkApiSupport(): boolean {
    try {
      // 检查netHandover模块是否存在
      return netHandover !== undefined && typeof netHandover.on === 'function';
    } catch (err) {
      hilog.error(DOMAIN, TAG, `API support check failed: ${(err as Error).message}`);
      return false;
    }
  }

  private async subscribeWithBoostKit(): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        this.handoverCallback = (info: HandoverInfo) => {
          this.handleHandoverInfo(info);
        };
        
        netHandover.on('handoverChange', this.handoverCallback);
        hilog.info(DOMAIN, TAG, 'Successfully subscribed with Network Boost Kit');
        resolve();
      } catch (err) {
        const error = err as BusinessError;
        hilog.error(DOMAIN, TAG, `Subscribe failed: ${error.code}, ${error.message}`);
        
        // 如果是权限问题或API不支持，使用降级方案
        if (error.code === 201 || error.code === 801) {
          this.useFallback = true;
          this.startBasicNetworkMonitor();
          resolve();
        } else {
          reject(err);
        }
      }
    });
  }

  private handleHandoverInfo(info: HandoverInfo): void {
    try {
      if (info.handoverStart) {
        hilog.info(DOMAIN, TAG, 'Handover started');
        hilog.info(DOMAIN, TAG, `Timeout: ${info.handoverStart.expires}s`);
        
        // 调整数传策略
        this.adjustDataTransmission(info.handoverStart.dataSpeedAction);
      } else if (info.handoverComplete) {
        hilog.info(DOMAIN, TAG, 'Handover completed');
        hilog.info(DOMAIN, TAG, `Result: ${info.handoverComplete.result}`);
        
        // 重建连接
        if (info.handoverComplete.result === 0) {
          this.rebuildConnection(info.handoverComplete.reEstAction);
        } else {
          this.handleHandoverError(info.handoverComplete.result);
        }
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Error handling handover info: ${(err as Error).message}`);
    }
  }

  private adjustDataTransmission(dataSpeedAction: any): void {
    hilog.info(DOMAIN, TAG, `Adjusting transmission: ${dataSpeedAction.dataSpeedSimpleAction}`);
    // 根据发包建议调整数据传输策略
  }

  private rebuildConnection(reEstAction: number): void {
    hilog.info(DOMAIN, TAG, `Rebuilding connection with action: ${reEstAction}`);
    // 根据重建类型重建连接
  }

  private handleHandoverError(result: number): void {
    hilog.error(DOMAIN, TAG, `Handover error: ${result}`);
    // 处理迁移错误
  }

  private startBasicNetworkMonitor(): void {
    try {
      // 使用基础网络监听作为降级方案
      this.networkCallback = connection.createNetConnection();
      
      this.networkCallback.register((err) => {
        if (err) {
          hilog.error(DOMAIN, TAG, `Network monitor registration failed: ${err.message}`);
          return;
        }
        hilog.info(DOMAIN, TAG, 'Basic network monitor registered');
      });

      this.networkCallback.on('netAvailable', (data) => {
        hilog.info(DOMAIN, TAG, `Network available: ${data.netHandle.netId}`);
        this.onNetworkChanged(data.netHandle);
      });

      this.networkCallback.on('netLost', (data) => {
        hilog.info(DOMAIN, TAG, `Network lost: ${data.netHandle.netId}`);
        this.onNetworkLost(data.netHandle);
      });

      this.networkCallback.on('netCapabilitiesChange', (data) => {
        hilog.info(DOMAIN, TAG, `Network capabilities changed: ${data.netHandle.netId}`);
        this.onNetworkCapabilitiesChanged(data);
      });

    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to start basic network monitor: ${(err as Error).message}`);
    }
  }

  private onNetworkChanged(netHandle: connection.NetHandle): void {
    hilog.info(DOMAIN, TAG, `Network changed to: ${netHandle.netId}`);
    // 网络变化时，建议应用重建连接
    // 注意：基础网络监听无法提供迁移建议，应用需要自行判断是否重建
    this.rebuildConnectionOnBasicMonitor();
  }

  private onNetworkLost(netHandle: connection.NetHandle): void {
    hilog.warn(DOMAIN, TAG, `Network lost: ${netHandle.netId}`);
    // 网络丢失时，应用应等待网络恢复或提示用户
    this.waitForNetworkRecovery();
  }

  private onNetworkCapabilitiesChanged(data: connection.NetCapabilityInfo): void {
    hilog.info(DOMAIN, TAG, `Network capabilities changed for: ${data.netHandle.netId}`);
    // 网络能力变化时，应用可根据新的能力调整策略
  }

  private rebuildConnectionOnBasicMonitor(): void {
    hilog.info(DOMAIN, TAG, 'Rebuilding connection (basic monitor mode)');
    // 在降级模式下，应用需要自行判断是否重建连接
    // 无法获得系统的迁移建议
  }

  private waitForNetworkRecovery(): void {
    hilog.info(DOMAIN, TAG, 'Waiting for network recovery');
    // 等待网络恢复
    // 可以实现重试机制
  }

  cleanup(): void {
    if (this.useFallback) {
      this.stopBasicNetworkMonitor();
    } else {
      this.unsubscribeBoostKit();
    }
  }

  private stopBasicNetworkMonitor(): void {
    if (this.networkCallback) {
      try {
        this.networkCallback.unregister((err) => {
          if (err) {
            hilog.error(DOMAIN, TAG, `Network monitor unregistration failed: ${err.message}`);
          } else {
            hilog.info(DOMAIN, TAG, 'Network monitor unregistered');
          }
        });
      } catch (err) {
        hilog.error(DOMAIN, TAG, `Failed to stop network monitor: ${(err as Error).message}`);
      }
      this.networkCallback = null;
    }
  }

  private unsubscribeBoostKit(): void {
    try {
      if (this.handoverCallback) {
        netHandover.off('handoverChange', this.handoverCallback);
        this.handoverCallback = null;
        hilog.info(DOMAIN, TAG, 'Unsubscribed from Network Boost Kit');
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to unsubscribe: ${(err as Error).message}`);
    }
  }

  isUsingFallback(): boolean {
    return this.useFallback;
  }
}

// 使用示例
export async function fallbackExample() {
  const networkMonitor = new NetworkHandoverFallback();
  
  // 初始化，会自动选择最佳方案
  await networkMonitor.initialize();
  
  if (networkMonitor.isUsingFallback()) {
    console.log('Using basic network monitoring (fallback mode)');
  } else {
    console.log('Using Network Boost Kit (enhanced mode)');
  }
  
  // 应用业务逻辑...
  
  // 清理资源
  // networkMonitor.cleanup();
}