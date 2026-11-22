# 相机控制（Camera Control）

## 概述

相机控制接口用于管理地图的视角、缩放级别、倾斜角度和旋转方向等。通过CameraUpdate对象可以动态调整地图显示区域。

## CameraUpdate

CameraUpdate是相机更新的配置对象，用于指定相机移动的目标位置和方式。

| 属性名 | 类型 | 是否可选 | 说明 |
|--------|------|----------|------|
| target | [LatLng](common.md#latlng坐标对象) | 是 | 相机目标位置经纬度 |
| zoom | number | 是 | 缩放级别（2-20） |
| tilt | number | 是 | 倾斜角度（0-75） |
| bearing | number | 是 | 旋转角度（0-360） |
| duration | number | 是 | 动画持续时间（毫秒） |

## CameraPosition

CameraPosition表示当前相机状态。

| 属性名 | 类型 | 是否可选 | 说明 |
|--------|------|----------|------|
| target | [LatLng](common.md#latlng坐标对象) | 否 | 相机目标位置经纬度 |
| zoom | number | 是 | 当前缩放级别 |
| tilt | number | 是 | 当前倾斜角度 |
| bearing | number | 是 | 当前旋转角度 |

## 接口说明

### 相机动画

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| animateCamera(update: CameraUpdate, duration?: number) | update: 相机更新配置<br>duration: 动画时长（毫秒） | void | 动画更新相机状态 |
| animateCameraStatus(update: CameraUpdate, duration?: number) | update: 相机更新配置<br>duration: 动画时长（毫秒） | Promise\<AnimateResult\> | 动画更新相机状态并返回执行结果（4.1.0+） |
| animateCameraWithMarker(update: CameraUpdate, marker: Marker, duration: number) | update: 相机更新配置<br>marker: 关联的标记<br>duration: 动画时长（毫秒） | Promise\<AnimateResult\> | 动画更新地图状态并关联单个标记（5.0.0+） |
| animateCameraWithMarkers(update: CameraUpdate, markers: Array\<Marker\>, duration: number) | update: 相机更新配置<br>markers: 关联的标记数组<br>duration: 动画时长（毫秒） | Promise\<AnimateResult\> | 动画更新地图状态并关联多个标记（5.0.0+） |
| stopAnimation() | 无 | void | 停止当前地图动画 |

### 相机移动

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| moveCamera(update: CameraUpdate) | update: 相机更新配置 | void | 无动画更新相机状态 |
| getCameraPosition() | 无 | mapCommon.CameraPosition | 获取当前相机状态 |

### 相机范围

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| setLatLngBounds(bounds: mapCommon.LatLngBounds) | bounds: 相机移动范围边界 | void | 设置相机移动范围边界 |
| setPointToCenter(point: mapCommon.MapPoint) | point: 屏幕像素位置 | void | 设置屏幕像素位置为中心点（4.1.0+） |

### 缩放级别

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| setMaxZoom(maxZoom: number) | maxZoom: 最大缩放级别（范围2-20） | void | 设置最大缩放级别 |
| getMaxZoom() | 无 | number | 获取最大缩放级别 |
| setMinZoom(minZoom: number) | minZoom: 最小缩放级别（范围2-20） | void | 设置最小缩放级别 |
| getMinZoom() | 无 | number | 获取最小缩放级别 |

## CameraUpdate静态方法

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| CameraUpdateFactory.newCameraPosition(cameraPosition) | cameraPosition: 相机位置对象 | CameraUpdate | 创建新相机位置更新 |
| CameraUpdateFactory.newLatLng(latLng) | latLng: 经纬度坐标 | CameraUpdate | 创建移动到指定经纬度 |
| CameraUpdateFactory.newLatLngZoom(latLng, zoom) | latLng: 经纬度坐标<br>zoom: 缩放级别 | CameraUpdate | 创建移动到指定经纬度并设置缩放级别 |
| CameraUpdateFactory.newLatLngBounds(bounds, padding) | bounds: 矩形区域<br>padding: 内边距 | CameraUpdate | 创建包含指定区域的新视角 |
| CameraUpdateFactory.newLatLngBounds(bounds, width, height, padding) | bounds: 矩形区域<br>width: 屏幕宽度<br>height: 屏幕高度<br>padding: 内边距 | CameraUpdate | 创建指定屏幕宽高的区域视角（5.0.0+） |
| CameraUpdateFactory.newLatLngBounds(bounds, padding) | bounds: 矩形区域<br>padding: 四向内边距对象 | CameraUpdate | 创建支持四向内边距的区域视角（5.1.1+） |
| CameraUpdateFactory.zoomIn() | 无 | CameraUpdate | 放大一级缩放 |
| CameraUpdateFactory.zoomOut() | 无 | CameraUpdate | 缩小一级缩放 |
| CameraUpdateFactory.zoomTo(zoom) | zoom: 目标缩放级别 | CameraUpdate | 缩放到指定级别 |
| CameraUpdateFactory.zoomBy(delta, focus) | delta: 缩放增量<br>focus: 缩放焦点 | CameraUpdate | 按增量缩放 |
| CameraUpdateFactory.scrollBy(x, y) | x: 水平滚动像素<br>y: 垂直滚动像素 | CameraUpdate | 按像素滚动地图 |
