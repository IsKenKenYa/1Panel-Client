import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { systemShare } from '@kit.ShareKit';

@Component
export struct ShareImageByExtension {
  private imagePath: string = '/data/storage/el2/base/haps/entry/files/test.jpg';

  build() {
    Column() {
      Button('分享图片（根据文件后缀）')
        .onClick(() => {
          this.shareImageByFileExtension();
        })
        .width('80%')
        .height(50)
        .margin({ top: 20 });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }

  private async shareImageByFileExtension(): Promise<void> {
    try {
      const filenameExtension = '.jpg';
      const belongsToType = utd.UniformDataType.IMAGE;

      const utdTypeId = utd.getUniformDataTypeByFilenameExtension(filenameExtension, belongsToType);

      if (utdTypeId) {
        console.info(`Successfully queried UTD type ID: ${utdTypeId}`);

        const shareData: systemShare.SharedData = new systemShare.SharedData({
          utd: utdTypeId,
          uri: `file://${this.imagePath}`
        });

        const controller: systemShare.ShareController = new systemShare.ShareController(shareData);

        const uiContext: UIContext = this.getUIContext();
        const context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;

        await controller.show(context, {
          previewMode: systemShare.SharePreviewMode.DETAIL,
          selectionMode: systemShare.SelectionMode.SINGLE
        });

        console.info('Share panel shown successfully');
      } else {
        console.warn('UTD type ID not found for .jpg extension');
      }
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to share image. Code: ${err.code}, message: ${err.message}`);
    }
  }
}