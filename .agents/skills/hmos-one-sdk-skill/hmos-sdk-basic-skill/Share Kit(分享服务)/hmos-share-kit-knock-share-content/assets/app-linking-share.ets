import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { harmonyShare, systemShare } from '@kit.ShareKit';
import { fileUri } from '@kit.CoreFileKit';

@Entry
@Component
struct AppLinkingShare {
  private onBackGround = () => {
    this.immersiveDisablingListening();
  }

  private immersiveCallback = (sharableTarget: harmonyShare.SharableTarget) => {
    let uiContext: UIContext = this.getUIContext();
    let contextFaker: Context = uiContext.getHostContext() as Context;
    let filePath = contextFaker.filesDir + '/app-linking-preview.jpg';
    
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.HYPERLINK,
      content: 'https://sharekitdemo.drcn.agconnect.link/ZB3p',
      thumbnailUri: fileUri.getUriFromPath(filePath),
      title: '碰一碰分享卡片标题',
      description: '碰一碰分享卡片描述'
    });
    
    sharableTarget.share(shareData);
  }

  private immersiveListening() {
    harmonyShare.on('knockShare', this.immersiveCallback);
  }

  private immersiveDisablingListening() {
    harmonyShare.off('knockShare', this.immersiveCallback);
  }

  aboutToAppear(): void {
    this.immersiveListening();
    let uiContext: UIContext = this.getUIContext();
    let context: Context = uiContext.getHostContext() as Context;
    context.eventHub.on('onBackGround', this.onBackGround);
  }

  aboutToDisappear(): void {
    this.immersiveDisablingListening();
    let uiContext: UIContext = this.getUIContext();
    let context: Context = uiContext.getHostContext() as Context;
    context.eventHub.off('onBackGround', this.onBackGround);
  }

  onPageHide(): void {
    let uiContext: UIContext = this.getUIContext();
    let context: Context = uiContext.getHostContext() as Context;
    context.eventHub.emit('onBackGround');
  }

  build() {
    Column() {
      Text('App Linking分享示例')
        .fontSize(24)
        .margin({ top: 50, bottom: 20 })
      
      Text('使用App Linking实现应用跳转')
        .fontSize(16)
        .fontColor('#666666')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}