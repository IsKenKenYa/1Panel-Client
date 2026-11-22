/**
 * 分层图标处理完整示例
 * 本示例展示如何使用UI Design Kit的hdsDrawable模块处理分层图标
 * 包含单个图标处理和批量处理两种方式
 */

import { LayeredDrawableDescriptor } from '@kit.ArkUI';
import { hdsDrawable } from '@kit.UIDesignKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { resourceManager } from '@kit.LocalizationKit';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct LayeredIconProcessExample {
  bundleName: string = 'com.example.uidesignkit';
  resManager: resourceManager.ResourceManager | undefined = undefined;
  layeredDrawableDescriptor: LayeredDrawableDescriptor | undefined = undefined;
  @State singleIconResult: image.PixelMap | null = null;
  @State layeredIconsResult: Array<hdsDrawable.ProcessedIcon> = [];
  @State asyncIconResult: image.PixelMap | null = null;
  @State errorMessage: string = '';

  build() {
    Column() {
      Text('分层图标处理示例')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin(10)

      Column() {
        Text('单个图标处理（同步）')
          .fontWeight(FontWeight.Bold)
          .fontSize(16)
          .margin(5)
        
        if (this.singleIconResult) {
          Image(this.singleIconResult)
            .width(48)
            .height(48)
            .margin(10)
        } else {
          Text(this.errorMessage || '加载中...')
            .fontSize(14)
            .margin(10)
        }
      }
      .margin(20)

      Column() {
        Text('单个图标处理（异步）')
          .fontWeight(FontWeight.Bold)
          .fontSize(16)
          .margin(5)
        
        if (this.asyncIconResult) {
          Image(this.asyncIconResult)
            .width(48)
            .height(48)
            .margin(10)
        } else {
          Text('加载中...')
            .fontSize(14)
            .margin(10)
        }
      }
      .margin(20)

      Column() {
        Text('批量图标处理')
          .fontWeight(FontWeight.Bold)
          .fontSize(16)
          .margin(5)
        
        if (this.layeredIconsResult.length > 0) {
          List() {
            ForEach(this.layeredIconsResult, 
              (item: hdsDrawable.ProcessedIcon, index?: number) => {
                ListItem() {
                  Column() {
                    Text(item.bundleName)
                      .fontWeight(FontWeight.Medium)
                      .fontSize(14)
                      .margin(5)
                    Image(item.pixelMap)
                      .width(48)
                      .height(48)
                  }
                  .margin(10)
                }
                .width('100%')
              }, (item: hdsDrawable.ProcessedIcon) => item.bundleName)
          }
          .scrollBar(BarState.On)
          .height(300)
        } else {
          Text('加载中...')
            .fontSize(14)
            .margin(10)
        }
      }
      .margin(20)

      Button('刷新图标')
        .onClick(() => {
          this.processIcons();
        })
        .margin(20)
    }
    .height('100%')
    .width('100%')
  }

  aboutToAppear(): void {
    this.initResources();
    this.processIcons();
  }

  /**
   * 初始化资源管理器和分层图标对象
   */
  private initResources(): void {
    try {
      // 获取资源管理器
      this.resManager = (this.getUIContext().getHostContext() as common.UIAbilityContext)?.resourceManager;
      if (!this.resManager) {
        this.errorMessage = '无法获取资源管理器';
        console.error('Failed to get resource manager');
        return;
      }

      // 通过资源管理器获取原始分层图标信息
      this.layeredDrawableDescriptor = 
        (this.resManager.getDrawableDescriptor($r('app.media.drawable').id)) as LayeredDrawableDescriptor;
      
      if (!this.layeredDrawableDescriptor) {
        this.errorMessage = '无法获取分层图标对象';
        console.error('Failed to get layeredDrawableDescriptor');
        return;
      }

      console.info('Resources initialized successfully');
    } catch (err) {
      const message = (err as BusinessError).message;
      const code = (err as BusinessError).code;
      this.errorMessage = `初始化失败: code ${code}, message ${message}`;
      console.error(`initResources failed, code: ${code}, message: ${message}`);
    }
  }

  /**
   * 处理所有图标
   */
  private async processIcons(): void {
    if (!this.layeredDrawableDescriptor) {
      console.error('layeredDrawableDescriptor is undefined');
      return;
    }

    // 处理单个图标（同步）
    this.processSingleIcon();

    // 处理单个图标（异步）
    await this.processSingleIconAsync();

    // 批量处理图标
    await this.processBatchIcons();
  }

  /**
   * 使用同步接口处理单个图标
   */
  private processSingleIcon(): void {
    if (!this.layeredDrawableDescriptor) {
      console.error('layeredDrawableDescriptor is undefined');
      return;
    }

    try {
      // 调用HDS分层图标接口处理图标
      const processedIcon: image.PixelMap = hdsDrawable.getHdsLayeredIcon(
        this.bundleName,
        this.layeredDrawableDescriptor,
        48,
        true
      );
      
      this.singleIconResult = processedIcon;
      this.errorMessage = '';
      console.info('getHdsLayeredIcon success');
    } catch (err) {
      const message = (err as BusinessError).message;
      const code = (err as BusinessError).code;
      this.errorMessage = `处理失败: code ${code}`;
      console.error(`getHdsLayeredIcon failed, code: ${code}, message: ${message}`);
    }
  }

  /**
   * 使用异步接口处理单个图标
   */
  private async processSingleIconAsync(): Promise<void> {
    if (!this.layeredDrawableDescriptor) {
      console.error('layeredDrawableDescriptor is undefined');
      return;
    }

    try {
      // 调用HDS异步分层图标接口
      const processedIcon: image.PixelMap = await hdsDrawable.getHdsLayeredIconAsync(
        this.bundleName,
        this.layeredDrawableDescriptor,
        48,
        true
      );
      
      this.asyncIconResult = processedIcon;
      console.info('getHdsLayeredIconAsync success');
    } catch (err) {
      const message = (err as BusinessError).message;
      const code = (err as BusinessError).code;
      console.error(`getHdsLayeredIconAsync failed, code: ${code}, message: ${message}`);
    }
  }

  /**
   * 批量处理图标
   */
  private async processBatchIcons(): Promise<void> {
    if (!this.layeredDrawableDescriptor) {
      console.error('layeredDrawableDescriptor is undefined');
      return;
    }

    // 构造批量接口传参
    const options: hdsDrawable.Options = {
      size: 48,
      hasBorder: true,
      parallelNumber: 4
    };

    const layeredIcons: Array<hdsDrawable.LayeredIcon> = [];
    for (let i = 0; i < 10; i++) {
      layeredIcons.push({
        bundleName: `${this.bundleName}-${i}`,
        layeredDrawableDescriptor: this.layeredDrawableDescriptor
      });
    }

    try {
      // 调用HDS批量分层接口处理图标
      const processedIcons: Array<hdsDrawable.ProcessedIcon> = 
        await hdsDrawable.getHdsLayeredIcons(layeredIcons, options);
      
      console.info(`getHdsLayeredIcons success, processed ${processedIcons.length} icons`);
      this.layeredIconsResult = processedIcons;
    } catch (err) {
      const message = (err as BusinessError).message;
      const code = (err as BusinessError).code;
      console.error(`getHdsLayeredIcons failed, code: ${code}, message: ${message}`);
      
      // 降级处理：逐个处理图标
      this.fallbackProcessIcons(layeredIcons, options);
    }
  }

  /**
   * 降级处理：批量处理失败时逐个处理
   */
  private async fallbackProcessIcons(
    icons: Array<hdsDrawable.LayeredIcon>,
    options: hdsDrawable.Options
  ): Promise<void> {
    console.warn('Batch processing failed, fallback to individual processing');
    
    const fallbackResults: Array<hdsDrawable.ProcessedIcon> = [];
    for (const icon of icons) {
      try {
        const pixelMap: image.PixelMap = hdsDrawable.getHdsLayeredIcon(
          icon.bundleName,
          icon.layeredDrawableDescriptor,
          options.size,
          options.hasBorder
        );
        
        fallbackResults.push({
          bundleName: icon.bundleName,
          pixelMap: pixelMap
        });
      } catch (err) {
        console.error(`Failed to process icon ${icon.bundleName}`);
      }
    }
    
    this.layeredIconsResult = fallbackResults;
    console.info(`Fallback processing completed, ${fallbackResults.length} icons processed`);
  }
}