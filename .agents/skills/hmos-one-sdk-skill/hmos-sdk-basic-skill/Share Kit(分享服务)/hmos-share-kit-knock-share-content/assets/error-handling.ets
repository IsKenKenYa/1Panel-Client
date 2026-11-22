import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { systemShare, harmonyShare } from '@kit.ShareKit';
import { fileUri } from '@kit.CoreFileKit';

@Entry
@Component
struct ErrorHandling {
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
    if (!this.canShare()) {
      sharableTarget.clarifyNonShare({ 
        message: '请在支持碰一碰分享的界面再试' 
      });
      return;
    }
    
    if (!this.isNetworkAvailable()) {
      sharableTarget.reject(harmonyShare.SharableErrorCode.NO_INTERNET_ERROR);
      return;
    }
    
    this.performShare(sharableTarget);
  }

  private canShare(): boolean {
    return true;
  }

  private isNetworkAvailable(): boolean {
    return true;
  }

  private performShare(sharableTarget: harmonyShare.SharableTarget): void {
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.PLAIN_TEXT,
      content: '这是一段文本内容'
    });
    
    sharableTarget.share(shareData);
  }

  build() {
    Column() {
      Text('异常处理示例')
        .fontSize(24)
        .margin({ top: 50, bottom: 20 })
      
      Text('处理无内容、无网络等异常场景')
        .fontSize(16)
        .fontColor('#666666')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}