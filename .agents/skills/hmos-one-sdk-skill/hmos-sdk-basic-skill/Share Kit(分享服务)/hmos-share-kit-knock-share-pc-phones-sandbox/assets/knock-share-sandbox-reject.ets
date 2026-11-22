import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { systemShare, harmonyShare } from '@kit.ShareKit';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct KnockShareSandboxReject {
  private capabilityRegistry: harmonyShare.RecvCapabilityRegistry = {
    windowId: 0,
    capabilities: [{
      utd: utd.UniformDataType.IMAGE,
      maxSupportedCount: 1
    }]
  };

  private isBusy: boolean = false;

  aboutToAppear(): void {
    this.registerDataReceive();
  }

  aboutToDisappear(): void {
    this.unregisterDataReceive();
  }

  private registerDataReceive(): void {
    try {
      const uiContext = this.getUIContext();
      const windowId = uiContext.getWindowId();
      this.capabilityRegistry.windowId = windowId;

      harmonyShare.on('dataReceive', this.capabilityRegistry, (receivableTarget: harmonyShare.ReceivableTarget) => {
        this.handleReceive(receivableTarget);
      });

      console.info('Data receive listener registered successfully');
    } catch (error) {
      console.error('Failed to register data receive listener:', error.message);
    }
  }

  private unregisterDataReceive(): void {
    try {
      harmonyShare.off('dataReceive', this.capabilityRegistry);
      console.info('Data receive listener unregistered successfully');
    } catch (error) {
      console.error('Failed to unregister data receive listener:', error.message);
    }
  }

  private handleReceive(receivableTarget: harmonyShare.ReceivableTarget): void {
    if (this.isBusy) {
      console.warn('Application is busy, rejecting receive request');
      receivableTarget.reject(harmonyShare.ReceivableErrorCode.NO_RECEIVABLE_ERROR);
      return;
    }

    this.isBusy = true;

    try {
      const uiContext = this.getUIContext();
      const context = uiContext.getHostContext() as common.UIAbilityContext;
      const receiveDir = context.filesDir;

      receivableTarget.receive(receiveDir, {
        onDataReceived: (sharedData: systemShare.SharedData) => {
          this.processReceivedFiles(sharedData);
        },
        onResult(resultCode: harmonyShare.ShareResultCode) {
          this.handleTransferResult(resultCode);
        }
      });
    } catch (error) {
      console.error('Failed to receive files:', error.message);
      receivableTarget.reject(harmonyShare.ReceivableErrorCode.NO_RECEIVABLE_ERROR);
    } finally {
      this.isBusy = false;
    }
  }

  private processReceivedFiles(sharedData: systemShare.SharedData): void {
    try {
      const sharedRecords = sharedData.getRecords();
      console.info(`Received ${sharedRecords.length} files`);

      sharedRecords.forEach((record: systemShare.SharedRecord, index: number) => {
        console.info(`File ${index + 1}: ${record.toString()}`);
      });
    } catch (error) {
      console.error('Failed to process received files:', error.message);
    }
  }

  private handleTransferResult(resultCode: harmonyShare.ShareResultCode): void {
    switch (resultCode) {
      case harmonyShare.ShareResultCode.SHARE_SUCCESS:
        console.info('File transfer completed successfully');
        break;
      case harmonyShare.ShareResultCode.SEND_FAILED:
        console.error('File transfer failed: sender error');
        break;
      case harmonyShare.ShareResultCode.CANCEL_BY_SENDER:
        console.warn('File transfer cancelled by sender');
        break;
      case harmonyShare.ShareResultCode.CANCEL_BY_RECEIVER:
        console.warn('File transfer cancelled by receiver');
        break;
      default:
        console.error('Unknown transfer result:', resultCode);
    }
  }

  build() {
    Column() {
      Text('Knock Share Sandbox Reject Demo')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      Text('Ready to receive files via knock share')
        .fontSize(16)
        .margin({ bottom: 10 });

      Text(`Supported type: IMAGE`)
        .fontSize(14)
        .margin({ bottom: 5 });

      Text(`Max count: 1`)
        .fontSize(14)
        .margin({ bottom: 10 });

      Text(`Status: ${this.isBusy ? 'Busy' : 'Available'}`)
        .fontSize(14)
        .fontColor(this.isBusy ? Color.Red : Color.Green);
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }
}