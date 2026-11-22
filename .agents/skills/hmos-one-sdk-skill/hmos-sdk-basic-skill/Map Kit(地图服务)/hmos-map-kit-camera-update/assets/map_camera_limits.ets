/**
 * 设置缩放级别和边界示例
 * 演示如何设置相机的缩放级别限制和移动边界
 */

import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct MapCameraLimitsDemo {
  private TAG = "MapCameraLimitsDemo";
  private mapOptions?: mapCommon.MapOptions;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;
  @State minZoomText: string = '当前最小缩放: 未设置';
  @State maxZoomText: string = '当前最大缩放: 未设置';
  @State boundsText: string = '当前边界: 未设置';

  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 31.0,
          longitude: 118.0
        },
        zoom: 10
      },
      minZoom: 2,
      maxZoom: 20
    };

    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        console.info(this.TAG, 'Map initialized');
        this.updateZoomDisplay();
      }
    };
  }

  // 更新缩放级别显示
  private updateZoomDisplay(): void {
    if (this.mapController) {
      let minZoom = this.mapController.getMinZoom();
      let maxZoom = this.mapController.getMaxZoom();
      this.minZoomText = `当前最小缩放: ${minZoom}`;
      this.maxZoomText = `当前最大缩放: ${maxZoom}`;
    }
  }

  // 设置最小缩放级别
  private setMinZoom(): void {
    this.mapController?.setMinZoom(6);
    console.info(this.TAG, 'Min zoom set to 6');
    this.updateZoomDisplay();
  }

  // 设置最大缩放级别
  private setMaxZoom(): void {
    this.mapController?.setMaxZoom(14);
    console.info(this.TAG, 'Max zoom set to 14');
    this.updateZoomDisplay();
  }

  // 同时设置最小和最大缩放级别
  private setBothZoomLimits(): void {
    this.mapController?.setMinZoom(8);
    this.mapController?.setMaxZoom(16);
    console.info(this.TAG, 'Zoom range set to 8-16');
    this.updateZoomDisplay();
  }

  // 设置相机边界
  private setCameraBounds(): void {
    let bounds: mapCommon.LatLngBounds = {
      northeast: {
        latitude: 32.0,
        longitude: 120.0
      },
      southwest: {
        latitude: 30.0,
        longitude: 116.0
      }
    };
    
    this.mapController?.setLatLngBounds(bounds);
    this.boundsText = '当前边界: 30-32°N, 116-120°E';
    console.info(this.TAG, 'Camera bounds set');
  }

  // 清除相机边界
  private clearCameraBounds(): void {
    // 设置为空参数可以清除边界（需要传空对象或特殊处理）
    // 实际使用时可能需要传入 undefined 或空对象
    console.info(this.TAG, 'Camera bounds cleared (implementation depends on API version)');
    this.boundsText = '当前边界: 未设置';
  }

  // 测试边界有效性
  private testInvalidBounds(): void {
    let invalidBounds: mapCommon.LatLngBounds = {
      northeast: {
        latitude: 30.0,
        longitude: 120.0
      },
      southwest: {
        latitude: 32.0,  // 西南角纬度大于东北角纬度（无效）
        longitude: 116.0
      }
    };
    
    // 验证逻辑
    if (invalidBounds.southwest.latitude > invalidBounds.northeast.latitude) {
      console.error(this.TAG, 'Invalid bounds: southwest latitude must be less than northeast latitude');
      console.warn(this.TAG, 'Bounds will not be applied');
    }
  }

  // 测试缩放级别超出范围
  private testZoomOutOfRange(): void {
    // 设置超出范围的缩放级别
    this.mapController?.setMinZoom(1);   // 超出下限，会被调整为2
    this.mapController?.setMaxZoom(25);  // 超出上限，会被调整为20
    
    this.updateZoomDisplay();
    console.info(this.TAG, 'Zoom limits adjusted to valid range automatically');
  }

  // 获取当前相机位置
  private getCameraPosition(): void {
    if (this.mapController) {
      let position = this.mapController.getCameraPosition();
      console.info(this.TAG, `Current position: lat=${position.target.latitude}, lon=${position.target.longitude}, zoom=${position.zoom}`);
      if (position.tilt !== undefined) {
        console.info(this.TAG, `Tilt: ${position.tilt}`);
      }
      if (position.bearing !== undefined) {
        console.info(this.TAG, `Bearing: ${position.bearing}`);
      }
    }
  }

  build() {
    Stack() {
      MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
        .width('100%')
        .height('100%')
      
      Column() {
        Text('缩放级别限制设置')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 10, bottom: 5 })
        
        Text(this.minZoomText)
          .fontSize(14)
          .margin(2)
        
        Text(this.maxZoomText)
          .fontSize(14)
          .margin(2)
        
        Button('设置最小缩放(6)')
          .onClick(() => this.setMinZoom())
          .width('80%')
          .margin(5)
        
        Button('设置最大缩放(14)')
          .onClick(() => this.setMaxZoom())
          .width('80%')
          .margin(5)
        
        Button('同时设置(8-16)')
          .onClick(() => this.setBothZoomLimits())
          .width('80%')
          .margin(5)
        
        Divider().margin(10)
        
        Text('相机边界设置')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 5, bottom: 5 })
        
        Text(this.boundsText)
          .fontSize(14)
          .margin(2)
        
        Button('设置边界')
          .onClick(() => this.setCameraBounds())
          .width('80%')
          .margin(5)
        
        Button('清除边界')
          .onClick(() => this.clearCameraBounds())
          .width('80%')
          .margin(5)
        
        Divider().margin(10)
        
        Text('测试场景')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 5, bottom: 5 })
        
        Button('测试无效边界')
          .onClick(() => this.testInvalidBounds())
          .width('80%')
          .margin(5)
        
        Button('测试缩放超范围')
          .onClick(() => this.testZoomOutOfRange())
          .width('80%')
          .margin(5)
        
        Button('获取当前位置')
          .onClick(() => this.getCameraPosition())
          .width('80%')
          .margin(5)
      }
      .width('35%')
      .height('100%')
      .position({ x: '65%', y: 0 })
      .backgroundColor('#FFFFFF')
      .padding(10)
    }
    .height('100%')
  }
}