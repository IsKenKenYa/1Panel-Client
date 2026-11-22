/**
 * P2P通信完整示例
 * 功能：演示手机应用与穿戴设备应用的完整通信流程
 */

import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { fileIo } from '@kit.CoreFileKit';

export class P2PCommunicationManager {
  private deviceClient: wearEngine.DeviceClient;
  private p2pClient: wearEngine.P2pClient;
  private targetDevice: wearEngine.Device | null = null;
  private appParam: wearEngine.P2pAppParam;
  
  private messageCallback: (p2pMessage: wearEngine.P2pMessage) => void;
  private fileCallback: (p2pFile: wearEngine.P2pFile) => void;

  constructor(
    context: common.Context,
    remoteBundleName: string,
    remoteFingerprint: string = ''
  ) {
    this.deviceClient = wearEngine.getDeviceClient(context);
    this.p2pClient = wearEngine.getP2pClient(context);
    
    this.appParam = {
      remoteApp: {
        bundleName: remoteBundleName,
        fingerprint: remoteFingerprint
      },
      transformLocalAppInfo: false
    };

    this.messageCallback = this.createMessageCallback();
    this.fileCallback = this.createFileCallback();
  }

  async initialize(): Promise<boolean> {
    try {
      let devices: wearEngine.Device[] = await this.deviceClient.getConnectedDevices();
      
      if (devices.length === 0) {
        console.error('没有已连接的穿戴设备');
        return false;
      }

      for (let device of devices) {
        let isSupported = await device.isDeviceCapabilitySupported(
          wearEngine.DeviceCapability.APP_INSTALLATION
        );
        if (isSupported) {
          this.targetDevice = device;
          console.info(`已选择设备：${device.name}, ID: ${device.randomId}`);
          break;
        }
      }

      if (!this.targetDevice) {
        console.error('未找到支持应用安装能力的设备');
        return false;
      }

      return true;
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`初始化失败。错误码：${businessError.code}, 错误信息：${businessError.message}`);
      return false;
    }
  }

  async checkRemoteAppInstalled(): Promise<boolean> {
    if (!this.targetDevice) {
      console.error('设备未初始化');
      return false;
    }

    try {
      let isInstall: boolean = await this.p2pClient.isRemoteAppInstalled(
        this.targetDevice.randomId,
        this.appParam.remoteApp.bundleName
      );
      
      if (isInstall) {
        console.info('应用已安装在穿戴设备上');
      } else {
        console.warn('应用未安装');
      }
      
      return isInstall;
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`检测应用安装失败。错误码：${businessError.code}, 错误信息：${businessError.message}`);
      return false;
    }
  }

  async getRemoteAppVersion(): Promise<number | null> {
    if (!this.targetDevice) {
      console.error('设备未初始化');
      return null;
    }

    try {
      let version: number = await this.p2pClient.getRemoteAppVersion(
        this.targetDevice.randomId,
        this.appParam.remoteApp.bundleName
      );
      
      console.info(`穿戴设备应用版本号：${version}`);
      return version;
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`获取应用版本号失败。错误码：${businessError.code}, 错误信息：${businessError.message}`);
      return null;
    }
  }

  async startRemoteApp(): Promise<boolean> {
    if (!this.targetDevice) {
      console.error('设备未初始化');
      return false;
    }

    try {
      let p2pResult: wearEngine.P2pResult = await this.p2pClient.startRemoteApp(
        this.targetDevice.randomId,
        this.appParam.remoteApp.bundleName
      );
      
      if (p2pResult.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
        console.info('穿戴设备应用已拉起');
        return true;
      } else {
        console.warn(`拉起应用失败，错误码：${p2pResult.code}`);
        return false;
      }
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`拉起应用失败。错误码：${businessError.code}, 错误信息：${businessError.message}`);
      return false;
    }
  }

  async sendMessage(messageContent: string): Promise<boolean> {
    if (!this.targetDevice) {
      console.error('设备未初始化');
      return false;
    }

    if (messageContent.length > 4096) {
      console.error('消息长度超过4096字节限制');
      return false;
    }

    try {
      let textEncoder: util.TextEncoder = new util.TextEncoder();
      let message: wearEngine.P2pMessage = {
        content: textEncoder.encodeInto(messageContent)
      };

      let p2pResult: wearEngine.P2pResult = await this.p2pClient.sendMessage(
        this.targetDevice.randomId,
        this.appParam,
        message
      );

      if (p2pResult.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
        console.info('消息发送成功');
        return true;
      } else {
        console.warn(`消息发送失败，错误码：${p2pResult.code}`);
        return false;
      }
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`发送消息失败。错误码：${businessError.code}, 错误信息：${businessError.message}`);
      return false;
    }
  }

  async transferFile(
    filePath: string,
    progressCallback?: (progress: number) => void
  ): Promise<boolean> {
    if (!this.targetDevice) {
      console.error('设备未初始化');
      return false;
    }

    if (filePath.includes('..')) {
      console.error('文件路径不能包含..字符');
      return false;
    }

    try {
      let p2pFile: wearEngine.P2pFile = {
        file: fileIo.openSync(filePath)
      };

      let success: boolean = false;

      await this.p2pClient.transferFile(
        this.targetDevice.randomId,
        this.appParam,
        p2pFile,
        (error: BusinessError, p2pResult: wearEngine.P2pResult) => {
          if (error) {
            console.error(`文件传输失败。错误码：${error.code}, 错误信息：${error.message}`);
            success = false;
            return;
          }

          if (p2pResult.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
            console.info('文件传输成功');
            success = true;
          } else {
            console.warn(`文件传输失败，错误码：${p2pResult.code}`);
            success = false;
          }

          if (p2pResult.progress && progressCallback) {
            progressCallback(p2pResult.progress);
          }
        }
      );

      fileIo.close(p2pFile.file);
      return success;
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`传输文件失败。错误码：${businessError.code}, 错误信息：${businessError.message}`);
      return false;
    }
  }

  async registerMessageReceiver(): Promise<boolean> {
    if (!this.targetDevice) {
      console.error('设备未初始化');
      return false;
    }

    try {
      await this.p2pClient.registerMessageReceiver(
        this.targetDevice.randomId,
        this.appParam,
        this.messageCallback
      );
      console.info('消息接收监听已注册');
      return true;
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`注册消息接收失败。错误码：${businessError.code}, 错误信息：${businessError.message}`);
      return false;
    }
  }

  async unregisterMessageReceiver(): Promise<boolean> {
    if (!this.targetDevice) {
      console.error('设备未初始化');
      return false;
    }

    try {
      await this.p2pClient.unregisterMessageReceiver(
        this.targetDevice.randomId,
        this.appParam,
        this.messageCallback
      );
      console.info('消息接收监听已取消');
      return true;
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`取消消息接收失败。错误码：${businessError.code}, 错误信息：${businessError.message}`);
      return false;
    }
  }

  async registerFileReceiver(): Promise<boolean> {
    if (!this.targetDevice) {
      console.error('设备未初始化');
      return false;
    }

    try {
      await this.p2pClient.registerFileReceiver(
        this.targetDevice.randomId,
        this.appParam,
        this.fileCallback
      );
      console.info('文件接收监听已注册');
      return true;
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`注册文件接收失败。错误码：${businessError.code}, 错误信息：${businessError.message}`);
      return false;
    }
  }

  async unregisterFileReceiver(): Promise<boolean> {
    if (!this.targetDevice) {
      console.error('设备未初始化');
      return false;
    }

    try {
      await this.p2pClient.unregisterFileReceiver(
        this.targetDevice.randomId,
        this.appParam,
        this.fileCallback
      );
      console.info('文件接收监听已取消');
      return true;
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`取消文件接收失败。错误码：${businessError.code}, 错误信息：${businessError.message}`);
      return false;
    }
  }

  private createMessageCallback(): (p2pMessage: wearEngine.P2pMessage) => void {
    return (p2pMessage: wearEngine.P2pMessage) => {
      let textDecoder: util.TextDecoder = new util.TextDecoder('utf-8');
      let receivedMessage: string = textDecoder.decodeToString(p2pMessage.content);
      console.info(`收到消息：${receivedMessage}`);
    };
  }

  private createFileCallback(): (p2pFile: wearEngine.P2pFile) => void {
    return (p2pFile: wearEngine.P2pFile) => {
      if (p2pFile.file) {
        console.info('收到文件');
        fileIo.close(p2pFile.file);
      }
      if (p2pFile.progress) {
        console.info(`接收进度：${p2pFile.progress}%`);
      }
    };
  }
}

/**
 * 使用示例
 */
async function exampleUsage(context: common.Context) {
  let manager = new P2PCommunicationManager(
    context,
    'com.example.wearapp',
    ''
  );

  if (!await manager.initialize()) {
    console.error('初始化失败');
    return;
  }

  if (!await manager.checkRemoteAppInstalled()) {
    console.warn('应用未安装，尝试拉起应用');
    if (!await manager.startRemoteApp()) {
      console.error('拉起应用失败');
      return;
    }
  }

  let version = await manager.getRemoteAppVersion();
  if (version) {
    console.info(`应用版本：${version}`);
  }

  await manager.registerMessageReceiver();
  await manager.registerFileReceiver();

  await manager.sendMessage('Hello from phone!');

  await manager.transferFile(
    '/data/local/tmp/test.txt',
    (progress: number) => {
      console.info(`传输进度：${progress}%`);
    }
  );

  setTimeout(async () => {
    await manager.unregisterMessageReceiver();
    await manager.unregisterFileReceiver();
  }, 60000);
}