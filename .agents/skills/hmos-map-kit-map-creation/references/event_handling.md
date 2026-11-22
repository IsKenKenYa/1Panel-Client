# 事件监听（Event Handling）

## 概述

事件监听接口用于捕获和处理地图上的各种交互事件，包括相机事件、点击事件、覆盖物事件等。

## MapEventManager

获取事件管理器：`mapController.getEventManager()`

## 接口说明

### 相机事件

| 事件类型 | 回调参数 | 说明 |
|----------|----------|------|
| cameraChange | [LatLng](common.md#latlng坐标对象) | 相机变化结束 |
| cameraIdle | void | 相机空闲 |
| cameraMove | void | 相机移动中 |
| cameraMoveStart | number | 相机开始移动 |
| cameraMoveCancel | void | 相机移动取消 |

### 地图事件

| 事件类型 | 回调参数 | 说明 |
|----------|----------|------|
| mapClick | [LatLng](common.md#latlng坐标对象) | 地图点击 |
| mapLongClick | [LatLng](common.md#latlng坐标对象) | 地图长按 |
| mapLoad | void | 地图加载完成 |

### 位置事件

| 事件类型 | 回调参数 | 说明 |
|----------|----------|------|
| myLocationButtonClick | void | 我的位置按钮点击 |
| myLocationClick | [LatLng](common.md#latlng坐标对象) | 我的位置图层点击 |

### POI事件

| 事件类型 | 回调参数 | 说明 |
|----------|----------|------|
| poiClick | [Poi](common.md#poi兴趣点) | POI点击 |

### 覆盖物事件

| 事件类型 | 回调参数 | 说明 |
|----------|----------|------|
| markerClick | [Marker](marker.md#marker标记) | 标记点击 |
| markerDragStart | [Marker](marker.md#marker标记) | 标记开始拖拽 |
| markerDrag | [Marker](marker.md#marker标记) | 标记拖拽中 |
| markerDragEnd | [Marker](marker.md#marker标记) | 标记拖拽结束 |
| circleClick | [MapCircle](overlay_management.md#mapcircleoptions圆形配置) | 圆形点击 |
| polylineClick | [MapPolyline](overlay_management.md#mappolylineoptions折线配置) | 折线点击 |
| polygonClick | [MapPolygon](overlay_management.md#mappolygonoptions多边形配置) | 多边形点击 |
| infoWindowClick | [Marker](marker.md#marker标记) | 信息窗口点击 |
| infoWindowClose | [Marker](marker.md#marker标记) | 信息窗口关闭 |
| pointAnnotationClick | [PointAnnotation](overlay_management.md#点标注与气泡) | 点标注点击 |
| bubbleClick | [Bubble](overlay_management.md#点标注与气泡) | 气泡点击 |
| imageOverlayClick | [ImageOverlay](image_overlay.md#imageoverlay图片覆盖物) | 图片覆盖物点击 |

### 错误事件

| 事件类型 | 回调参数 | 说明 |
|----------|----------|------|
| error | ErrorCallback | 地图错误 |

## 事件监听方法

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| on(eventType: string, callback: Function) | eventType: 事件类型<br>callback: 回调函数 | void | 注册事件监听 |
| off(eventType: string, callback?: Function) | eventType: 事件类型<br>callback: 回调函数（可选） | void | 取消事件监听 |

## Poi（兴趣点）

| 属性名 | 类型 | 是否可选 | 说明 |
|--------|------|----------|------|
| name | string | 是 | POI名称 |
| latLng | [LatLng](common.md#latlng坐标对象) | 是 | POI经纬度 |
| snippet | string | 是 | POI描述 |
| businessName | string | 是 | 商户名称 |
| latitude | number | 是 | 纬度 |
| longitude | number | 是 | 经度 |
| distance | number | 是 | 距离 |
| isCurrentPosition | boolean | 是 | 是否为当前位置 |
