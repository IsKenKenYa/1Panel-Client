import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct ShareLinkUI {
  @State shareResult: string = '';
  @State selectedMode: string = 'App Linking';
  
  private async generateThumbnail(context: Context): Promise<Uint8Array> {
    let thumbnailPath = context.filesDir + '/app_icon.jpg';
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
        title: 'HarmonyOS应用',
        description: '直达应用分享',
        thumbnail: thumbnail
      });
      
      let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
      let abilityContext: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
      
      controller.on('dismiss', () => {
        this.shareResult = '分享面板已关闭';
      });
      
      controller.on('shareCompleted', (result: systemShare.ShareOperationResult) => {
        this.shareResult = `分享完成,渠道: ${result.targetAbilityInfo.name}`;
      });
      
      await controller.show(abilityContext, {
        previewMode: systemShare.SharePreviewMode.DEFAULT,
        selectionMode: systemShare.SelectionMode.SINGLE
      });
      
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      this.shareResult = `分享失败: code ${businessError.code}`;
    }
  }
  
  private shareNormalLink() {
    try {
      let uiContext: UIContext = this.getUIContext();
      
      let shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utd.UniformDataType.HYPERLINK,
        content: 'https://www.huawei.com',
        title: '华为官网',
        description: '查看华为最新产品'
      });
      
      let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
      let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
      
      controller.on('dismiss', () => {
        this.shareResult = '分享面板已关闭';
      });
      
      controller.show(context, {
        selectionMode: systemShare.SelectionMode.SINGLE,
        previewMode: systemShare.SharePreviewMode.DEFAULT
      }).then(() => {
        this.shareResult = '分享面板显示成功';
      }).catch((error: BusinessError) => {
        this.shareResult = `分享失败: code ${error.code}`;
      });
      
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      this.shareResult = `分享失败: code ${businessError.code}`;
    }
  }
  
  private shareMultipleLinks() {
    try {
      let uiContext: UIContext = this.getUIContext();
      
      let shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utd.UniformDataType.HYPERLINK,
        content: 'https://www.vmall.com',
        title: '华为商城'
      });
      
      shareData.addRecord({
        utd: utd.UniformDataType.HYPERLINK,
        content: 'https://consumer.huawei.com',
        title: '华为消费者业务'
      });
      
      let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
      let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
      
      controller.show(context, {
        selectionMode: systemShare.SelectionMode.SINGLE,
        previewMode: systemShare.SharePreviewMode.DEFAULT
      }).then(() => {
        this.shareResult = '多条链接分享成功';
      }).catch((error: BusinessError) => {
        this.shareResult = `分享失败: code ${error.code}`;
      });
      
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      this.shareResult = `分享失败: code ${businessError.code}`;
    }
  }
  
  build() {
    Column() {
      Text('分享链接完整示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 30 })
      
      RadioGroup({ group: 'shareMode' }) {
        Radio({ value: 'App Linking', group: 'shareMode' })
          .checked(this.selectedMode === 'App Linking')
          .onChange((isChecked: boolean) => {
            if (isChecked) this.selectedMode = 'App Linking';
          })
          .text('App Linking分享')
        
        Radio({ value: '普通链接', group: 'shareMode' })
          .checked(this.selectedMode === '普通链接')
          .onChange((isChecked: boolean) => {
            if (isChecked) this.selectedMode = '普通链接';
          })
          .text('普通链接分享')
        
        Radio({ value: '多条链接', group: 'shareMode' })
          .checked(this.selectedMode === '多条链接')
          .onChange((isChecked: boolean) => {
            if (isChecked) this.selectedMode = '多条链接';
          })
          .text('多条链接分享')
      }
      .margin({ bottom: 30 })
      
      Button('开始分享')
        .width('80%')
        .height(50)
        .onClick(() => {
          if (this.selectedMode === 'App Linking') {
            this.shareAppLinking();
          } else if (this.selectedMode === '普通链接') {
            this.shareNormalLink();
          } else {
            this.shareMultipleLinks();
          }
        })
      
      if (this.shareResult !== '') {
        Text(this.shareResult)
          .fontSize(16)
          .margin({ top: 20 })
          .fontColor('#666666')
      }
      
      Divider()
        .margin({ top: 30, bottom: 20 })
      
      Text('使用说明:')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 10 })
      
      Text('1. App Linking分享需要开通App Linking服务')
        .fontSize(14)
        .margin({ bottom: 5 })
      
      Text('2. 缩略图限制32KB以下')
        .fontSize(14)
        .margin({ bottom: 5 })
      
      Text('3. 数据总量限制200KB以下')
        .fontSize(14)
        .margin({ bottom: 5 })
      
      Text('4. 最大支持500条数据记录')
        .fontSize(14)
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }
}