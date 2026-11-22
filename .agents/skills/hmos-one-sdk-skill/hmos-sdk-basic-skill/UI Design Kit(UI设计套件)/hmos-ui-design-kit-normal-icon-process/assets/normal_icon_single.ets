import { LayeredDrawableDescriptor, DrawableDescriptor } from '@kit.ArkUI';
import { hdsDrawable } from '@kit.UIDesignKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { resourceManager } from '@kit.LocalizationKit';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct NormalIconSingleExample {
  private bundleName: string = 'com.example.uidesignkit';
  private resManager: resourceManager.ResourceManager | undefined = undefined;
  private layeredDrawableDescriptor: LayeredDrawableDescriptor | undefined = undefined;
  private drawableDescriptor: DrawableDescriptor | undefined = undefined;
  @State private processedIcon: image.PixelMap | null = null;
  @State private errorMessage: string = '';

  build() {
    Column() {
      Text('单层图标处理示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin(20)

      if (this.processedIcon) {
        Column() {
          Text('处理后的图标:')
            .fontSize(16)
            .margin(10)
          Image(this.processedIcon)
            .width(96)
            .height(96)
            .borderRadius(12)
        }
        .margin(20)
      }

      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(14)
          .fontColor(Color.Red)
          .margin(10)
      }

      Button('处理图标')
        .width('80%')
        .height(50)
        .margin(20)
        .onClick(() => {
          this.processIcon();
        })
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

  private processIcon(): void {
    try {
      if (!this.drawableDescriptor || !this.layeredDrawableDescriptor) {
        this.errorMessage = '图标资源未正确初始化';
        return;
      }

      this.processedIcon = hdsDrawable.getHdsIcon(
        this.bundleName,
        this.drawableDescriptor.getPixelMap(),
        96,
        this.layeredDrawableDescriptor.getMask().getPixelMap(),
        true
      );

      this.errorMessage = '';
    } catch (err) {
      let error = err as BusinessError;
      this.errorMessage = `图标处理失败 [${error.code}]: ${error.message}`;
      this.processedIcon = null;
    }
  }
}