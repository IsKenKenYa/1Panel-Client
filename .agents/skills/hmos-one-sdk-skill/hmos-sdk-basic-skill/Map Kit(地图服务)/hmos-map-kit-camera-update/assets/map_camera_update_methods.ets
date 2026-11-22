/**
 * 多种CameraUpdate创建方式示例
 * 演示如何使用不同的方法创建CameraUpdate对象
 */

import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct MapCameraUpdateMethodsDemo {
  private TAG = "MapCameraUpdateMethodsDemo";
  private mapOptions?: mapCommon.MapOptions;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;

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
        console.info(this.TAG, 'Map initialized');
      }
    };
  }

  // 方式1：newCameraPosition - 设置相机完整位置
  private useNewCameraPosition(): void {
    let cameraPosition: mapCommon.CameraPosition = {
      target: { latitude: 31.0, longitude: 118.0 },
      zoom: 10,
      tilt: 30,    // 倾斜角度
      bearing: 45  // 旋转角度
    };
    let cameraUpdate = map.newCameraPosition(cameraPosition);
    this.mapController?.moveCamera(cameraUpdate);
    console.info(this.TAG, 'Method 1: newCameraPosition used');
  }

  // 方式2：newLatLng - 设置经纬度和缩放
  private useNewLatLng(): void {
    let latLng: mapCommon.LatLng = {
      latitude: 31.5,
      longitude: 118.9
    };
    let cameraUpdate = map.newLatLng(latLng, 12);
    this.mapController?.moveCamera(cameraUpdate);
    console.info(this.TAG, 'Method 2: newLatLng used');
  }

  // 方式3：zoomTo - 设置缩放级别
  private useZoomTo(): void {
    let zoom = 15.0;
    let cameraUpdate = map.zoomTo(zoom);
    this.mapController?.moveCamera(cameraUpdate);
    console.info(this.TAG, 'Method 3: zoomTo level 15');
  }

  // 方式4：zoomIn - 放大一级
  private useZoomIn(): void {
    let cameraUpdate = map.zoomIn();
    this.mapController?.animateCamera(cameraUpdate, 500);
    console.info(this.TAG, 'Method 4: zoomIn (放大一级)');
  }

  // 方式5：zoomOut - 缩小一级
  private useZoomOut(): void {
    let cameraUpdate = map.zoomOut();
    this.mapController?.animateCamera(cameraUpdate, 500);
    console.info(this.TAG, 'Method 5: zoomOut (缩小一级)');
  }

  // 方式6：zoomBy - 按增量缩放
  private useZoomBy(): void {
    let point: mapCommon.MapPoint = {
      positionX: 100,
      positionY: 200
    };
    let cameraUpdate = map.zoomBy(2.0, point);
    this.mapController?.moveCamera(cameraUpdate);
    console.info(this.TAG, 'Method 6: zoomBy with center point');
  }

  // 方式7：scrollBy - 按像素滚动
  private useScrollBy(): void {
    let x = 100.0;
    let y = 100.0;
    let cameraUpdate = map.scrollBy(x, y);
    this.mapController?.moveCamera(cameraUpdate);
    console.info(this.TAG, 'Method 7: scrollBy (100px, 100px)');
  }

  // 方式8：newLatLngBounds - 显示区域（单padding）
  private useNewLatLngBoundsSingle(): void {
    let latLngBounds: mapCommon.LatLngBounds = {
      northeast: { latitude: 32.5, longitude: 119.9 },
      southwest: { latitude: 31.5, longitude: 118.9 }
    };
    let cameraUpdate = map.newLatLngBounds(latLngBounds, 5);
    this.mapController?.animateCamera(cameraUpdate, 1000);
    console.info(this.TAG, 'Method 8: newLatLngBounds with single padding');
  }

  // 方式9：newLatLngBounds - 显示区域（宽高padding）
  private useNewLatLngBoundsWithDimensions(): void {
    let latLngBounds: mapCommon.LatLngBounds = {
      northeast: { latitude: 32.5, longitude: 119.9 },
      southwest: { latitude: 31.5, longitude: 118.9 }
    };
    let cameraUpdate = map.newLatLngBounds(latLngBounds, 1000, 1000, 100);
    this.mapController?.animateCamera(cameraUpdate, 1000);
    console.info(this.TAG, 'Method 9: newLatLngBounds with width/height/padding');
  }

  // 方式10：newLatLngBounds - 显示区域（四方向padding）
  private useNewLatLngBoundsWithPadding(): void {
    let latLngBounds: mapCommon.LatLngBounds = {
      northeast: { latitude: 32.5, longitude: 119.9 },
      southwest: { latitude: 31.5, longitude: 118.9 }
    };
    let paddings: mapCommon.Padding = {
      left: 5,
      top: 6,
      right: 7,
      bottom: 8
    };
    let cameraUpdate = map.newLatLngBounds(latLngBounds, paddings);
    this.mapController?.animateCamera(cameraUpdate, 1000);
    console.info(this.TAG, 'Method 10: newLatLngBounds with 4-direction padding');
  }

  build() {
    Stack() {
      MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
        .width('100%')
        .height('100%')
      
      Scroll() {
        Column() {
          Button('方式1: newCameraPosition')
            .onClick(() => this.useNewCameraPosition())
            .width('90%')
            .margin(5)
          
          Button('方式2: newLatLng')
            .onClick(() => this.useNewLatLng())
            .width('90%')
            .margin(5)
          
          Button('方式3: zoomTo(15)')
            .onClick(() => this.useZoomTo())
            .width('90%')
            .margin(5)
          
          Button('方式4: zoomIn')
            .onClick(() => this.useZoomIn())
            .width('90%')
            .margin(5)
          
          Button('方式5: zoomOut')
            .onClick(() => this.useZoomOut())
            .width('90%')
            .margin(5)
          
          Button('方式6: zoomBy')
            .onClick(() => this.useZoomBy())
            .width('90%')
            .margin(5)
          
          Button('方式7: scrollBy')
            .onClick(() => this.useScrollBy())
            .width('90%')
            .margin(5)
          
          Button('方式8: 区域显示(单padding)')
            .onClick(() => this.useNewLatLngBoundsSingle())
            .width('90%')
            .margin(5)
          
          Button('方式9: 区域显示(宽高padding)')
            .onClick(() => this.useNewLatLngBoundsWithDimensions())
            .width('90%')
            .margin(5)
          
          Button('方式10: 区域显示(四方向padding)')
            .onClick(() => this.useNewLatLngBoundsWithPadding())
            .width('90%')
            .margin(5)
        }
        .width('100%')
      }
      .width('30%')
      .height('100%')
      .position({ x: '70%', y: 0 })
      .backgroundColor('#FFFFFF')
    }
    .height('100%')
  }
}