# 图层控制（Layer Control）

## 概述

图层控制接口用于管理地图上各种图层的显示与隐藏，包括交通图层、建筑图层、位置图层、室内地图等。

## 接口说明

### 交通与建筑图层

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| setTrafficEnabled(enabled: boolean) | enabled: 是否启用交通图层 | void | 设置是否启用交通图层 |
| isTrafficEnabled() | 无 | boolean | 获取交通图层启用状态 |
| setBuildingEnabled(enabled: boolean) | enabled: 是否启用3D建筑图层 | void | 设置是否启用3D建筑图层 |
| isBuildingEnabled() | 无 | boolean | 获取3D建筑图层启用状态 |
| setContourEnabled(enabled: boolean) | enabled: 是否启用等高线图层 | void | 设置是否启用等高线图层（systemapi, 5.1.0+） |

### 位置图层

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| setMyLocationEnabled(myLocationEnabled: boolean) | myLocationEnabled: 是否启用我的位置图层 | void | 设置是否启用我的位置图层 |
| isMyLocationEnabled() | 无 | boolean | 获取我的位置图层启用状态 |
| setMyLocation(location: geoLocationManager.Location) | location: 用户位置信息 | void | 设置用户位置 |
| setMyLocationStyle(style: mapCommon.MyLocationStyle) | style: 我的位置样式配置 | Promise\<void\> | 设置我的位置样式 |
| changeMyLocationLayerOrder(isBelow: boolean) | isBelow: 是否在其他覆盖物下方 | void | 调整我的位置图层与其他覆盖物的层叠顺序（6.0.1+） |

### 室内地图

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| setIndoorMapEnabled(enabled: boolean) | enabled: 是否启用室内地图 | void | 设置是否启用室内地图（5.1.1+） |
| isIndoorMapEnabled() | 无 | boolean | 获取室内地图启用状态（5.1.1+） |
| setIndoorParkingMapEnabled(enabled: boolean) | enabled: 是否启用室内停车地图 | void | 设置是否启用室内停车地图（systemapi, 6.1.1+） |
| switchIndoorMapFloor(buildingId: string, floorName: string) | buildingId: 建筑ID<br>floorName: 楼层名称 | void | 切换室内地图楼层（5.1.1+） |
| setFloorControlsPosition(point: mapCommon.MapPoint) | point: 楼层切换控件位置 | void | 设置楼层切换控件位置（6.0.0+） |
| setLocationFloorEnabled(enabled: boolean) | enabled: 是否显示定位楼层信息 | void | 设置是否显示定位楼层信息（6.0.2+） |
| isLocationFloorEnabled() | 无 | boolean | 获取定位楼层信息显示状态（6.0.2+） |
| queryBuildingIdForParking(parkingId: string) | parkingId: 停车ID | Promise\<string\> | 根据停车ID查询建筑ID（systemapi, 6.1.1+） |

## MyLocationStyle（我的位置样式）

| 属性名 | 类型 | 是否可选 | 说明 |
|--------|------|----------|------|
| icon | PixelMap | 是 | 定位图标 |
| iconColor | number | 是 | 定位图标颜色 |
| accuracyFillColor | number | 是 | 精度圈填充颜色 |
| accuracyStrokeColor | number | 是 | 精度圈边框颜色 |
| accuracyFillAlpha | number | 是 | 精度圈填充透明度 |
| accuracyStrokeWidth | number | 是 | 精度圈边框宽度 |
| boundsType | [MyLocationBoundsType](#mylocationboundstype定位精度圈形状) | 是 | 定位精度圈形状 |
