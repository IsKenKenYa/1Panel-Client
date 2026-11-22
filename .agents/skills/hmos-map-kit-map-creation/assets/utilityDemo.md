# 工具方法（Utility）示例

```typescript
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';

@Entry
@Component
struct UtilityDemo {
  private TAG = "UtilityDemo";
  private mapController?: map.MapComponentController;

  // 获取投影对象
  getProjection(): map.Projection {
    return this.mapController.getProjection();
  }

  // 屏幕坐标转经纬度
  screenToLatLng(): void {
    let projection = this.getProjection();
    let screenPoint: mapCommon.MapPoint = { x: 200, y: 300 };
    let latLng = projection.fromScreenLocation(screenPoint);
    console.info(this.TAG, `Screen (200, 300) -> LatLng: ${JSON.stringify(latLng)}`);
  }

  // 经纬度转屏幕坐标
  latLngToScreen(): void {
    let projection = this.getProjection();
    let latLng: mapCommon.LatLng = { latitude: 39.9, longitude: 116.4 };
    let screenPoint = projection.toScreenLocation(latLng);
    console.info(this.TAG, `LatLng (39.9, 116.4) -> Screen: ${JSON.stringify(screenPoint)}`);
  }

  // 获取可见区域
  getVisibleRegion(): void {
    let projection = this.getProjection();
    let visibleRegion = projection.getVisibleRegion();
    console.info(this.TAG, `Visible region: ${JSON.stringify(visibleRegion)}`);
  }

  // 获取每像素对应长度
  getScalePerPixel(): void {
    let scale = this.mapController.getScalePerPixel();
    console.info(this.TAG, `Scale per pixel: ${scale} meters`);
  }

  // 生成地图快照
  async takeSnapshot(): Promise<image.PixelMap> {
    let pixelMap = await this.mapController.snapshot();
    console.info(this.TAG, `Snapshot taken: ${pixelMap.getWidth()}x${pixelMap.getHeight()}`);
    return pixelMap;
  }

  // 判断坐标是否在可见区域内
  isLocationVisible(latLng: mapCommon.LatLng): boolean {
    let projection = this.getProjection();
    let visibleRegion = projection.getVisibleRegion();
    
    if (visibleRegion.nearLeft && visibleRegion.nearRight && 
        visibleRegion.farLeft && visibleRegion.farRight) {
      // 检查坐标是否在可见矩形范围内
      let minLat = Math.min(
        visibleRegion.nearLeft.latitude, visibleRegion.farLeft.latitude,
        visibleRegion.nearRight.latitude, visibleRegion.farRight.latitude
      );
      let maxLat = Math.max(
        visibleRegion.nearLeft.latitude, visibleRegion.farLeft.latitude,
        visibleRegion.nearRight.latitude, visibleRegion.farRight.latitude
      );
      let minLng = Math.min(
        visibleRegion.nearLeft.longitude, visibleRegion.farLeft.longitude,
        visibleRegion.nearRight.longitude, visibleRegion.farRight.longitude
      );
      let maxLng = Math.max(
        visibleRegion.nearLeft.longitude, visibleRegion.farLeft.longitude,
        visibleRegion.nearRight.longitude, visibleRegion.farRight.longitude
      );
      
      return latLng.latitude >= minLat && latLng.latitude <= maxLat &&
             latLng.longitude >= minLng && latLng.longitude <= maxLng;
    }
    return false;
  }

  // 处理地图点击获取坐标
  handleMapClick(latLng: mapCommon.LatLng): void {
    let projection = this.getProjection();
    let screenPoint = projection.toScreenLocation(latLng);
    console.info(this.TAG, `Clicked at screen: ${screenPoint.x}, ${screenPoint.y}`);
  }
}
```
