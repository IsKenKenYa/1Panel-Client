import testNetManager from 'libentry.so';
import { hilog } from '@kit.PerformanceAnalysisKit';

enum ReturnCode {
  SUCCESS = 0,
  MISSING_PERMISSION = 201,
  PARAMETER_ERROR = 401,
  SERVICE_UNAVAILABLE = 2100002,
  INTERNAL_ERROR = 2100003
}

export class NetworkManager {
  private static readonly DOMAIN = 0x0000;
  private static readonly TAG = 'NetworkManager';

  checkNetworkConnection(): void {
    try {
      const hasDefaultNet: number = testNetManager.HasDefaultNet();
      
      if (hasDefaultNet === -1) {
        hilog.error(NetworkManager.DOMAIN, NetworkManager.TAG, 'Failed to check network');
        return;
      }
      
      if (hasDefaultNet === 1) {
        hilog.info(NetworkManager.DOMAIN, NetworkManager.TAG, 'Network is connected');
      } else {
        hilog.info(NetworkManager.DOMAIN, NetworkManager.TAG, 'Network is not connected');
      }
    } catch (error) {
      hilog.error(NetworkManager.DOMAIN, NetworkManager.TAG, `Exception: ${error}`);
    }
  }

  getDefaultNetId(): number {
    try {
      const netId: number = testNetManager.GetNetId();
      
      if (netId === -1) {
        hilog.error(NetworkManager.DOMAIN, NetworkManager.TAG, 'Failed to get default net ID');
        return -1;
      }
      
      hilog.info(NetworkManager.DOMAIN, NetworkManager.TAG, `Default net ID: ${netId}`);
      return netId;
    } catch (error) {
      hilog.error(NetworkManager.DOMAIN, NetworkManager.TAG, `Exception: ${error}`);
      return -1;
    }
  }

  testGetDefaultNet(testParam: number): void {
    try {
      const resultCode: number = testNetManager.GetDefaultNet(testParam);
      
      switch (resultCode) {
        case ReturnCode.SUCCESS:
          hilog.info(NetworkManager.DOMAIN, NetworkManager.TAG, 'GetDefaultNet success');
          break;
        case ReturnCode.MISSING_PERMISSION:
          hilog.warn(NetworkManager.DOMAIN, NetworkManager.TAG, 'Missing permissions (code 201)');
          break;
        case ReturnCode.PARAMETER_ERROR:
          hilog.warn(NetworkManager.DOMAIN, NetworkManager.TAG, 'Parameter error (code 401)');
          break;
        case ReturnCode.SERVICE_UNAVAILABLE:
          hilog.error(NetworkManager.DOMAIN, NetworkManager.TAG, 'Service unavailable (code 2100002)');
          break;
        case ReturnCode.INTERNAL_ERROR:
          hilog.error(NetworkManager.DOMAIN, NetworkManager.TAG, 'Internal error (code 2100003)');
          break;
        default:
          hilog.error(NetworkManager.DOMAIN, NetworkManager.TAG, `Unexpected result: ${resultCode}`);
          break;
      }
    } catch (error) {
      hilog.error(NetworkManager.DOMAIN, NetworkManager.TAG, `Exception: ${error}`);
    }
  }

  checkNetworkMetered(): void {
    try {
      const isMetered: number = testNetManager.IsMetered();
      
      if (isMetered === -1) {
        hilog.error(NetworkManager.DOMAIN, NetworkManager.TAG, 'Failed to check metered status');
        return;
      }
      
      if (isMetered === 1) {
        hilog.info(NetworkManager.DOMAIN, NetworkManager.TAG, 'Network is metered (traffic counted)');
      } else {
        hilog.info(NetworkManager.DOMAIN, NetworkManager.TAG, 'Network is not metered (free traffic)');
      }
    } catch (error) {
      hilog.error(NetworkManager.DOMAIN, NetworkManager.TAG, `Exception: ${error}`);
    }
  }

  getAllNetworksCount(): number {
    try {
      const count: number = testNetManager.GetAllNetsCount();
      
      if (count === -1) {
        hilog.error(NetworkManager.DOMAIN, NetworkManager.TAG, 'Failed to get all networks');
        return -1;
      }
      
      hilog.info(NetworkManager.DOMAIN, NetworkManager.TAG, `Active networks count: ${count}`);
      return count;
    } catch (error) {
      hilog.error(NetworkManager.DOMAIN, NetworkManager.TAG, `Exception: ${error}`);
      return -1;
    }
  }

  getNetworkInfo(): string {
    let info: string = 'Network Information:\n';
    
    try {
      const hasDefaultNet: number = testNetManager.HasDefaultNet();
      info += `Has Default Network: ${hasDefaultNet === 1 ? 'Yes' : 'No'}\n`;
      
      if (hasDefaultNet === 1) {
        const netId: number = this.getDefaultNetId();
        info += `Default Network ID: ${netId}\n`;
        
        const isMetered: number = testNetManager.IsMetered();
        info += `Is Metered: ${isMetered === 1 ? 'Yes' : 'No'}\n`;
      }
      
      const netCount: number = this.getAllNetworksCount();
      info += `Active Networks: ${netCount}\n`;
      
    } catch (error) {
      info += `Error: ${error}\n`;
    }
    
    return info;
  }
}

export default new NetworkManager();