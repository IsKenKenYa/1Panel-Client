import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { fileUri } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct ShareMultipleVideos {
  private async shareMultipleVideos(): Promise<void> {
    try {
      let uiContext: UIContext = this.getUIContext();
      let contextFaker: Context = uiContext.getHostContext() as Context;
      
      let thumbnailPath = contextFaker.filesDir + '/exampleImage.jpg';
      let filePath1 = contextFaker.filesDir + '/exampleVideo1.mp4';
      let filePath2 = contextFaker.filesDir + '/exampleVideo2.mp4';
      
      let imageSource: image.ImageSource = image.createImageSource(thumbnailPath);
      let imagePacker: image.ImagePacker = image.createImagePacker();
      let buffer: ArrayBuffer = await imagePacker.packToData(imageSource, {
        format: 'image/jpeg',
        quality: 30
      });
      
      let utdTypeId = utd.getUniformDataTypeByFilenameExtension('.mp4', utd.UniformDataType.VIDEO);
      let shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utdTypeId,
        uri: fileUri.getUriFromPath(filePath1),
        title: '视频1',
        description: '第一个视频',
        thumbnail: new Uint8Array(buffer)
      });
      
      shareData.addRecord({
        utd: utdTypeId,
        uri: fileUri.getUriFromPath(filePath2),
        title: '视频2',
        description: '第二个视频'
      });
      
      let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
      let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
      
      controller.show(context, {
        selectionMode: systemShare.SelectionMode.BATCH,
        previewMode: systemShare.SharePreviewMode.DETAIL
      }).then(() => {
        console.info('ShareController show success.');
      }).catch((error: BusinessError) => {
        if (error.code === 1003702001) {
          console.error('记录类型不支持');
        } else if (error.code === 1003702002) {
          console.error('IPC数据过大');
        } else {
          console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
        }
      });
      
      imageSource.release();
      imagePacker.release();
    } catch (error) {
      console.error('分享多个视频失败:', error);
    }
  }

  build() {
    Column() {
      Button('分享多个视频')
        .onClick(() => {
          this.shareMultipleVideos();
        })
        .width('80%')
        .height(50)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}