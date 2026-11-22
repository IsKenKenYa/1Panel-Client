import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct ShareAppLinkingExample {
  private async generateThumbnail(context: Context): Promise<Uint8Array> {
    let thumbnailPath = context.filesDir + '/exampleImage.jpg';
    let imageSource: image.ImageSource = image.createImageSource(thumbnailPath);
    let imagePacker: image.ImagePacker = image.createImagePacker();
    
    let buffer: ArrayBuffer = await imagePacker.packToData(imageSource, {
      format: 'image/jpeg',
      quality: 30
    });
    
    return new Uint8Array(buffer);
  }
  
  private async shareAppLinking() {
    try {
      let uiContext: UIContext = this.getUIContext();
      let context: Context = uiContext.getHostContext() as Context;
      
      let thumbnail = await this.generateThumbnail(context);
      
      let shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utd.UniformDataType.HYPERLINK,
        content: 'https://sharekitdemo.drcn.agconnect.link/ZB3p',
        title: '应用名称',
        description: '应用描述',
        thumbnail: thumbnail
      });
      
      let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
      let abilityContext: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
      
      controller.on('dismiss', () => {
        console.info('分享面板已关闭');
      });
      
      controller.on('shareCompleted', (result: systemShare.ShareOperationResult) => {
        console.info('分享完成,渠道:', result.targetAbilityInfo.name);
      });
      
      await controller.show(abilityContext, {
        previewMode: systemShare.SharePreviewMode.DEFAULT,
        selectionMode: systemShare.SelectionMode.SINGLE
      });
      
      console.info('ShareController show success.');
      
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      
      switch (businessError.code) {
        case 1003702001:
          console.error('数据记录类型不支持,请检查链接格式');
          break;
        case 1003702002:
          console.error('数据量超过上限200KB,请压缩缩略图或减少文本内容');
          break;
        case 401:
          console.error('参数错误,请检查参数类型和必填项');
          break;
        default:
          console.error(`未知错误: code ${businessError.code}, message ${businessError.message}`);
      }
    }
  }
  
  build() {
    Column() {
      Text('分享App Linking示例')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })
      
      Button('分享App Linking链接')
        .width('80%')
        .onClick(() => this.shareAppLinking())
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}