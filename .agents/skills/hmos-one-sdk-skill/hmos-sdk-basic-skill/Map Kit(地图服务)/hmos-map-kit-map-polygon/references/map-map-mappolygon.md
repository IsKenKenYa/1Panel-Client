# MapPolygon
---
# MapPolygon
#### 导入模块
```typescript
import { map, mapCommon } from '@kit.MapKit';
```
#### MapPolygon
多边形，继承 [BaseOverlay](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-baseoverlay.md) 。多边形可以是凸面或凹面，它可以跨越180子午线并且可以具有未填充的孔。在调用map. [MapComponentController](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 类的 [addPolygon](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 方法时会返回该类型的实例。
**模型约束：** 此接口仅可在Stage模型下使用。
**元服务API：** 从版本4.1.0(11)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Map.Core
**起始版本：** 4.1.0(11)
**示例：**
```typescript
let polygonOptions: mapCommon.MapPolygonOptions = {
  points: [
    { latitude: 31.9844102, longitude: 118.7662 },
    { latitude: 31.9844102, longitude: 123.7662 },
    { latitude: 36.9844102, longitude: 123.7662 },
    { latitude: 36.9844102, longitude: 118.7662 }
  ]
};
let mapPolygon = await this.mapController.addPolygon(polygonOptions);
```
#### getFillColor
getFillColor(): number
获取ARGB格式的多边形的填充色值。
**模型约束：** 此接口仅可在Stage模型下使用。
**元服务API：** 从版本4.1.0(11)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Map.Core
**起始版本：** 4.1.0(11)
**返回值：**
| 类型 | 说明 |
| --- | --- |
| number | ARGB格式的颜色值。 |
**示例：**
```typescript
let fillColor: number = mapPolygon.getFillColor();
```
#### getHoles
getHoles(): Array<Array<mapCommon.LatLng>>
获取多边形的空心洞。
**模型约束：** 此接口仅可在Stage模型下使用。
**元服务API：** 从版本4.1.0(11)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Map.Core
**起始版本：** 4.1.0(11)
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Array<Array<[mapCommon.LatLng](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md)>> | 多边形的空心洞数组，其中空心洞是[LatLng](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md)数组。 |
**示例：**
```typescript
let holes: Array<Array<mapCommon.LatLng>> = mapPolygon.getHoles();
```
#### getPoints
getPoints(): Array<mapCommon.LatLng>
获取多边形的顶点坐标。
**模型约束：** 此接口仅可在Stage模型下使用。
**元服务API：** 从版本4.1.0(11)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Map.Core
**起始版本：** 4.1.0(11)
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Array<[mapCommon.LatLng](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md)> | 多边形的顶点坐标。 |
**示例：**
```typescript
let points: Array<mapCommon.LatLng> = mapPolygon.getPoints();
```
#### getStrokeColor
getStrokeColor(): number
获取多边形的边框颜色。
**模型约束：** 此接口仅可在Stage模型下使用。
**元服务API：** 从版本4.1.0(11)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Map.Core
**起始版本：** 4.1.0(11)
**返回值：**
| 类型 | 说明 |
| --- | --- |
| number | ARGB格式颜色值，默认值为黑色（0xff000000）。 |
**示例：**
```typescript
let strokeColor: number = mapPolygon.getStrokeColor();
```
#### getJointType
getJointType(): mapCommon.JointType
获取多边形的顶点样式。
**模型约束：** 此接口仅可在Stage模型下使用。
**元服务API：** 从版本4.1.0(11)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Map.Core
**起始版本：** 4.1.0(11)
**返回值：**
| 类型 | 说明 |
| --- | --- |
| [mapCommon.JointType](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md) | 多边形的顶点样式。 |
**示例：**
```typescript
let jointType: mapCommon.JointType = mapPolygon.getJointType();
```
#### getPatterns
getPatterns(): Array<mapCommon.PatternItem>
获取多边形的边框样式。
**模型约束：** 此接口仅可在Stage模型下使用。
**元服务API：** 从版本4.1.0(11)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Map.Core
**起始版本：** 4.1.0(11)
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Array<[mapCommon.PatternItem](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md)> | 多边形的边框样式。 |
**示例：**
```typescript
let patterns: Array<mapCommon.PatternItem> = mapPolygon.getPatterns();
```
#### getStrokeWidth
getStrokeWidth(): number
获取多边形的边框宽度。
**模型约束：** 此接口仅可在Stage模型下使用。
**元服务API：** 从版本4.1.0(11)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Map.Core
**起始版本：** 4.1.0(11)
**返回值：**
| 类型 | 说明 |
| --- | --- |
| number | 多边形的边框宽度，单位：px。 |
**示例：**
```typescript
let strokeWidth: number = mapPolygon.getStrokeWidth();
```
#### isClickable
isClickable(): boolean
获取多边形的可点击性。
**模型约束：** 此接口仅可在Stage模型下使用。
**元服务API：** 从版本4.1.0(11)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Map.Core
**起始版本：** 4.1.0(11)
**返回值：**
| 类型 | 说明 |
| --- | --- |
| boolean | 多边形的可点击性。true：可点击false：不可点击 |
**示例：**
```typescript
let clickable: boolean = mapPolygon.isClickable();
```
#### isGeodesic
isGeodesic(): boolean
获取多边形的每个线段是否为大地线。
**模型约束：** 此接口仅可在Stage模型下使用。
**元服务API：** 从版本4.1.0(11)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Map.Core
**起始版本：** 4.1.0(11)
**返回值：**
| 类型 | 说明 |
| --- | --- |
| boolean | 多边形的每个线段是否为大地线。true：大地线false：非大地线 |
**示例：**
```typescript
let geodesic: boolean = mapPolygon.isGeodesic();
```
#### setClickable
setClickable(clickable: boolean): void
设置多边形的可点击性。
**模型约束：** 此接口仅可在Stage模型下使用。
**元服务API：** 从版本4.1.0(11)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Map.Core
**起始版本：** 4.1.0(11)
**参数：**
| **参数名** | **类型** | 必填 | **说明** |
| --- | --- | --- | --- |
| clickable | boolean | 是 | 多边形的可点击性，默认是false。true：可点击false：不可点击 |
**示例：**
```typescript
mapPolygon.setClickable(true);
```
#### setFillColor
setFillColor(color: number): void
设置多边形的填充色。
**模型约束：** 此接口仅可在Stage模型下使用。
**元服务API：** 从版本4.1.0(11)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Map.Core
**起始版本：** 4.1.0(11)
**参数：**
| **参数名** | **类型** | 必填 | **说明** |
| --- | --- | --- | --- |
| color | number | 是 | ARGB格式颜色值，默认值为0x00000000（透明）。 |
**示例：**
```typescript
mapPolygon.setFillColor(0xff000FFF);
```
#### setGeodesic
setGeodesic(geodesic: boolean): void
设置是否将多边形的每个线段绘制为大地线。
**模型约束：** 此接口仅可在Stage模型下使用。
**元服务API：** 从版本4.1.0(11)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Map.Core
**起始版本：** 4.1.0(11)
**参数：**
| **参数名** | **类型** | 必填 | **说明** |
| --- | --- | --- | --- |
| geodesic | boolean | 是 | 将多边形的每个线段绘制为大地线，默认值为false。true：每段绘制为大地线false：不是大地线 |
**示例：**
```typescript
mapPolygon.setGeodesic(true);
```
#### setHoles
setHoles(holes: Array<Array<mapCommon.LatLng>>): void
设置多边形的空心洞。
**模型约束：** 此接口仅可在Stage模型下使用。
**元服务API：** 从版本4.1.0(11)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Map.Core
**起始版本：** 4.1.0(11)
**参数：**
| **参数名** | **类型** | 必填 | **说明** |
| --- | --- | --- | --- |
| holes | Array<Array<[mapCommon.LatLng](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md)>> | 是 | 空心洞数组，其中空心洞是[LatLng](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md)数组。 |
**示例：**
```typescript
let holes: Array<Array<mapCommon.LatLng>> = [
  [
    {
      latitude: 31.98,
      longitude: 115.76
    },
    {
      latitude: 31.98,
      longitude: 118.76
    },
    {
      latitude: 35.98,
      longitude: 118.76
    },
    {
      latitude: 35.98,
      longitude: 118.76
    }
  ]
];
mapPolygon.setHoles(holes);
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/19/v3/YiUd870xStykyIorDsezhQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093826Z&HW-CC-Expire=86400&HW-CC-Sign=C5A31799C9FCD92A7FC85F1CE9502C6AAEF198957707C0E13E2F4674887163EB)
当空心洞的坐标贴合多边形边缘时，会导致渲染出现异常，渲染多余的空心区域。
#### setPoints
setPoints(points: Array<mapCommon.LatLng>): void
重新设置多边形的顶点坐标。
**模型约束：** 此接口仅可在Stage模型下使用。
**元服务API：** 从版本4.1.0(11)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Map.Core
**起始版本：** 4.1.0(11)
**参数：**
| **参数名** | **类型** | 必填 | **说明** |
| --- | --- | --- | --- |
| points | Array<[mapCommon.LatLng](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md)> | 是 | 顶点坐标数组。 |
**示例：**
```typescript
let points: Array<mapCommon.LatLng> = [
  { 
    latitude: 31.98,
    longitude: 115.76
  },
  { 
    latitude: 31.98,
    longitude: 118.76
  },
  { 
    latitude: 35.98,
    longitude: 118.76
  },
  { 
    latitude: 35.98,
    longitude: 118.76
  }
];
mapPolygon.setPoints(points);
```
#### setStrokeColor
setStrokeColor(color: number): void
设置多边形的边框颜色。
**模型约束：** 此接口仅可在Stage模型下使用。
**元服务API：** 从版本4.1.0(11)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Map.Core
**起始版本：** 4.1.0(11)
**参数：**
| **参数名** | **类型** | 必填 | **说明** |
| --- | --- | --- | --- |
| color | number | 是 | ARGB格式颜色值，默认值为黑色（0xff000000）。 |
**示例：**
```typescript
mapPolygon.setStrokeColor(0xff00DB93);
```
#### setJointType
setJointType(jointType: mapCommon.JointType): void
设置多边形的顶点样式。
**模型约束：** 此接口仅可在Stage模型下使用。
**元服务API：** 从版本4.1.0(11)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Map.Core
**起始版本：** 4.1.0(11)
**参数：**
| **参数名** | **类型** | 必填 | **说明** |
| --- | --- | --- | --- |
| jointType | [mapCommon.JointType](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md) | 是 | 顶点样式，默认值为[JointType](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md).DEFAULT。 |
**示例：**
```typescript
mapPolygon.setJointType(mapCommon.JointType.ROUND);
```
#### setPatterns
setPatterns(patterns: Array<mapCommon.PatternItem>): void
设置多边形的边框样式。
**模型约束：** 此接口仅可在Stage模型下使用。
**元服务API：** 从版本4.1.0(11)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Map.Core
**起始版本：** 4.1.0(11)
**参数：**
| **参数名** | **类型** | 必填 | **说明** |
| --- | --- | --- | --- |
| patterns | Array<[mapCommon.PatternItem](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md)> | 是 | [PatternItem](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md)对象的数组。默认的边框样式为实心。 |
**示例：**
```typescript
let linePatterns: Array<mapCommon.PatternItem> = [
  { 
    type: mapCommon.PatternItemType.DASH,
    length: 100
  },
  { 
    type: mapCommon.PatternItemType.DOT,
    length: 100
  },
  { 
    type: mapCommon.PatternItemType.GAP,
    length: 100 
  }
];
mapPolygon.setPatterns(linePatterns);
```
#### setStrokeWidth
setStrokeWidth(width: number): void
设置多边形的边框宽度。
**模型约束：** 此接口仅可在Stage模型下使用。
**元服务API：** 从版本4.1.0(11)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Map.Core
**起始版本：** 4.1.0(11)
**参数：**
| **参数名** | **类型** | 必填 | **说明** |
| --- | --- | --- | --- |
| width | number | 是 | 边框的宽度，单位：px，默认值为10，取值范围：大于等于0，异常值不处理。 |
**示例：**
```typescript
mapPolygon.setStrokeWidth(30);
```