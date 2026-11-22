import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { fileUri } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct ShareVideoWithThumbnail {
  private async shareVideoWithThumbnail(): Promise<void> {
    try {
      let uiContext: UIContext = this.getUIContext();
      let contextFaker: Context = uiContext.getHostContext() as Context;
      
      let thumbnailPath = contextFaker.filesDir + '/exampleImage.jpg';
      let filePath = contextFaker.filesDir + '/exampleVideo.mp4';
      
      let imageSource: image.ImageSource = image.createImageSource(thumbnailPath);
      let imagePacker: image.ImagePacker = image.createImagePacker();
      let buffer: ArrayBuffer = await imagePacker.packToData(imageSource, {
        format: 'image/jpeg',
        quality: 30
      });
      
      let utdTypeId = utd.getUniformDataTypeByFilenameExtension('.mp4', utd.UniformDataType.VIDEO);
      let shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utdTypeId,
        uri: fileUri.getUriFromPath(filePath),
        title: '视频标题',
        description: '视频描述',
        thumbnail: new Uint8Array(buffer)
      });
      
      let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
      let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
      
      controller.show(context, {
        selectionMode: systemShare.SelectionMode.SINGLE,
        previewMode: systemShare.SharePreviewMode.DETAIL
      }).then(() => {
        console.info('ShareController show success.');
      }).catch((error: BusinessError) => {
        console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
      });
      
      imageSource.release();
      imagePacker.release();
    } catch (error) {
      console.error('分享视频失败:', error);
    }
  }

  build() {
    Column() {
      Button('分享视频（带缩略图）')
        .onClick(() => {
          this.shareVideoWithThumbnail();
        })
        .width('80%')
        .height(50)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}