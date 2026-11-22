# 覆盖物管理（Overlay Management）示例

## 标记（Marker）示例

### 添加标记

```typescript
import { map, mapCommon } from '@kit.MapKit';

const markerOptions: mapCommon.MarkerOptions = {
  position: { latitude: 39.9042, longitude: 116.4074 },
  title: "天安门广场",
  snippet: "北京市东城区",
  clickable: true,
  draggable: true,
  visible: true,
  zIndex: 1,
  anchorU: 0.5,
  anchorV: 1.0
};

const marker = await this.mapController.addMarker(markerOptions);
```

### 批量添加标记点

```typescript
const locations = [
  { latitude: 39.9042, longitude: 116.4074, title: "天安门" },
  { latitude: 39.9163, longitude: 116.3972, title: "故宫" },
  { latitude: 39.9285, longitude: 116.3974, title: "景山" }
];

for (const loc of locations) {
  const marker = await this.mapController.addMarker({
    position: { latitude: loc.latitude, longitude: loc.longitude
    title: loc.title,
    clickable: true,
    zIndex: 1
  });
}
```

### 标记事件监听

```typescript
this.mapController.on("markerClick", (marker) => {
  console.info('Marker clicked: ' + marker.getId());
});

this.mapController.on("markerDragStart", (marker) => {
  console.info('Marker drag start');
});

this.mapController.on("markerDrag", (marker) => {
  const pos = marker.getPosition();
  console.info('Marker dragging, position: ' + JSON.stringify(pos));
});

this.mapController.on("markerDragEnd", (marker) => {
  const pos = marker.getPosition();
  console.info('Marker drag end, new position: ' + JSON.stringify(pos));
});

this.mapController.on("infoWindowClick", (marker) => {
  console.info('Info window clicked');
});

this.mapController.on("infoWindowClose", (marker) => {
  console.info('Info window closed');
});
```

### 移除标记

```typescript
marker.remove();
```

## 圆形（Circle）示例

### 添加圆形

```typescript
import { map, mapCommon } from '@kit.MapKit';

const circleOptions: mapCommon.MapCircleOptions = {
  center: {
    latitude: 39.9042,
    longitude: 116.4074
  },
  radius: 1000,
  strokeColor: 0xFF0000FF,
  strokeWidth: 3,
  fillColor: 0x550000FF,
  clickable: true,
  visible: true,
  zIndex: 0
};

const mapCircle = await this.mapController.addCircle(circleOptions);
```

### 修改圆形属性

```typescript
mapCircle.setRadius(2000);
mapCircle.setStrokeColor(0xFF00FF00);
mapCircle.setFillColor(0x5500FF00);
```

### 圆形点击事件

```typescript
this.mapController.on("circleClick", (circle) => {
  console.info('Circle clicked');
});
```

### 移除圆形

```typescript
mapCircle.remove();
```

## 多边形（Polygon）示例

### 添加多边形

```typescript
import { map, mapCommon } from '@kit.MapKit';

const polygonOptions: mapCommon.PolygonOptions = {
  points: [
    { latitude: 39.9042, longitude: 116.4074 },
    { latitude: 39.9142, longitude: 116.4074 },
    { latitude: 39.9142, longitude: 116.4174 },
    { latitude: 39.9042, longitude: 116.4174 }
  ],
  strokeColor: 0xFF00FF00,
  strokeWidth: 3,
  fillColor: 0x5500FF00,
  clickable: true,
  visible: true,
  zIndex: 0
};

const mapPolygon = await this.mapController.addPolygon(polygonOptions);
```

### 修改多边形属性

```typescript
mapPolygon.setStrokeColor(0xFFFF0000);
mapPolygon.setFillColor(0x550000FF);
```

### 多边形点击事件

```typescript
this.mapController.on("polygonClick", (polygon) => {
  console.info('Polygon clicked');
});
```

### 移除多边形

```typescript
mapPolygon.remove();
```

## 折线（Polyline）示例

### 添加折线

```typescript
import { map, mapCommon } from '@kit.MapKit';

const MapPolylineOptions: mapCommon.MapPolylineOptions = {
  points: [
    { latitude: 39.9042, longitude: 116.4074 },
    { latitude: 39.9092, longitude: 116.4124 },
    { latitude: 39.9142, longitude: 116.4174 },
    { latitude: 39.9192, longitude: 116.4224 }
  ],
  color: 0xFFFF0000,
  width: 5,
  clickable: true,
  visible: true,
  zIndex: 0
};

const mapPolyline = await this.mapController.addPolyline(MapPolylineOptions);
```

### 添加虚线折线

