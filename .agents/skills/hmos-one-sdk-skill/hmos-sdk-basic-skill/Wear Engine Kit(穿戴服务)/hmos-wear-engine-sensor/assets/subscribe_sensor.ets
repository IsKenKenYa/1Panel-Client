import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct SubscribeSensorExample {
  @State isSubscribed: boolean = false;
  @State sensorData: string = '';
  @State heartRate: number = 0;
  @State accData: number[] = [];
  @State message: string = '';
  
  private selectedDevice: wearEngine.Device | null = null;
  private sensorClient: wearEngine.SensorClient | null = null;
  private sensorCallback: (sensorResult: wearEngine.SensorResult) => void | null = null;
  private sensorType: wearEngine.SensorType = wearEngine.SensorType.HEART_RATE;

  async aboutToAppear(): Promise<void> {
    try {
      this.sensorClient = wearEngine.getSensorClient(this.getUIContext().getHostContext());
      let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
      let devices: wearEngine.Device[] = await deviceClient.getConnectedDevices();
      
      if (devices.length > 0) {
        this.selectedDevice = devices[0];
        this.message = `Selected device: ${devices[0].name || 'Unknown'}`;
      } else {
        this.message = 'No connected device found';
      }
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.message = `Init failed. Code: ${err.code}, Message: ${err.message}`;
    }
  }

  async subscribeSensor(): Promise<void> {
    if (!this.selectedDevice || !this.sensorClient) {
      this.message = 'Device not selected or sensor client not initialized';
      return;
    }

    try {
      this.sensorCallback = (sensorResult: wearEngine.SensorResult) => {
        if (sensorResult.errorCode) {
          this.message = `Sensor error: ${sensorResult.errorCode}`;
          this.handleSensorErrorCode(sensorResult.errorCode);
          return;
        }

        if (sensorResult.data && sensorResult.data.length > 0) {
          sensorResult.data.forEach((sensorData, index) => {
            this.parseSensorData(sensorData);
          });
        }
      };

      await this.sensorClient.subscribeSensor(
        this.selectedDevice.randomId,
        this.sensorType,
        this.sensorCallback
      );

      this.isSubscribed = true;
      this.message = `Succeeded in subscribing ${this.getSensorTypeName(this.sensorType)} sensor`;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.message = `Failed to subscribe sensor. Code: ${err.code}, Message: ${err.message}`;
    }
  }

  async unsubscribeSensor(): Promise<void> {
    if (!this.selectedDevice || !this.sensorClient || !this.sensorCallback) {
      this.message = 'Cannot unsubscribe: missing required components';
      return;
    }

    try {
      await this.sensorClient.unsubscribeSensor(
        this.selectedDevice.randomId,
        this.sensorType,
        this.sensorCallback
      );

      this.isSubscribed = false;
      this.sensorData = '';
      this.heartRate = 0;
      this.accData = [];
      this.message = `Succeeded in unsubscribing ${this.getSensorTypeName(this.sensorType)} sensor`;
      
      this.sensorCallback = null;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.message = `Failed to unsubscribe sensor. Code: ${err.code}, Message: ${err.message}`;
    }
  }

  parseSensorData(sensorData: wearEngine.SensorData): void {
    switch (sensorData.sensorType) {
      case wearEngine.SensorType.HEART_RATE:
        if (sensorData.data.length > 0) {
          this.heartRate = sensorData.data[0];
          this.sensorData = `Heart Rate: ${this.heartRate} bpm`;
        }
        break;

      case wearEngine.SensorType.ACCELEROMETER:
        this.accData = sensorData.data;
        this.sensorData = `ACC Data: ${sensorData.data.length} values\nFirst 3 values: ${sensorData.data.slice(0, 3).join(', ')}`;
        break;

      case wearEngine.SensorType.GYROSCOPE:
        this.sensorData = `GYRO Data: ${sensorData.data.length} values`;
        break;

      case wearEngine.SensorType.PHOTOPLETHYSMOGRAPHY:
        this.sensorData = `PPG Data: channel=${sensorData.channel}, ${sensorData.data.length} values`;
        break;

      case wearEngine.SensorType.ELECTROCARDIOGRAPHY:
        this.sensorData = `ECG Data: channel=${sensorData.channel}, ${sensorData.data.length} values`;
        break;

      default:
        this.sensorData = `Unknown sensor type: ${sensorData.sensorType}`;
    }

    console.info(`Sensor data: type=${sensorData.sensorType}, timestamp=${sensorData.timestamp}, channel=${sensorData.channel}`);
  }

  handleSensorErrorCode(errorCode: number): void {
    switch (errorCode) {
      case 300:
        this.message = 'Device not being worn. Please wear the device.';
        break;
      case 301:
        this.message = 'Device lead off. Please check device connection.';
        break;
      case 302:
        this.message = 'Sensor turned off manually.';
        break;
      case 303:
        this.message = 'Sensor occupied by other app.';
        break;
      case 304:
        this.message = 'Sensor not supported on this device.';
        break;
      default:
        this.message = `Unknown sensor error: ${errorCode}`;
    }
  }

  build() {
    Column() {
      Text('Subscribe Sensor Example')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      Row() {
        Text('Sensor Type:')
          .fontSize(16);
        
        Select([
          { value: 'Heart Rate (HR)', icon: $r('sys.media.ohos_ic_public_heart') },
          { value: 'Accelerometer (ACC)', icon: $r('sys.media.ohos_ic_public_location') },
          { value: 'Gyroscope (GYRO)', icon: $r('sys.media.ohos_ic_public_location') }
        ])
        .selected(this.sensorType === wearEngine.SensorType.HEART_RATE ? 0 : 
                  this.sensorType === wearEngine.SensorType.ACCELEROMETER ? 1 : 2)
        .value('Heart Rate (HR)')
        .onSelect((index: number) => {
          if (index === 0) {
            this.sensorType = wearEngine.SensorType.HEART_RATE;
          } else if (index === 1) {
            this.sensorType = wearEngine.SensorType.ACCELEROMETER;
          } else if (index === 2) {
            this.sensorType = wearEngine.SensorType.GYROSCOPE;
          }
          
          if (this.isSubscribed) {
            this.unsubscribeSensor();
          }
        });
      }
      .width('80%')
      .margin({ bottom: 20 });

      if (!this.isSubscribed) {
        Button('Subscribe Sensor')
          .width('80%')
          .onClick(() => {
            this.subscribeSensor();
          })
          .margin({ bottom: 10 });
      } else {
        Button('Unsubscribe Sensor')
          .width('80%')
          .backgroundColor(Color.Red)
          .onClick(() => {
            this.unsubscribeSensor();
          })
          .margin({ bottom: 10 });
      }

      if (this.heartRate > 0) {
        Text(`Heart Rate: ${this.heartRate} bpm`)
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Red)
          .margin({ top: 20 });
      }

      if (this.sensorData) {
        Text(this.sensorData)
          .fontSize(14)
          .margin({ top: 10 });
      }

      Text(this.message)
        .fontSize(14)
        .fontColor(this.message.includes('Succeeded') ? Color.Green : Color.Red)
        .margin({ top: 20 });
    }
    .width('100%')
    .height('100%');
  }

  getSensorTypeName(type: wearEngine.SensorType): string {
    switch (type) {
      case wearEngine.SensorType.ACCELEROMETER:
        return 'Accelerometer';
      case wearEngine.SensorType.GYROSCOPE:
        return 'Gyroscope';
      case wearEngine.SensorType.HEART_RATE:
        return 'Heart Rate';
      case wearEngine.SensorType.PHOTOPLETHYSMOGRAPHY:
        return 'PPG';
      case wearEngine.SensorType.ELECTROCARDIOGRAPHY:
        return 'ECG';
      default:
        return 'Unknown';
    }
  }
}