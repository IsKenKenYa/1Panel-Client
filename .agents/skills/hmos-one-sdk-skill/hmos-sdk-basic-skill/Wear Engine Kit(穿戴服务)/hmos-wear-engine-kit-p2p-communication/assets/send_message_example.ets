/**
 * 发送消息完整示例
 * 功能：向穿戴设备应用发送点对点消息
 */

import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';

export class SendMessageExample {
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

  async sendMessage(
    remoteBundleName: string,
    remoteFingerprint: string,
    messageContent: string
  ): Promise<void> {
    if (!this.targetDevice) {
      throw new Error('设备未初始化，请先调用initialize方法');
    }

    if (messageContent.length > 4096) {
      throw new Error('消息长度超过4096字节限制，请使用文件传输或分包发送');
    }

    let appInfo: wearEngine.AppInfo = {
      bundleName: remoteBundleName,
      fingerprint: remoteFingerprint
    };

    let appParam: wearEngine.P2pAppParam = {
      remoteApp: appInfo,
      transformLocalAppInfo: false
    };

    let textEncoder: util.TextEncoder = new util.TextEncoder();
    let message: wearEngine.P2pMessage = {
      content: textEncoder.encodeInto(messageContent)
    };

    try {
      let p2pResult: wearEngine.P2pResult = await this.p2pClient.sendMessage(
        this.targetDevice.randomId,
        appParam,
        message
      );

      if (p2pResult.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
        console.info('消息发送成功');
      } else {
        console.warn(`消息发送失败，错误码：${p2pResult.code}`);
      }
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      this.handleSendError(businessError);
      throw error;
    }
  }

  private handleSendError(error: BusinessError): void {
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
      default:
        console.error(`未知错误。错误码：${error.code}, 错误信息：${error.message}`);
    }
  }
}

/**
 * 使用示例
 */
async function exampleUsage(context: common.Context) {
  let sendExample = new SendMessageExample(context);
  
  try {
    await sendExample.initialize();
    
    await sendExample.sendMessage(
      'com.example.wearapp',
      '',
      'Hello from phone! This is a test message.'
    );
  } catch (error) {
    console.error('发送消息失败', error);
  }
}