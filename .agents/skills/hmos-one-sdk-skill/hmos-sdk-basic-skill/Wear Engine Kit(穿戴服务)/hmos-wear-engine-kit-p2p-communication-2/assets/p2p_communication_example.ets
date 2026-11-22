import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { fileIo } from '@kit.CoreFileKit';

@Entry
@Component
struct P2PCommunicationPage {
  @State deviceList: wearEngine.Device[] = [];
  @State targetDevice: wearEngine.Device | null = null;
  @State messageContent: string = '';
  @State filePath: string = '';
  @State remoteBundleName: string = 'com.example.remoteapp';
  @State remoteFingerprint: string = '';
  
  private deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
  private p2pClient: wearEngine.P2pClient = wearEngine.getP2pClient(this.getUIContext().getHostContext());
  
  aboutToAppear() {
    this.queryConnectedDevices();
  }
  
  async queryConnectedDevices() {
    try {
      let devices: wearEngine.Device[] = await this.deviceClient.getConnectedDevices();
      this.deviceList = devices;
      
      for (let device of devices) {
        let isSupportP2P = await device.isWearEngineCapabilitySupported(
          wearEngine.WearEngineCapability.P2P_COMMUNICATION
        );
        if (isSupportP2P) {
          this.targetDevice = device;
          console.info(`Found P2P capable device: ${device.name}`);
          break;
        }
      }
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to get devices. Code: ${err.code}, Message: ${err.message}`);
    }
  }
  
  async checkRemoteAppInstalled() {
    if (!this.targetDevice) {
      console.error('No target device selected');
      return false;
    }
    
    try {
      let isInstalled: boolean = await this.p2pClient.isRemoteAppInstalled(
        this.targetDevice.randomId,
        this.remoteBundleName
      );
      console.info(`Remote app installed: ${isInstalled}`);
      return isInstalled;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to check app installation. Code: ${err.code}, Message: ${err.message}`);
      return false;
    }
  }
  
  async sendMessage() {
    if (!this.targetDevice) {
      console.error('No target device selected');
      return;
    }
    
    if (this.messageContent.length === 0) {
      console.error('Message content is empty');
      return;
    }
    
    if (this.messageContent.length >= 4096) {
      console.error('Message content exceeds 4096 bytes');
      return;
    }
    
    let isInstalled = await this.checkRemoteAppInstalled();
    if (!isInstalled) {
      console.error('Remote app is not installed');
      return;
    }
    
    try {
      let appInfo: wearEngine.AppInfo = {
        bundleName: this.remoteBundleName,
        fingerprint: this.remoteFingerprint
      };
      
      let appParam: wearEngine.P2pAppParam = {
        remoteApp: appInfo
      };
      
      let textEncoder: util.TextEncoder = new util.TextEncoder();
      let message: wearEngine.P2pMessage = {
        content: textEncoder.encodeInto(this.messageContent)
      };
      
      let result: wearEngine.P2pResult = await this.p2pClient.sendMessage(
        this.targetDevice.randomId,
        appParam,
        message
      );
      
      if (result.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
        console.info('Message sent successfully');
        AlertDialog.show({
          title: 'Success',
          message: 'Message sent successfully'
        });
      } else {
        console.error(`Message send failed with code: ${result.code}`);
        AlertDialog.show({
          title: 'Error',
          message: `Message send failed: ${this.handleP2pError(result.code)}`
        });
      }
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to send message. Code: ${err.code}, Message: ${err.message}`);
      AlertDialog.show({
        title: 'Error',
        message: `Failed to send message: ${err.message}`
      });
    }
  }
  
  async sendFile() {
    if (!this.targetDevice) {
      console.error('No target device selected');
      return;
    }
    
    if (this.filePath.length === 0) {
      console.error('File path is empty');
      return;
    }
    
    if (this.filePath.includes('..')) {
      console.error('File path contains illegal characters');
      return;
    }
    
    let p2pFile: wearEngine.P2pFile | undefined;
    
    try {
      p2pFile = {
        file: fileIo.openSync(this.filePath)
      };
      
      let appInfo: wearEngine.AppInfo = {
        bundleName: this.remoteBundleName,
        fingerprint: this.remoteFingerprint
      };
      
      let appParam: wearEngine.P2pAppParam = {
        remoteApp: appInfo
      };
      
      this.p2pClient.transferFile(
        this.targetDevice.randomId,
        appParam,
        p2pFile,
        (error: BusinessError, p2pResult: wearEngine.P2pResult) => {
          if (error) {
            console.error(`Transfer failed. Code: ${error.code}, Message: ${error.message}`);
            AlertDialog.show({
              title: 'Error',
              message: `Transfer failed: ${error.message}`
            });
            return;
          }
          
          if (p2pResult.code) {
            if (p2pResult.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
              console.info('File transferred successfully');
              AlertDialog.show({
                title: 'Success',
                message: 'File transferred successfully'
              });
            } else {
              console.error(`Transfer failed with code: ${p2pResult.code}`);
              AlertDialog.show({
                title: 'Error',
                message: `Transfer failed: ${this.handleP2pError(p2pResult.code)}`
              });
            }
          }
          
          if (p2pResult.progress) {
            console.info(`Transfer progress: ${p2pResult.progress}%`);
          }
        }
      );
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to send file. Code: ${err.code}, Message: ${err.message}`);
      AlertDialog.show({
        title: 'Error',
        message: `Failed to send file: ${err.message}`
      });
    } finally {
      if (p2pFile && p2pFile.file) {
        try {
          await fileIo.close(p2pFile.file);
          console.info('File closed successfully');
        } catch (closeError) {
          const err: BusinessError = closeError as BusinessError;
          console.error(`Failed to close file. Code: ${err.code}, Message: ${err.message}`);
        }
      }
    }
  }
  
  async registerMessageReceiver() {
    if (!this.targetDevice) {
      console.error('No target device selected');
      return;
    }
    
    try {
      let appInfo: wearEngine.AppInfo = {
        bundleName: this.remoteBundleName,
        fingerprint: this.remoteFingerprint
      };
      
      let appParam: wearEngine.P2pAppParam = {
        remoteApp: appInfo
      };
      
      let callback = (p2pMessage: wearEngine.P2pMessage) => {
        console.info(`Received message: ${p2pMessage.content}`);
        AlertDialog.show({
          title: 'Message Received',
          message: `Content: ${p2pMessage.content}`
        });
      };
      
      await this.p2pClient.registerMessageReceiver(
        this.targetDevice.randomId,
        appParam,
        callback
      );
      
      console.info('Message receiver registered successfully');
      AlertDialog.show({
        title: 'Success',
        message: 'Message receiver registered'
      });
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to register receiver. Code: ${err.code}, Message: ${err.message}`);
      AlertDialog.show({
        title: 'Error',
        message: `Failed to register: ${err.message}`
      });
    }
  }
  
  handleP2pError(errorCode: number): string {
    switch (errorCode) {
      case 200:
        return 'Remote app not installed';
      case 201:
        return 'Remote app not running';
      case 203:
        return 'Unknown error';
      case 206:
        return 'Communication failure';
      case 1008500001:
        return 'Network error';
      case 1008500003:
        return 'Device disconnected';
      default:
        return `Error code: ${errorCode}`;
    }
  }
  
  build() {
    Column() {
      Text('P2P Communication Demo')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });
      
      if (this.targetDevice) {
        Text(`Connected Device: ${this.targetDevice.name}`)
          .fontSize(16)
          .margin({ bottom: 10 });
        
        TextInput({ placeholder: 'Enter message content (max 4096 bytes)' })
          .width('90%')
          .height(50)
          .onChange((value: string) => {
            this.messageContent = value;
          })
          .margin({ bottom: 10 });
        
        Button('Send Message')
          .width('90%')
          .height(40)
          .onClick(() => {
            this.sendMessage();
          })
          .margin({ bottom: 10 });
        
        TextInput({ placeholder: 'Enter file path' })
          .width('90%')
          .height(50)
          .onChange((value: string) => {
            this.filePath = value;
          })
          .margin({ bottom: 10 });
        
        Button('Send File')
          .width('90%')
          .height(40)
          .onClick(() => {
            this.sendFile();
          })
          .margin({ bottom: 10 });
        
        Button('Register Message Receiver')
          .width('90%')
          .height(40)
          .onClick(() => {
            this.registerMessageReceiver();
          })
          .margin({ bottom: 10 });
      } else {
        Text('No P2P capable device connected')
          .fontSize(16)
          .margin({ top: 20 });
      }
    }
    .width('100%')
    .height('100%')
    .padding(20);
  }
}