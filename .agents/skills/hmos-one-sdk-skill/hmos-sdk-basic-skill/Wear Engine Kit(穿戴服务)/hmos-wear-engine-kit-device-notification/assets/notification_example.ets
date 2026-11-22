import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct NotificationExample {
  @State deviceList: wearEngine.Device[] = [];
  @State targetDevice: wearEngine.Device | null = null;
  @State notificationResult: string = '';

  async aboutToAppear(): Promise<void> {
    await this.queryConnectedDevices();
  }

  async queryConnectedDevices(): Promise<void> {
    try {
      let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
      this.deviceList = await deviceClient.getConnectedDevices();
      
      if (this.deviceList.length > 0) {
        this.targetDevice = this.deviceList[0];
        console.info(`Found ${this.deviceList.length} connected devices`);
      } else {
        console.warn('No connected devices found');
        this.notificationResult = 'No connected devices';
      }
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`Failed to query devices: ${businessError.code}, ${businessError.message}`);
      this.notificationResult = `Error: ${businessError.message}`;
    }
  }

  buildNotificationOptions(type: number): wearEngine.NotificationOptions {
    let buttons: wearEngine.NotificationButton[] = [];
    
    if (type >= 1) {
      buttons.push({
        buttonId: wearEngine.ButtonId.FIRST_BUTTON,
        content: 'Accept'
      });
    }
    
    if (type >= 2) {
      buttons.push({
        buttonId: wearEngine.ButtonId.SECOND_BUTTON,
        content: 'Reject'
      });
    }
    
    if (type >= 3) {
      buttons.push({
        buttonId: wearEngine.ButtonId.THIRD_BUTTON,
        content: 'Ignore'
      });
    }

    let notification: wearEngine.Notification = {
      type: type === 0 ? wearEngine.NotificationType.NOTIFICATION_WITHOUT_BUTTONS :
            type === 1 ? wearEngine.NotificationType.NOTIFICATION_WITH_ONE_BUTTON :
            type === 2 ? wearEngine.NotificationType.NOTIFICATION_WITH_TWO_BUTTONS :
            wearEngine.NotificationType.NOTIFICATION_WITH_THREE_BUTTONS,
      bundleName: 'com.example.notification',
      title: 'Incoming Call',
      text: 'You have an incoming call from John Doe',
      buttons: buttons
    };

    let options: wearEngine.NotificationOptions = {
      notification: notification,
      onAction: (feedback: wearEngine.NotificationFeedback) => {
        this.handleNotificationFeedback(feedback);
      }
    };

    return options;
  }

  handleNotificationFeedback(feedback: wearEngine.NotificationFeedback): void {
    if (feedback.action) {
      switch (feedback.action) {
        case wearEngine.NotificationAction.FIRST_BUTTON_CLICKED:
          this.notificationResult = 'User clicked Accept button';
          console.info('User clicked Accept button');
          break;
        case wearEngine.NotificationAction.SECOND_BUTTON_CLICKED:
          this.notificationResult = 'User clicked Reject button';
          console.info('User clicked Reject button');
          break;
        case wearEngine.NotificationAction.THIRD_BUTTON_CLICKED:
          this.notificationResult = 'User clicked Ignore button';
          console.info('User clicked Ignore button');
          break;
        case wearEngine.NotificationAction.NOTIFICATION_DELETED:
          this.notificationResult = 'User deleted notification';
          console.info('User deleted notification');
          break;
        case wearEngine.NotificationAction.NOTIFICATION_SWITCHED_TO_BACKGROUND:
          this.notificationResult = 'Notification switched to background';
          console.info('Notification switched to background');
          break;
      }
    } else if (feedback.errorCode) {
      this.notificationResult = `Error on device: ${feedback.errorCode}`;
      console.error(`Notification error: ${feedback.errorCode}`);
    }
  }

  async sendNotification(type: number): Promise<void> {
    if (!this.targetDevice) {
      this.notificationResult = 'No target device selected';
      return;
    }

    try {
      let notifyClient: wearEngine.NotifyClient = wearEngine.getNotifyClient(this.getUIContext().getHostContext());
      let options: wearEngine.NotificationOptions = this.buildNotificationOptions(type);
      
      await notifyClient.notify(this.targetDevice.randomId, options);
      this.notificationResult = 'Notification sent successfully';
      console.info('Succeeded in sending notification');
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      this.notificationResult = `Failed: ${businessError.message}`;
      console.error(`Failed to send notification: ${businessError.code}, ${businessError.message}`);
      
      switch (businessError.code) {
        case 1008500001:
          console.error('Network error');
          break;
        case 1008500003:
          console.error('Device disconnected');
          break;
        case 1008500004:
          console.error('App not applied for Wear Engine service');
          break;
        case 1008500006:
          console.error('User privacy not agreed');
          break;
        case 401:
          console.error('Parameter error');
          break;
        default:
          console.error(`Unknown error: ${businessError.code}`);
      }
    }
  }

  build() {
    Column() {
      Text('Wear Engine Notification Example')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })

      Text(`Connected Devices: ${this.deviceList.length}`)
        .fontSize(16)
        .margin({ bottom: 10 })

      if (this.targetDevice) {
        Text(`Target Device: ${this.targetDevice.name || 'Unknown'}`)
          .fontSize(16)
          .margin({ bottom: 10 })
      }

      Text(this.notificationResult)
        .fontSize(14)
        .margin({ bottom: 20 })

      Button('Send No Button Notification')
        .onClick(() => this.sendNotification(0))
        .width('80%')
        .margin({ bottom: 10 })

      Button('Send One Button Notification')
        .onClick(() => this.sendNotification(1))
        .width('80%')
        .margin({ bottom: 10 })

      Button('Send Two Buttons Notification')
        .onClick(() => this.sendNotification(2))
        .width('80%')
        .margin({ bottom: 10 })

      Button('Send Three Buttons Notification')
        .onClick(() => this.sendNotification(3))
        .width('80%')
        .margin({ bottom: 10 })

      Button('Refresh Device List')
        .onClick(() => this.queryConnectedDevices())
        .width('80%')
        .margin({ top: 20 })
    }
    .width('100%')
    .padding(20)
  }
}