```typescript
const dashedPolylineOptions: mapCommon.MapPolylineOptions = {
  points: [
    { latitude: 39.9042, longitude: 116.4074 },
    { latitude: 39.9142, longitude: 116.4174 }
  ],
  color: 0xFF0000FF,
  width: 3,
  patterns: [{ type: 0, length: 100 }, { type: 0, length: 100 }],
  clickable: false,
  visible: true,
  zIndex: 0
};

const mapPolyline = await this.mapController.addPolyline(dashedPolylineOptions);
```

### 修改折线属性

```typescript
mapPolyline.setColor(0xFF00FF00);
mapPolyline.setWidth(10);
```

### 折线点击事件

```typescript
this.mapController.on("polylineClick", (polyline) => {
  console.info('Polyline clicked');
});
```

### 移除折线

```typescript
mapPolyline.remove();
```

## 图片覆盖物（ImageOverlay）示例

### 添加图片覆盖物

```typescript
import { map, mapCommon } from '@kit.MapKit';

const imageOverlayParams: mapCommon.ImageOverlayParams = {
  image: $r("app.media.icon_louvre_6000_19531KB"),
  bounds: {
    northeast: { latitude: 39.9142, longitude: 116.4174 },
    southwest: { latitude: 39.9042, longitude: 116.4074 }
  },
  transparency: 0.8,
  zIndex: 0
};

const imageOverlay = await this.mapController.addImageOverlay(imageOverlayParams);
```

### 图片覆盖物点击事件

```typescript
this.mapController.on("imageOverlayClick", (img) => {
  console.info('ImageOverlay clicked');
});
```

### 移除图片覆盖物

```typescript
imageOverlay.remove();
```

## 聚合标记（ClusterOverlay）示例

### 添加聚合标记

```typescript
import { map, mapCommon } from '@kit.MapKit';

const clusterItems: mapCommon.ClusterItem[] = [];
for (let i = 0; i < 100; i++) {
  clusterItems.push({
    position: {
      latitude: 39.9 + Math.random() * 0.05,
      longitude: 116.4 + Math.random() * 0.05
    }
  });
}

const clusterOverlayParams: mapCommon.ClusterOverlayParams = {
  clusterItems: clusterItems,
  distance: 80
};

const clusterOverlay = await this.mapController.addClusterOverlay(clusterOverlayParams);
```

### 移除聚合标记

```typescript
clusterOverlay.remove();
```

## 瓦片覆盖物（TileOverlay）示例

### 添加瓦片覆盖物

```typescript
import { map, mapCommon } from '@kit.MapKit';

const tileOverlayOptions: mapCommon.TileOverlayOptions = {
  tileUrl: "https://a.tile.openstreetmap.org/{z}/{x}/{y}.png",
  transparency: 0.2
};

const tileOverlay = this.mapController.addTileOverlay(tileOverlayOptions);
```

### 清除缓存并移除

```typescript
tileOverlay.clearCache();
tileOverlay.remove();
```

## 轨迹覆盖物（TraceOverlay）示例

### 添加轨迹覆盖物

```typescript
import { map, mapCommon } from '@kit.MapKit';

const traceOverlayParams: mapCommon.TraceOverlayParams = {
  points: [
    { latitude: 39.9042, longitude: 116.4074 },
    { latitude: 39.9092, longitude: 116.4124 },
    { latitude: 39.9142, longitude: 116.4174 }
  ],
  color: 0xFFFF0000,
  width: 10
};

let markers: map.Marker[] = [];
const traceOverlay = await this.mapController.addTraceOverlay(traceOverlayParams, markers);
```

### 移除轨迹覆盖物

```typescript
traceOverlay.remove();
```

## 热力图示例

### 添加热力图

```typescript
import { map, mapCommon } from '@kit.MapKit';

const heatmapParams: mapCommon.HeatmapParams = {
  points: [
    { latitude: 39.9, longitude: 116.4, intensity: 0.8 },
    { latitude: 39.95, longitude: 116.45, intensity: 0.6 },
    { latitude: 39.92, longitude: 116.42, intensity: 0.9 }
  ],
  radius: 50,
  opacity: 0.7
};

const heatmap = await this.mapController.addHeatmap(heatmapParams);
```

### 添加海量点覆盖物

```typescript
const massPointParams: mapCommon.MassPointOverlayParams = {
  points: [
    { latitude: 39.9, longitude: 116.4 },
    { latitude: 39.95, longitude: 116.45 },
    { latitude: 39.92, longitude: 116.42 }
  ],
  fillColor: 0xFF0000FF,
  radius: 10
};

const massPointOverlay = await this.mapController.addMassPointOverlay(massPointParams);
```

## 清空所有覆盖物

```typescript
this.mapController.clear();
```
