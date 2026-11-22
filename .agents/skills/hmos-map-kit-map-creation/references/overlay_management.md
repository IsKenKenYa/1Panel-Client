# 覆盖物管理（Overlay Management）

## 概述

覆盖物管理接口用于在地图上添加和管理各种图形元素和标记，包括标记、圆形、折线、多边形、弧线、热力图等。

## 接口说明

### 基础覆盖物

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| addMarker(options: mapCommon.MarkerOptions) | options: 标记配置 | Promise\<Marker\> | 添加标记 |
| addCircle(options: mapCommon.MapCircleOptions) | options: 圆形配置 | Promise\<MapCircle\> | 添加圆形 |
| addPolyline(options: mapCommon.MapPolylineOptions) | options: 折线配置 | Promise\<MapPolyline\> | 添加折线 |
| addPolygon(options: mapCommon.MapPolygonOptions) | options: 多边形配置 | Promise\<MapPolygon\> | 添加多边形 |
| addArc(params: mapCommon.MapArcParams) | params: 弧线配置 | MapArc | 添加弧线（5.0.0+） |
| clear() | 无 | void | 清空所有覆盖物 |

### 点标注与气泡

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| addPointAnnotation(params: mapCommon.PointAnnotationParams) | params: 点标注配置 | Promise\<PointAnnotation\> | 添加点标注（4.1.0+） |
| addBubble(params: mapCommon.BubbleParams) | params: 气泡配置 | Promise\<Bubble\> | 添加气泡（4.1.0+） |

### 聚合与特殊覆盖物

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| addClusterOverlay(params: mapCommon.ClusterOverlayParams) | params: 聚合标记配置 | Promise\<ClusterOverlay\> | 添加聚合标记（5.0.0+） |
| addImageOverlay(params: mapCommon.ImageOverlayParams) | params: 图片覆盖物配置 | Promise\<ImageOverlay\> | 添加图片覆盖物（5.0.0+） |
| addTileOverlay(params: mapCommon.TileOverlayParams \| mapCommon.TileOverlayOptions) | params: 瓦片覆盖物配置 | TileOverlay | 添加瓦片覆盖物 |
| addBuildingOverlay(params: mapCommon.BuildingOverlayParams) | params: 建筑覆盖物配置 | Promise\<BuildingOverlay\> | 添加建筑覆盖物（5.0.0+） |
| addTraceOverlay(params: mapCommon.TraceOverlayParams, markers?: Array\<Marker\>) | params: 轨迹覆盖物配置<br>markers: 轨迹标记数组 | Promise\<TraceOverlay\> | 添加轨迹覆盖物（5.0.0+） |

### 海量数据覆盖物

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| addHeatmap(params: mapCommon.HeatmapParams) | params: 热力图配置 | Promise\<Heatmap\> | 添加热力图（6.0.0+） |
| addMvtOverlay(params: mapCommon.MvtOverlayParams) | params: Mvt覆盖物配置 | MvtOverlay | 添加Mvt覆盖物（6.0.0+） |
| addFlowFieldOverlay(params: mapCommon.FlowFieldOverlayParams) | params: 热力图（实时）配置 | Promise\<FlowFieldOverlay\> | 添加热力图（实时）（6.0.0+） |
| addMassPointOverlay(params: mapCommon.MassPointOverlayParams) | params: 海量点覆盖物配置 | Promise\<MassPointOverlay\> | 添加海量点覆盖物（6.0.0+） |
| addMassPolygonOverlay(params: mapCommon.MassPolygonOverlayParams) | params: 海量多边形覆盖物配置 | Promise\<MassPolygonOverlay\> | 添加海量多边形覆盖物（6.0.2+） |

## MarkerOptions（标记配置）

> **提示**：如果用户只提供地点名称而未提供经纬度，请先调用 `hmos-map-kit-poi-search` skill 获取该地点的真实经纬度，再进行后续操作。

