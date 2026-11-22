import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common, Want } from '@kit.AbilityKit';

const TAG: string = 'DeepLinking';
const DOMAIN: number = 0x0001;

function startAppGalleryDetailAbility(context: common.UIAbilityContext, bundleName: string): void {
  let want: Want = {
    action: 'ohos.want.action.appdetail',
    uri: 'store://appgallery.huawei.com/app/detail?id=' + bundleName
  };

  context.startAbility(want).then(() => {
    hilog.info(DOMAIN, TAG, "Succeeded in starting Ability successfully.");
  }).catch((error: BusinessError) => {
    hilog.error(DOMAIN, TAG, 
      `Failed to startAbility.Code: ${error.code}, message is ${error.message}`);
  });
}

@Entry
@Component
struct DeepLinkingExample {
  @State message: string = '拉起应用市场详情页';

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
            startAppGalleryDetailAbility(context, bundleName);
          })
      }
      .width('100%')
    }
    .height('100%')
  }
}