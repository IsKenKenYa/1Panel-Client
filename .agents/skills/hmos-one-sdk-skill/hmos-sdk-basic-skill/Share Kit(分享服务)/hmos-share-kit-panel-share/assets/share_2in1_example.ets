import { common } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

@Component
export struct Share2in1Example {
  @State shareButtonId: string = 'shareButtonId';

  private shareWithAnchorId() {
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.PLAIN_TEXT,
      content: '2in1设备分享示例'
    });

    let controller: systemShare.ShareController = new systemShare.ShareController(shareData);

    let uiContext: UIContext = this.getUIContext();
    let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;

    controller.on('dismiss', () => {
      console.info('Share panel closed (Popup mode)');
    });

    controller.show(context, {
      anchor: this.shareButtonId,
      previewMode: systemShare.SharePreviewMode.DEFAULT,
      selectionMode: systemShare.SelectionMode.SINGLE
    }).then(() => {
      console.info('ShareController show success in 2in1 device.');
    }).catch((error: BusinessError) => {
      console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
    });
  }

  private shareWithCoordinates() {
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.PLAIN_TEXT,
      content: '2in1设备坐标分享示例'
    });

    let controller: systemShare.ShareController = new systemShare.ShareController(shareData);

    let uiContext: UIContext = this.getUIContext();
    let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;

    controller.on('dismiss', () => {
      console.info('Share panel closed (Popup mode with coordinates)');
    });

    controller.show(context, {
      anchor: {
        windowOffset: { x: 200, y: 150 },
        size: { width: 100, height: 50 }
      },
      previewMode: systemShare.SharePreviewMode.DETAIL,
      selectionMode: systemShare.SelectionMode.SINGLE
    }).then(() => {
      console.info('ShareController show success with coordinates.');
    }).catch((error: BusinessError) => {
      console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
    });
  }

  build() {
    Column() {
      Button('分享（控件ID锚点）')
        .id(this.shareButtonId)
        .onClick(() => {
          this.shareWithAnchorId();
        })
        .width('80%')
        .height(50)
        .margin({ bottom: 20 })

      Button('分享（坐标位置锚点）')
        .onClick(() => {
          this.shareWithCoordinates();
        })
        .width('80%')
        .height(50)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}