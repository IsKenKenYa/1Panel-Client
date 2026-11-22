# UI控件控制（UI Control）示例

```typescript
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct UIControlDemo {
  private TAG = "UIControlDemo";
  private mapController?: map.MapComponentController;

  // 缩放控制器
  setZoomControls(enabled: boolean): void {
    this.mapController.setZoomControlsEnabled(enabled);
  }

  isZoomControlsEnabled(): boolean {
    return this.mapController.isZoomControlsEnabled();
  }

  // 位置控制器
  setMyLocationControls(enabled: boolean): void {
    this.mapController.setMyLocationControlsEnabled(enabled);
  }

  isMyLocationControlsEnabled(): boolean {
    return this.mapController.isMyLocationControlsEnabled();
  }

  // 比例尺控制器
  setScaleControls(enabled: boolean): void {
    this.mapController.setScaleControlsEnabled(enabled);
  }

  isScaleControlsEnabled(): boolean {
    return this.mapController.isScaleControlsEnabled();
  }

  setScalePosition(): void {
    let point: mapCommon.MapPoint = { x: 50, y: 200 };
    this.mapController.setScalePosition(point);
  }

  setAlwaysShowScale(enabled: boolean): void {
    this.mapController.setAlwaysShowScaleEnabled(enabled);
  }

  isAlwaysShowScaleEnabled(): boolean {
    return this.mapController.isAlwaysShowScaleEnabled();
  }

  getScaleSize(): void {
    let height = this.mapController.getScaleControlsHeight();
    let width = this.mapController.getScaleControlsWidth();
    console.info(this.TAG, `Scale controls size: ${width}x${height}`);
  }

  getScaleLevelInfo(): void {
    let level = this.mapController.getScaleLevel();
    console.info(this.TAG, `Scale level: ${level}`);
  }

  // 指南针控制器
  setCompassControls(enabled: boolean): void {
    this.mapController.setCompassControlsEnabled(enabled);
  }

  isCompassControlsEnabled(): boolean {
    return this.mapController.isCompassControlsEnabled();
  }

  setCompassPosition(): void {
    let point: mapCommon.MapPoint = { x: 300, y: 100 };
    this.mapController.setCompassPosition(point);
  }

  // Logo控制
  setLogoAlign(): void {
    this.mapController.setLogoAlignment(mapCommon.LogoAlignment.BOTTOM_LEFT);
  }

  setLogoPadding(): void {
    let padding: mapCommon.Padding = { left: 10, top: 10, right: 10, bottom: 10 };
    this.mapController.setLogoPadding(padding);
  }

  setLogoScaleValue(scale: number): void {
    this.mapController.setLogoScale(scale);
  }

  getLogoScaleValue(): number {
    return this.mapController.getLogoScale();
  }

  // 审图号
  setApproveNumber(enabled: boolean): void {
    this.mapController.setApproveNumberEnabled(enabled);
  }

  isApproveNumberEnabled(): boolean {
    return this.mapController.isApproveNumberEnabled();
  }
}
```
