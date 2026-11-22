import { common } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileUri } from '@kit.CoreFileKit';

@Component
export struct ShareImageExample {
  private async shareImage() {
    try {
      let imagePath = '/data/storage/el2/base/files/test.png';
      let imageUri = fileUri.getUriFromPath(imagePath);

      let shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utd.UniformDataType.PNG,
        uri: imageUri,
        title: '图片分享',
        description: '这是一张分享的图片',
        label: '图片'
      });

      let controller: systemShare.ShareController = new systemShare.ShareController(shareData);

      let uiContext: UIContext = this.getUIContext();
      let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;

      controller.on('dismiss', () => {
        console.info('Share panel closed');
      });

      controller.show(context, {
        previewMode: systemShare.SharePreviewMode.DETAIL,
        selectionMode: systemShare.SelectionMode.SINGLE
      }).then(() => {
        console.info('ShareController show success.');
      }).catch((error: BusinessError) => {
        console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
      });
    } catch (error) {
      console.error('Share image failed:', error);
    }
  }

  build() {
    Column() {
      Button('分享图片')
        .onClick(() => {
          this.shareImage();
        })
        .width('80%')
        .height(50)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}