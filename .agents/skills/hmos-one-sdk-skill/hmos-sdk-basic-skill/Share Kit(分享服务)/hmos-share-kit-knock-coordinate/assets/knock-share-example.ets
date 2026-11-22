import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { harmonyShare, systemShare } from '@kit.ShareKit';
import { fileUri } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Component
export default struct KnockShareExample {
  @State knockShareScreenX: number | undefined = undefined;
  @State knockShareScreenY: number | undefined = undefined;
  @State dataReceiveScreenX: number | undefined = undefined;
  @State dataReceiveScreenY: number | undefined = undefined;
  @State message: string = '';
  @State windowId: number = 999;
  
  aboutToAppear(): void {
    this.initializeShareListeners();
  }
  
  aboutToDisappear(): void {
    this.cleanupShareListeners();
  }
  
  private initializeShareListeners(): void {
    try {
      this.registerKnockShareListener();
      this.registerDataReceiveListener();
      this.message = 'Share listeners initialized successfully';
    } catch (error) {
      let businessError = error as BusinessError;
      this.message = `Initialization failed: ${businessError.message}`;
      console.error('Initialize failed:', businessError.code, businessError.message);
    }
  }
  
  private cleanupShareListeners(): void {
    try {
      harmonyShare.off('knockShare');
      
      let capabilityRegistry: harmonyShare.RecvCapabilityRegistry = {
        windowId: this.windowId,
        capabilities: [{
          utd: utd.UniformDataType.IMAGE,
          maxSupportedCount: 1
        }]
      };
      harmonyShare.off('dataReceive', capabilityRegistry);
      
      console.info('Listeners cleanup completed');
    } catch (error) {
      console.error('Cleanup failed:', error.message);
    }
  }
  
  private registerKnockShareListener(): void {
    harmonyShare.on('knockShare', this.knockShareCallback);
    console.info('KnockShare listener registered');
  }
  
  private registerDataReceiveListener(): void {
    let capabilityRegistry: harmonyShare.RecvCapabilityRegistry = {
      windowId: this.windowId,
      capabilities: [{
        utd: utd.UniformDataType.IMAGE,
        maxSupportedCount: 1
      }]
    };
    
    harmonyShare.on('dataReceive', capabilityRegistry, this.dataReceiveCallback);
    console.info('DataReceive listener registered');
  }
  
  private knockShareCallback = (sharableTarget: harmonyShare.SharableTarget) => {
    try {
      let uiContext: UIContext = this.getUIContext();
      let contextFaker: Context = uiContext.getHostContext() as Context;
      
      let filePath = contextFaker.filesDir + '/exampleKnock1.jpg';
      let shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utd.UniformDataType.JPEG,
        uri: fileUri.getUriFromPath(filePath),
        thumbnailUri: fileUri.getUriFromPath(filePath)
      });
      
      let sharableTargetInfo = sharableTarget.getInfo();
      this.knockShareScreenX = sharableTargetInfo.coordinate?.screenX;
      this.knockShareScreenY = sharableTargetInfo.coordinate?.screenY;
      
      console.info(`KnockShare coordinate: X=${this.knockShareScreenX}, Y=${this.knockShareScreenY}`);
      this.message = `Share coordinate: (${this.knockShareScreenX}, ${this.knockShareScreenY})`;
      
