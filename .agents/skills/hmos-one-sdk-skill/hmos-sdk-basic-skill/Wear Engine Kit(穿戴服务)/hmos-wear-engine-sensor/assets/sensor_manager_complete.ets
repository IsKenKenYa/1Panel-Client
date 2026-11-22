import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

interface SensorSubscription {
  sensorType: wearEngine.SensorType;
  callback: (sensorResult: wearEngine.SensorResult) => void;
  isActive: boolean;
}

@Entry
@Component
struct SensorManagerComplete {
  @State deviceList: wearEngine.Device[] = [];
  @State selectedDevice: wearEngine.Device | null = null;
  @State sensorList: wearEngine.Sensor[] = [];
  @State subscriptions: Map<wearEngine.SensorType, SensorSubscription> = new Map();
  @State messages: string[] = [];
  @State currentData: Map<wearEngine.SensorType, string> = new Map();
  
  private deviceClient: wearEngine.DeviceClient | null = null;
  private sensorClient: wearEngine.SensorClient | null = null;
  private authClient: wearEngine.AuthClient | null = null;

  async aboutToAppear(): Promise<void> {
    try {
      let context = this.getUIContext().getHostContext();
      this.deviceClient = wearEngine.getDeviceClient(context);
      this.sensorClient = wearEngine.getSensorClient(context);
      this.authClient = wearEngine.getAuthClient(context);
      
      await this.checkAuthorization();
      await this.getConnectedDevices();
      
      this.addMessage('Sensor manager initialized successfully');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.addMessage(`Init failed: ${err.code} - ${err.message}`);
    }
  }

  async checkAuthorization(): Promise<void> {
    if (!this.authClient) {
      return;
    }

    try {
      let authResponse = await this.authClient.getAuthorization();
      this.addMessage(`Current authorized permissions: ${authResponse.permissions.join(', ')}`);
      
      if (!authResponse.permissions.includes(wearEngine.Permission.HEALTH_SENSOR) && 
          !authResponse.permissions.includes(wearEngine.Permission.MOTION_SENSOR)) {
        this.addMessage('No sensor permissions authorized. Requesting...');
        
        let request: wearEngine.AuthorizationRequest = {
          permissions: [
            wearEngine.Permission.HEALTH_SENSOR,
            wearEngine.Permission.MOTION_SENSOR
          ]
        };
        
        let response = await this.authClient.requestAuthorization(request);
        this.addMessage(`Authorization result: ${response.permissions.join(', ')}`);
      }
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.addMessage(`Authorization check failed: ${err.code}`);
    }
  }

  async getConnectedDevices(): Promise<void> {
    if (!this.deviceClient) {
      return;
    }

    try {
      let devices = await this.deviceClient.getConnectedDevices();
      this.deviceList = devices;
      
      if (devices.length > 0) {
        this.selectedDevice = devices[0];
        this.addMessage(`Found ${devices.length} device(s). Selected: ${devices[0].name || 'Unknown'}`);
        await this.getSensorList();
      } else {
        this.addMessage('No connected devices found');
      }
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.addMessage(`Get devices failed: ${err.code}`);
    }
  }

  async getSensorList(): Promise<void> {
    if (!this.selectedDevice || !this.sensorClient) {
      return;
    }

    try {
      let sensors = await this.sensorClient.getSensorList(this.selectedDevice.randomId);
      this.sensorList = sensors;
      this.addMessage(`Found ${sensors.length} sensors available`);
      
      sensors.forEach((sensor, index) => {
        console.info(`Sensor[${index}]: ${sensor.name} (${this.getSensorTypeName(sensor.type)})`);
      });
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.addMessage(`Get sensor list failed: ${err.code}`);
    }
  }

