import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { systemShare, harmonyShare } from '@kit.ShareKit';
import { fileUri } from '@kit.CoreFileKit';

@Entry
@Component
struct BasicKnockShare {
  private immersiveCallback = (sharableTarget: harmonyShare.SharableTarget) => {
    this.handleKnockShare(sharableTarget);
  }

  aboutToAppear(): void {
    harmonyShare.on('knockShare', this.immersiveCallback);
  }

  aboutToDisappear(): void {
    harmonyShare.off('knockShare', this.immersiveCallback);
  }

  private handleKnockShare(sharableTarget: harmonyShare.SharableTarget): void {
    let uiContext: UIContext = this.getUIContext();
    let contextFaker: Context = uiContext.getHostContext() as Context;
    let filePath = contextFaker.filesDir + '/exampleImage.jpg';
    
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.IMAGE,
      thumbnailUri: fileUri.getUriFromPath(filePath)
    });
    
    sharableTarget.share(shareData);
  }

  build() {
    Column() {
      Text('碰一碰分享示例')
        .fontSize(24)
        .margin({ top: 50, bottom: 20 })
      
      Text('请将手机背面轻碰另一台HarmonyOS设备')
        .fontSize(16)
        .fontColor('#666666')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}