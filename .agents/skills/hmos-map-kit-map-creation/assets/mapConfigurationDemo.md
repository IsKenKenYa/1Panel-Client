# 地图配置（Map Configuration）示例

```typescript
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct MapConfigurationDemo {
  private TAG = "MapConfigurationDemo";
  private mapController?: map.MapComponentController;

  // 设置地图内边距
  setMapPadding(): void {
    let padding: mapCommon.Padding = {
      left: 50,
      top: 100,
      right: 50,
      bottom: 100
    };
    this.mapController.setPadding(padding);
  }

  // 设置地图类型
  setMapTypeStandard(): void {
    this.mapController.setMapType(mapCommon.MapType.STANDARD);
  }

  setMapTypeTerrain(): void {
    this.mapController.setMapType(mapCommon.MapType.TERRAIN);
  }

  setMapTypeNone(): void {
    this.mapController.setMapType(mapCommon.MapType.NONE);
  }

  getCurrentMapType(): mapCommon.MapType {
    return this.mapController.getMapType();
  }

  // 昼夜模式
  setDayMode(): void {
    this.mapController.setDayNightMode(mapCommon.DayNightMode.DAY);
  }

  setNightMode(): void {
    this.mapController.setDayNightMode(mapCommon.DayNightMode.NIGHT);
  }

  setAutoMode(): void {
    this.mapController.setDayNightMode(mapCommon.DayNightMode.AUTO);
  }

  getCurrentDayNightMode(): mapCommon.DayNightMode {
    return this.mapController.getDayNightMode();
  }

  // 球形效果
  enableSphere(): void {
    this.mapController.setSphereEnabled(true);
  }

  disableSphere(): void {
    this.mapController.setSphereEnabled(false);
  }

  toggleSphereWithAnimation(): void {
    this.mapController.setSphereEnabled(false, 1000);
  }

  toggleSphereWithAnimationAndCityLight(): void {
    this.mapController.setSphereEnabled(false, 1000, true);
  }

  isSphereEnabled(): boolean {
    return this.mapController.isSphereEnabled();
  }

  // 语言设置
  setChineseLanguage(): void {
    this.mapController.setLanguage("zh");
  }

  setEnglishLanguage(): void {
    this.mapController.setLanguage("en");
  }

  getCurrentLanguage(): string {
    return this.mapController.getLanguage();
  }

  // 显示顺序
  setDisplayOrder(): void {
    let types: mapCommon.MapElementType[] = [
      mapCommon.MapElementType.BUILDING,
      mapCommon.MapElementType.ROAD,
      mapCommon.MapElementType.BUS
    ];
    this.mapController.setDisplayOrder(types);
  }

  // 帧率设置
  setFrameRate(fps: number): void {
    this.mapController.setFramePerSecond(fps);
  }

  // 生命周期
  showMap(): void {
    this.mapController.show();
  }

  hideMap(): void {
    this.mapController.hide();
  }

  // 自定义地图样式
  async setCustomStyle(): Promise<void> {
    let styleOptions: mapCommon.CustomMapStyleOptions = {
      styleId: "your_style_id",
      styleJson: '{"version": 1, "sources": {}, "layers": []}'
    };
    await this.mapController.setCustomMapStyle(styleOptions);
  }

  async setCustomStyleWithData(): Promise<void> {
    let styleData = new Uint8Array([0x7B, 0x22, 0x76, 0x65, 0x72, 0x73, 0x69, 0x6F, 0x6E, 0x22, 0x3A, 0x20, 0x31, 0x7D]);
    let styleOptions: mapCommon.CustomMapStyleOptions = {
      styleData: styleData
    };
    await this.mapController.setCustomMapStyle(styleOptions);
  }
}
```
