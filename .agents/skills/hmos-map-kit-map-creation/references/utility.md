# 工具方法（Utility）

## 概述

工具方法提供了一些实用的辅助功能，包括屏幕坐标与地理坐标的转换、地图快照等。

## 接口说明

### 投影与坐标转换

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| getProjection() | 无 | Projection | 获取投影对象，用于屏幕坐标与经纬度坐标转换 |

### 快照

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| snapshot() | 无 | Promise\<image.PixelMap\> | 生成地图快照（5.0.0+） |

### 比例尺

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| getScalePerPixel() | 无 | number | 获取当前缩放级别下1像素的长度（米） |

### 坐标计算与转换

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| calculateDistance(from: mapCommon.LatLng, to: mapCommon.LatLng) | from: 起点坐标<br>to: 终点坐标 | number | 计算两点间距离（米），异常时返回0（4.1.0+） |
| convertCoordinate(fromType: mapCommon.CoordinateType, toType: mapCommon.CoordinateType, location: mapCommon.LatLng) | fromType: 源坐标类型<br>toType: 目标坐标类型<br>location: 源坐标 | Promise\<mapCommon.LatLng> | 坐标转换，仅支持WGS84到GCJ02（4.1.0+） |
| convertCoordinateSync(fromType: mapCommon.CoordinateType, toType: mapCommon.CoordinateType, location: mapCommon.LatLng) | fromType: 源坐标类型<br>toType: 目标坐标类型<br>location: 源坐标 | mapCommon.LatLng | 同步坐标转换，仅支持WGS84到GCJ02（5.0.0+） |
| rectifyCoordinate(context: common.Context, locations: Array\<mapCommon.CoordinateLatLng>) | context: Ability上下文<br>locations: 输入坐标数组 | Promise\<Array\<mapCommon.CoordinateLatLng>> | 根据坐标系统和数据坐标系校正坐标（5.0.0+） |

## Projection（投影对象）

Projection用于屏幕像素坐标与地理经纬度坐标之间的转换。

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| fromScreenLocation(point: mapCommon.MapPoint) | point: 屏幕像素坐标 | [LatLng](common.md#latlng坐标对象) | 将屏幕坐标转换为经纬度坐标 |
| toScreenLocation(latLng: mapCommon.LatLng) | latLng: 经纬度坐标 | [MapPoint](common.md#mappoint像素点) | 将经纬度坐标转换为屏幕坐标 |
| getVisibleRegion() | 无 | [VisibleRegion](common.md#visibleregion可视区域) | 获取当前可见区域 |

## 使用场景

### 坐标转换

通过Projection可以将屏幕上的点击位置转换为对应的地理坐标，也可以将地理坐标转换为屏幕上的像素位置。

### 获取可见区域

通过Projection可以获取当前地图可见区域的经纬度范围，用于判断某个位置是否在可见范围内。

### 地图快照

snapshot方法可以生成当前地图区域的静态图片，常用于分享或保存地图视图。
