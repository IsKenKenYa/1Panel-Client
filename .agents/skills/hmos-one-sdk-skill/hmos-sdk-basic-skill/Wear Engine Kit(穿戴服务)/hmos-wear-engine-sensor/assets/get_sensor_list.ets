import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct GetSensorListExample {
  @State sensorList: wearEngine.Sensor[] = [];
  @State deviceList: wearEngine.Device[] = [];
  @State selectedDevice: wearEngine.Device | null = null;
  @State message: string = '';

  async getConnectedDevices(): Promise<void> {
    try {
      let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
      let devices: wearEngine.Device[] = await deviceClient.getConnectedDevices();
      this.deviceList = devices;
      
      if (devices.length === 0) {
        this.message = 'No connected device found';
        return;
      }
      
      this.selectedDevice = devices[0];
      this.message = `Found ${devices.length} connected device(s)`;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.message = `Failed to get devices. Code: ${err.code}, Message: ${err.message}`;
    }
  }

  async getSensorList(): Promise<void> {
    if (!this.selectedDevice) {
      this.message = 'Please select a device first';
      return;
    }

    try {
      let sensorClient: wearEngine.SensorClient = wearEngine.getSensorClient(this.getUIContext().getHostContext());
      let sensors: wearEngine.Sensor[] = await sensorClient.getSensorList(this.selectedDevice.randomId);
      
      this.sensorList = sensors;
      this.message = `Succeeded in getting sensor list. Total: ${sensors.length} sensors`;
      
      sensors.forEach((sensor, index) => {
        console.info(`Sensor[${index}]: name=${sensor.name}, id=${sensor.id}, type=${sensor.type}`);
      });
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.message = `Failed to get sensor list. Code: ${err.code}, Message: ${err.message}`;
    }
  }

  build() {
    Column() {
      Text('Get Sensor List Example')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      Button('Get Connected Devices')
        .width('80%')
        .onClick(() => {
          this.getConnectedDevices();
        })
        .margin({ bottom: 10 });

      if (this.deviceList.length > 0) {
        Text(`Devices: ${this.deviceList.length}`)
          .fontSize(16)
          .margin({ bottom: 10 });

        List() {
          ForEach(this.deviceList, (device: wearEngine.Device) => {
            ListItem() {
              Row() {
                Text(`Device: ${device.name || 'Unknown'}`)
                  .fontSize(14);
                Radio({ value: device.randomId, group: 'deviceGroup' })
                  .checked(this.selectedDevice?.randomId === device.randomId)
                  .onChange((isChecked: boolean) => {
                    if (isChecked) {
                      this.selectedDevice = device;
                    }
                  });
              }
            }
          });
        }
        .width('80%')
        .height(100)
        .margin({ bottom: 20 });
      }

      Button('Get Sensor List')
        .width('80%')
        .enabled(this.selectedDevice !== null)
        .onClick(() => {
          this.getSensorList();
        })
        .margin({ bottom: 10 });

      if (this.sensorList.length > 0) {
        Text(`Sensors: ${this.sensorList.length}`)
          .fontSize(16)
          .margin({ bottom: 10 });

        List() {
          ForEach(this.sensorList, (sensor: wearEngine.Sensor) => {
            ListItem() {
              Column() {
                Text(`Name: ${sensor.name}`)
                  .fontSize(14);
                Text(`ID: ${sensor.id}`)
                  .fontSize(14);
                Text(`Type: ${this.getSensorTypeName(sensor.type)}`)
                  .fontSize(14);
                Text(`Accuracy: ${sensor.accuracy || 'N/A'} ms`)
                  .fontSize(14);
              }
              .margin({ bottom: 10 });
            }
          });
        }
        .width('80%')
        .height(200);
      }

      Text(this.message)
        .fontSize(14)
        .fontColor(Color.Red)
        .margin({ top: 20 });
    }
    .width('100%')
    .height('100%');
  }

  getSensorTypeName(type: wearEngine.SensorType): string {
    switch (type) {
      case wearEngine.SensorType.ACCELEROMETER:
        return 'Accelerometer (ACC)';
      case wearEngine.SensorType.GYROSCOPE:
        return 'Gyroscope (GYRO)';
      case wearEngine.SensorType.MAGNETIC_FIELD:
        return 'Magnetic Field (MAG)';
      case wearEngine.SensorType.HEART_RATE:
        return 'Heart Rate (HR)';
      case wearEngine.SensorType.PHOTOPLETHYSMOGRAPHY:
        return 'PPG';
      case wearEngine.SensorType.ELECTROCARDIOGRAPHY:
        return 'ECG';
      default:
        return 'Unknown';
    }
  }
}