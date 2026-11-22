# 相机控制（Camera Control）示例

## 相机动画示例

```typescript
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct CameraControlDemo {
  private TAG = "CameraControlDemo";
  private mapController?: map.MapComponentController;

  aboutToAppear(): void {
    let mapOptions: mapCommon.MapOptions = {
      position: {
        target: {
          latitude: 39.9,
          longitude: 116.4
        },
        zoom: 10
      }
    };

    let callback: AsyncCallback<map.MapComponentController> = (err, controller) => {
      if (!err) {
        this.mapController = controller;
      }
    };

    // 创建地图
    this.mapController = MapComponent({ mapOptions: mapOptions, mapCallback: callback }).getController();
  }

  // 动画移动相机到指定位置
  animateCameraToLocation(): void {
    let cameraPosition: mapCommon.CameraPosition = {
      target: {
        latitude: 40.0,
        longitude: 116.5
      },
      zoom: 15,
      tilt: 45,
      bearing: 0
    };
    let cameraUpdate = mapCommon.CameraUpdateFactory.newCameraPosition(cameraPosition);
    this.mapController.animateCamera(cameraUpdate, 1000);
  }

  // 带动画时长移动相机
  animateCameraWithDuration(): void {
    let latLng: mapCommon.LatLng = {
      latitude: 39.95,
      longitude: 116.45
    };
    let cameraUpdate = mapCommon.CameraUpdateFactory.newLatLngZoom(latLng, 12);
    this.mapController.animateCamera(cameraUpdate, 2000);
  }

  // 获取当前相机位置
  getCurrentCameraPosition(): void {
    let position = this.mapController.getCameraPosition();
    console.info(this.TAG, `Current camera position: ${JSON.stringify(position)}`);
  }

  // 无动画直接移动相机
  moveCameraDirectly(): void {
    let latLng: mapCommon.LatLng = {
      latitude: 39.9,
      longitude: 116.4
    };
    let cameraUpdate = mapCommon.CameraUpdateFactory.newLatLngZoom(latLng, 14);
    this.mapController.moveCamera(cameraUpdate);
  }

  // 停止动画
  stopCurrentAnimation(): void {
    this.mapController.stopAnimation();
  }
}
```

## 缩放级别控制示例

```typescript
// 设置最大最小缩放级别
setZoomLevels(): void {
  this.mapController.setMinZoom(5);
  this.mapController.setMaxZoom(18);
}

// 获取当前缩放级别范围
getZoomLevels(): void {
  let minZoom = this.mapController.getMinZoom();
  let maxZoom = this.mapController.getMaxZoom();
  console.info(this.TAG, `Zoom range: ${minZoom} - ${maxZoom}`);
}

// 放大一级
zoomIn(): void {
  let cameraUpdate = mapCommon.CameraUpdateFactory.zoomIn();
  this.mapController.animateCamera(cameraUpdate);
}

// 缩小一级
zoomOut(): void {
  let cameraUpdate = mapCommon.CameraUpdateFactory.zoomOut();
  this.mapController.animateCamera(cameraUpdate);
}

// 缩放到指定级别
zoomToLevel(level: number): void {
  let cameraUpdate = mapCommon.CameraUpdateFactory.zoomTo(level);
  this.mapController.animateCamera(cameraUpdate);
}

// 按增量缩放
zoomByDelta(delta: number): void {
  let cameraUpdate = mapCommon.CameraUpdateFactory.zoomBy(delta);
  this.mapController.animateCamera(cameraUpdate);
}
```

## 相机范围控制示例

```typescript
// 设置相机移动范围边界
setCameraBounds(): void {
  let bounds: mapCommon.LatLngBounds = {
    northeast: {
      latitude: 40.0,
      longitude: 116.6
    },
    southwest: {
      latitude: 39.8,
      longitude: 116.3
    }
  };
  this.mapController.setLatLngBounds(bounds);
}

// 设置屏幕像素位置为中心点
setPointAsCenter(): void {
  let point: mapCommon.MapPoint = {
    x: 200,
    y: 300
  };
  this.mapController.setPointToCenter(point);
}
```

## 相机位置更新工厂方法示例

```typescript
// 创建新相机位置更新
newCameraPosition(): void {
  let cameraPosition: mapCommon.CameraPosition = {
    target: { latitude: 39.9, longitude: 116.4 },
    zoom: 12,
    tilt: 30,
    bearing: 45
  };
  let update = mapCommon.CameraUpdateFactory.newCameraPosition(cameraPosition);
  this.mapController.animateCamera(update);
}

// 创建移动到指定经纬度
newLatLng(): void {
  let latLng: mapCommon.LatLng = { latitude: 39.9, longitude: 116.4 };
  let update = mapCommon.CameraUpdateFactory.newLatLng(latLng);
  this.mapController.animateCamera(update);
}

// 创建移动到指定经纬度并设置缩放级别
newLatLngZoom(): void {
  let latLng: mapCommon.LatLng = { latitude: 39.9, longitude: 116.4 };
  let update = mapCommon.CameraUpdateFactory.newLatLngZoom(latLng, 15);
  this.mapController.animateCamera(update);
}

// 创建包含指定区域的新视角
newLatLngBounds(): void {
  let bounds: mapCommon.LatLngBounds = {
    northeast: { latitude: 40.0, longitude: 116.6 },
    southwest: { latitude: 39.8, longitude: 116.3 }
  };
  let update = mapCommon.CameraUpdateFactory.newLatLngBounds(bounds, 50);
  this.mapController.animateCamera(update);
}

// 按像素滚动地图
scrollMap(): void {
  let update = mapCommon.CameraUpdateFactory.scrollBy(100, 50);
  this.mapController.animateCamera(update);
}
```
