/**
 * 移动相机基本示例
 * 演示如何使用动画和非动画方式移动地图相机
 */

import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct MapCameraBasicDemo {
  private TAG = "MapCameraBasicDemo";
  private mapOptions?: mapCommon.MapOptions;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;

  aboutToAppear(): void {
    // 地图初始化参数
    this.mapOptions = {
      position: {
        target: {
          latitude: 39.9,
          longitude: 116.4
        },
        zoom: 10
      }
    };

    // 地图初始化回调
    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        console.info(this.TAG, 'Map initialized successfully');
        this.demonstrateCameraMove();
      } else {
        console.error(this.TAG, 'Map initialization failed:', err.message);
      }
    };
  }

  // 演示相机移动功能
  private demonstrateCameraMove(): void {
    // 示例1：非动画方式移动相机
    this.moveCameraWithoutAnimation();
    
    // 示例2：动画方式移动相机
    this.moveCameraWithAnimation();
    
    // 示例3：动画方式移动并获取结果
    this.moveCameraWithStatus();
  }

  // 非动画方式移动相机
  private moveCameraWithoutAnimation(): void {
    let cameraPosition: mapCommon.CameraPosition = {
      target: {
        latitude: 32.0,
        longitude: 118.0
      },
      zoom: 10,
      tilt: 0,
      bearing: 0
    };
    
    let cameraUpdate = map.newCameraPosition(cameraPosition);
    this.mapController?.moveCamera(cameraUpdate);
    console.info(this.TAG, 'Camera moved immediately without animation');
  }

  // 动画方式移动相机
  private moveCameraWithAnimation(): void {
    let cameraPosition: mapCommon.CameraPosition = {
      target: {
        latitude: 35.0,
        longitude: 120.0
      },
      zoom: 12
    };
    
    let cameraUpdate = map.newCameraPosition(cameraPosition);
    this.mapController?.animateCamera(cameraUpdate, 1000);
    console.info(this.TAG, 'Camera animation started (duration: 1000ms)');
  }

  // 动画方式移动并获取结果
  private async moveCameraWithStatus(): Promise<void> {
    try {
      let cameraPosition: mapCommon.CameraPosition = {
        target: {
          latitude: 40.0,
          longitude: 117.0
        },
        zoom: 8
      };
      
      let cameraUpdate = map.newCameraPosition(cameraPosition);
      let animateResult = await this.mapController?.animateCameraStatus(cameraUpdate, 2000);
      
      if (animateResult) {
        if (animateResult.isFinished) {
          console.info(this.TAG, 'Camera animation completed successfully');
        } else if (animateResult.isCanceled) {
          console.warn(this.TAG, 'Camera animation was canceled');
        }
      }
    } catch (error) {
      console.error(this.TAG, 'Camera animation failed:', error.message);
    }
  }

  build() {
    Stack() {
      MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
        .width('100%')
        .height('100%')
      
      Column() {
        Button('移动到南京 (非动画)')
          .onClick(() => this.moveCameraWithoutAnimation())
          .margin(10)
        
        Button('移动到青岛 (动画)')
          .onClick(() => this.moveCameraWithAnimation())
          .margin(10)
        
        Button('移动到北京 (动画+结果)')
          .onClick(() => this.moveCameraWithStatus())
          .margin(10)
      }
      .position({ x: 10, y: 10 })
    }
    .height('100%')
  }
}