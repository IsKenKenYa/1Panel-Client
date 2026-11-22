# 地图组件（MapComponent）开发指南

## 概述

MapComponent是HarmonyOS Map Kit的地图视图组件，用于在应用中显示地图。通过MapComponent可以创建地图视图并获取MapComponentController控制器，以便进行覆盖物添加、地图交互等操作。

## MapComponent 参数说明

| 参数名 | 类型 | 是否可选 | 说明 |
|--------|------|----------|------|
| mapOptions | [MapOptions](#mapoptions-属性说明) | 否 | 地图初始化配置 |
| mapCallback | AsyncCallback<[MapComponentController](#mapcomponentcontroller-对象方法)> | 否 | 地图初始化完成回调，返回地图控制器 |
| customInfoWindow | [customInfoWindowCallback](#custominfowindowcallback自定义信息窗口) | 是 | 自定义信息窗口构建器 |

### customInfoWindowCallback（自定义信息窗口）

| 参数名 | 类型 | 说明 |
|--------|------|------|
| markerDelegate | [MarkerDelegate](#markerdelegate标记委托) | 标记委托对象 |

### MarkerDelegate（标记委托）

| 属性名 | 类型                           | 是否可选 | 说明 |
|--------|------------------------------|----------|------|
| marker | [Marker](marker.md#marker标记) | 是 | 显示自定义信息窗口的标记 |

## MapOptions 属性说明

| 属性名 | 类型 | 是否可选 | 说明 |
|--------|------|----------|------|
| mapType | [MapType](#maptype地图类型) | 是 | 地图类型，默认STANDARD |
| position | [CameraPosition](#cameraposition相机位置) | 否 | 地图相机位置 |
| bounds | [LatLngBounds](common.md#latlngbounds矩形区域) | 是 | 相机移动范围 |
| maxZoom | number | 是 | 最大缩放级别（2-20），默认20 |
| minZoom | number | 是 | 最小缩放级别（2-20），默认2 |
| rotateGesturesEnabled | boolean | 是 | 是否启用旋转手势，默认true |
| scrollGesturesEnabled | boolean | 是 | 是否启用滑动手势，默认true |
| zoomGesturesEnabled | boolean | 是 | 是否启用缩放手势，默认true |
| tiltGesturesEnabled | boolean | 是 | 是否启用倾斜手势，默认true |
| zoomControlsEnabled | boolean | 是 | 是否显示缩放控制器，默认true |
| myLocationControlsEnabled | boolean | 是 | 是否显示我的位置控制器，默认false |
| compassControlsEnabled | boolean | 是 | 是否显示指南针控制器，默认true |
| scaleControlsEnabled | boolean | 是 | 是否显示比例尺控制器，默认false |
| mapPadding | [Padding](#padding内边距) | 是 | 地图内边距 |

### CameraPosition（相机位置）

| 属性名 | 类型 | 是否可选 | 说明 |
|--------|------|----------|------|
| target | [LatLng](common.md#latlng坐标对象) | 否 | 地图中心点经纬度 |
| zoom | number | 否 | 缩放级别（2-20），默认2 |
| tilt | number | 是 | 倾斜角度（0-75），默认0 |
| bearing | number | 是 | 旋转角度（0-360），默认0 |

### MapType（地图类型）

| 枚举值 | 说明 |
|--------|------|
| MapType.STANDARD | 标准地图，显示道路、建筑、绿 地、河流等自然特征 |
| MapType.NONE | 空地图（无底图） |
| MapType.TERRAIN | 地形地图，在标准地图上叠加地形数据 |

### Padding（内边距）

| 属性名 | 类型 | 是否可选 | 说明 |
|--------|------|----------|------|
| left | number | 是 | 左边距，默认0 |
| top | number | 是 | 上边距，默认0 |
| right | number | 是 | 右边距，默认0 |
| bottom | number | 是 | 下边距，默认0 |

## MapComponentController 对象方法

地图创建成功后，通过callback回调返回 map.MapComponentController，包含以下方法：

### 相机操作

详细可参考[camera_control.md](camera_control.md)

| 方法 | 说明 |
|------|------|
| animateCamera(update: CameraUpdate, duration?: number): void | 动画更新相机状态（带时长） |
| animateCameraStatus(update: CameraUpdate, duration?: number): Promise\<AnimateResult\> | 动画更新相机状态并返回结果（4.1.0+） |
| animateCameraWithMarker(update: CameraUpdate, marker: Marker, duration: number): Promise\<AnimateResult\> | 动画更新地图状态和单个标记（5.0.0+） |
| animateCameraWithMarkers(update: CameraUpdate, markers: Array\<Marker\>, duration: number): Promise\<AnimateResult\> | 动画更新地图状态和多个标记（5.0.0+） |
| stopAnimation(): void | 停止当前地图动画 |
| moveCamera(update: CameraUpdate): void | 无动画更新相机状态 |
| getCameraPosition(): mapCommon.CameraPosition | 获取当前相机状态 |
| setLatLngBounds(bounds: mapCommon.LatLngBounds): void | 设置相机移动范围边界 |
| setPointToCenter(point: mapCommon.MapPoint): void | 设置屏幕像素位置为中心点（4.1.0+） |
| setMaxZoom(maxZoom: number): void | 设置最大缩放级别（范围2-20） |
| getMaxZoom(): number | 获取最大缩放级别 |
| setMinZoom(minZoom: number): void | 设置最小缩放级别（范围2-20） |
| getMinZoom(): number | 获取最小缩放级别 |

### 手势控制

详细可参考[gesture_control.md](gesture_control.md)

| 方法 | 说明 |
|------|------|
| setZoomGesturesEnabled(enabled: boolean): void | 设置是否启用缩放手势 |
| isZoomGesturesEnabled(): boolean | 获取缩放手势启用状态 |
| setScrollGesturesEnabled(enabled: boolean): void | 设置是否启用滑动手势 |
| isScrollGesturesEnabled(): boolean | 获取滑动手势启用状态 |
| setRotateGesturesEnabled(enabled: boolean): void | 设置是否启用旋转手势 |
| isRotateGesturesEnabled(): boolean | 获取旋转手势启用状态 |
| setTiltGesturesEnabled(enabled: boolean): void | 设置是否启用倾斜手势 |
| isTiltGesturesEnabled(): boolean | 获取倾斜手势启用状态 |
| setGestureScaleByMapCenter(enabled: boolean): void | 设置是否以地图中心点缩放 |
| isGestureScaleByMapCenter(): boolean | 获取是否以地图中心点缩放 |
| setAllGesturesEnabled(enabled: boolean): void | 设置是否启用所有手势 |

### 控制器显示

详细可参考[ui_control.md](ui_control.md)

| 方法 | 说明 |
|------|------|
| setZoomControlsEnabled(enabled: boolean): void | 设置是否显示缩放控制器 |
| isZoomControlsEnabled(): boolean | 获取缩放控制器显示状态 |
| setMyLocationControlsEnabled(enabled: boolean): void | 设置是否显示我的位置控制器 |
| isMyLocationControlsEnabled(): boolean | 获取我的位置控制器显示状态 |
| setScaleControlsEnabled(enabled: boolean): void | 设置是否显示比例尺控制器 |
| isScaleControlsEnabled(): boolean | 获取比例尺控制器显示状态 |
| setCompassControlsEnabled(enabled: boolean): void | 设置是否显示指南针控制器 |
| isCompassControlsEnabled(): boolean | 获取指南针控制器显示状态 |
| setScalePosition(point: mapCommon.MapPoint): void | 设置比例尺控制器位置（5.0.0+） |
| setCompassPosition(point: mapCommon.MapPoint): void | 设置指南针控制器位置（5.0.0+） |
| setAlwaysShowScaleEnabled(enabled: boolean): void | 设置是否始终显示比例尺（5.0.0+） |
| isAlwaysShowScaleEnabled(): boolean | 获取是否始终显示比例尺（5.0.0+） |
| getScaleControlsHeight(): number | 获取比例尺控制器高度（vp）（5.0.0+） |
| getScaleControlsWidth(): number | 获取比例尺控制器宽度（vp）（5.0.0+） |

### 图层控制

详细可参考[layer_control.md](layer_control.md)

| 方法 | 说明 |
|------|------|
| setTrafficEnabled(enabled: boolean): void | 设置是否启用交通图层 |
| isTrafficEnabled(): boolean | 获取交通图层启用状态 |
| setBuildingEnabled(enabled: boolean): void | 设置是否启用3D建筑图层 |
| isBuildingEnabled(): boolean | 获取3D建筑图层启用状态 |
| setMyLocationEnabled(myLocationEnabled: boolean): void | 设置是否启用我的位置图层 |
| isMyLocationEnabled(): boolean | 获取我的位置图层启用状态 |
| setMyLocation(location: geoLocationManager.Location): void | 设置用户位置 |
| setMyLocationStyle(style: mapCommon.MyLocationStyle): Promise\<void\> | 设置我的位置样式 |
| changeMyLocationLayerOrder(isBelow: boolean): void | 调整我的位置图层与其他覆盖物的层叠顺序（6.0.1+） |
| setContourEnabled(enabled: boolean): void | 设置是否启用等高线图层（systemapi, 5.1.0+） |
| setIndoorMapEnabled(enabled: boolean): void | 设置是否启用室内地图（5.1.1+） |
| isIndoorMapEnabled(): boolean | 获取室内地图启用状态（5.1.1+） |
| setIndoorParkingMapEnabled(enabled: boolean): void | 设置是否启用室内停车地图（systemapi, 6.1.1+） |

### Logo与显示

详细可参考[ui_control.md](ui_control.md)

| 方法 | 说明 |
|------|------|
| setLogoAlignment(alignment: mapCommon.LogoAlignment): void | 设置地图Logo对齐方式 |
| setLogoPadding(padding: mapCommon.Padding): void | 设置地图Logo内边距 |
| setLogoScale(logoScale: number): void | 设置Logo缩放比例（范围0.8-1） |
| getLogoScale(): number | 获取Logo缩放比例 |
| setPadding(padding?: mapCommon.Padding): void | 设置地图内边距 |
| getScalePerPixel(): number | 获取当前缩放级别下1像素的长度（米） |
| getScaleLevel(): number | 获取比例尺等级（米） |
| setDisplayOrder(types: Array\<mapCommon.MapElementType\>): void | 设置地图元素显示顺序（5.0.0+） |

### 地图样式与类型

详细可参考[map_configuration.md](map_configuration.md)

| 方法 | 说明 |
|------|------|
| getMapType(): mapCommon.MapType | 获取地图类型 |
| setMapType(mapType: mapCommon.MapType): void | 设置地图类型 |
| getDayNightMode(): mapCommon.DayNightMode | 获取昼夜模式（5.0.0+） |
| setDayNightMode(mode: mapCommon.DayNightMode): void | 设置昼夜模式（5.0.0+） |
| setCustomMapStyle(customMapStyleOptions: mapCommon.CustomMapStyleOptions): Promise\<void\> | 设置自定义地图样式（5.0.0+） |
| setLanguage(language: string): void | 设置地图语言（6.0.0+） |
| getLanguage(): string | 获取地图语言（6.0.0+） |
| setSphereEnabled(enabled: boolean): void | 设置是否启用球形效果（5.0.3+） |
| setSphereEnabled(enabled: boolean, animateDuration: number): void | 切换2D/3D动画（6.0.0+） |
| setSphereEnabled(enabled: boolean, animateDuration: number, cityLight: boolean): void | 切换2D/3D动画并设置城市灯光（6.1.0+） |
| isSphereEnabled(): boolean | 获取球形效果启用状态（5.0.3+） |
| setFramePerSecond(fps: number): void | 设置帧率（范围1-60）（6.0.0+） |
| setApproveNumberEnabled(enabled: boolean): void | 设置是否显示地图审图号（6.1.0+） |
| isApproveNumberEnabled(): boolean | 获取地图审图号显示状态（6.1.0+） |

### 覆盖物操作

详细可参考[overlay_management.md](overlay_management.md)

| 方法 | 说明 |
|------|------|
| addMarker(options: mapCommon.MarkerOptions): Promise\<Marker\> | 添加标记 |
| addCircle(options: mapCommon.MapCircleOptions): Promise\<MapCircle\> | 添加圆形 |
| addPolyline(options: mapCommon.MapPolylineOptions): Promise\<MapPolyline\> | 添加折线 |
| addPolygon(options: mapCommon.MapPolygonOptions): Promise\<MapPolygon\> | 添加多边形 |
| addPointAnnotation(params: mapCommon.PointAnnotationParams): Promise\<PointAnnotation\> | 添加点标注（4.1.0+） |
| addBubble(params: mapCommon.BubbleParams): Promise\<Bubble\> | 添加气泡（4.1.0+） |
| addClusterOverlay(params: mapCommon.ClusterOverlayParams): Promise\<ClusterOverlay\> | 添加聚合标记（5.0.0+） |
| addImageOverlay(params: mapCommon.ImageOverlayParams): Promise\<ImageOverlay\> | 添加图片覆盖物（5.0.0+） |
| addTraceOverlay(params: mapCommon.TraceOverlayParams, markers?: Array\<Marker\>): Promise\<TraceOverlay\> | 添加轨迹覆盖物（5.0.0+） |
| addTileOverlay(params: mapCommon.TileOverlayParams \| mapCommon.TileOverlayOptions): TileOverlay | 添加瓦片覆盖物 |
| addBuildingOverlay(params: mapCommon.BuildingOverlayParams): Promise\<BuildingOverlay\> | 添加建筑覆盖物（5.0.0+） |
| addArc(params: mapCommon.MapArcParams): MapArc | 添加弧线（5.0.0+） |
| addHeatmap(params: mapCommon.HeatmapParams): Promise\<Heatmap\> | 添加热力图（6.0.0+） |
| addMvtOverlay(params: mapCommon.MvtOverlayParams): MvtOverlay | 添加Mvt覆盖物（6.0.0+） |
| addFlowFieldOverlay(params: mapCommon.FlowFieldOverlayParams): Promise\<FlowFieldOverlay\> | 添加热力图（实时）（6.0.0+） |
| addMassPointOverlay(params: mapCommon.MassPointOverlayParams): Promise\<MassPointOverlay\> | 添加海量点覆盖物（6.0.0+） |
| addMassPolygonOverlay(params: mapCommon.MassPolygonOverlayParams): Promise\<MassPolygonOverlay\> | 添加海量多边形覆盖物（6.0.2+） |
| clear(): void | 清空所有覆盖物 |
| getProjection(): Projection | 获取投影对象，用于屏幕坐标与经纬度坐标转换 |

### 室内地图

详细可参考[layer_control.md](layer_control.md)

| 方法 | 说明 |
|------|------|
| switchIndoorMapFloor(buildingId: string, floorName: string): void | 切换室内地图楼层（5.1.1+） |
| setFloorControlsPosition(point: mapCommon.MapPoint): void | 设置楼层切换控件位置（6.0.0+） |
| setLocationFloorEnabled(enabled: boolean): void | 设置是否显示定位楼层信息（6.0.2+） |
| isLocationFloorEnabled(): boolean | 获取定位楼层信息显示状态（6.0.2+） |
| queryBuildingIdForParking(parkingId: string): Promise\<string\> | 根据停车ID查询建筑ID（systemapi, 6.1.1+） |

### 地图生命周期

详细可参考[utility.md](utility.md)

| 方法 | 说明 |
|------|------|
| show(): void | 将地图组件切换到前台（5.0.0+） |
| hide(): void | 将地图组件切换到后台（5.0.0+） |
| snapshot(): Promise\<image.PixelMap\> | 生成地图快照（5.0.0+） |
| getEventManager(): MapEventManager | 获取地图事件管理器（5.0.0+） |

### 事件监听

详细可参考[event_handling.md](event_handling.md)

| 事件类型 | 回调参数 | 说明 |
|----------|----------|------|
| mapClick | mapCommon.LatLng | 地图点击 |
| mapLongClick | mapCommon.LatLng | 地图长按 |
| mapLoad | void | 地图加载完成 |
| cameraChange | mapCommon.LatLng | 相机变化结束 |
| cameraIdle | void | 相机空闲 |
| cameraMove | void | 相机移动中 |
| cameraMoveStart | number | 相机开始移动 |
| cameraMoveCancel | void | 相机移动取消 |
| markerClick | Marker | 标记点击 |
| markerDragStart | Marker | 标记开始拖拽 |
| markerDrag | Marker | 标记拖拽中 |
| markerDragEnd | Marker | 标记拖拽结束 |
| circleClick | MapCircle | 圆形点击 |
| polylineClick | MapPolyline | 折线点击 |
| polygonClick | MapPolygon | 多边形点击 |
| infoWindowClick | Marker | 信息窗口点击 |
| infoWindowClose | Marker | 信息窗口关闭 |
| pointAnnotationClick | PointAnnotation | 点标注点击 |
| bubbleClick | Bubble | 气泡点击 |
| imageOverlayClick | ImageOverlay | 图片覆盖物点击 |
| myLocationButtonClick | void | 我的位置按钮点击 |
| myLocationClick | mapCommon.LatLng | 我的位置图层点击 |
| poiClick | mapCommon.Poi | POI点击 |
| error | ErrorCallback | 地图错误 |

```typescript
// 监听事件
this.mapController.on(eventType: string, callback: Function): void

// 取消事件监听
this.mapController.off(eventType: string, callback?: Function): void
```

## 完整示例

详情见 ../assets/mapComponentDemo.md
