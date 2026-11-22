# 图层控制（Layer Control）示例

## 交通与建筑图层示例

```typescript
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct LayerControlDemo {
  private TAG = "LayerControlDemo";
  private mapController?: map.MapComponentController;

  // 设置是否启用交通图层
  setTrafficLayer(enabled: boolean): void {
    this.mapController.setTrafficEnabled(enabled);
  }

  // 获取交通图层启用状态
  isTrafficLayerEnabled(): boolean {
    return this.mapController.isTrafficEnabled();
  }

  // 设置是否启用3D建筑图层
  set3DBuildings(enabled: boolean): void {
    this.mapController.setBuildingEnabled(enabled);
  }

  // 获取3D建筑图层启用状态
  is3DBuildingsEnabled(): boolean {
    return this.mapController.isBuildingEnabled();
  }

  // 设置是否启用等高线图层
  setContourLayer(enabled: boolean): void {
    this.mapController.setContourEnabled(enabled);
  }
}
```

## 位置图层示例

```typescript
import { geoLocationManager } from '@kit.LocationKit';
import { map, mapCommon } from '@kit.MapKit';

// 设置我的位置图层
setMyLocationLayer(enabled: boolean): void {
  this.mapController.setMyLocationEnabled(enabled);
}

// 获取我的位置图层启用状态
isMyLocationLayerEnabled(): boolean {
  return this.mapController.isMyLocationEnabled();
}

// 设置用户位置
setUserLocation(location: geoLocationManager.Location): void {
  this.mapController.setMyLocation(location);
}

// 设置我的位置样式
async setMyLocationStyleConfig(): Promise<void> {
  let style: mapCommon.MyLocationStyle = {
    iconColor: 0x0000FF,
    accuracyFillColor: 0x448888FF,
    accuracyStrokeColor: 0xFF0000FF,
    accuracyFillAlpha: 0.3,
    accuracyStrokeWidth: 2,
    boundsType: mapCommon.MyLocationBoundsType.CIRCLE
  };
  await this.mapController.setMyLocationStyle(style);
}

// 调整位置图层顺序
changeLocationLayerOrder(): void {
  // true: 位置图标在其他覆盖物下方
  // false: 位置图标在其他覆盖物上方
  this.mapController.changeMyLocationLayerOrder(true);
}
```

## 室内地图示例

```typescript
// 设置是否启用室内地图
setIndoorMap(enabled: boolean): void {
  this.mapController.setIndoorMapEnabled(enabled);
}

// 获取室内地图启用状态
isIndoorMapEnabled(): boolean {
  return this.mapController.isIndoorMapEnabled();
}

// 切换室内地图楼层
switchFloor(buildingId: string, floorName: string): void {
  this.mapController.switchIndoorMapFloor(buildingId, floorName);
}

// 设置楼层切换控件位置
setFloorControlPosition(): void {
  let point: mapCommon.MapPoint = {
    x: 100,
    y: 300
  };
  this.mapController.setFloorControlsPosition(point);
}

// 设置是否显示定位楼层信息
setLocationFloor(enabled: boolean): void {
  this.mapController.setLocationFloorEnabled(enabled);
}

// 获取定位楼层信息显示状态
isLocationFloorEnabled(): boolean {
  return this.mapController.isLocationFloorEnabled();
}

// 设置室内停车地图
setIndoorParkingMap(enabled: boolean): void {
  this.mapController.setIndoorParkingMapEnabled(enabled);
}

// 根据停车ID查询建筑ID
async getBuildingIdByParking(parkingId: string): Promise<string> {
  return await this.mapController.queryBuildingIdForParking(parkingId);
}
```
