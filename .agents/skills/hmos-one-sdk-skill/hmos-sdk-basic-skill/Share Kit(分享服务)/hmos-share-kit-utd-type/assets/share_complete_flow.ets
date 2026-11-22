import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { systemShare } from '@kit.ShareKit';

@Component
export struct ShareCompleteFlow {
  private imagePath: string = '/data/storage/el2/base/haps/entry/files/test.jpg';
  private textContent: string = '分享文本和图片';

  build() {
    Column() {
      Button('分享图片（文件后缀）')
        .onClick(() => {
          this.shareImageByExtension();
        })
        .width('80%')
        .height(50)
        .margin({ top: 10 });

      Button('分享文本（MIME类型）')
        .onClick(() => {
          this.shareTextByMIMEType();
        })
        .width('80%')
        .height(50)
        .margin({ top: 10 });

      Button('分享多类型数据')
        .onClick(() => {
          this.shareMultipleData();
        })
        .width('80%')
        .height(50)
        .margin({ top: 10 });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }

  private async shareImageByExtension(): Promise<void> {
    try {
      const utdTypeId = utd.getUniformDataTypeByFilenameExtension('.jpg', utd.UniformDataType.IMAGE);

      if (!utdTypeId) {
        console.warn('UTD type ID not found, using fallback FILE type');
        const fallbackTypeId = utd.UniformDataType.FILE;
        this.showSharePanel(fallbackTypeId, `file://${this.imagePath}`, undefined);
        return;
      }

      console.info(`UTD type ID: ${utdTypeId}`);
      await this.showSharePanel(utdTypeId, `file://${this.imagePath}`, undefined);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Error in shareImageByExtension: Code ${err.code}, message: ${err.message}`);
      this.handleShareError(err);
    }
  }

  private async shareTextByMIMEType(): Promise<void> {
    try {
      const utdTypeId = utd.getUniformDataTypeByMIMEType('text/plain', utd.UniformDataType.TEXT);

      if (!utdTypeId) {
        console.warn('UTD type ID not found, using fallback TEXT type');
        const fallbackTypeId = utd.UniformDataType.TEXT;
        await this.showSharePanel(fallbackTypeId, undefined, this.textContent);
        return;
      }

      console.info(`UTD type ID: ${utdTypeId}`);
      await this.showSharePanel(utdTypeId, undefined, this.textContent);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Error in shareTextByMIMEType: Code ${err.code}, message: ${err.message}`);
      this.handleShareError(err);
    }
  }

  private async shareMultipleData(): Promise<void> {
    try {
      const imageUtd = utd.getUniformDataTypeByFilenameExtension('.jpg', utd.UniformDataType.IMAGE);
      const textUtd = utd.getUniformDataTypeByMIMEType('text/plain', utd.UniformDataType.TEXT);

      if (!imageUtd || !textUtd) {
        console.warn('One or more UTD types not found');
        return;
      }

      const shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: textUtd,
        content: this.textContent
      });

      shareData.addRecord({
        utd: imageUtd,
        uri: `file://${this.imagePath}`
      });

      const records = shareData.getRecords();
      console.info(`Total share records: ${records.length}`);

      const controller = new systemShare.ShareController(shareData);
      controller.on('dismiss', () => {
        console.info('Share panel closed');
      });

      const uiContext: UIContext = this.getUIContext();
      const context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;

      await controller.show(context, {
        previewMode: systemShare.SharePreviewMode.DEFAULT,
        selectionMode: systemShare.SelectionMode.SINGLE
      });

      console.info('Share panel shown successfully');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Error in shareMultipleData: Code ${err.code}, message: ${err.message}`);
      this.handleShareError(err);
    }
  }

  private async showSharePanel(utdTypeId: string, uri?: string, content?: string): Promise<void> {
    try {
      const shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utdTypeId,
        uri: uri || '',
        content: content || ''
      });

      const controller = new systemShare.ShareController(shareData);

      const uiContext: UIContext = this.getUIContext();
      const context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;

      await controller.show(context, {
        previewMode: systemShare.SharePreviewMode.DEFAULT,
        selectionMode: systemShare.SelectionMode.SINGLE
      });

      console.info('Share panel shown successfully');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Error in showSharePanel: Code ${err.code}, message: ${err.message}`);
      throw error;
    }
  }

  private handleShareError(error: BusinessError): void {
    switch (error.code) {
      case 401:
        console.error('Parameter error. Check input parameters.');
        break;
      case 1003700001:
        console.error('Number of records exceeds maximum (500).');
        break;
      case 1003702001:
        console.error('Record types not supported in batch mode.');
        break;
      case 1003702002:
        console.error('IPC data oversized (exceeds 200KB).');
        break;
      case 1003703001:
        console.error('Parse data failed.');
        break;
      default:
        console.error(`Unknown error: Code ${error.code}, message: ${error.message}`);
        break;
    }
  }
}