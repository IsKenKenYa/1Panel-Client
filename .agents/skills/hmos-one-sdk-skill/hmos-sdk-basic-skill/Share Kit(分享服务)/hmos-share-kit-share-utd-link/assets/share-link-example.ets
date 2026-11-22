import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct ShareLinkExample {
  private shareNormalLink() {
    try {
      let uiContext: UIContext = this.getUIContext();
      
      let shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utd.UniformDataType.HYPERLINK,
        content: 'https://www.vmall.com/index.html?cid=128688',
        title: '华为商城',
        description: '华为手机'
      });
      
      shareData.addRecord({
        utd: utd.UniformDataType.HYPERLINK,
        content: 'https://www.huawei.com/products',
        title: '华为产品',
        description: '查看华为全系列产品'
      });
      
      let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
      let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
      
      controller.on('dismiss', () => {
        console.info('分享面板已关闭');
      });
      
      controller.show(context, {
        selectionMode: systemShare.SelectionMode.SINGLE,
        previewMode: systemShare.SharePreviewMode.DEFAULT
      }).then(() => {
        console.info('ShareController show success.');
      }).catch((error: BusinessError) => {
        console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
      });
      
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`分享失败: code ${businessError.code}, message ${businessError.message}`);
    }
  }
  
  build() {
    Column() {
      Text('分享普通链接示例')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })
      
      Button('分享网页链接')
        .width('80%')
        .onClick(() => this.shareNormalLink())
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}