/**
 * 多网发起和释放完整示例代码
 * 功能：演示如何发起多网请求、监听状态变化、查询配额、释放多网
 * API版本：6.0.0(20)及以上
 * 权限：ohos.permission.LINKTURBO
 */

import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

class MultiPathManager {
  private isMultiPathActive: boolean = false;
  
  async init(): Promise<void> {
    try {
      await this.subscribeMultiPathStateChange();
      await this.subscribeMultiPathRecommendation();
      console.info('MultiPathManager initialized successfully');
    } catch (err) {
      console.error('Failed to initialize MultiPathManager:', (err as BusinessError).message);
    }
  }
  
  async requestMultiPath(): Promise<boolean> {
    try {
      const quotaInfo = netHandover.getMultiPathQuotaStats();
      console.info('Current quota info - Used: count=' + quotaInfo.used.count + ', duration=' + quotaInfo.used.duration);
      console.info('Current quota info - Remaining: count=' + quotaInfo.remaining.count + ', duration=' + quotaInfo.remaining.duration);
      
      if (quotaInfo.remaining.count <= 0) {
        console.warn('Quota exhausted, cannot request multiPath');
        return false;
      }
      
      return new Promise<boolean>((resolve, reject) => {
        netHandover.requestMultiPath((data: netHandover.MultiPathRequestResult) => {
          console.info('requestMultiPath result: ' + JSON.stringify(data));
          
          if (data.result === netHandover.MultiPathErrorResult.MULTIPATH_ERROR_NONE) {
            this.isMultiPathActive = true;
            console.info('MultiPath request succeeded');
            resolve(true);
          } else {
            console.error('MultiPath request failed with error code: ' + data.result);
            this.handleMultiPathError(data.result);
            resolve(false);
          }
        });
      });
    } catch (err) {
      const error = err as BusinessError;
      console.error('requestMultiPath failed: errCode=' + error.code + ', errMessage=' + error.message);
      this.handleException(error.code);
      return false;
    }
  }
  
  releaseMultiPath(): void {
    if (!this.isMultiPathActive) {
      console.warn('MultiPath is not active, skip release');
      return;
    }
    
    try {
      netHandover.releaseMultiPath();
      this.isMultiPathActive = false;
      console.info('MultiPath released successfully');
    } catch (err) {
      const error = err as BusinessError;
      console.error('releaseMultiPath failed: errCode=' + error.code + ', errMessage=' + error.message);
      this.handleException(error.code);
    }
  }
  
  private async subscribeMultiPathStateChange(): Promise<void> {
    try {
      netHandover.on('multiPathStateChange', (data: netHandover.MultiPathStateInfo) => {
        console.info('multiPathStateChange: ' + JSON.stringify(data));
        
        switch (data.multiPathState) {
          case netHandover.MultiPathState.MULTIPATH_IDLE:
            console.info('MultiPath state: IDLE');
            this.isMultiPathActive = false;
            break;
          case netHandover.MultiPathState.MULTIPATH_CREATING:
            console.info('MultiPath state: CREATING');
            break;
          case netHandover.MultiPathState.MULTIPATH_CREATED:
            console.info('MultiPath state: CREATED');
            this.isMultiPathActive = true;
            break;
          case netHandover.MultiPathState.MULTIPATH_RELEASING:
            console.info('MultiPath state: RELEASING');
            break;
        }
        
        console.info('Cause: ' + this.getChangeCauseDescription(data.cause));
        console.info('Path state: ' + this.getPathStateDescription(data.pathState));
      });
    } catch (err) {
      console.error('Failed to subscribe multiPathStateChange:', (err as BusinessError).message);
    }
  }
  
  private async subscribeMultiPathRecommendation(): Promise<void> {
    try {
      netHandover.on('multiPathRecommendation', (data: netHandover.MultiPathRecommendationInfo) => {
        console.info('multiPathRecommendation: ' + JSON.stringify(data));
        
        if (data.action === netHandover.MultiPathAction.MULTIPATH_ACTION_REQUEST) {
          console.info('System recommends to request multiPath');
          this.requestMultiPath();
        } else if (data.action === netHandover.MultiPathAction.MULTIPATH_ACTION_RELEASE) {
          console.info('System recommends to release multiPath');
          this.releaseMultiPath();
        }
      });
    } catch (err) {
      console.error('Failed to subscribe multiPathRecommendation:', (err as BusinessError).message);
    }
  }
  
