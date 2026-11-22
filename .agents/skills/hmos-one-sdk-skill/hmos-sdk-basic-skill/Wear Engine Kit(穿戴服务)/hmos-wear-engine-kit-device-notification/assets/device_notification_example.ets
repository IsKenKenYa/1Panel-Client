/**
 * 穿戴设备模板化通知完整示例
 * 功能：向已连接的穿戴设备发送模板化通知并接收反馈
 * 适用场景：消息提醒、状态通知、用户交互
 */

import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

/**
 * 通知发送管理类
 */
export class DeviceNotificationManager {
  private notifyClient: wearEngine.NotifyClient | null = null;
  private deviceClient: wearEngine.DeviceClient | null = null;
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  /**
   * 初始化客户端
   */
  async init(): Promise<void> {
    try {
      this.notifyClient = wearEngine.getNotifyClient(this.context);
      this.deviceClient = wearEngine.getDeviceClient(this.context);
      console.info('[NotificationManager] Clients initialized successfully');
    } catch (error) {
      console.error('[NotificationManager] Failed to initialize clients:', error);
      throw error;
    }
  }

  /**
   * 获取已连接设备列表
   */
  async getConnectedDevices(): Promise<wearEngine.Device[]> {
    if (!this.deviceClient) {
      throw new Error('DeviceClient not initialized');
    }

    try {
      const devices = await this.deviceClient.getConnectedDevices();
      console.info(`[NotificationManager] Found ${devices.length} connected devices`);
      return devices;
    } catch (error) {
      const err = error as BusinessError;
      console.error(`[NotificationManager] Failed to get devices. Code: ${err.code}, Message: ${err.message}`);
      throw error;
    }
  }

  /**
   * 发送单按钮通知
   * @param device 目标设备
   * @param title 通知标题（1-28字节）
   * @param text 通知内容（1-400字节）
   * @param buttonText 按钮文字（1-12字节）
   * @param bundleName 应用包名
   * @param onButtonClick 按钮点击回调
   */
  async sendOneButtonNotification(
    device: wearEngine.Device,
    title: string,
    text: string,
    buttonText: string,
    bundleName: string,
    onButtonClick?: () => void
  ): Promise<void> {
    // 参数校验
    this.validateParameters(title, text, buttonText);

    if (!this.notifyClient) {
      throw new Error('NotifyClient not initialized');
    }

    const button: wearEngine.NotificationButton = {
      buttonId: wearEngine.ButtonId.FIRST_BUTTON,
      content: buttonText
    };

    const notification: wearEngine.Notification = {
      type: wearEngine.NotificationType.NOTIFICATION_WITH_ONE_BUTTON,
      bundleName: bundleName,
      title: title,
      text: text,
      buttons: [button]
    };

    const options: wearEngine.NotificationOptions = {
      notification: notification,
      onAction: (feedback: wearEngine.NotificationFeedback) => {
        this.handleFeedback(feedback, onButtonClick);
      }
    };

    await this.sendNotification(device.randomId, options);
  }

  /**
   * 发送双按钮通知
   * @param device 目标设备
   * @param title 通知标题（1-28字节）
   * @param text 通知内容（1-400字节）
   * @param button1Text 第一个按钮文字（1-12字节）
   * @param button2Text 第二个按钮文字（1-12字节）
   * @param bundleName 应用包名
   * @param onButton1Click 第一个按钮点击回调
   * @param onButton2Click 第二个按钮点击回调
   */
  async sendTwoButtonsNotification(
    device: wearEngine.Device,
    title: string,
    text: string,
    button1Text: string,
    button2Text: string,
    bundleName: string,
    onButton1Click?: () => void,
    onButton2Click?: () => void
  ): Promise<void> {
    // 参数校验
    this.validateParameters(title, text, button1Text, button2Text);

    if (!this.notifyClient) {
      throw new Error('NotifyClient not initialized');
    }

    const button1: wearEngine.NotificationButton = {
      buttonId: wearEngine.ButtonId.FIRST_BUTTON,
      content: button1Text
    };

    const button2: wearEngine.NotificationButton = {
      buttonId: wearEngine.ButtonId.SECOND_BUTTON,
      content: button2Text
    };

    const notification: wearEngine.Notification = {
      type: wearEngine.NotificationType.NOTIFICATION_WITH_TWO_BUTTONS,
      bundleName: bundleName,
      title: title,
      text: text,
      buttons: [button1, button2]
    };

    const options: wearEngine.NotificationOptions = {
      notification: notification,
      onAction: (feedback: wearEngine.NotificationFeedback) => {
        this.handleFeedback(feedback, onButton1Click, onButton2Click);
      }
    };

    await this.sendNotification(device.randomId, options);
  }

