import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { fileUri } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Component
export struct ShareImageExample {
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;

  build() {
    Column() {
      Button('分享单张图片')
        .onClick(() => {
          this.shareSingleImage();
        })
        .margin({ bottom: 20 });

      Button('分享多张图片')
        .onClick(() => {
          this.shareMultipleImages();
        })
        .margin({ bottom: 20 });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }

  private async shareSingleImage(): Promise<void> {
    try {
      let uiContext: UIContext = this.getUIContext();
      let contextFaker: Context = uiContext.getHostContext() as Context;
      let filePath = contextFaker.filesDir + '/exampleImage.jpg';

      let utdTypeId = utd.getUniformDataTypeByFilenameExtension('.jpg', utd.UniformDataType.IMAGE);

      let shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utdTypeId,
        uri: fileUri.getUriFromPath(filePath),
        title: '示例图片',
        description: '这是一张示例图片'
      });

      let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
      let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;

      await controller.show(context, {
        selectionMode: systemShare.SelectionMode.SINGLE,
        previewMode: systemShare.SharePreviewMode.DETAIL
      });

      console.info('ShareController show success.');
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`ShareController show error. code: ${businessError.code}, message: ${businessError.message}`);
    }
  }

  private async shareMultipleImages(): Promise<void> {
    try {
      let uiContext: UIContext = this.getUIContext();
      let contextFaker: Context = uiContext.getHostContext() as Context;

      let filePath1 = contextFaker.filesDir + '/image1.jpg';
      let filePath2 = contextFaker.filesDir + '/image2.jpg';
      let filePath3 = contextFaker.filesDir + '/image3.jpg';

      let utdTypeId = utd.getUniformDataTypeByFilenameExtension('.jpg', utd.UniformDataType.IMAGE);

      let shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utdTypeId,
        uri: fileUri.getUriFromPath(filePath1),
        title: '图片1',
        description: '第一张图片'
      });

      shareData.addRecord({
        utd: utdTypeId,
        uri: fileUri.getUriFromPath(filePath2),
        title: '图片2',
        description: '第二张图片'
      });

      shareData.addRecord({
        utd: utdTypeId,
        uri: fileUri.getUriFromPath(filePath3),
        title: '图片3',
        description: '第三张图片'
      });

      let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
      let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;

      await controller.show(context, {
        selectionMode: systemShare.SelectionMode.SINGLE,
        previewMode: systemShare.SharePreviewMode.DETAIL
      });

      console.info('ShareController show success.');
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`ShareController show error. code: ${businessError.code}, message: ${businessError.message}`);
    }
  }
}