  unsubscribeAll(): void {
    try {
      netHandover.off('multiPathStateChange');
      netHandover.off('multiPathRecommendation');
      console.info('Unsubscribed all events');
    } catch (err) {
      console.error('Failed to unsubscribe:', (err as BusinessError).message);
    }
  }
  
  getQuotaInfo(): netHandover.MultiPathQuota {
    try {
      return netHandover.getMultiPathQuotaStats();
    } catch (err) {
      console.error('Failed to get quota info:', (err as BusinessError).message);
      throw err;
    }
  }
  
  private handleMultiPathError(errorResult: netHandover.MultiPathErrorResult): void {
    switch (errorResult) {
      case netHandover.MultiPathErrorResult.MULTIPATH_ERROR_NETWORK_REFUSED:
        console.warn('Network refused multiPath request');
        break;
      case netHandover.MultiPathErrorResult.MULTIPATH_ERROR_TIMEOUT:
        console.warn('MultiPath request timeout');
        break;
      case netHandover.MultiPathErrorResult.MULTIPATH_ERROR_LOCAL:
        console.warn('MultiPath released locally during creation');
        break;
    }
  }
  
  private handleException(errorCode: number): void {
    switch (errorCode) {
      case 201:
        console.error('Permission denied. Please apply for ohos.permission.LINKTURBO');
        break;
      case 1013600001:
        console.error('Internal processing exception');
        break;
      case 1013600002:
        console.error('System processing exception');
        break;
      case 1013620000:
        console.warn('MultiPath feature not enabled. Please check network boost settings');
        break;
      case 1013620001:
        console.warn('MultiPath already active or activating');
        break;
      case 1013620002:
        console.warn('Application multiPath request quota exhausted');
        break;
      case 1013620003:
        console.warn('Power consumption limit prevents multiPath');
        break;
      case 1013620004:
        console.warn('Quota exhausted');
        break;
      case 1013620005:
        console.warn('MultiPath request scenario conflict');
        break;
      case 1013620006:
        console.warn('MultiPath request too frequent');
        break;
      case 1013620007:
        console.warn('No suitable multiPath link available');
        break;
      case 1013620008:
        console.warn('Insufficient data traffic');
        break;
      case 1013620009:
        console.warn('Device does not support concurrent networks');
        break;
      case 1013620100:
        console.warn('MultiPath active but not requested by current app');
        break;
      case 1013620101:
        console.warn('MultiPath not in active state');
        break;
      default:
        console.error('Unknown error code: ' + errorCode);
    }
  }
  
  private getChangeCauseDescription(cause: netHandover.MultiPathChangeCause): string {
    switch (cause) {
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_REQUEST_NORMAL:
        return 'Normal request';
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_NORMAL:
        return 'Normal release';
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_NETWORK:
        return 'Network reason release';
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_USER_REFUSED:
        return 'User refused release';
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_NO_QUOTA:
        return 'Quota exhausted release';
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_POWER_CONSUMPTION:
        return 'Power consumption release';
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_INSUFFICIENT_TRAFFIC:
        return 'Insufficient traffic release';
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_CONFLICT:
        return 'Scenario conflict release';
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_SYS_FUSING:
        return 'System forced release (improper usage)';
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_SYS_DEFAULT:
        return 'System network state change release';
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_SUSPEND_ENTER:
        return 'Enter suspend state';
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_SUSPEND_LEAVE:
        return 'Leave suspend state';
      case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_CONN_PROPERTIES_UPDATE:
        return 'Connection properties update';
      default:
        return 'Unknown cause: ' + cause;
    }
  }
  
  private getPathStateDescription(state: netHandover.PathState): string {
    switch (state) {
      case netHandover.PathState.PATH_IDLE:
        return 'Path idle';
      case netHandover.PathState.PATH_CONNECTED:
        return 'Path connected';
      case netHandover.PathState.PATH_SUSPENDED:
        return 'Path suspended';
      default:
        return 'Unknown state: ' + state;
    }
  }
  
  isActive(): boolean {
    return this.isMultiPathActive;
  }
}

async function main(): Promise<void> {
  const manager = new MultiPathManager();
  
  await manager.init();
  
  const success = await manager.requestMultiPath();
  if (success) {
    console.info('MultiPath is active, starting business logic...');
    
    await new Promise<void>(resolve => setTimeout(resolve, 5000));
    
    console.info('Business logic completed, releasing multiPath...');
    manager.releaseMultiPath();
  } else {
    console.warn('MultiPath request failed, using single network fallback');
  }
  
  manager.unsubscribeAll();
}

main().catch(err => {
  console.error('Main execution failed:', err);
});