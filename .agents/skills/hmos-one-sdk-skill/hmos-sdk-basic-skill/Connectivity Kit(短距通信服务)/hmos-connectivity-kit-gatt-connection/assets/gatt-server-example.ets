import { ble, constant } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG: string = 'GattServerManager';

export class GattServerManager {
  device = '';
  gattServer: ble.GattServer | undefined = undefined;
  connectState: ble.ProfileConnectionState = constant.ProfileConnectionState.STATE_DISCONNECTED;
  myServiceUuid: string = '00001810-0000-1000-8000-00805F9B34FB';
  myCharacteristicUuid: string = '00001820-0000-1000-8000-00805F9B34FB';
  myFirstDescriptorUuid: string = '00002902-0000-1000-8000-00805F9B34FB';
  mySecondDescriptorUuid: string = '00008888-0000-1000-8000-00805F9B34FB';
  charBuffer = new ArrayBuffer(2);
  charValue = new Uint8Array(this.charBuffer);
  firDescBuffer = new ArrayBuffer(2);
  firDescValue = new Uint8Array(this.firDescBuffer);
  secDescBuffer = new ArrayBuffer(2);
  secDescValue = new Uint8Array(this.secDescBuffer);

  private initDescriptor(des: string, value: ArrayBuffer): ble.BLEDescriptor {
    let descriptor: ble.BLEDescriptor = {
      serviceUuid: this.myServiceUuid,
      characteristicUuid: this.myCharacteristicUuid,
      descriptorUuid: des,
      descriptorValue: value
    };
    return descriptor;
  }

  private initCharacteristic(): ble.BLECharacteristic {
    let descriptors: Array<ble.BLEDescriptor> = [];
    descriptors[0] = this.initDescriptor(this.myFirstDescriptorUuid, this.firDescBuffer);
    this.secDescValue[0] = 31;
    this.secDescValue[1] = 32;
    descriptors[1] = this.initDescriptor(this.mySecondDescriptorUuid, this.secDescBuffer);
    this.charValue[0] = 1;
    this.charValue[1] = 2;
    let characteristic: ble.BLECharacteristic = {
      serviceUuid: this.myServiceUuid,
      characteristicUuid: this.myCharacteristicUuid,
      characteristicValue: this.charBuffer,
      descriptors: descriptors
    };
    return characteristic;
  }

  onGattServerStateChange = (stateInfo: ble.BLEConnectionChangeState) => {
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
    console.info(TAG, 'onGattServerStateChange: device=' + stateInfo.deviceId + ', state=' + state);
    this.device = stateInfo.deviceId;
  }

