import { productViewManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG: string = 'Fallback';
const DOMAIN: number = 0x0001;

async function openAppDetailWithFallback(context: common.UIAbilityContext, bundleName: string): Promise<void> {
  try {
    const wantParam: Want = {
      parameters: {
        bundleName: bundleName
      }
    };

    productViewManager.loadProduct(context, wantParam, {
      onError: async (error: BusinessError) => {
        hilog.error(DOMAIN, TAG, `loadProduct failed: ${error.code}`);
        
        try {
          const want: Want = {
            action: 'ohos.want.action.appdetail',
            uri: 'store://appgallery.huawei.com/app/detail?id=' + bundleName
          };
          await context.startAbility(want);
          hilog.info(DOMAIN, TAG, 'Deep Linking succeeded');
        } catch (deepLinkError) {
          hilog.error(DOMAIN, TAG, 'Deep Linking failed');
          
          try {
            const link = 'https://appgallery.huawei.com/app/detail?id=' + bundleName;
            await context.openLink(link, { appLinkingOnly: false });
            hilog.info(DOMAIN, TAG, 'App Linking succeeded');
          } catch (appLinkError) {
            hilog.error(DOMAIN, TAG, 
              'All methods failed. Please search the app manually in AppGallery.');
          }
        }
      },
      onAppear: () => {
        hilog.info(DOMAIN, TAG, 'loadProduct onAppear');
      },
      onDisappear: () => {
        hilog.info(DOMAIN, TAG, 'loadProduct onDisappear');
      }
    });
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Failed to open app detail page: ${err.message}`);
  }
}

@Entry
@Component
struct FallbackExample {
  @State message: string = '拉起应用详情页（带降级）';

  build() {
    Row() {
      Column() {
        Button(this.message)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            const context: common.UIAbilityContext = 
              this.getUIContext().getHostContext() as common.UIAbilityContext;
            const bundleName = 'com.huawei.hmsapp.books';
            openAppDetailWithFallback(context, bundleName);
          })
      }
      .width('100%')
    }
    .height('100%')
  }
}