  async subscribeSensor(sensorType: wearEngine.SensorType): Promise<void> {
    if (!this.selectedDevice || !this.sensorClient) {
      this.addMessage('Cannot subscribe: device or client not ready');
      return;
    }

    if (this.subscriptions.has(sensorType) && this.subscriptions.get(sensorType)?.isActive) {
      this.addMessage(`Sensor ${this.getSensorTypeName(sensorType)} already subscribed`);
      return;
    }

    try {
      let callback = (sensorResult: wearEngine.SensorResult) => {
        this.handleSensorResult(sensorType, sensorResult);
      };

      await this.sensorClient.subscribeSensor(
        this.selectedDevice.randomId,
        sensorType,
        callback
      );

      this.subscriptions.set(sensorType, {
        sensorType: sensorType,
        callback: callback,
        isActive: true
      });

      this.addMessage(`Subscribed to ${this.getSensorTypeName(sensorType)} successfully`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.addMessage(`Subscribe failed: ${err.code} - ${err.message}`);
    }
  }

  async unsubscribeSensor(sensorType: wearEngine.SensorType): Promise<void> {
    if (!this.selectedDevice || !this.sensorClient) {
      return;
    }

    if (!this.subscriptions.has(sensorType) || !this.subscriptions.get(sensorType)?.isActive) {
      this.addMessage(`Sensor ${this.getSensorTypeName(sensorType)} not subscribed`);
      return;
    }

    try {
      let subscription = this.subscriptions.get(sensorType);
      if (!subscription) {
        return;
      }

      await this.sensorClient.unsubscribeSensor(
        this.selectedDevice.randomId,
        sensorType,
        subscription.callback
      );

      subscription.isActive = false;
      this.currentData.delete(sensorType);
      
      this.addMessage(`Unsubscribed from ${this.getSensorTypeName(sensorType)} successfully`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.addMessage(`Unsubscribe failed: ${err.code}`);
    }
  }

  handleSensorResult(sensorType: wearEngine.SensorType, sensorResult: wearEngine.SensorResult): void {
    if (sensorResult.errorCode) {
      this.handleSensorErrorCode(sensorType, sensorResult.errorCode);
      return;
    }

    if (sensorResult.data && sensorResult.data.length > 0) {
      sensorResult.data.forEach((sensorData) => {
        let displayText = this.parseSensorData(sensorData);
        this.currentData.set(sensorType, displayText);
      });
    }
  }

  parseSensorData(sensorData: wearEngine.SensorData): string {
    switch (sensorData.sensorType) {
      case wearEngine.SensorType.HEART_RATE:
        if (sensorData.data.length > 0) {
          let hr = sensorData.data[0];
          return `Heart Rate: ${hr} bpm\nTimestamp: ${sensorData.timestamp || 'N/A'}`;
        }
        return 'HR: No data';

      case wearEngine.SensorType.ACCELEROMETER:
        if (sensorData.data.length >= 3) {
          let x = sensorData.data[0];
          let y = sensorData.data[1];
          let z = sensorData.data[2];
          return `ACC: X=${x.toFixed(2)}, Y=${y.toFixed(2)}, Z=${z.toFixed(2)}\nTotal: ${sensorData.data.length} values`;
        }
        return 'ACC: Insufficient data';

      case wearEngine.SensorType.GYROSCOPE:
        return `GYRO: ${sensorData.data.length} values\nTimestamp: ${sensorData.timestamp || 'N/A'}`;

      case wearEngine.SensorType.PHOTOPLETHYSMOGRAPHY:
        return `PPG: Channel ${sensorData.channel || 0}, ${sensorData.data.length} values`;

      case wearEngine.SensorType.ELECTROCARDIOGRAPHY:
        return `ECG: Channel ${sensorData.channel || 0}, ${sensorData.data.length} values`;

      default:
        return `Unknown sensor: ${sensorData.sensorType}`;
    }
  }

  handleSensorErrorCode(sensorType: wearEngine.SensorType, errorCode: number): void {
    let errorMessages: Map<number, string> = new Map([
      [300, 'Device not being worn'],
      [301, 'Device lead off'],
      [302, 'Sensor turned off manually'],
      [303, 'Sensor occupied'],
      [304, 'Sensor not supported']
    ]);

    let message = errorMessages.get(errorCode) || `Unknown error: ${errorCode}`;
    this.addMessage(`${this.getSensorTypeName(sensorType)} error: ${message}`);
    
    if (errorCode >= 300 && errorCode <= 304) {
      this.subscriptions.get(sensorType)?.isActive = false;
    }
  }

  addMessage(message: string): void {
    this.messages.push(`${new Date().toLocaleTimeString()}: ${message}`);
    if (this.messages.length > 10) {
      this.messages.shift();
    }
  }

  getSensorTypeName(type: wearEngine.SensorType): string {
    const typeNames: Map<wearEngine.SensorType, string> = new Map([
      [wearEngine.SensorType.ACCELEROMETER, 'Accelerometer'],
      [wearEngine.SensorType.GYROSCOPE, 'Gyroscope'],
      [wearEngine.SensorType.MAGNETIC_FIELD, 'Magnetic'],
      [wearEngine.SensorType.HEART_RATE, 'Heart Rate'],
      [wearEngine.SensorType.PHOTOPLETHYSMOGRAPHY, 'PPG'],
      [wearEngine.SensorType.ELECTROCARDIOGRAPHY, 'ECG']
    ]);
    return typeNames.get(type) || 'Unknown';
  }

  build() {
    Column() {
      Text('Wear Sensor Manager')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 10 });

      if (this.selectedDevice) {
        Text(`Device: ${this.selectedDevice.name || 'Unknown'}`)
          .fontSize(16)
          .margin({ bottom: 10 });
      }

      if (this.sensorList.length > 0) {
        Text(`Available Sensors: ${this.sensorList.length}`)
          .fontSize(16)
          .margin({ bottom: 10 });

        List() {
          ForEach(this.sensorList, (sensor: wearEngine.Sensor) => {
            ListItem() {
              Row() {
                Column() {
                  Text(`${this.getSensorTypeName(sensor.type)}`)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium);
                  Text(`ID: ${sensor.id}, Accuracy: ${sensor.accuracy || 'N/A'}ms`)
                    .fontSize(12);
                }
                .width('60%');

                Toggle({ type: ToggleType.Switch, isOn: this.subscriptions.get(sensor.type)?.isActive || false })
                  .onChange((isOn: boolean) => {
                    if (isOn) {
                      this.subscribeSensor(sensor.type);
                    } else {
                      this.unsubscribeSensor(sensor.type);
                    }
                  });
              }
              .padding(10);
            }
          });
        }
        .width('90%')
        .height(150)
        .margin({ bottom: 10 });
      }

      if (this.currentData.size > 0) {
        Text('Current Sensor Data:')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 10, bottom: 5 });

        List() {
          ForEach(Array.from(this.currentData.entries()), (entry: [wearEngine.SensorType, string]) => {
            ListItem() {
              Column() {
                Text(`${this.getSensorTypeName(entry[0])}:`)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium);
                Text(entry[1])
                  .fontSize(12)
                  .margin({ top: 5 });
              }
              .width('100%')
              .padding(10);
            }
          });
        }
        .width('90%')
        .height(150);
      }

      Text('Messages:')
        .fontSize(16)
        .margin({ top: 10 });

      List() {
        ForEach(this.messages, (message: string) => {
          ListItem() {
            Text(message)
              .fontSize(12)
              .width('100%');
          }
        });
      }
      .width('90%')
      .height(100)
      .backgroundColor('#F0F0F0');
    }
    .width('100%')
    .height('100%');
  }
}