  onCharacteristicRead = (charReq: ble.CharacteristicReadRequest) => {
    let deviceId: string = charReq.deviceId;
    let transId: number = charReq.transId;
    let offset: number = charReq.offset;
    console.info(TAG, 'receive characteristicRead: uuid: ' + charReq.characteristicUuid + ', value: ' + JSON.stringify(this.charValue));
    let serverResponse: ble.ServerResponse = {
      deviceId: deviceId,
      transId: transId,
      status: 0,
      offset: offset,
      value: this.charBuffer
    };
    try {
      this.gattServer?.sendResponse(serverResponse);
    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  };

  private checkDescriptorNotification(buffer: Uint8Array): boolean {
    const notify = new ArrayBuffer(2);
    let notifyValue = new Uint8Array(notify);
    notifyValue.set([1, 0]);
    return notifyValue.every((value, index) => value === buffer[index]);
  }

  private checkDescriptorIndication(buffer: Uint8Array): boolean {
    const notify = new ArrayBuffer(2);
    let notifyValue = new Uint8Array(notify);
    notifyValue.set([2, 0]);
    return notifyValue.every((value, index) => value === buffer[index]);
  }

  onCharacteristicWrite = (charReq: ble.CharacteristicWriteRequest) => {
    let deviceId: string = charReq.deviceId;
    let transId: number = charReq.transId;
    let offset: number = charReq.offset;
    this.charBuffer = charReq.value;
    this.charValue = new Uint8Array(charReq.value);
    console.info(TAG, 'receive characteristicWrite: uuid: ' + charReq.characteristicUuid + ', needRsp=' + charReq.needRsp + ', value: ' + JSON.stringify(this.charValue));
    if (!charReq.needRsp) {
      return;
    }
    let rspBuffer = new ArrayBuffer(0);
    let serverResponse: ble.ServerResponse = {
      deviceId: deviceId,
      transId: transId,
      status: 0,
      offset: offset,
      value: rspBuffer
    };
    try {
      this.gattServer?.sendResponse(serverResponse);
      this.sendCharacterChange();
    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  onDescriptorRead = (desReq: ble.DescriptorReadRequest) => {
    let deviceId: string = desReq.deviceId;
    let transId: number = desReq.transId;
    let offset: number = desReq.offset;
    let tmpBuffer = new ArrayBuffer(2);
    if (desReq.descriptorUuid == this.myFirstDescriptorUuid) {
      tmpBuffer = this.firDescBuffer;
    } else {
      tmpBuffer = this.secDescBuffer;
    }
    let tmpValue = new Uint8Array(tmpBuffer);
    console.info(TAG, 'receive descriptorRead: ' + desReq.descriptorUuid + ', tmpValue: ' + JSON.stringify(tmpValue));
    let serverResponse: ble.ServerResponse = {
      deviceId: deviceId,
      transId: transId,
      status: 0,
      offset: offset,
      value: tmpBuffer
    };
    try {
      this.gattServer?.sendResponse(serverResponse);
    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  onDescriptorWrite = (desReq: ble.DescriptorWriteRequest) => {
    let deviceId: string = desReq.deviceId;
    let transId: number = desReq.transId;
    let offset: number = desReq.offset;
    console.info(TAG, 'receive descriptorWrite: uuid: ' + desReq.descriptorUuid + ', needRsp: ' + desReq.needRsp + ', value: ' + JSON.stringify(new Uint8Array(desReq.value)));
    if (desReq.descriptorUuid == this.myFirstDescriptorUuid) {
      this.firDescBuffer = desReq.value;
      this.firDescValue = new Uint8Array(desReq.value);
    } else {
      this.secDescBuffer = desReq.value;
      this.secDescValue = new Uint8Array(desReq.value);
    }
    if (!desReq.needRsp) {
      return;
    }
    let rspBuffer = new ArrayBuffer(0);
    let serverResponse: ble.ServerResponse = {
      deviceId: deviceId,
      transId: transId,
      status: 0,
      offset: offset,
      value: rspBuffer
    };
    try {
      this.gattServer?.sendResponse(serverResponse);
    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  public registerServer() {
    let characteristics: Array<ble.BLECharacteristic> = [];
    let characteristic = this.initCharacteristic();
    characteristics.push(characteristic);
    let gattService: ble.GattService = {
      serviceUuid: this.myServiceUuid,
      isPrimary: true,
      characteristics: characteristics
    };
    console.info(TAG, 'registerServer ' + this.myServiceUuid);
    try {
      this.gattServer = ble.createGattServer();
      this.gattServer.addService(gattService);
      this.gattServer.on('connectionStateChange', this.onGattServerStateChange);
      this.gattServer.on('characteristicRead', this.onCharacteristicRead);
      this.gattServer.on('characteristicWrite', this.onCharacteristicWrite);
      this.gattServer.on('descriptorRead', this.onDescriptorRead);
      this.gattServer.on('descriptorWrite', this.onDescriptorWrite);
    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  public sendCharacterChange() {
    console.info(TAG, 'sendCharacterChange: uuid: ' + this.myCharacteristicUuid + ', value: ' + JSON.stringify(new Uint8Array(this.charBuffer)));
    if (this.checkDescriptorNotification(this.firDescValue)) {
      let notifyCharacter: ble.NotifyCharacteristic = {
        serviceUuid: this.myServiceUuid,
        characteristicUuid: this.myCharacteristicUuid,
        characteristicValue: this.charBuffer,
        confirm: false
      };
      console.info(TAG, 'sendCharacterChange notification');
      this.gattServer?.notifyCharacteristicChanged(this.device, notifyCharacter, (err: BusinessError) => {
        if (err) {
          console.error(TAG, 'notifyCharacteristicChanged notification callback failed');
        } else {
          console.info(TAG, 'notifyCharacteristicChanged notification callback successful');
        }
      });
    } else if (this.checkDescriptorIndication(this.firDescValue)) {
      let notifyCharacter: ble.NotifyCharacteristic = {
        serviceUuid: '00001810-0000-1000-8000-00805F9B34FB',
        characteristicUuid: '00001820-0000-1000-8000-00805F9B34FB',
        characteristicValue: this.charBuffer,
        confirm: true
      };
      console.info(TAG, 'sendCharacterChange indication');
      this.gattServer?.notifyCharacteristicChanged(this.device, notifyCharacter, (err: BusinessError) => {
        if (err) {
          console.error(TAG, 'notifyCharacteristicChanged indication callback failed');
        } else {
          console.info(TAG, 'notifyCharacteristicChanged indication callback successful');
        }
      });
    } else {
      console.info(TAG, 'notification/indication is disabled');
    }
  }

  public unRegisterServer() {
    if (!this.gattServer) {
      console.error(TAG, 'no gattServer');
      return;
    }
    console.info(TAG, 'unRegisterServer ' + this.myServiceUuid);
    try {
      this.gattServer.removeService(this.myServiceUuid);
      this.gattServer.off('connectionStateChange', this.onGattServerStateChange);
      this.gattServer.off('characteristicRead', this.onCharacteristicRead);
      this.gattServer.off('characteristicWrite', this.onCharacteristicWrite);
      this.gattServer.off('descriptorRead', this.onDescriptorRead);
      this.gattServer.off('descriptorWrite', this.onDescriptorWrite);
      this.gattServer.close();
    } catch (err) {
      console.error(TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }
}

let gattServerManager = new GattServerManager();
export default gattServerManager as GattServerManager;