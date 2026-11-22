import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { systemShare, harmonyShare } from '@kit.ShareKit';
import { fileUri } from '@kit.CoreFileKit';

@Entry
@Component
struct PreviewDelayUpdate {
  private immersiveCallback = (sharableTarget: harmonyShare.SharableTarget) => {
    this.handleKnockShare(sharableTarget);
  }

  aboutToAppear(): void {
    let capabilityRegistry: harmonyShare.SendCapabilityRegistry = {
      windowId: 999
    };
    harmonyShare.on('knockShare', capabilityRegistry, this.immersiveCallback);
  }

  aboutToDisappear(): void {
    let capabilityRegistry: harmonyShare.SendCapabilityRegistry = {
      windowId: 999
    };
    harmonyShare.off('knockShare', capabilityRegistry, this.immersiveCallback);
  }

  private handleKnockShare(sharableTarget: harmonyShare.SharableTarget): void {
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.HYPERLINK,
      content: 'https://sharekitdemo.drcn.agconnect.link/ZB3p',
      title: '碰一碰分享卡片标题',
      description: '碰一碰分享卡片描述'
    });
    
    sharableTarget.share(shareData);
    
    setTimeout(() => {
      let uiContext: UIContext = this.getUIContext();
      let contextFaker: Context = uiContext.getHostContext() as Context;
      let filePath = contextFaker.filesDir + '/exampleKnock1.jpg';
      
      sharableTarget.updateShareData({
        thumbnailUri: fileUri.getUriFromPath(filePath)
      });
    }, 5000);
  }

  build() {
    Column() {
      Text('预览图延迟更新示例')
        .fontSize(24)
        .margin({ top: 50, bottom: 20 })
      
      Text('云端图片下载完成后更新预览图')
        .fontSize(16)
        .fontColor('#666666')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}