import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Component
export struct ShareTextMultipleExample {
  private textList: string[] = [
    '第一条文本内容',
    '第二条文本内容',
    '第三条文本内容'
  ];

  build() {
    Column() {
      Button('批量分享文本')
        .onClick(() => {
          this.shareMultipleTexts();
        })
        .width('80%')
        .height(50)
        .margin({ top: 20 });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }

  private shareMultipleTexts(): void {
    try {
      if (this.textList.length === 0) {
        console.error('Text list is empty.');
        return;
      }

      let shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utd.UniformDataType.TEXT,
        content: this.textList[0],
        title: '文本1',
        description: '第一条文本内容'
      });

      this.textList.slice(1).forEach((text, index) => {
        shareData.addRecord({
          utd: utd.UniformDataType.TEXT,
          content: text,
          title: `文本${index + 2}`,
          description: `第${index + 2}条文本内容`
        });
      });

      let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
      let uiContext: UIContext = this.getUIContext();
      let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;

      controller.show(context, {
        selectionMode: systemShare.SelectionMode.SINGLE,
        previewMode: systemShare.SharePreviewMode.DEFAULT
      }).then(() => {
        console.info('ShareController show success.');
      }).catch((error: BusinessError) => {
        console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
        this.handleError(error);
      });
    } catch (error) {
      console.error('Share multiple texts failed:', error);
    }
  }

  private handleError(error: BusinessError): void {
    switch (error.code) {
      case 401:
        console.error('Parameter error. Please check input parameters.');
        break;
      case 1003700001:
        console.error('The number of records exceeds the maximum (500).');
        break;
      case 1003702002:
        console.error('IPC data is oversized. Please reduce data size.');
        break;
      default:
        console.error(`Unknown error. code: ${error.code}, message: ${error.message}`);
    }
  }
}