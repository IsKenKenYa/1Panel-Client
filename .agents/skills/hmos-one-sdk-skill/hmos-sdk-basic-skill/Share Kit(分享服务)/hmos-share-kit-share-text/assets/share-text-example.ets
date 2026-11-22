import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Component
export struct ShareTextExample {
  private textContent: string = '这是一段文本内容';
  private title: string = '文本标题';
  private description: string = '文本描述';

  build() {
    Column() {
      Button('分享文本')
        .onClick(() => {
          this.shareText();
        })
        .width('80%')
        .height(50)
        .margin({ top: 20 });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }

  private shareText(): void {
    try {
      let shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utd.UniformDataType.TEXT,
        content: this.textContent,
        title: this.title,
        description: this.description
      });

      let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
      let uiContext: UIContext = this.getUIContext();
      let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;

      controller.show(context, {
        selectionMode: systemShare.SelectionMode.SINGLE,
        previewMode: systemShare.SharePreviewMode.DETAIL
      }).then(() => {
        console.info('ShareController show success.');
      }).catch((error: BusinessError) => {
        console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
      });
    } catch (error) {
      console.error('Share text failed:', error);
    }
  }
}