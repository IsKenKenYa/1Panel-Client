import { productViewManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG: string = 'LoadProduct';
const DOMAIN: number = 0x0001;

@Entry
@Component
struct LoadProductExample {
  @State message: string = '拉起应用市场详情页';

  build() {
    Row() {
      Column() {
        Button(this.message)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            this.loadProductPage();
          })
          .width('100%')
      }
      .height('100%')
    }
  }

  private loadProductPage(): void {
    try {
      const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;

      const wantParam: Want = {
        parameters: {
          bundleName: 'com.huawei.hmsapp.books'
        }
      };

      const callback: productViewManager.ProductViewCallback = {
        onError: (error: BusinessError) => {
          hilog.error(DOMAIN, TAG, 
            `loadProduct onError.code is ${error.code}, message is ${error.message}`);
          this.handleError(error.code);
        },
        onAppear: () => {
          hilog.info(DOMAIN, TAG, `loadProduct onAppear.`);
        },
        onDisappear: () => {
          hilog.info(DOMAIN, TAG, `loadProduct onDisappear.`);
        }
      };

      productViewManager.loadProduct(uiContext, wantParam, callback);
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, 
        `loadProduct failed.code is ${error.code}, message is ${error.message}`);
    }
  }

  private handleError(errorCode: number): void {
    switch (errorCode) {
      case 401:
        hilog.error(DOMAIN, TAG, 'Parameter error. Please check bundleName parameter.');
        break;
      case 1011:
        hilog.error(DOMAIN, TAG, 'Failed to launch or switch to foreground.');
        break;
      case 1012:
        hilog.error(DOMAIN, TAG, 'Failed to switch to background.');
        break;
      case 1013:
        hilog.error(DOMAIN, TAG, 'Failed to destroy.');
        break;
      default:
        hilog.error(DOMAIN, TAG, `Unknown error: code ${errorCode}`);
    }
  }
}