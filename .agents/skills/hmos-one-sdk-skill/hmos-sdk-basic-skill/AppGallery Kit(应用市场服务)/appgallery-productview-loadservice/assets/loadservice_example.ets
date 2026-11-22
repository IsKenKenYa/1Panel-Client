import { productViewManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG: string = 'LoadServiceExample';

@Entry
@Component
struct LoadServiceExample {
  @State message: string = '添加元服务卡片至桌面';
  @State loadResult: string = '';

  build() {
    Column() {
      Text(this.message)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 });

      Text(this.loadResult)
        .fontSize(16)
        .margin({ bottom: 20 })
        .visibility(this.loadResult ? Visibility.Visible : Visibility.None);

      Button('加载元服务卡片')
        .fontSize(20)
        .width('80%')
        .height(60)
        .onClick(() => {
          this.loadServiceCard();
        });

      Button('重置状态')
        .fontSize(18)
        .width('60%')
        .height(50)
        .margin({ top: 20 })
        .onClick(() => {
          this.loadResult = '';
        });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(20);
  }

  private loadServiceCard(): void {
    try {
      const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      
      const wantParam: Want = {
        uri: 'store://appgallery.huawei.com/oper/addhome?referrer=xxxx&id=xxxx&installType=xxxx&s=xxxx'
      };
      
      const callback: productViewManager.ServiceViewCallback = {
        onReceive: (data: productViewManager.ServiceViewReceiveData) => {
          hilog.info(0x0001, TAG, `onReceive triggered`);
          hilog.info(0x0001, TAG, `result: ${data.result}, msg: ${data.msg}`);
          
          if (data.result === productViewManager.ReceiveDataResult.SUCCESS) {
            this.loadResult = '加桌成功';
            hilog.info(0x0001, TAG, `卡片包名: ${data.formInfo.bundleName}`);
            hilog.info(0x0001, TAG, `卡片名称: ${data.formInfo.name}`);
            hilog.info(0x0001, TAG, `卡片尺寸: ${data.formInfo.defaultDimension}`);
          } else if (data.result === productViewManager.ReceiveDataResult.FAILURE) {
            this.loadResult = `加桌失败: ${data.msg}`;
          } else if (data.result === productViewManager.ReceiveDataResult.EXCEPTION) {
            this.loadResult = `加桌异常: ${data.msg}`;
          }
        },
        onError: (error: BusinessError) => {
          hilog.error(0x0001, TAG, `onError triggered`);
          hilog.error(0x0001, TAG, `error code: ${error.code}, message: ${error.message}`);
          
          if (error.code === 401) {
            this.loadResult = '参数错误：请检查uri是否有效';
          } else if (error.code === 1011) {
            this.loadResult = '拉起/切前台失败';
          } else if (error.code === 1012) {
            this.loadResult = '切后台失败';
          } else if (error.code === 1013) {
            this.loadResult = '销毁失败';
          } else {
            this.loadResult = `未知错误: ${error.code}`;
          }
        },
        onAppear: () => {
          hilog.info(0x0001, TAG, `onAppear triggered`);
          this.loadResult = '加桌页面已打开';
        },
        onDisappear: () => {
          hilog.info(0x0001, TAG, `onDisappear triggered`);
          hilog.info(0x0001, TAG, '加桌页面已关闭');
        }
      };
      
      hilog.info(0x0001, TAG, 'Calling loadService API');
      productViewManager.loadService(uiContext, wantParam, callback);
      
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(0x0001, TAG, `Exception caught: ${error.code}, ${error.message}`);
      this.loadResult = `调用失败: ${error.message}`;
    }
  }
}