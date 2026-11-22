/**
 * 发送文件完整示例
 * 功能：向穿戴设备应用发送文件，支持进度监控和取消传输
 */

import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';

export class TransferFileExample {
  private deviceClient: wearEngine.DeviceClient;
  private p2pClient: wearEngine.P2pClient;
  private targetDevice: wearEngine.Device | null = null;

  constructor(context: common.Context) {
    this.deviceClient = wearEngine.getDeviceClient(context);
    this.p2pClient = wearEngine.getP2pClient(context);
  }

  async initialize(): Promise<void> {
    try {
      let devices: wearEngine.Device[] = await this.deviceClient.getConnectedDevices();
      
      if (devices.length === 0) {
        throw new Error('没有已连接的穿戴设备');
      }

      for (let device of devices) {
        let isSupported = await device.isDeviceCapabilitySupported(
          wearEngine.DeviceCapability.APP_INSTALLATION
        );
        if (isSupported) {
          this.targetDevice = device;
          console.info(`已选择设备：${device.name}`);
          break;
        }
      }

      if (!this.targetDevice) {
        throw new Error('未找到支持应用安装能力的设备');
      }
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`初始化失败。错误码：${businessError.code}, 错误信息：${businessError.message}`);
      throw error;
    }
  }

  async transferFile(
    remoteBundleName: string,
    remoteFingerprint: string,
    filePath: string,
    progressCallback?: (progress: number) => void,
    completeCallback?: (success: boolean) => void
  ): Promise<void> {
    if (!this.targetDevice) {
      throw new Error('设备未初始化，请先调用initialize方法');
    }

    if (filePath.includes('..')) {
      throw new Error('文件路径不能包含..字符');
    }

    let appInfo: wearEngine.AppInfo = {
      bundleName: remoteBundleName,
      fingerprint: remoteFingerprint
    };

    let appParam: wearEngine.P2pAppParam = {
      remoteApp: appInfo,
      transformLocalAppInfo: false
    };

    try {
      let p2pFile: wearEngine.P2pFile = {
        file: fileIo.openSync(filePath)
      };

      this.p2pClient.transferFile(
        this.targetDevice.randomId,
        appParam,
        p2pFile,
        (error: BusinessError, p2pResult: wearEngine.P2pResult) => {
          if (error) {
            console.error(`文件传输失败。错误码：${error.code}, 错误信息：${error.message}`);
            if (completeCallback) {
              completeCallback(false);
            }
            return;
          }

          if (p2pResult.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
            console.info('文件传输成功');
            if (completeCallback) {
              completeCallback(true);
            }
          } else {
            console.warn(`文件传输失败，错误码：${p2pResult.code}`);
            if (completeCallback) {
              completeCallback(false);
            }
          }

          if (p2pResult.progress && progressCallback) {
            progressCallback(p2pResult.progress);
          }
        }
      );

      fileIo.close(p2pFile.file);
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      this.handleTransferError(businessError);
      throw error;
    }
  }

  async cancelFileTransfer(
    remoteBundleName: string,
    remoteFingerprint: string,
    filePath: string
  ): Promise<void> {
    if (!this.targetDevice) {
      throw new Error('设备未初始化，请先调用initialize方法');
    }

    let appInfo: wearEngine.AppInfo = {
      bundleName: remoteBundleName,
      fingerprint: remoteFingerprint
    };

    let appParam: wearEngine.P2pAppParam = {
      remoteApp: appInfo,
      transformLocalAppInfo: false
    };

    try {
      let p2pFile: wearEngine.P2pFile = {
        file: fileIo.openSync(filePath)
      };

      let p2pResult: wearEngine.P2pResult = await this.p2pClient.cancelFileTransfer(
        this.targetDevice.randomId,
        appParam,
        p2pFile
      );

      if (p2pResult.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
        console.info('文件传输已取消');
      } else {
        console.warn(`取消文件传输失败，错误码：${p2pResult.code}`);
      }

      fileIo.close(p2pFile.file);
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      this.handleTransferError(businessError);
      throw error;
    }
  }

  private handleTransferError(error: BusinessError): void {
    switch (error.code) {
      case 1008500001:
        console.error('网络错误，请检查设备连接状态');
        break;
      case 1008500002:
        console.error('没有绑定设备，请先绑定穿戴设备');
        break;
      case 1008500003:
        console.error('设备已断开连接');
        break;
      case 1008500004:
        console.error('应用未申请Wear Engine服务');
        break;
      case 1008500010:
        console.error('设备ID无效');
        break;
      case 1008500011:
        console.error('文件无效，请检查文件路径');
        break;
      default:
        console.error(`未知错误。错误码：${error.code}, 错误信息：${error.message}`);
    }
  }
}

/**
 * 使用示例
 */
async function exampleUsage(context: common.Context) {
  let transferExample = new TransferFileExample(context);
  
  try {
    await transferExample.initialize();
    
    await transferExample.transferFile(
      'com.example.wearapp',
      '',
      '/data/local/tmp/test.txt',
      (progress: number) => {
        console.info(`传输进度：${progress}%`);
      },
      (success: boolean) => {
        if (success) {
          console.info('文件传输完成');
        } else {
          console.error('文件传输失败');
        }
      }
    );
  } catch (error) {
    console.error('文件传输失败', error);
  }
}