  /**
   * 发送三按钮通知
   */
  async sendThreeButtonsNotification(
    device: wearEngine.Device,
    title: string,
    text: string,
    button1Text: string,
    button2Text: string,
    button3Text: string,
    bundleName: string,
    onButton1Click?: () => void,
    onButton2Click?: () => void,
    onButton3Click?: () => void
  ): Promise<void> {
    // 参数校验
    this.validateParameters(title, text, button1Text, button2Text, button3Text);

    if (!this.notifyClient) {
      throw new Error('NotifyClient not initialized');
    }

    const buttons: wearEngine.NotificationButton[] = [
      { buttonId: wearEngine.ButtonId.FIRST_BUTTON, content: button1Text },
      { buttonId: wearEngine.ButtonId.SECOND_BUTTON, content: button2Text },
      { buttonId: wearEngine.ButtonId.THIRD_BUTTON, content: button3Text }
    ];

    const notification: wearEngine.Notification = {
      type: wearEngine.NotificationType.NOTIFICATION_WITH_THREE_BUTTONS,
      bundleName: bundleName,
      title: title,
      text: text,
      buttons: buttons
    };

    const options: wearEngine.NotificationOptions = {
      notification: notification,
      onAction: (feedback: wearEngine.NotificationFeedback) => {
        this.handleFeedback(feedback, onButton1Click, onButton2Click, onButton3Click);
      }
    };

    await this.sendNotification(device.randomId, options);
  }

  /**
   * 发送无按钮通知
   */
  async sendNoButtonNotification(
    device: wearEngine.Device,
    title: string,
    text: string,
    bundleName: string,
    onNotificationDeleted?: () => void
  ): Promise<void> {
    // 参数校验（仅标题和内容）
    this.validateTitleAndText(title, text);

    if (!this.notifyClient) {
      throw new Error('NotifyClient not initialized');
    }

    const notification: wearEngine.Notification = {
      type: wearEngine.NotificationType.NOTIFICATION_WITHOUT_BUTTONS,
      bundleName: bundleName,
      title: title,
      text: text,
      buttons: []
    };

    const options: wearEngine.NotificationOptions = {
      notification: notification,
      onAction: (feedback: wearEngine.NotificationFeedback) => {
        if (feedback.action === wearEngine.NotificationAction.NOTIFICATION_DELETED) {
          console.info('[NotificationManager] Notification deleted by user');
          if (onNotificationDeleted) {
            onNotificationDeleted();
          }
        }
      }
    };

    await this.sendNotification(device.randomId, options);
  }

  /**
   * 发送通知核心方法
   */
  private async sendNotification(deviceRandomId: string, options: wearEngine.NotificationOptions): Promise<void> {
    try {
      await this.notifyClient!.notify(deviceRandomId, options);
      console.info('[NotificationManager] Notification sent successfully');
    } catch (error) {
      const err = error as BusinessError;
      this.handleError(err);
      throw error;
    }
  }

