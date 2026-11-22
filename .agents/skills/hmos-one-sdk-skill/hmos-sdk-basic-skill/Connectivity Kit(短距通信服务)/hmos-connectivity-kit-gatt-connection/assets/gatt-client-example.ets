import { ble, constant } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG: string = 'GattClientManager';

export class GattClientManager {
  device: string = '';
  gattClient: ble.GattClientDevice | undefined = undefined;
  connectState: ble.ProfileConnectionState = constant.ProfileConnectionState.STATE_DISCONNECTED;
  myServiceUuid: string = '00001810-0000-1000-8000-00805F9B34FB';
  myCharacteristicUuid: string = '00001820-0000-1000-8000-00805F9B34FB';
  myFirstDescriptorUuid: string = '00002902-0000-1000-8000-00805F9B34FB';
  mySecondDescriptorUuid: string = '00008888-0000-1000-8000-00805F9B34FB';
  myService: ble.GattService | undefined = undefined;
  myCharacteristic: ble.BLECharacteristic | undefined = undefined;
  myFirstDescriptor: ble.BLEDescriptor | undefined = undefined;
  mySecondDescriptor: ble.BLEDescriptor | undefined = undefined;
  foundService: boolean = false;
  foundChar: boolean = false;
  foundFirstDes: boolean = false;
  foundSecondDes: boolean = false;

  private initDescriptor(des: string, value: ArrayBuffer): ble.BLEDescriptor {
    let descriptor: ble.BLEDescriptor = {
      serviceUuid: this.myServiceUuid,
      characteristicUuid: this.myCharacteristicUuid,
      descriptorUuid: des,
      descriptorValue: value
    };
    return descriptor;
  }

  private initCharacteristic(isWrite: boolean): ble.BLECharacteristic {
    let descriptors: Array<ble.BLEDescriptor> = [];
    let charBuffer = new ArrayBuffer(2);
    if (isWrite) {
      let charValue = new Uint8Array(charBuffer);
      charValue[0] = 21;
      charValue[1] = 22;
    }
    let characteristic: ble.BLECharacteristic = {
      serviceUuid: this.myServiceUuid,
      characteristicUuid: this.myCharacteristicUuid,
      characteristicValue: charBuffer,
      descriptors: descriptors
    };
    return characteristic;
  }

  private logCharacteristic(char: ble.BLECharacteristic) {
    let message = 'logCharacteristic uuid:' + char.characteristicUuid + ', value: ';
    let value = new Uint8Array(char.characteristicValue);
    message += 'logCharacteristic value: ';
    for (let i = 0; i < char.characteristicValue.byteLength; i++) {
      message += value[i] + ' ';
    }
    console.info(TAG, message);
  }

  private logDescriptor(des: ble.BLEDescriptor) {
    let message = 'logDescriptor uuid:' + des.descriptorUuid + ', value: ';
    let value = new Uint8Array(des.descriptorValue);
    message += 'logDescriptor value: ';
    for (let i = 0; i < des.descriptorValue.byteLength; i++) {
      message += value[i] + ' ';
    }
    console.info(TAG, message);
  }

  private checkService(services: Array<ble.GattService>) {
    for (let i = 0; i < services.length; i++) {
      if (services[i].serviceUuid != this.myServiceUuid) {
        continue;
      }
      this.myService = services[i];
      this.foundService = true;
      for (let j = 0; j < services[i].characteristics.length; j++) {
        if (services[i].characteristics[j].characteristicUuid != this.myCharacteristicUuid) {
          continue;
        }
        this.logCharacteristic(services[i].characteristics[j]);
        this.myCharacteristic = services[i].characteristics[j];
        this.foundChar = true;
        for (let k = 0; k < services[i].characteristics[j].descriptors.length; k++) {
          if (services[i].characteristics[j].descriptors[k].descriptorUuid == this.myFirstDescriptorUuid) {
            this.myFirstDescriptor = services[i].characteristics[j].descriptors[k];
            this.foundFirstDes = true;
            continue;
          }
          if (services[i].characteristics[j].descriptors[k].descriptorUuid == this.mySecondDescriptorUuid) {
            this.mySecondDescriptor = services[i].characteristics[j].descriptors[k];
            this.foundSecondDes = true;
            continue;
          }
        }
      }
    }
    console.info(TAG, 'foundService: ' + this.foundService + ', foundChar: ' + this.foundChar +
      ', foundFirDes: ' + this.foundFirstDes + ', foundSecDes: ' + this.foundSecondDes);
  }

