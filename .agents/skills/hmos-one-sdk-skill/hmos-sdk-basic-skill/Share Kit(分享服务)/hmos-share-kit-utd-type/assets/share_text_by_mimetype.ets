import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { systemShare } from '@kit.ShareKit';

@Component
export struct ShareTextByMimeType {
  private textContent: string = '这是一段分享的文本内容';

  build() {
    Column() {
      Button('分享文本（根据MIME类型）')
        .onClick(() => {
          this.shareTextByMIMEType();
        })
        .width('80%')
        .height(50)
        .margin({ top: 20 });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }

  private async shareTextByMIMEType(): Promise<void> {
    try {
      const mimeType = 'text/plain';
      const belongsToType = utd.UniformDataType.TEXT;

      const utdTypeId = utd.getUniformDataTypeByMIMEType(mimeType, belongsToType);

      if (utdTypeId) {
        console.info(`Successfully queried UTD type ID: ${utdTypeId}`);

        const shareData: systemShare.SharedData = new systemShare.SharedData({
          utd: utdTypeId,
          content: this.textContent
        });

        const controller: systemShare.ShareController = new systemShare.ShareController(shareData);

        const uiContext: UIContext = this.getUIContext();
        const context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;

        await controller.show(context, {
          previewMode: systemShare.SharePreviewMode.DEFAULT,
          selectionMode: systemShare.SelectionMode.SINGLE
        });

        console.info('Share panel shown successfully');
      } else {
        console.warn('UTD type ID not found for text/plain MIME type');
      }
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to share text. Code: ${err.code}, message: ${err.message}`);
    }
  }
}