  /**
   * 处理用户反馈
   */
  private handleFeedback(
    feedback: wearEngine.NotificationFeedback,
    onButton1Click?: () => void,
    onButton2Click?: () => void,
    onButton3Click?: () => void
  ): void {
    if (feedback.action) {
      console.info(`[NotificationManager] User action: ${feedback.action}`);
      
      switch (feedback.action) {
        case wearEngine.NotificationAction.FIRST_BUTTON_CLICKED:
          if (onButton1Click) {
            onButton1Click();
          }
          break;
        case wearEngine.NotificationAction.SECOND_BUTTON_CLICKED:
          if (onButton2Click) {
            onButton2Click();
          }
          break;
        case wearEngine.NotificationAction.THIRD_BUTTON_CLICKED:
          if (onButton3Click) {
            onButton3Click();
          }
          break;
        case wearEngine.NotificationAction.NOTIFICATION_DELETED:
          console.info('[NotificationManager] Notification deleted by user');
          break;
        case wearEngine.NotificationAction.NOTIFICATION_SWITCHED_TO_BACKGROUND:
          console.info('[NotificationManager] Notification switched to background');
          break;
      }
    } else if (feedback.errorCode) {
      console.error(`[NotificationManager] Device error: ${feedback.errorCode}`);
    }
  }

  /**
   * 参数校验
   */
  private validateParameters(title: string, text: string, ...buttonTexts: string[]): void {
    this.validateTitleAndText(title, text);
    
    buttonTexts.forEach((buttonText, index) => {
      const buttonBytes = this.getUtf8ByteLength(buttonText);
      if (buttonBytes < 1 || buttonBytes >= 12) {
        throw new Error(`Button ${index + 1} text length must be [1, 12) bytes, current: ${buttonBytes} bytes`);
      }
    });
  }

  private validateTitleAndText(title: string, text: string): void {
    const titleBytes = this.getUtf8ByteLength(title);
    if (titleBytes < 1 || titleBytes >= 28) {
      throw new Error(`Title length must be [1, 28) bytes, current: ${titleBytes} bytes`);
    }

    const textBytes = this.getUtf8ByteLength(text);
    if (textBytes < 1 || textBytes >= 400) {
      throw new Error(`Text length must be [1, 400) bytes, current: ${textBytes} bytes`);
    }
  }

  /**
   * 计算UTF-8字节长度
   */
  private getUtf8ByteLength(text: string): number {
    const encoder = new TextEncoder();
    return encoder.encode(text).length;
  }

  /**
   * 错误处理
   */
  private handleError(error: BusinessError): void {
    const errorMessages: Record<number, string> = {
      401: 'Parameter error. Check title/text/button length limits.',
      801: 'Capability not supported. Only Phone/Tablet devices supported.',
      1008500001: 'Network error. Please check network connection.',
      1008500002: 'No device is bound. Please bind device first.',
      1008500003: 'Device disconnected. Please reconnect device.',
      1008500004: 'App has not applied for Wear Engine service.',
      1008500005: 'HUAWEI ID is not authorized.',
      1008500006: 'User privacy is not agreed.',
      1008500007: 'Device capability is not supported.',
      1008500008: 'Account error. User has not logged in with HUAWEI ID.',
      1008500009: 'Account error. Failed to obtain account information.',
      1008500010: 'Device ID is invalid.',
      1008509999: 'Internal error. Please contact support.'
    };

    const message = errorMessages[error.code] || `Unknown error: ${error.code}`;
    console.error(`[NotificationManager] Error ${error.code}: ${message}`);
  }
}

/**
 * 使用示例
 */
export async function notificationExample(context: common.UIAbilityContext): Promise<void> {
  try {
    // 创建管理器
    const manager = new DeviceNotificationManager(context);
    
    // 初始化
    await manager.init();
    
    // 获取设备列表
    const devices = await manager.getConnectedDevices();
    
    if (devices.length === 0) {
      console.error('No connected devices found');
      return;
    }
    
    // 选择第一个设备
    const targetDevice = devices[0];
    console.info(`Sending notification to: ${targetDevice.name}`);
    
    // 发送单按钮通知示例
    await manager.sendOneButtonNotification(
      targetDevice,
      '消息提醒',
      '您有一条新消息，请查看',
      '查看',
      'com.example.myapp',
      () => {
        console.info('User clicked "查看" button');
      }
    );
    
    console.info('Notification sent successfully');
  } catch (error) {
    console.error('Notification example failed:', error);
  }
}