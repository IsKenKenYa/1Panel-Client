# 手势控制（Gesture Control）示例

```typescript
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct GestureControlDemo {
  private TAG = "GestureControlDemo";
  private mapController?: map.MapComponentController;

  // 启用/禁用缩放手势
  setZoomGesture(enabled: boolean): void {
    this.mapController.setZoomGesturesEnabled(enabled);
  }

  // 获取缩放手势启用状态
  isZoomGestureEnabled(): boolean {
    return this.mapController.isZoomGesturesEnabled();
  }

  // 启用/禁用滑动手势
  setScrollGesture(enabled: boolean): void {
    this.mapController.setScrollGesturesEnabled(enabled);
  }

  // 获取滑动手势启用状态
  isScrollGestureEnabled(): boolean {
    return this.mapController.isScrollGesturesEnabled();
  }

  // 启用/禁用旋转手势
  setRotateGesture(enabled: boolean): void {
    this.mapController.setRotateGesturesEnabled(enabled);
  }

  // 获取旋转手势启用状态
  isRotateGestureEnabled(): boolean {
    return this.mapController.isRotateGesturesEnabled();
  }

  // 启用/禁用倾斜手势
  setTiltGesture(enabled: boolean): void {
    this.mapController.setTiltGesturesEnabled(enabled);
  }

  // 获取倾斜手势启用状态
  isTiltGestureEnabled(): boolean {
    return this.mapController.isTiltGesturesEnabled();
  }

  // 启用/禁用所有手势
  setAllGestures(enabled: boolean): void {
    this.mapController.setAllGesturesEnabled(enabled);
  }

  // 设置是否以地图中心点缩放
  setScaleByMapCenter(enabled: boolean): void {
    this.mapController.setGestureScaleByMapCenter(enabled);
  }

  // 获取是否以地图中心点缩放
  isScaleByMapCenter(): boolean {
    return this.mapController.isGestureScaleByMapCenter();
  }
}
```
