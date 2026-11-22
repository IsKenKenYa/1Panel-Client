import { netHandover, HandoverInfo, HandoverStart, HandoverComplete, ErrorResult, ReEstAction, DataSpeedAction } from '@kit.NetworkBoostKit';
import { connection, NetHandle } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceKitKit';

const TAG = '[NetworkHandoverExample]';
const DOMAIN = 0xFF00;

enum HandoverState {
  IDLE = 'IDLE',
  STARTED = 'STARTED',
  COMPLETED = 'COMPLETED'
}

export class NetworkHandoverExample {
  private handoverState: HandoverState = HandoverState.IDLE;
  private handoverCallback: (info: HandoverInfo) => void;
  private isSubscribed: boolean = false;

  constructor() {
    this.handoverCallback = this.handleHandoverInfo.bind(this);
  }

  subscribeHandover(): void {
    if (this.isSubscribed) {
      hilog.warn(DOMAIN, TAG, 'Already subscribed to handover events');
      return;
    }

    try {
      netHandover.on('handoverChange', this.handoverCallback);
      this.isSubscribed = true;
      hilog.info(DOMAIN, TAG, 'Successfully subscribed to handover events');
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, `Failed to subscribe: ${error.code}, ${error.message}`);
      this.handleSubscribeError(error);
    }
  }

  unsubscribeHandover(): void {
    if (!this.isSubscribed) {
      hilog.warn(DOMAIN, TAG, 'Not subscribed to handover events');
      return;
    }

    try {
      netHandover.off('handoverChange', this.handoverCallback);
      this.isSubscribed = false;
      this.handoverState = HandoverState.IDLE;
      hilog.info(DOMAIN, TAG, 'Successfully unsubscribed from handover events');
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, `Failed to unsubscribe: ${error.code}, ${error.message}`);
    }
  }

  private handleHandoverInfo(info: HandoverInfo): void {
    try {
      if (info.handoverStart) {
        this.onHandoverStart(info.handoverStart);
      } else if (info.handoverComplete) {
        this.onHandoverComplete(info.handoverComplete);
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Error in handover callback: ${(err as Error).message}`);
    }
  }

  private onHandoverStart(startInfo: HandoverStart): void {
    this.handoverState = HandoverState.STARTED;
    hilog.info(DOMAIN, TAG, '=== Handover Started ===');
    hilog.info(DOMAIN, TAG, `Timeout: ${startInfo.expires} seconds`);
    hilog.info(DOMAIN, TAG, `Data speed action: ${startInfo.dataSpeedAction.dataSpeedSimpleAction}`);
    
    if (startInfo.dataSpeedAction) {
      this.adjustDataTransmission(startInfo.dataSpeedAction, 'old');
    }
  }

  private onHandoverComplete(completeInfo: HandoverComplete): void {
    this.handoverState = HandoverState.COMPLETED;
    hilog.info(DOMAIN, TAG, '=== Handover Completed ===');
    hilog.info(DOMAIN, TAG, `Result: ${this.getErrorResultDescription(completeInfo.result)}`);
    hilog.info(DOMAIN, TAG, `Continue: ${completeInfo.handoverContinue}`);
    hilog.info(DOMAIN, TAG, `Old path lifetime: ${completeInfo.oldPathLifetime} seconds`);
    hilog.info(DOMAIN, TAG, `Path type changed: ${completeInfo.pathTypeChanged}`);

    if (completeInfo.result === ErrorResult.ERROR_NONE) {
      hilog.info(DOMAIN, TAG, 'Handover succeeded, rebuilding connection...');
      this.rebuildConnection(completeInfo.reEstAction, completeInfo.newNetHandle);
      
      if (completeInfo.newDataSpeedAction) {
        this.adjustDataTransmission(completeInfo.newDataSpeedAction, 'new');
      }
    } else {
      hilog.error(DOMAIN, TAG, `Handover failed with result: ${completeInfo.result}`);
      this.handleHandoverError(completeInfo.result);
    }

    if (completeInfo.oldDataSpeedAction) {
      this.adjustDataTransmission(completeInfo.oldDataSpeedAction, 'old');
    }
  }

  private adjustDataTransmission(action: DataSpeedAction, path: string): void {
    hilog.info(DOMAIN, TAG, `Adjusting ${path} path transmission:`);
    hilog.info(DOMAIN, TAG, `  Simple action: ${action.dataSpeedSimpleAction}`);
    hilog.info(DOMAIN, TAG, `  Up bandwidth: ${action.linkUpBandwidth} bps`);
    hilog.info(DOMAIN, TAG, `  Down bandwidth: ${action.linkDownBandwidth} bps');
    
    // 根据带宽建议调整数据发送速率
    // 实际应用中应根据action.dataSpeedSimpleAction调整发包策略
  }

  private rebuildConnection(reEstAction: ReEstAction, newNetHandle?: NetHandle): void {
    hilog.info(DOMAIN, TAG, `Rebuild action: ${this.getReEstActionDescription(reEstAction)}`);
    
    if (newNetHandle) {
      hilog.info(DOMAIN, TAG, `New net handle available: ${newNetHandle.netId}`);
    }

    switch (reEstAction) {
      case ReEstAction.DEFAULT:
        this.rebuildWithSameIP();
        break;
        
      case ReEstAction.QUERY_DNS:
        this.rebuildWithDNSQuery();
        break;
        
      case ReEstAction.CHANGE_REMOTE_IP:
        this.rebuildWithNewIP();
        break;
        
      case ReEstAction.CHANGE_IP_VERSION:
        this.rebuildWithIPVersionChange();
        break;
        
      case ReEstAction.NO_EST:
        this.retryOnOldPath();
        break;
        
      default:
        hilog.warn(DOMAIN, TAG, `Unknown rebuild action: ${reEstAction}`);
    }
  }

  private rebuildWithSameIP(): void {
    hilog.info(DOMAIN, TAG, 'Rebuilding connection with same remote IP');
    // 使用相同的远端IP重建链路
    // this.httpClient.reconnect();
  }

  private rebuildWithDNSQuery(): void {
    hilog.info(DOMAIN, TAG, 'Rebuilding connection with DNS query');
    // 链路类型变化（如WiFi<->蜂窝），需要重新查询DNS
    // this.dnsResolver.resolve(this.hostname);
  }

  private rebuildWithNewIP(): void {
    hilog.info(DOMAIN, TAG, 'Rebuilding connection with different remote IP');
    // 使用不同的远端IP重建链路
    // this.httpClient.connect(this.backupServerUrl);
  }

  private rebuildWithIPVersionChange(): void {
    hilog.info(DOMAIN, TAG, 'Rebuilding connection with IP version change');
    // 修改IP类型（IPv4/IPv6）重建链路
    // this.connection.switchIPVersion();
  }

  private retryOnOldPath(): void {
    hilog.info(DOMAIN, TAG, 'Retrying on old path');
    // 在老链路上立即重试
    // this.httpClient.retry();
  }

  private handleHandoverError(result: ErrorResult): void {
    switch (result) {
      case ErrorResult.ERROR_HANDOVER_TIMEOUT:
        hilog.error(DOMAIN, TAG, 'Handover timeout, will retry later');
        setTimeout(() => {
          this.retryAfterDelay(2000);
        }, 2000);
        break;
        
      case ErrorResult.ERROR_NEW_PATH_ACTIVATION_FAILED:
        hilog.error(DOMAIN, TAG, 'New path activation failed, fallback to old path');
        this.fallbackToOldPath();
        break;
        
      case ErrorResult.ERROR_ABORT:
        hilog.error(DOMAIN, TAG, 'Handover aborted');
        this.notifyUserNetworkChanged();
        break;
        
      default:
        hilog.error(DOMAIN, TAG, `Unknown handover error: ${result}`);
    }
  }

  private handleSubscribeError(error: BusinessError): void {
    switch (error.code) {
      case 201:
        hilog.error(DOMAIN, TAG, 'Permission denied, please add ohos.permission.GET_NETWORK_INFO');
        break;
        
      case 401:
        hilog.error(DOMAIN, TAG, 'Invalid parameters, check callback type');
        break;
        
      case 801:
        hilog.error(DOMAIN, TAG, 'API not supported on this device');
        break;
        
      default:
        hilog.error(DOMAIN, TAG, `Unknown error: ${error.code}`);
    }
  }

  private retryAfterDelay(delay: number): void {
    hilog.info(DOMAIN, TAG, `Retrying after ${delay}ms delay`);
    // 延迟后重试网络请求
  }

  private fallbackToOldPath(): void {
    hilog.info(DOMAIN, TAG, 'Falling back to old network path');
    // 回退到老链路继续传输
  }

  private notifyUserNetworkChanged(): void {
    hilog.info(DOMAIN, TAG, 'Network has changed, user should be notified');
    // 通知用户网络已变更
  }

  private getErrorResultDescription(result: ErrorResult): string {
    switch (result) {
      case ErrorResult.ERROR_NONE:
        return 'Success';
      case ErrorResult.ERROR_HANDOVER_TIMEOUT:
        return 'Timeout';
      case ErrorResult.ERROR_NEW_PATH_ACTIVATION_FAILED:
        return 'New path activation failed';
      case ErrorResult.ERROR_ABORT:
        return 'Aborted';
      default:
        return `Unknown (${result})`;
    }
  }

  private getReEstActionDescription(action: ReEstAction): string {
    switch (action) {
      case ReEstAction.DEFAULT:
        return 'Use same remote IP';
      case ReEstAction.QUERY_DNS:
        return 'Query DNS for new IP';
      case ReEstAction.CHANGE_REMOTE_IP:
        return 'Use different remote IP';
      case ReEstAction.CHANGE_IP_VERSION:
        return 'Change IP version (IPv4/IPv6)';
      case ReEstAction.NO_EST:
        return 'Retry on old path';
      default:
        return `Unknown (${action})`;
    }
  }

  getHandoverState(): HandoverState {
    return this.handoverState;
  }
}

// 使用示例
export function exampleUsage() {
  const handoverManager = new NetworkHandoverExample();
  
  // 订阅连接迁移事件
  handoverManager.subscribeHandover();
  
  // 应用业务逻辑...
  
  // 在应用退出或不需要时取消订阅
  // handoverManager.unsubscribeHandover();
}