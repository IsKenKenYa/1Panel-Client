import { productViewManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG: string = 'LoadServiceExample';
const DOMAIN_NUMBER: number = 0x0001;

@Entry
@Component
struct LoadServiceExample {
  @State message: string = '添加元服务卡片至桌面';

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 20 })
        
        Button('加载元服务卡片')
          .fontSize(18)
          .width('80%')
          .onClick(() => {
            this.loadServiceCard();
          })
        
        Button('加载示例元服务（测试）')
          .fontSize(18)
          .width('80%')
          .margin({ top: 20 })
          .onClick(() => {
            this.loadServiceCardWithFallback();
          })
      }
      .width('100%')
    }
    .height('100%')
  }

  loadServiceCard(): void {
    try {
      const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      
      const wantParam: Want = {
        uri: 'store://appgallery.huawei.com/oper/addhome?referrer=xxxx&id=xxxx&installType=xxxx&s=xxxx'
      };

      const callback: productViewManager.ServiceViewCallback = {
        onReceive: (data: productViewManager.ServiceViewReceiveData) => {
          hilog.info(DOMAIN_NUMBER, TAG, `loadService onReceive.result is ${data.result}, msg is ${data.msg}`);
          hilog.info(DOMAIN_NUMBER, TAG, `formInfo is ${JSON.stringify(data.formInfo)}`);
          
          if (data.result === productViewManager.ReceiveDataResult.SUCCESS) {
            this.message = '加桌成功';
            hilog.info(DOMAIN_NUMBER, TAG, `Successfully added to desktop`);
            hilog.info(DOMAIN_NUMBER, TAG, `bundleName: ${data.formInfo.bundleName}`);
            hilog.info(DOMAIN_NUMBER, TAG, `abilityName: ${data.formInfo.abilityName}`);
            hilog.info(DOMAIN_NUMBER, TAG, `moduleName: ${data.formInfo.moduleName}`);
            hilog.info(DOMAIN_NUMBER, TAG, `name: ${data.formInfo.name}`);
            hilog.info(DOMAIN_NUMBER, TAG, `defaultDimension: ${data.formInfo.defaultDimension}`);
          } else if (data.result === productViewManager.ReceiveDataResult.FAILURE) {
            this.message = '加桌失败';
            hilog.warn(DOMAIN_NUMBER, TAG, `Failed to add to desktop: ${data.msg}`);
          } else if (data.result === productViewManager.ReceiveDataResult.EXCEPTION) {
            this.message = '加桌异常';
            hilog.error(DOMAIN_NUMBER, TAG, `Exception when adding to desktop: ${data.msg}`);
          }
        },
        
        onError: (error: BusinessError) => {
          this.message = `加载失败: ${error.code}`;
          hilog.error(DOMAIN_NUMBER, TAG, `loadService onError.code is ${error.code}, message is ${error.message}`);
          
          if (error.code === 401) {
            hilog.error(DOMAIN_NUMBER, TAG, 'Parameter error, please check your input parameters');
          } else if (error.code === 1011) {
            hilog.error(DOMAIN_NUMBER, TAG, 'Failed to launch or switch to foreground');
          } else if (error.code === 1012) {
            hilog.error(DOMAIN_NUMBER, TAG, 'Failed to switch to background');
          } else if (error.code === 1013) {
            hilog.error(DOMAIN_NUMBER, TAG, 'Failed to destroy');
          }
        },
        
        onAppear: () => {
          hilog.info(DOMAIN_NUMBER, TAG, `loadService onAppear.`);
          this.message = '加载中...';
        },
        
        onDisappear: () => {
          hilog.info(DOMAIN_NUMBER, TAG, `loadService onDisappear.`);
        }
      };

      productViewManager.loadService(uiContext, wantParam, callback);
      hilog.info(DOMAIN_NUMBER, TAG, 'loadService called successfully');
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN_NUMBER, TAG, `loadService failed. code is ${error.code}, message is ${error.message}`);
      this.message = `加载失败: ${error.message}`;
    }
  }

  async loadServiceCardWithFallback(): Promise<void> {
    try {
      const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      
      const wantParam: Want = {
        uri: 'store://appgallery.huawei.com/oper/addhome?referrer=example&id=example&installType=example&s=example'
      };

      await new Promise<void>((resolve, reject) => {
        const timeout = setTimeout(() => {
          reject(new Error('Timeout after 5 seconds'));
        }, 5000);

        const callback: productViewManager.ServiceViewCallback = {
          onReceive: (data: productViewManager.ServiceViewReceiveData) => {
            clearTimeout(timeout);
            
            if (data.result === productViewManager.ReceiveDataResult.SUCCESS) {
              this.message = '加桌成功';
              hilog.info(DOMAIN_NUMBER, TAG, `Successfully added to desktop with fallback`);
              resolve();
            } else {
              reject(new Error(`Failed with result: ${data.result}, msg: ${data.msg}`));
            }
          },
          
          onError: (error: BusinessError) => {
            clearTimeout(timeout);
            reject(error);
          },
          
          onAppear: () => {
            hilog.info(DOMAIN_NUMBER, TAG, `loadService with fallback onAppear.`);
            this.message = '加载中...';
          },
          
          onDisappear: () => {
            hilog.info(DOMAIN_NUMBER, TAG, `loadService with fallback onDisappear.`);
            clearTimeout(timeout);
            resolve();
          }
        };

        productViewManager.loadService(uiContext, wantParam, callback);
      });
    } catch (error) {
      const businessError = error as BusinessError | Error;
      
      if ('code' in businessError) {
        hilog.error(DOMAIN_NUMBER, TAG, `loadService with fallback failed. code: ${businessError.code}, message: ${businessError.message}`);
        
        if (businessError.code === 401) {
          this.message = '参数错误，请检查链接';
          hilog.warn(DOMAIN_NUMBER, TAG, 'Invalid parameters or unsupported device');
        } else {
          this.message = '加载失败，请稍后重试';
        }
      } else {
        hilog.error(DOMAIN_NUMBER, TAG, `loadService with fallback failed: ${businessError.message}`);
        this.message = '网络异常，请稍后重试';
      }
    }
  }
}