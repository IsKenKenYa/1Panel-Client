import { LayeredDrawableDescriptor, DrawableDescriptor } from '@kit.ArkUI';
import { hdsDrawable } from '@kit.UIDesignKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { resourceManager } from '@kit.LocalizationKit';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct NormalIconProcessExample {
  bundleName: string = 'com.example.uidesignkit';
  resManager: resourceManager.ResourceManager | undefined = undefined;
  layeredDrawableDescriptor: LayeredDrawableDescriptor | undefined = undefined;
  drawableDescriptor: DrawableDescriptor | undefined = undefined;
  @State singleIconResult: image.PixelMap | null = null;
  @State batchIconsResult: Array<hdsDrawable.ProcessedIcon> = [];
  @State statusMessage: string = 'Ready';

  build() {
    Column() {
      Text('单层图标处理示例')
        .fontWeight(FontWeight.Bold)
        .fontSize(20)
        .margin(10)

      Text(this.statusMessage)
        .fontSize(16)
        .margin(5)
        .fontColor(this.statusMessage.includes('success') ? Color.Green : Color.Blue)

      Button('处理单个图标')
        .width('80%')
        .margin(10)
        .onClick(() => {
          this.processSingleIcon();
        })

      if (this.singleIconResult) {
        Column() {
          Text('单个图标处理结果:')
            .fontSize(14)
            .margin(5)
          Image(this.singleIconResult)
            .width(48)
            .height(48)
            .margin(5)
        }
        .margin(10)
      }

      Button('批量处理图标')
        .width('80%')
        .margin(10)
        .onClick(() => {
          this.processBatchIcons();
        })

      if (this.batchIconsResult.length > 0) {
        Column() {
          Text('批量图标处理结果:')
            .fontSize(14)
            .margin(5)
          List() {
            ForEach(this.batchIconsResult, (item: hdsDrawable.ProcessedIcon, index?: number) => {
              ListItem() {
                Column() {
                  Text(item.bundleName)
                    .fontSize(12)
                    .margin(2)
                  Image(item.pixelMap)
                    .width(48)
                    .height(48)
                    .margin(2)
                }
                .margin(5)
              }
              .width('100%')
            }, (item: hdsDrawable.ProcessedIcon) => item.bundleName)
          }
          .scrollBar(BarState.On)
          .height('40%')
          .width('90%')
        }
        .margin(10)
      }
    }
    .height('100%')
    .width('100%')
    .padding(10)
  }

  aboutToAppear(): void {
    this.initializeResources();
  }

  private initializeResources(): void {
    try {
      this.resManager = (this.getUIContext().getHostContext() as common.UIAbilityContext)?.resourceManager;
      
      if (!this.resManager) {
        this.statusMessage = 'Error: ResourceManager is undefined';
        console.error('ResourceManager is undefined');
        return;
      }

      this.layeredDrawableDescriptor = (this.resManager.getDrawableDescriptor($r('app.media.drawable').id)) as LayeredDrawableDescriptor;
      this.drawableDescriptor = (this.resManager?.getDrawableDescriptor($r('app.media.normal_icon').id)) as DrawableDescriptor;
      
      if (!this.layeredDrawableDescriptor || !this.drawableDescriptor) {
        this.statusMessage = 'Error: Icon resources not found';
        console.error('Icon resources not found');
        return;
      }

      this.statusMessage = 'Resources initialized successfully';
      console.info('Resources initialized successfully');
    } catch (err) {
      const message = (err as BusinessError).message;
      const code = (err as BusinessError).code;
      this.statusMessage = `Error: ${message}`;
      console.error(`Initialize resources failed, code: ${code}, message: ${message}`);
    }
  }

  private processSingleIcon(): void {
    try {
      this.statusMessage = 'Processing single icon...';
      
      const result = this.getHdsIcon();
      
      if (result) {
        this.singleIconResult = result;
        this.statusMessage = 'Single icon processed successfully';
        console.info('Single icon processed successfully');
      } else {
        this.statusMessage = 'Error: Failed to process single icon';
        console.error('Failed to process single icon');
      }
    } catch (err) {
      const message = (err as BusinessError).message;
      const code = (err as BusinessError).code;
      this.statusMessage = `Error: ${message}`;
      console.error(`Process single icon failed, code: ${code}, message: ${message}`);
    }
  }

  private getHdsIcon(): image.PixelMap | null {
    try {
      if (!this.drawableDescriptor || !this.layeredDrawableDescriptor) {
        console.error('DrawableDescriptor or LayeredDrawableDescriptor is undefined');
        return null;
      }

      const size: number = 48;
      const hasBorder: boolean = true;
      const pixelMap: image.PixelMap = this.drawableDescriptor.getPixelMap();
      const mask: image.PixelMap = this.layeredDrawableDescriptor.getMask().getPixelMap();

      const processedIcon: image.PixelMap = hdsDrawable.getHdsIcon(
        this.bundleName,
        pixelMap,
        size,
        mask,
        hasBorder
      );

      console.info('getHdsIcon success');
      return processedIcon;
    } catch (err) {
      const message = (err as BusinessError).message;
      const code = (err as BusinessError).code;
      console.error(`getHdsIcon failed, code: ${code}, message: ${message}`);
      return null;
    }
  }

  private async processBatchIcons(): Promise<void> {
    try {
      this.statusMessage = 'Processing batch icons...';
      
      const result = await this.getHdsIcons();
      
      if (result && result.length > 0) {
        this.batchIconsResult = result;
        this.statusMessage = `Batch icons processed successfully (${result.length} icons)`;
        console.info(`Batch icons processed successfully (${result.length} icons)`);
      } else {
        this.statusMessage = 'Error: Failed to process batch icons';
        console.error('Failed to process batch icons');
      }
    } catch (err) {
      const message = (err as BusinessError).message;
      const code = (err as BusinessError).code;
      this.statusMessage = `Error: ${message}`;
      console.error(`Process batch icons failed, code: ${code}, message: ${message}`);
    }
  }

  private async getHdsIcons(): Promise<Array<hdsDrawable.ProcessedIcon>> {
    if (!this.drawableDescriptor) {
      console.error('DrawableDescriptor is undefined');
      throw new Error('DrawableDescriptor is undefined');
    }

    if (!this.layeredDrawableDescriptor) {
      console.error('LayeredDrawableDescriptor is undefined');
      throw new Error('LayeredDrawableDescriptor is undefined');
    }

    const options: hdsDrawable.Options = {
      size: 48,
      hasBorder: true,
      parallelNumber: 4
    };

    const icons: Array<hdsDrawable.Icon> = [];
    for (let i = 0; i < 10; i++) {
      icons.push({
        bundleName: `${this.bundleName}-${i}`,
        pixelMap: this.drawableDescriptor.getPixelMap()
      });
    }

    const mask: image.PixelMap = this.layeredDrawableDescriptor.getMask().getPixelMap();

    try {
      const data: Array<hdsDrawable.ProcessedIcon> = await hdsDrawable.getHdsIcons(icons, mask, options);
      console.info(`getHdsIcons success, processed ${data.length} icons`);
      return data;
    } catch (err) {
      const code = (err as BusinessError).code;
      
      if (code === 1012600001) {
        console.warn('Task is busy, retrying with reduced parallel number...');
        
        const fallbackOptions: hdsDrawable.Options = {
          size: 48,
          hasBorder: true,
          parallelNumber: 2
        };

        try {
          const data: Array<hdsDrawable.ProcessedIcon> = await hdsDrawable.getHdsIcons(icons, mask, fallbackOptions);
          console.info(`getHdsIcons fallback success, processed ${data.length} icons`);
          return data;
        } catch (retryErr) {
          console.error('Fallback failed, switching to single icon processing');
          return this.processIconsOneByOne(icons, mask, options);
        }
      }
      
      throw err;
    }
  }

  private async processIconsOneByOne(
    icons: Array<hdsDrawable.Icon>,
    mask: image.PixelMap,
    options: hdsDrawable.Options
  ): Promise<Array<hdsDrawable.ProcessedIcon>> {
    const results: Array<hdsDrawable.ProcessedIcon> = [];

    for (const icon of icons) {
      try {
        const processedIcon: image.PixelMap = hdsDrawable.getHdsIcon(
          icon.bundleName,
          icon.pixelMap,
          options.size,
          mask,
          options.hasBorder
        );

        results.push({
          bundleName: icon.bundleName,
          pixelMap: processedIcon
        });

        console.info(`Successfully processed icon ${icon.bundleName}`);
      } catch (err) {
        console.error(`Failed to process icon ${icon.bundleName}: ${(err as BusinessError).message}`);
      }
    }

    console.info(`Processed ${results.length} icons one by one`);
    return results;
  }

  private handleErrorCode(code: number): string {
    switch (code) {
      case 401:
        return 'Parameter error. Please check bundleName, pixelMap, size, mask, hasBorder parameters.';
      case 1012600001:
        return 'Task is busy. Please wait and retry or reduce parallel number.';
      default:
        return `Unknown error code: ${code}`;
    }
  }
}