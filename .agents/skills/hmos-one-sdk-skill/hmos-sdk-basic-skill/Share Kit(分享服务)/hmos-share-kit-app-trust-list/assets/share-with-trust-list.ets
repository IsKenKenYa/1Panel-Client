import { common } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

@Component
export struct ShareWithTrustList {
  @State message: string = '企业内部数据分享';

  build() {
    Column() {
      Text(this.message)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })

      Button('分享到企业应用')
        .width('80%')
        .height(50)
        .fontSize(18)
        .onClick(() => {
          this.shareToTrustedApps();
        })
        .margin({ top: 20 })

      Button('获取应用标识符')
        .width('80%')
        .height(50)
        .fontSize(18)
        .onClick(() => {
          this.getAppIdentifier();
        })
        .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  private async shareToTrustedApps() {
    try {
      const shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utd.UniformDataType.PLAIN_TEXT,
        content: '企业内部机密资料：重要数据信息'
      });

      const controller: systemShare.ShareController = new systemShare.ShareController(shareData);

      const uiContext: UIContext = this.getUIContext();
      const context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;

      const trustAppList: string[] = [
        '5765880207853060000',
        '1171817433862770000',
      ];

      controller.on('shareCompleted', (result: systemShare.ShareOperationResult) => {
        console.info('分享完成，目标应用:', result.targetAbilityInfo.name);
      });

      controller.on('dismiss', () => {
        console.info('分享面板已关闭');
      });

      await controller.show(context, {
        previewMode: systemShare.SharePreviewMode.DEFAULT,
        selectionMode: systemShare.SelectionMode.SINGLE,
        appLaunchTrustInfo: trustAppList
      });

      console.info('分享面板已显示，信任列表配置生效');
    } catch (error) {
      const businessError = error as BusinessError;
      this.handleShareError(businessError);
    }
  }

  private handleShareError(error: BusinessError) {
    switch (error.code) {
      case 401:
        console.error('参数错误，请检查传入的参数');
        this.message = '参数错误';
        break;
      case 1003702001:
        console.error('记录类型不支持');
        this.message = '记录类型不支持';
        break;
      case 1003702002:
        console.error('IPC数据过大，请减少分享数据大小');
        this.message = '数据过大';
        break;
      default:
        console.error('分享失败:', error.message);
        this.message = '分享失败: ' + error.message;
        this.fallbackToNormalShare();
    }
  }

  private async fallbackToNormalShare() {
    try {
      const shareData = new systemShare.SharedData({
        utd: utd.UniformDataType.PLAIN_TEXT,
        content: '企业内部数据'
      });

      const controller = new systemShare.ShareController(shareData);
      const uiContext: UIContext = this.getUIContext();
      const context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;

      await controller.show(context, {
        previewMode: systemShare.SharePreviewMode.DEFAULT,
        selectionMode: systemShare.SelectionMode.SINGLE
      });

      console.warn('已降级为普通分享模式');
      this.message = '已降级为普通分享模式';
    } catch (error) {
      console.error('降级分享也失败:', error);
      this.message = '分享失败';
    }
  }

  private async getAppIdentifier() {
    try {
      const bundleInfo = await bundleManager.getBundleInfoForSelf(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT
      );
      console.info('当前应用appIdentifier:', bundleInfo.appIdentifier);
      this.message = '当前应用标识符: ' + bundleInfo.appIdentifier;
    } catch (error) {
      console.error('获取appIdentifier失败:', error);
      this.message = '获取标识符失败';
    }
  }
}