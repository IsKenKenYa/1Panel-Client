import { safetyDetect } from '@kit.DeviceSecurityKit';
import { BusinessError } from '@ohos.base';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = "SysIntegrityCheckExample";

export class SysIntegrityCheckExample {
  async checkSystemIntegrity(): Promise<string> {
    try {
      hilog.info(0x0000, TAG, '开始系统完整性检测');
      
      const nonce = this.generateNonce();
      hilog.info(0x0000, TAG, '生成的nonce值: %{public}s', nonce);
      
      let req: safetyDetect.SysIntegrityRequest = {
        nonce: nonce
      };
      
      const data: safetyDetect.SysIntegrityResponse = await safetyDetect.checkSysIntegrity(req);
      hilog.info(0x0000, TAG, '检测成功，结果: %{public}s', data.result);
      
      return data.result;
    } catch (error) {
      let e: BusinessError = error as BusinessError;
      hilog.error(0x0000, TAG, '检测失败，错误码: %{public}d，错误信息: %{public}s', e.code, e.message);
      throw error;
    }
  }
  
  generateNonce(): string {
    const length = 32;
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let nonce = '';
    for (let i = 0; i < length; i++) {
      nonce += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return nonce;
  }
  
  handleError(errorCode: number): string {
    switch (errorCode) {
      case 201:
        return '权限被拒绝，请检查权限配置';
      case 401:
        return '参数无效，请检查nonce长度和格式';
      case 801:
        return 'API不支持，请检查设备能力';
      case 1010800001:
        return '内部错误，请稍后重试';
      case 1010800002:
        return '网络不可达，请检查网络连接';
      case 1010800003:
        return '访问云服务器失败，请稍后重试';
      case 1010800005:
        return '并发调用超限，请等待其他调用完成';
      case 1010800006:
        return '调用频率超限，请稍后重试';
      case 1010800007:
        return '操作超时，请检查网络连接';
      case 1010800008:
        return '云服务流量超限，请稍后重试';
      default:
        return '未知错误';
    }
  }
}

export async function main(): Promise<void> {
  const example = new SysIntegrityCheckExample();
  
  try {
    const result = await example.checkSystemIntegrity();
    hilog.info(0x0000, TAG, '系统完整性检测结果: %{public}s', result);
  } catch (error) {
    let e: BusinessError = error as BusinessError;
    const errorMsg = example.handleError(e.code);
    hilog.error(0x0000, TAG, '检测失败: %{public}s', errorMsg);
  }
}