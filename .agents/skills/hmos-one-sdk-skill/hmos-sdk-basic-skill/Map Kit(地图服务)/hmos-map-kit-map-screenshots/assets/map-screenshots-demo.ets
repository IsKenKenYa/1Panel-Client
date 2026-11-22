import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback, BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { fileIo as fs } from '@kit.CoreFileKit';

@Entry
@Component
struct MapScreenshotsDemo {
  private TAG = 'MapScreenshotsDemo';
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapEventManager?: map.MapEventManager;
  
  @State screenshotImage?: image.PixelMap = undefined;
  @State isMapLoaded: boolean = false;
  @State screenshotStatus: string = '';

  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 39.9,
          longitude: 116.4
        },
        zoom: 10
      }
    };
    
    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        this.mapEventManager = mapController.getEventManager();
        
        this.mapEventManager.on('mapLoad', () => {
          this.isMapLoaded = true;
          console.info(this.TAG, '地图加载完成');
        });
        
        console.info(this.TAG, '地图初始化成功');
      } else {
        console.error(this.TAG, `地图初始化失败: ${err.code}, ${err.message}`);
      }
    };
  }

  async takeScreenshot(): Promise<void> {
    if (!this.mapController) {
      this.screenshotStatus = '地图控制器未初始化';
      console.error(this.TAG, '地图控制器未初始化');
      return;
    }
    
    if (!this.isMapLoaded) {
      this.screenshotStatus = '地图未加载完成，请稍后';
      console.warn(this.TAG, '地图未加载完成');
      return;
    }
    
    this.screenshotStatus = '正在截图...';
    
    try {
      let pixelMap = await this.mapController.snapshot();
      
      if (pixelMap) {
        this.screenshotImage = pixelMap;
        this.screenshotStatus = '截图成功';
        console.info(this.TAG, '地图截图成功');
        
        const imageInfo = await pixelMap.getImageInfo();
        console.info(this.TAG, `截图尺寸: ${imageInfo.size.width}x${imageInfo.size.height}`);
      } else {
        this.screenshotStatus = '截图返回空结果';
        console.warn(this.TAG, '截图返回空结果');
      }
    } catch (error) {
      const err = error as BusinessError;
      this.screenshotStatus = `截图失败: ${err.code}`;
      
      switch (err.code) {
        case 1002601001:
          console.error(this.TAG, '操作对象不存在');
          break;
        case 501:
          console.error(this.TAG, '资源不可用');
          break;
        default:
          console.error(this.TAG, `未知错误: ${err.code}, ${err.message}`);
      }
    }
  }

  async saveScreenshot(): Promise<string> {
    if (!this.screenshotImage) {
      this.screenshotStatus = '无截图可保存';
      return '';
    }
    
    try {
      const imagePackerApi = image.createImagePacker();
      let packOpts: image.PackingOption = {
        format: 'image/jpeg',
        quality: 90
      };
      
      const data = await imagePackerApi.packing(this.screenshotImage, packOpts);
      const timestamp = Date.now();
      const filePath = `/data/storage/el2/base/files/map_screenshot_${timestamp}.jpg`;
      
      const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
      fs.writeSync(file.fd, data);
      fs.closeSync(file.fd);
      
      this.screenshotStatus = `截图已保存: ${filePath}`;
      console.info(this.TAG, `截图已保存: ${filePath}`);
      
      imagePackerApi.release();
      return filePath;
    } catch (error) {
      const err = error as BusinessError;
      this.screenshotStatus = `保存失败: ${err.message}`;
      console.error(this.TAG, `保存截图失败: ${err.code}, ${err.message}`);
      return '';
    }
  }

  build() {
    Column() {
      Stack() {
        MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
          .width('100%')
          .height('50%');
        
        if (!this.isMapLoaded) {
          Text('地图加载中...')
            .fontSize(14)
            .fontColor(Color.White)
            .backgroundColor(Color.Black)
            .padding(8);
        }
      }
      
      Scroll() {
        Column() {
          Text(this.screenshotStatus)
            .fontSize(12)
            .margin({ bottom: 10 });
          
          Row() {
            Button('获取截图')
              .fontSize(14)
              .margin({ right: 10 })
              .onClick(async () => {
                await this.takeScreenshot();
              });
            
            Button('保存截图')
              .fontSize(14)
              .enabled(this.screenshotImage !== undefined)
              .onClick(async () => {
                await this.saveScreenshot();
              });
          }
          .margin({ bottom: 10 });
          
          if (this.screenshotImage) {
            Text('截图预览:')
              .fontSize(12)
              .margin({ bottom: 5 });
            
            Image(this.screenshotImage)
              .objectFit(ImageFit.Auto)
              .width('100%')
              .border({ width: 1, color: Color.Blue })
              .margin({ bottom: 10 });
          }
        }
        .width('90%')
        .padding(10);
      }
      .width('100%')
      .height('50%');
    }
    .width('100%')
    .height('100%');
  }
}