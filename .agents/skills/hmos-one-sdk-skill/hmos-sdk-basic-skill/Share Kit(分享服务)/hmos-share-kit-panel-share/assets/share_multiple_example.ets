import { common } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileUri } from '@kit.CoreFileKit';

@Component
export struct ShareMultipleExample {
  private async shareMultipleData() {
    try {
      let shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utd.UniformDataType.PLAIN_TEXT,
        content: '这是一段文本内容',
        title: '文本标题'
      });

      let imagePath1 = '/data/storage/el2/base/files/image1.png';
      let imageUri1 = fileUri.getUriFromPath(imagePath1);
      shareData.addRecord({
        utd: utd.UniformDataType.PNG,
        uri: imageUri1,
        title: '图片1',
        label: '图片'
      });

      let imagePath2 = '/data/storage/el2/base/files/image2.png';
      let imageUri2 = fileUri.getUriFromPath(imagePath2);
      shareData.addRecord({
        utd: utd.UniformDataType.PNG,
        uri: imageUri2,
        title: '图片2',
        label: '图片'
      });

      shareData.addRecord({
        utd: utd.UniformDataType.HYPERLINK,
        content: 'https://developer.huawei.com',
        title: '华为开发者网站',
        label: '链接'
      });

      let records: systemShare.SharedRecord[] = shareData.getRecords();
      console.info(`Total records: ${records.length}`);

      let controller: systemShare.ShareController = new systemShare.ShareController(shareData);

      let uiContext: UIContext = this.getUIContext();
      let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;

      controller.on('dismiss', () => {
        console.info('Share panel closed');
      });

      controller.on('shareCompleted', (result: systemShare.ShareOperationResult) => {
        console.info('shareCompleted name:', result.targetAbilityInfo.name);
      });

      controller.show(context, {
        previewMode: systemShare.SharePreviewMode.DETAIL,
        selectionMode: systemShare.SelectionMode.SINGLE
      }).then(() => {
        console.info('ShareController show success.');
      }).catch((error: BusinessError) => {
        console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
        if (error.code === 1003700001) {
          console.error('数据记录超过上限500条');
        } else if (error.code === 1003702002) {
          console.error('IPC传输数据超过200KB上限');
        }
      });
    } catch (error) {
      console.error('Share multiple data failed:', error);
    }
  }

  build() {
    Column() {
      Button('分享多条数据')
        .onClick(() => {
          this.shareMultipleData();
        })
        .width('80%')
        .height(50)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}