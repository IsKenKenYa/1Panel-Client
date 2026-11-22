import { LayeredDrawableDescriptor, DrawableDescriptor } from '@kit.ArkUI';
import { hdsDrawable } from '@kit.UIDesignKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { resourceManager } from '@kit.LocalizationKit';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct NormalIconBatchExample {
  private bundleName: string = 'com.example.uidesignkit';
  private resManager: resourceManager.ResourceManager | undefined = undefined;
  private layeredDrawableDescriptor: LayeredDrawableDescriptor | undefined = undefined;
  private drawableDescriptor: DrawableDescriptor | undefined = undefined;
  @State private processedIcons: Array<hdsDrawable.ProcessedIcon> = [];
  @State private processingStatus: string = '等待处理';
  @State private errorMessage: string = '';

  build() {
    Column() {
      Text('批量图标处理示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin(20)

      Text(this.processingStatus)
        .fontSize(16)
        .margin(10)

      if (this.processedIcons.length > 0) {
        List() {
          ForEach(this.processedIcons, (item: hdsDrawable.ProcessedIcon, index?: number) => {
            ListItem() {
              Row() {
                Image(item.pixelMap)
                  .width(48)
                  .height(48)
                  .borderRadius(8)
                  .margin({ right: 10 })
                
                Text(item.bundleName)
                  .fontSize(14)
                  .layoutWeight(1)
              }
              .padding(10)
              .width('100%')
            }
          }, (item: hdsDrawable.ProcessedIcon) => item.bundleName)
        }
        .width('100%')
        .height('50%')
        .margin(10)
      }

      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(14)
          .fontColor(Color.Red)
          .margin(10)
      }

      Row() {
        Button('处理10个图标')
          .width('45%')
          .height(50)
          .onClick(() => {
            this.processBatchIcons(10);
          })
        
        Button('处理50个图标')
          .width('45%')
          .height(50)
          .onClick(() => {
            this.processBatchIcons(50);
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .margin(20)
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }

  aboutToAppear(): void {
    this.initResources();
  }

  private initResources(): void {
    try {
      this.resManager = (this.getUIContext().getHostContext() as common.UIAbilityContext)?.resourceManager;
      if (!this.resManager) {
        this.errorMessage = '获取资源管理器失败';
        return;
      }

      this.layeredDrawableDescriptor = 
        (this.resManager.getDrawableDescriptor($r('app.media.drawable').id)) as LayeredDrawableDescriptor;
      
      this.drawableDescriptor = 
        (this.resManager.getDrawableDescriptor($r('app.media.normal_icon').id)) as DrawableDescriptor;
    } catch (err) {
      let error = err as BusinessError;
      this.errorMessage = `资源初始化失败: ${error.message}`;
    }
  }

  private async processBatchIcons(count: number): Promise<void> {
    try {
      if (!this.drawableDescriptor || !this.layeredDrawableDescriptor) {
        this.errorMessage = '图标资源未正确初始化';
        return;
      }

      this.processingStatus = `正在处理 ${count} 个图标...`;
      this.errorMessage = '';
      this.processedIcons = [];

      const options: hdsDrawable.Options = {
        size: 48,
        hasBorder: true,
        parallelNumber: 4
      };

      const icons: Array<hdsDrawable.Icon> = [];
      for (let i = 0; i < count; i++) {
        icons.push({
          bundleName: `${this.bundleName}-${i}`,
          pixelMap: this.drawableDescriptor.getPixelMap()
        });
      }

      const result: Array<hdsDrawable.ProcessedIcon> = 
        await hdsDrawable.getHdsIcons(
          icons,
          this.layeredDrawableDescriptor.getMask().getPixelMap(),
          options
        );

      this.processedIcons = result;
      this.processingStatus = `处理完成，共 ${result.length} 个图标`;
    } catch (err) {
      let error = err as BusinessError;
      this.errorMessage = `批量处理失败 [${error.code}]: ${error.message}`;
      this.processingStatus = '处理失败';
    }
  }
}