import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { productViewManager } from '@kit.AppGalleryKit';

const TAG: string = 'GetPinShortcutInfos';
const DOMAIN: number = 0x0001;

@Entry
@Component
struct GetPinShortcutInfos {
  @State shortcutList: string = '';

  build() {
    Column() {
      Button("查询桌面快捷方式")
        .onClick(() => {
          this.getShortcutInfos();
        })
        .width('80%')
        .margin(16)

      Text(this.shortcutList)
        .width('90%')
        .fontSize(14)
        .margin(16)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  private async getShortcutInfos(): void {
    try {
      const result = await productViewManager.getPinShortcutInfos();
      hilog.info(DOMAIN, TAG, `getPinShortcutInfos success. Count: ${result.length}`);
      
      if (result.length === 0) {
        this.shortcutList = '当前应用未添加任何快捷方式到桌面';
        return;
      }

      let infoText = `已添加 ${result.length} 个快捷方式到桌面:\n`;
      for (let i = 0; i < result.length; i++) {
        infoText += `${i + 1}. ${JSON.stringify(result[i])}\n`;
      }
      this.shortcutList = infoText;
      
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `getPinShortcutInfos failed. Code: ${err.code}, Message: ${err.message}`);
      
      this.shortcutList = `查询失败: ${err.message}`;
    }
  }
}