import { appInfoManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG: string = 'DynamicIconPage';

@Entry
@Component
struct DynamicIconPage {
  @State dynamicIconInfos: appInfoManager.DynamicIconInfo[] = [];
  @State currentIconId: string = '';
  @State message: string = '点击按钮查询动态图标';
  @State isLoading: boolean = false;

  build() {
    Column() {
      Text('动态图标管理')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })

      Text(this.message)
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 20 })
        .width('90%')

      if (this.isLoading) {
        LoadingProgress()
          .width(50)
          .height(50)
          .margin({ bottom: 20 })
      }

      Button('查询动态图标')
        .width('90%')
        .height(40)
        .margin({ bottom: 10 })
        .onClick(() => this.queryIcons())

      if (this.dynamicIconInfos.length > 0) {
        List() {
          ForEach(this.dynamicIconInfos, (icon: appInfoManager.DynamicIconInfo, index: number) => {
            ListItem() {
              Row() {
                Column() {
                  Text(`图标 ${index + 1}`)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                  
                  Text(`ID: ${icon.iconId}`)
                    .fontSize(12)
                    .fontColor('#999999')
                    .margin({ top: 4 })
                  
                  Text(`状态: ${icon.enabled ? '使用中' : '未使用'}`)
                    .fontSize(12)
                    .fontColor(icon.enabled ? '#00AA00' : '#999999')
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Button(icon.enabled ? '当前图标' : '切换')
                  .width(80)
                  .height(32)
                  .fontSize(12)
                  .enabled(!icon.enabled && !this.isLoading)
                  .backgroundColor(icon.enabled ? '#CCCCCC' : '#007DFF')
                  .onClick(() => this.switchIcon(icon.iconId))
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .margin({ bottom: 8 })
            }
          }, (icon: appInfoManager.DynamicIconInfo) => icon.iconId)
        }
        .width('90%')
        .height(300)
        .margin({ top: 10, bottom: 10 })
      }

      if (this.currentIconId) {
        Button('恢复默认图标')
          .width('90%')
          .height(40)
          .backgroundColor('#FF0000')
          .margin({ top: 10 })
          .onClick(() => this.restoreIcon())
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  private async queryIcons(): Promise<void> {
    this.isLoading = true;
    this.message = '查询中...';

    try {
      const icons = await appInfoManager.queryDynamicIcons();
      this.dynamicIconInfos = icons;
      
      const enabledIcon = icons.find(icon => icon.enabled);
      this.currentIconId = enabledIcon ? enabledIcon.iconId : '';
      
      this.message = `查询成功，共${icons.length}个图标`;
      hilog.info(0, TAG, `Query succeeded: ${icons.length} icons`);
    } catch (error) {
      const err = error as BusinessError;
      this.message = `查询失败: ${err.message}`;
      hilog.error(0, TAG, `Query failed: ${err.code} - ${err.message}`);
    } finally {
      this.isLoading = false;
    }
  }

  private async switchIcon(iconId: string): Promise<void> {
    this.isLoading = true;
    this.message = '切换中...';

    try {
      await appInfoManager.selectDynamicIcon(iconId);
      
      this.currentIconId = iconId;
      this.message = '切换成功';
      
      await this.queryIcons();
      
      hilog.info(0, TAG, `Switch succeeded: ${iconId}`);
    } catch (error) {
      const err = error as BusinessError;
      this.message = `切换失败: ${this.getErrorMessage(err.code)}`;
      hilog.error(0, TAG, `Switch failed: ${err.code} - ${err.message}`);
    } finally {
      this.isLoading = false;
    }
  }

  private async restoreIcon(): Promise<void> {
    this.isLoading = true;
    this.message = '恢复中...';

    try {
      await appInfoManager.disableDynamicIcon();
      
      this.currentIconId = '';
      this.message = '已恢复默认图标';
      
      await this.queryIcons();
      
      hilog.info(0, TAG, 'Restore succeeded');
    } catch (error) {
      const err = error as BusinessError;
      this.message = `恢复失败: ${this.getErrorMessage(err.code)}`;
      hilog.error(0, TAG, `Restore failed: ${err.code} - ${err.message}`);
    } finally {
      this.isLoading = false;
    }
  }

  private getErrorMessage(code: number): string {
    switch (code) {
      case 1006800001:
        return '服务连接失败，请安装应用市场客户端';
      case 1006800009:
        return '系统内部错误，请重试';
      case 1006800010:
        return '无动态图标数据，请在AGC上传图标';
      case 1006800011:
        return '选择动态图标失败';
      case 1006800012:
        return '当前已是默认图标';
      case 1006800013:
        return '主题自定义图标生效中，请切换至官方主题';
      case 401:
        return '参数错误';
      default:
        return `未知错误: ${code}`;
    }
  }
}