      sharableTarget.share(shareData)
        .then(() => {
          console.info('Share successful');
          this.message = 'Share completed successfully';
        })
        .catch((error: BusinessError) => {
          console.error('Share failed:', error.code, error.message);
          this.handleShareError(error);
        });
    } catch (error) {
      let businessError = error as BusinessError;
      console.error('KnockShare callback error:', businessError.message);
      this.message = `Share callback error: ${businessError.message}`;
    }
  }
  
  private dataReceiveCallback = (receivableTarget: harmonyShare.ReceivableTarget) => {
    try {
      let uiContext: UIContext = this.getUIContext();
      let context = uiContext.getHostContext() as common.UIAbilityContext;
      
      let sandboxUri = fileUri.getUriFromPath(context.filesDir);
      
      let receivableTargetInfo = receivableTarget.getInfo();
      this.dataReceiveScreenX = receivableTargetInfo.coordinate?.screenX;
      this.dataReceiveScreenY = receivableTargetInfo.coordinate?.screenY;
      
      console.info(`DataReceive coordinate: X=${this.dataReceiveScreenX}, Y=${this.dataReceiveScreenY}`);
      this.message = `Receive coordinate: (${this.dataReceiveScreenX}, ${this.dataReceiveScreenY})`;
      
      receivableTarget.receive(sandboxUri, {
        onDataReceived: (sharedData: systemShare.SharedData) => {
          let sharedRecords = sharedData.getRecords();
          sharedRecords.forEach((record: systemShare.SharedRecord) => {
            console.info('Received file:', record.uri);
          });
          this.message = `Received ${sharedRecords.length} files`;
        },
        onResult: (resultCode: harmonyShare.ShareResultCode) => {
          if (resultCode === harmonyShare.ShareResultCode.SHARE_SUCCESS) {
            console.info('Receive successful');
            this.message = 'Receive completed successfully';
          } else {
            console.error('Receive failed with code:', resultCode);
            this.handleReceiveError(resultCode);
          }
        }
      });
    } catch (error) {
      let businessError = error as BusinessError;
      console.error('DataReceive callback error:', businessError.message);
      this.message = `Receive callback error: ${businessError.message}`;
    }
  }
  
  private handleShareError(error: BusinessError): void {
    switch (error.code) {
      case 401:
        this.message = 'Parameter error. Check file path and data type.';
        break;
      case 1003700001:
        this.message = 'Records exceed maximum (500).';
        break;
      case 1003702001:
        this.message = 'Data type not supported.';
        break;
      case 1003702002:
        this.message = 'Data size exceeds limit (200KB).';
        break;
      default:
        this.message = `Unknown error: ${error.message}`;
        this.fallbackToSystemShare();
    }
  }
  
  private handleReceiveError(resultCode: harmonyShare.ShareResultCode): void {
    switch (resultCode) {
      case harmonyShare.ShareResultCode.SEND_FAILED:
        this.message = 'Data transmission failed.';
        break;
      case harmonyShare.ShareResultCode.CANCEL_BY_SENDER:
        this.message = 'Sender cancelled transmission.';
        break;
      case harmonyShare.ShareResultCode.CANCEL_BY_RECEIVER:
        this.message = 'Receiver cancelled transmission.';
        break;
      default:
        this.message = 'Unknown receive error.';
    }
  }
  
  private fallbackToSystemShare(): void {
    try {
      let uiContext: UIContext = this.getUIContext();
      let context = uiContext.getHostContext() as common.UIAbilityContext;
      let filePath = context.filesDir + '/fallback.jpg';
      
      let shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utd.UniformDataType.IMAGE,
        uri: fileUri.getUriFromPath(filePath)
      });
      
      let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
      
      controller.show(context, {
        selectionMode: systemShare.SelectionMode.SINGLE,
        previewMode: systemShare.SharePreviewMode.DETAIL
      }).then(() => {
        console.info('Fallback to system share successful');
        this.message = 'Using system share panel';
      }).catch((error: BusinessError) => {
        console.error('Fallback failed:', error.message);
        this.message = 'Please use other sharing method';
      });
    } catch (error) {
      console.error('Fallback error:', error.message);
      this.message = 'Fallback failed. Use manual sharing.';
    }
  }
  
  build() {
    Column() {
      Text('Knock Share Example')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });
      
      Text('Share Coordinate:')
        .fontSize(16)
        .margin({ top: 10 });
      
      Text(`X: ${this.knockShareScreenX ?? 'Not available'}`)
        .fontSize(14)
        .margin({ top: 5 });
      
      Text(`Y: ${this.knockShareScreenY ?? 'Not available'}`)
        .fontSize(14)
        .margin({ top: 5 });
      
      Text('Receive Coordinate:')
        .fontSize(16)
        .margin({ top: 20 });
      
      Text(`X: ${this.dataReceiveScreenX ?? 'Not available'}`)
        .fontSize(14)
        .margin({ top: 5 });
      
      Text(`Y: ${this.dataReceiveScreenY ?? 'Not available'}`)
        .fontSize(14)
        .margin({ top: 5 });
      
      Text(this.message)
        .fontSize(14)
        .fontColor(Color.Blue)
        .margin({ top: 20, bottom: 20 });
      
      Button('Clear Coordinates')
        .onClick(() => {
          this.knockShareScreenX = undefined;
          this.knockShareScreenY = undefined;
          this.dataReceiveScreenX = undefined;
          this.dataReceiveScreenY = undefined;
          this.message = 'Coordinates cleared';
        })
        .margin({ top: 10 });
    }
    .width('100%')
    .padding(20);
  }
}