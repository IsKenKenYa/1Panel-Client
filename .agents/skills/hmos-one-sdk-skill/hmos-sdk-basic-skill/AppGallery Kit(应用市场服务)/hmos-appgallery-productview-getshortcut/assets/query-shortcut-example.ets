import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { productViewManager } from '@kit.AppGalleryKit';
import { common } from '@kit.AbilityKit';

const TAG: string = 'QueryShortcutExample';
const DOMAIN: number = 0x0001;

@Entry
@Component
struct QueryShortcutExample {
  @State shortcutInfos: string[] = [];
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State totalCount: number = 0;

  private context: common.UIAbilityContext | null = null;

  aboutToAppear(): void {
    this.context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  build() {
    Column() {
      Text('查询应用内快捷方式示例')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 30, bottom: 20 })
        .width('100%')
        .textAlign(TextAlign.Center);

      Button('查询快捷方式列表')
        .width('80%')
        .height(60)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 20, bottom: 30 })
        .enabled(!this.isLoading)
        .onClick(() => {
          this.queryPinShortcuts();
        });

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(60)
            .height(60)
            .color('#007DFF');
          Text('正在查询...')
            .fontSize(16)
            .margin({ top: 10 });
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center);
      }

      if (this.errorMessage !== '') {
        Column() {
          Text('查询失败')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF0000');
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 10 });
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#FFF5F5F5')
        .borderRadius(10)
        .margin({ top: 20 });
      }

      if (!this.isLoading && this.totalCount > 0) {
        Column() {
          Text(`快捷方式总数: ${this.totalCount}`)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 15 });

          List() {
            ForEach(this.shortcutInfos, (item: string, index: number) => {
              ListItem() {
                Row() {
                  Text(`${index + 1}.`)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .width(40);
                  Text(item)
                    .fontSize(14)
                    .width('80%');
                }
                .width('100%')
                .padding(15)
                .backgroundColor('#F8F8F8')
                .borderRadius(8)
                .margin({ bottom: 8 });
              }
            }, (item: string) => item);
          }
          .width('90%')
          .layoutWeight(1)
          .margin({ top: 10 });
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
        .margin({ top: 20 });
      }

      if (!this.isLoading && this.totalCount === 0 && this.errorMessage === '') {
        Column() {
          Text('暂无快捷方式')
            .fontSize(20)
            .fontColor('#999999');
          Text('当前应用没有已固定在桌面的快捷方式')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 10 });
        }
        .width('100%')
        .padding(30)
        .justifyContent(FlexAlign.Center);
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF');
  }

  private async queryPinShortcuts(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    this.shortcutInfos = [];
    this.totalCount = 0;

    try {
      hilog.info(DOMAIN, TAG, 'Starting to query pin shortcut infos');

      const result = await productViewManager.getPinShortcutInfos();
      
      this.totalCount = result.length;
      hilog.info(DOMAIN, TAG, `Query successful, total count: ${this.totalCount}`);

      if (this.totalCount > 0) {
        this.shortcutInfos = result.map((info: any, index: number) => {
          const infoStr = JSON.stringify(info);
          hilog.debug(DOMAIN, TAG, `Shortcut ${index + 1}: ${infoStr}`);
          return infoStr;
        });
      }

      this.isLoading = false;

    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Query failed, code: ${err.code}, message: ${err.message}`);
      
      this.isLoading = false;
      this.totalCount = 0;
      
      switch (err.code) {
        case 401:
          this.errorMessage = '参数错误，请检查API调用';
          break;
        case 1006620001:
          this.errorMessage = '系统内部错误，请稍后重试';
          break;
        default:
          this.errorMessage = `查询失败: ${err.message}`;
      }
    }
  }
}