| 属性名 | 类型 | 是否可选 | 说明 |
|--------|------|----------|------|
| position | [LatLng](common.md#latlng坐标对象) | 否 | 标记位置经纬度 |
| title | string | 是 | 信息窗口标题 |
| snippet | string | 是 | 信息窗口副标题 |
| icon | string\|image.PixelMap\|Resource | 是 | 自定义图标 |
| alpha | number | 是 | 图标透明度（0-1），默认1 |
| anchorU | number | 是 | 图标水平锚点（0-1），默认0.5 |
| anchorV | number | 是 | 图标垂直锚点（0-1），默认1 |
| clickable | boolean | 是 | 是否可点击，默认false |
| draggable | boolean | 是 | 是否可拖拽，默认false |
| flat | boolean | 是 | 图标是否显示在地面上，默认false |
| rotation | number | 是 | 图标旋转角度，默认0 |
| infoWindowAnchorU | number | 是 | 信息窗口水平锚点（0-1），默认0.5 |
| infoWindowAnchorV | number | 是 | 信息窗口垂直锚点（0-1），默认0 |
| altitude | number | 是 | 海拔高度（米），默认0 |
| visible | boolean | 是 | 是否可见，默认true |
| zIndex | number | 是 | 覆盖物层级，默认0 |

### Marker对象方法

添加成功后返回Marker对象，包含以下方法：

```typescript
let id = marker.getId();
let visible = marker.isVisible();
let tag = marker.getTag();
let position = marker.getPosition();

marker.setVisible(true);
marker.setZIndex(10);
marker.setTag({ key: 'customData' });
marker.remove();
```

## MapCircleOptions（圆形配置）

| 属性名 | 类型 | 是否可选 | 说明 |
|--------|------|----------|------|
| center | [LatLng](common.md#latlng坐标对象) | 否 | 圆心 |
| radius | number | 否 | 半径（米） |
| strokeWidth | number | 是 | 描边宽度 |
| strokeColor | number | 是 | 描边颜色（ARGB格式），默认0xff000000 |
| fillColor | number | 是 | 填充颜色（ARGB格式），默认0x00000000（透明） |
| clickable | boolean | 是 | 是否可点击，默认false |
| visible | boolean | 是 | 是否可见，默认true |
| zIndex | number | 是 | 覆盖物层级，默认0 |

### MapCircle对象方法

```typescript
let id = mapCircle.getId();
let visible = mapCircle.isVisible();

mapCircle.setRadius(2000);
mapCircle.setStrokeColor(0xFF00FF00);
mapCircle.setFillColor(0x5500FF00);
mapCircle.setVisible(true);
mapCircle.setZIndex(10);
mapCircle.remove();
```

## MapPolylineOptions（折线配置）

| 属性名 | 类型 | 是否可选 | 说明 |
|--------|------|----------|------|
| points | Array\<[LatLng](common.md#latlng坐标对象)\> | 否 | 折线顶点数组（至少2个点） |
| clickable | boolean | 是 | 是否可点击，默认false |
| color | number | 是 | 线条颜色（ARGB格式），默认0xff000000 |
| colors | number[] | 是 | 多段折线颜色数组 |
| width | number | 是 | 线条宽度，单位像素，默认4 |
| startCap | [CapStyle](common.md#capstyle线帽样式) | 是 | 起点线帽样式，默认BUTT |
| endCap | [CapStyle](common.md#capstyle线帽样式) | 是 | 终点线帽样式，默认BUTT |
| geodesic | boolean | 是 | 是否绘制大地测量线，默认false |
| jointType | [JointType](#jointtype线条拐点类型) | 是 | 拐点类型，默认DEFAULT |
| patterns | [PatternItem](common.md#patternitem虚线样式)[] | 是 | 虚线样式 |
| visible | boolean | 是 | 是否可见，默认true |
| zIndex | number | 是 | 覆盖物层级，默认0 |

### MapPolyline对象方法

```typescript
let id = mapPolyline.getId();
let points = mapPolyline.getPoints();
let visible = mapPolyline.isVisible();

mapPolyline.setPoints([
  { latitude: 39.9, longitude: 116.4 },
  { latitude: 39.95, longitude: 116.45 }
]);
mapPolyline.setColor(0xFF00FF00);
mapPolyline.setWidth(10);
mapPolyline.setVisible(true);
mapPolyline.setZIndex(10);
mapPolyline.remove();
```

## MapPolygonOptions（多边形配置）

| 属性名 | 类型 | 是否可选 | 说明 |
|--------|------|----------|------|
| points | Array\<[LatLng](common.md#latlng坐标对象)\> | 否 | 多边形顶点数组（至少3个点） |
| holes | Array\<Array\<[LatLng](common.md#latlng坐标对象)\>\> | 是 | 多边形内部空洞数组 |
| clickable | boolean | 是 | 是否可点击，默认false |
| fillColor | number | 是 | 填充颜色（ARGB格式），默认0x00000000（透明） |
| geodesic | boolean | 是 | 是否绘制大地测量线，默认false |
| strokeColor | number | 是 | 边框颜色（ARGB格式），默认0xff000000 |
| strokeWidth | number | 是 | 边框宽度，单位像素，默认10 |
| jointType | [JointType](#jointtype线条拐点类型) | 是 | 拐点类型，默认DEFAULT |
| patterns | [PatternItem](common.md#patternitem虚线样式)[] | 是 | 虚线样式 |
| visible | boolean | 是 | 是否可见，默认true |
| zIndex | number | 是 | 覆盖物层级，默认0 |

### MapPolygon对象方法

```typescript
let id = mapPolygon.getId();
let points = mapPolygon.getPoints();
let visible = mapPolygon.isVisible();

mapPolygon.setPoints([
  { latitude: 39.9, longitude: 116.4 },
  { latitude: 39.95, longitude: 116.4 },
  { latitude: 39.95, longitude: 116.45 }
]);
mapPolygon.setStrokeColor(0xFFFF0000);
mapPolygon.setFillColor(0x550000FF);
mapPolygon.setVisible(true);
mapPolygon.setZIndex(10);
mapPolygon.remove();
```

## ImageOverlayParams（图片覆盖物配置）

| 属性名 | 类型 | 是否可选 | 说明 |
|--------|------|----------|------|
| bounds | [LatLngBounds](common.md#latlngbounds矩形区域) | 是 | 图片覆盖的地理范围 |
| position | [LatLng](common.md#latlng坐标对象) | 是 | 图片中心位置 |
| width | number | 是 | 图标宽度（米），仅当position设置时有效 |
| height | number | 是 | 图标高度（米），仅当position和width设置时有效 |
| anchorU | number | 是 | 图标水平锚点（0-1），默认0.5 |
| anchorV | number | 是 | 图标垂直锚点（0-1），默认0.5 |
| bearing | number | 是 | 旋转角度（度），默认0 |
| clickable | boolean | 是 | 是否可点击，默认false |
| image | ResourceStr\|image.PixelMap | 否 | 图片资源 |
| transparency | number | 是 | 透明度（0-1），默认0 |
| visible | boolean | 是 | 是否可见，默认true |
| zIndex | number | 是 | 覆盖物层级，默认0 |

### ImageOverlay对象方法

```typescript
let id = imageOverlay.getId();
let bounds = imageOverlay.getBounds();
let visible = imageOverlay.isVisible();

imageOverlay.setImage($r('app.media.ic_new_overlay'));
imageOverlay.setBounds({
  northeast: { latitude: 39.92, longitude: 116.42 },
  southwest: { latitude: 39.9, longitude: 116.4 }
});
imageOverlay.setVisible(true);
imageOverlay.setZIndex(10);
imageOverlay.remove();
```

## TileOverlayOptions（瓦片覆盖物配置）

| 属性名 | 类型 | 是否可选 | 说明 |
|--------|------|----------|------|
| tileUrl | string | 是 | 瓦片URL模板，支持{z}、{x}、{y}占位符 |
| tileProvider | TileProvider | 是 | 自定义瓦片提供者 |
| transparency | number | 是 | 透明度（0-1），默认0 |
| fadeIn | boolean | 是 | 是否渐显，默认true |
| diskCacheEnabled | boolean | 是 | 是否启用磁盘缓存，默认false |
| diskCacheSize | number | 是 | 磁盘缓存大小（KB），默认20480 |
| diskCachePath | string | 是 | 磁盘缓存路径，启用磁盘缓存时必填 |
| tileDataReuse | boolean | 是 | 是否启用瓦片数据重用，默认false |
| visible | boolean | 是 | 是否可见，默认true |
| zIndex | number | 是 | 覆盖物层级，默认0 |

### TileOverlay对象方法

```typescript
tileOverlay.clearCache();
tileOverlay.remove();
```

## TraceOverlayParams（轨迹覆盖物配置）

| 属性名 | 类型 | 是否可选 | 说明 |
|--------|------|----------|------|
| points | Array\<[LatLng](common.md#latlng坐标对象)\> | 否 | 轨迹点数组 |
| width | number | 是 | 轨迹线条宽度，单位像素，默认10 |
| color | number | 是 | 轨迹线条颜色（ARGB格式），默认0xaaff0000 |
| isMapMoving | boolean | 是 | 轨迹动画时地图是否跟随移动，默认false |
| animationDuration | number | 是 | 轨迹动画时长（毫秒），最小值100，默认5000 |
| animationCallback | Callback\<number> | 是 | 轨迹动画进度回调，返回当前轨迹点索引 |

### TraceOverlay对象方法

```typescript
let id = traceOverlay.getId();
let visible = traceOverlay.isVisible();

traceOverlay.setVisible(true);
traceOverlay.remove();
```

## ClusterOverlayParams（聚合标记配置）

| 属性名 | 类型 | 是否可选 | 说明 |
|--------|------|----------|------|
| clusterItems | Array\<ClusterItem\> | 否 | 聚合项数组 |
| distance | number | 否 | 聚合距离（像素），默认100 |

### ClusterOverlay对象方法

```typescript
clusterOverlay.remove();
```

## 枚举类型

### JointType（线条拐点类型）

| 枚举值 | 说明 |
|--------|------|
| JointType.DEFAULT | 默认类型 |
| JointType.BEVEL | 斜面类型 |
| JointType.ROUND | 圆角类型 |

### LineCapType（线帽类型）

| 枚举值 | 说明 |
|--------|------|
| LineCapType.BUTT | 平头 |
| LineCapType.ROUND | 圆头 |
| LineCapType.SQUARE | 方头 |

## 事件监听

### 支持的事件类型

| 事件名称 | 参数类型 | 说明 |
|----------|----------|------|
| markerClick | Marker | 标记点击事件 |
| markerDragStart | Marker | 标记开始拖拽事件 |
| markerDrag | Marker | 标记拖拽中事件 |
| markerDragEnd | Marker | 标记拖拽结束事件 |
| infoWindowClick | Marker | 信息窗口点击事件 |
| infoWindowClose | Marker | 信息窗口关闭事件 |
| circleClick | MapCircle | 圆形点击事件 |
| polygonClick | MapPolygon | 多边形点击事件 |
| polylineClick | MapPolyline | 折线点击事件 |
| imageOverlayClick | ImageOverlay | 图片覆盖物点击事件 |

### 事件监听方法

```typescript
// 添加事件监听
mapController.on('markerClick', (marker: map.Marker) => {
  console.info('Marker clicked: ' + marker.getId());
});

// 移除事件监听
let callback = (marker: map.Marker) => {
  console.info('Marker clicked');
};
mapController.on('markerClick', callback);
mapController.off('markerClick', callback);

// 移除所有事件监听
mapController.off('markerClick');
```

## 示例代码

详情见 ../assets/overlayManagementDemo.md
