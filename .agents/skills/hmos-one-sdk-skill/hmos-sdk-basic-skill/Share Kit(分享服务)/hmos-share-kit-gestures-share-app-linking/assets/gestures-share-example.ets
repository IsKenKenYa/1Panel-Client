/**
 * 隔空传送分享App Linking完整示例
 * 功能：演示如何通过隔空传送分享App Linking实现应用直达
 * API版本：6.0.0(20)
 */

import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { systemShare, harmonyShare } from '@kit.ShareKit';
import { fileUri } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import deviceInfo from '@ohos.deviceInfo';

@Entry
@Component
struct GesturesShareExample {
  private immersiveCallback: (sharableTarget: harmonyShare.SharableTarget) => void;
  private appLinkingUrl: string = 'https://example.drcn.agconnect.link/XXXX';

  aboutToAppear(): void {
    // 检查设备能力
    if (!this.checkDeviceCapability()) {
      console.info('当前设备不支持隔空传送功能');
      return;
    }

    // 初始化回调函数
    this.immersiveCallback = (sharableTarget: harmonyShare.SharableTarget) => {
      this.handleGesturesShare(sharableTarget);
    };

    // 注册隔空传送监听
    this.immersiveListening();

    // 监听应用退至后台事件
    let uiContext: UIContext = this.getUIContext();
    let context: Context = uiContext.getHostContext() as Context;
    context.eventHub.on('onBackGround', this.onBackGround);
  }

  aboutToDisappear(): void {
    // 取消隔空传送监听
    this.immersiveDisablingListening();

    // 取消监听应用退至后台事件
    let uiContext: UIContext = this.getUIContext();
    let context: Context = uiContext.getHostContext() as Context;
    context.eventHub.off('onBackGround', this.onBackGround);
  }

  onPageHide(): void {
    // 页面隐藏时触发应用退至后台事件
    let uiContext: UIContext = this.getUIContext();
    let context: Context = uiContext.getHostContext() as Context;
    context.eventHub.emit('onBackGround');
  }

  /**
   * 检查设备能力
   * @returns true-支持，false-不支持
   */
  private checkDeviceCapability(): boolean {
    // Tablet设备不支持隔空传送
    if (deviceInfo.deviceType === 'tablet') {
      console.warn('Tablet设备不支持隔空传送功能');
      return false;
    }
    return true;
  }

  /**
   * 注册隔空传送监听事件
   */
  private immersiveListening(): void {
    try {
      harmonyShare.on('gesturesShare', this.immersiveCallback);
      console.info('已注册隔空传送监听');
    } catch (error) {
      console.error('注册隔空传送监听失败:', JSON.stringify(error));
    }
  }

  /**
   * 取消隔空传送监听事件
   */
  private immersiveDisablingListening(): void {
    try {
      harmonyShare.off('gesturesShare', this.immersiveCallback);
      console.info('已取消隔空传送监听');
    } catch (error) {
      console.error('取消隔空传送监听失败:', JSON.stringify(error));
    }
  }

  /**
   * 处理隔空传送事件回调
   * @param sharableTarget 分享目标对象
   */
  private handleGesturesShare(sharableTarget: harmonyShare.SharableTarget): void {
    try {
      // 构造分享数据（必须在3秒内发起分享）
      let shareData = this.buildShareData();

      // 发起分享
      sharableTarget.share(shareData)
        .then(() => {
          console.info('分享成功');
        })
        .catch((error: Error) => {
          console.error('分享失败:', error.message);
          this.handleShareError(error, sharableTarget);
        });
    } catch (error) {
      console.error('构造分享数据失败:', JSON.stringify(error));
      // 拒绝分享
      sharableTarget.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR);
    }
  }

  /**
   * 构造分享数据
   * @returns 分享数据对象
   */
  private buildShareData(): systemShare.SharedData {
    let uiContext: UIContext = this.getUIContext();
    let context: Context = uiContext.getHostContext() as Context;

    // 构造缩略图URI（可选）
    let thumbnailPath = context.filesDir + '/thumbnail.jpg';
    let thumbnailUri = '';
    
    try {
      thumbnailUri = fileUri.getUriFromPath(thumbnailPath);
    } catch (error) {
      console.warn('获取缩略图URI失败，使用默认缩略图:', JSON.stringify(error));
    }

    // 构造分享数据
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.HYPERLINK,    // 数据类型：超链接
      content: this.appLinkingUrl,            // App Linking地址
      thumbnailUri: thumbnailUri,             // 缩略图URI
      title: '隔空传送分享标题',
      description: '点击打开应用直达页面'
    });

    return shareData;
  }

  /**
   * 处理分享错误
   * @param error 错误对象
   * @param sharableTarget 分享目标对象
   */
  private handleShareError(error: Error, sharableTarget: harmonyShare.SharableTarget): void {
    let errorCode = harmonyShare.SharableErrorCode.NO_CONTENT_ERROR;

    // 根据错误类型选择拒绝原因
    if (error.message.includes('network') || error.message.includes('network')) {
      errorCode = harmonyShare.SharableErrorCode.NO_INTERNET_ERROR;
    } else if (error.message.includes('download') || error.message.includes('download')) {
      errorCode = harmonyShare.SharableErrorCode.DOWNLOAD_ERROR;
    }

    // 拒绝分享
    sharableTarget.reject(errorCode)
      .then(() => {
        console.info('已拒绝分享，错误码:', errorCode);
      })
      .catch((rejectError: Error) => {
        console.error('拒绝分享失败:', rejectError.message);
      });
  }

  /**
   * 应用退至后台回调
   */
  private onBackGround = (): void => {
    // 应用退至后台时取消监听
    this.immersiveDisablingListening();
  }

  build() {
    Column() {
      Text('隔空传送分享App Linking示例')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })

      Text('请在支持隔空传送的设备上测试')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ bottom: 20 })

      Text('App Linking: ' + this.appLinkingUrl)
        .fontSize(14)
        .margin({ bottom: 20 })

      Button('测试分享')
        .width('80%')
        .onClick(() => {
          // 注意：隔空传送需要用户手势触发，这里仅用于测试构造数据
          let testData = this.buildShareData();
          console.info('测试分享数据构造成功:', JSON.stringify(testData));
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}