  onGattClientStateChange = (stateInfo: ble.BLEConnectionChangeState) => {
    let state = '';
    switch (stateInfo.state) {
      case 0:
        state = 'DISCONNECTED';
        break;
      case 1:
        state = 'CONNECTING';
        break;
      case 2:
        state = 'CONNECTED';
        break;
      case 3:
        state = 'DISCONNECTING';
        break;
      default:
        state = 'undefined';
        break;
    }
    console.info(TAG, 'onGattClientStateChange: device=' + stateInfo.deviceId + ', state=' + state);
    if (stateInfo.deviceId == this.device) {
      this.connectState = stateInfo.state;
    }
  };

  public startConnect(peerDevice: string) {
    if (this.connectState != constant.ProfileConnectionState.STATE_DISCONNECTED) {
      console.error(TAG, 'startConnect failed');
      return;
    }
    console.info(TAG, 'startConnect ' + peerDevice);
    this.device = peerDevice;
    this.gattClient = ble.createGattClientDevice(peerDevice);
    try {
      this.gattClient.on('BLEConnectionStateChange', this.onGattClientStateChange);
      this.gattClient.connect();
    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  public async discoverServices() {
    if (!this.gattClient) {
      console.error(TAG, 'gattClient does not exist');
      return;
    }
    console.info(TAG, 'discoverServices');
    try {
      let serverService = await this.gattClient.getServices();
      this.checkService(serverService);
      if (typeof this.myService !== 'undefined') {
        console.info(TAG, 'Service: ' + JSON.stringify(this.myService));
      }
      if (typeof this.myCharacteristic !== 'undefined') {
        this.logCharacteristic(this.myCharacteristic);
      }
      if (typeof this.myFirstDescriptor !== 'undefined') {
        this.logDescriptor(this.myFirstDescriptor);
      }
      if (typeof this.mySecondDescriptor !== 'undefined') {
        this.logDescriptor(this.mySecondDescriptor);
      }
    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  public readCharacteristicValue() {
    if (!this.gattClient || this.connectState != constant.ProfileConnectionState.STATE_CONNECTED) {
      console.error(TAG, 'gattClient does not exist or state not connected');
      return;
    }
    if (!this.foundChar) {
      console.error(TAG, 'server characteristic does not exist');
      return;
    }
    let characteristic = this.initCharacteristic(false);
    console.info(TAG, 'readCharacteristicValue');
    try {
      this.gattClient.readCharacteristicValue(characteristic).then((outData: ble.BLECharacteristic) => {
        this.myCharacteristic = outData;
        this.logCharacteristic(this.myCharacteristic);
      });
    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  public writeCharacteristicValue() {
    if (!this.gattClient || this.connectState != constant.ProfileConnectionState.STATE_CONNECTED) {
      console.error(TAG, 'gattClient does not exist or state not connected');
      return;
    }
    if (!this.foundChar) {
      console.error(TAG, 'server characteristic does not exist');
      return;
    }
    let characteristic = this.initCharacteristic(true);
    console.info(TAG, 'writeCharacteristicValue');
    try {
      this.gattClient.writeCharacteristicValue(characteristic, ble.GattWriteType.WRITE, (err) => {
        if (err) {
          console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
          return;
        }
        console.info(TAG, 'writeCharacteristicValue success');
      });
    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  public readDescriptorValue() {
    if (!this.gattClient || this.connectState != constant.ProfileConnectionState.STATE_CONNECTED) {
      console.error(TAG, 'gattClient does not exist or state not connected');
      return;
    }
    if (!this.foundSecondDes) {
      console.error(TAG, 'server descriptor does not exist');
      return;
    }
    let descBuffer = new ArrayBuffer(0);
    let descriptor = this.initDescriptor(this.mySecondDescriptorUuid, descBuffer);
    console.info(TAG, 'readDescriptorValue');
    try {
      this.gattClient.readDescriptorValue(descriptor).then((outData: ble.BLEDescriptor) => {
        this.logDescriptor(outData);
      });
    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  public writeDescriptorValue() {
    if (!this.gattClient || this.connectState != constant.ProfileConnectionState.STATE_CONNECTED) {
      console.error(TAG, 'gattClient does not exist or state not connected');
      return;
    }
    if (!this.foundSecondDes) {
      console.error(TAG, 'server descriptor does not exist');
      return;
    }
    let descBuffer = new ArrayBuffer(2);
    let descValue = new Uint8Array(descBuffer);
    descValue[0] = 41;
    descValue[1] = 42;
    let descriptor = this.initDescriptor(this.mySecondDescriptorUuid, descBuffer);
    console.info(TAG, 'writeDescriptorValue');
    try {
      this.gattClient.writeDescriptorValue(descriptor, (err) => {
        if (err) {
          console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
          return;
        }
        console.info(TAG, 'writeDescriptorValue success');
      });
    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  onCharacteristicChange = (char: ble.BLECharacteristic) => {
    console.info(TAG, 'onCharacteristicChange: uuid: ' + char.characteristicUuid + ', value: ' + JSON.stringify(new Uint8Array(char.characteristicValue)));
    this.myCharacteristic = char;
    this.logCharacteristic(this.myCharacteristic);
  }

  public Notify(enable: boolean) {
    if (!this.gattClient || this.connectState != constant.ProfileConnectionState.STATE_CONNECTED) {
      console.error(TAG, 'gattClient does not exist or state not connected');
      return;
    }
    if (!this.foundFirstDes) {
      console.error(TAG, 'server client configuration descriptor does not exist');
      return;
    }
    console.info(TAG, 'Notify ' + this.device + ' enable: ' + enable);
    try {
      this.gattClient.on('BLECharacteristicChange', this.onCharacteristicChange);
      this.gattClient.setCharacteristicChangeNotification(this.myCharacteristic, enable, (err: BusinessError) => {
        if (err) {
          console.error('setCharacteristicChangeNotification callback failed');
        } else {
          console.info('setCharacteristicChangeNotification callback successful');
        }
      });
    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  public Indicate(enable: boolean) {
    if (!this.gattClient || this.connectState != constant.ProfileConnectionState.STATE_CONNECTED) {
      console.error(TAG, 'gattClient does not exist or state not connected');
      return;
    }
    if (!this.foundFirstDes) {
      console.error(TAG, 'server client configuration descriptor does not exist');
      return;
    }
    console.info(TAG, 'Indicate ' + this.device + ' enable: ' + enable);
    try {
      this.gattClient.on('BLECharacteristicChange', this.onCharacteristicChange);
      this.gattClient.setCharacteristicChangeIndication(this.myCharacteristic, enable, (err: BusinessError) => {
        if (err) {
          console.error('setCharacteristicChangeIndication callback failed');
        } else {
          console.info('setCharacteristicChangeIndication callback successful');
        }
      });
    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  public stopConnect() {
    if (!this.gattClient || this.connectState != constant.ProfileConnectionState.STATE_CONNECTED) {
      console.error(TAG, 'gattClient does not exist or state not connected');
      return;
    }
    console.info(TAG, 'stopConnect ' + this.device);
    try {
      this.gattClient.disconnect();
      this.gattClient.off('BLEConnectionStateChange', this.onGattClientStateChange);
      this.gattClient.off('BLECharacteristicChange', this.onCharacteristicChange);
      this.gattClient.close();
    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }
}

let gattClientManager = new GattClientManager();
export default gattClientManager as GattClientManager;