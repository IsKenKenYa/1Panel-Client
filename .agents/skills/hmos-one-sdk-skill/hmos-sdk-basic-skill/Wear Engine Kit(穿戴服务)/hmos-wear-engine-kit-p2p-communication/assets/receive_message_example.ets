/**
 * 接收消息完整示例
 * 功能：订阅接收穿戴设备应用发送的消息
 */

import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';

export class ReceiveMessageExample {
  private deviceClient: wearEngine.DeviceClient;
  private p2pClient: wearEngine.P2pClient;
  private targetDevice: wearEngine.Device | null = null;
  private messageCallback: (p2pMessage: wearEngine.P2pMessage) => void;

  constructor(context: common.Context) {
    this.deviceClient = wearEngine.getDeviceClient(context);
    this.p2pClient = wearEngine.getP2pClient(context);
    this.messageCallback = this.createMessageCallback();
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

  private createMessageCallback(): (p2pMessage: wearEngine.P2pMessage) => void {
    return (p2pMessage: wearEngine.P2pMessage) => {
      let textDecoder: util.TextDecoder = new util.TextDecoder('utf-8');
      let receivedMessage: string = textDecoder.decodeToString(p2pMessage.content);
      console.info(`收到消息：${receivedMessage}`);
      console.info(`消息长度：${p2pMessage.content.length}字节`);
    };
  }

  async registerMessageReceiver(
    remoteBundleName: string,
    remoteFingerprint: string
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
      await this.p2pClient.registerMessageReceiver(
        this.targetDevice.randomId,
        appParam,
        this.messageCallback
      );
      console.info('消息接收监听已注册');
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      this.handleRegisterError(businessError);
      throw error;
    }
  }

  async unregisterMessageReceiver(
    remoteBundleName: string,
    remoteFingerprint: string
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
      await this.p2pClient.unregisterMessageReceiver(
        this.targetDevice.randomId,
        appParam,
        this.messageCallback
      );
      console.info('消息接收监听已取消');
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      this.handleRegisterError(businessError);
      throw error;
    }
  }

  private handleRegisterError(error: BusinessError): void {
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
      case 1008500005:
        console.error('HUAWEI ID未授权');
        break;
      case 1008500006:
        console.error('用户隐私未同意');
        break;
      case 1008500007:
        console.error('设备不支持此能力');
        break;
      case 1008500010:
        console.error('设备ID无效');
        break;
      case 1008500012:
        console.error('回调函数过多，请减少同类型的回调函数注册');
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
  let receiveExample = new ReceiveMessageExample(context);
  
  try {
    await receiveExample.initialize();
    
    await receiveExample.registerMessageReceiver(
      'com.example.wearapp',
      ''
    );
    
    console.info('等待接收消息...');
    
    setTimeout(async () => {
      await receiveExample.unregisterMessageReceiver(
        'com.example.wearapp',
        ''
      );
    }, 60000);
  } catch (error) {
    console.error('接收消息失败', error);
  }
}