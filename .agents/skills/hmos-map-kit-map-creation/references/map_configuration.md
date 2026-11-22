# 地图配置（Map Configuration）

## 概述

地图配置接口用于设置地图的显示样式、类型、内边距、语言等属性。

## 接口说明

### 内边距

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| setPadding(padding?: mapCommon.Padding) | padding: 地图内边距 | void | 设置地图内边距 |

### 地图样式

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| setCustomMapStyle(customMapStyleOptions: mapCommon.CustomMapStyleOptions) | customMapStyleOptions: 自定义地图样式配置 | Promise\<void\> | 设置自定义地图样式（5.0.0+） |

### 昼夜模式

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| getDayNightMode() | 无 | mapCommon.DayNightMode | 获取昼夜模式（5.0.0+） |
| setDayNightMode(mode: mapCommon.DayNightMode) | mode: 昼夜模式 | void | 设置昼夜模式（5.0.0+） |

### 地图类型

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| getMapType() | 无 | mapCommon.MapType | 获取地图类型 |
| setMapType(mapType: mapCommon.MapType) | mapType: 地图类型 | void | 设置地图类型 |

### 显示顺序

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| setDisplayOrder(types: Array\<mapCommon.MapElementType\>) | types: 地图元素类型数组 | void | 设置地图元素显示顺序（5.0.0+） |

### 语言

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| setLanguage(language: string) | language: 语言代码 | void | 设置地图语言（6.0.0+） |
| getLanguage() | 无 | string | 获取地图语言（6.0.0+） |

### 球形效果

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| isSphereEnabled() | 无 | boolean | 获取球形效果启用状态（5.0.3+） |
| setSphereEnabled(enabled: boolean) | enabled: 是否启用球形效果 | void | 设置是否启用球形效果（5.0.3+） |
| setSphereEnabled(enabled: boolean, animateDuration: number) | enabled: 是否启用球形效果<br>animateDuration: 动画时长 | void | 切换2D/3D动画（6.0.0+） |
| setSphereEnabled(enabled: boolean, animateDuration: number, cityLight: boolean) | enabled: 是否启用球形效果<br>animateDuration: 动画时长<br>cityLight: 是否显示城市灯光 | void | 切换2D/3D动画并设置城市灯光（6.1.0+） |

### 性能

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| setFramePerSecond(fps: number) | fps: 帧率（范围1-60） | void | 设置帧率（6.0.0+） |

### 生命周期

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| show() | 无 | void | 将地图组件切换到前台（5.0.0+） |
| hide() | 无 | void | 将地图组件切换到后台（5.0.0+） |

## DayNightMode（昼夜模式）

| 枚举值 | 说明 |
|--------|------|
| DayNightMode.DAY | 白天模式 |
| DayNightMode.NIGHT | 夜间模式 |
| DayNightMode.AUTO | 自动模式 |

## MapElementType（地图元素类型）

| 枚举值 | 说明 |
|--------|------|
| MapElementType.BUILDING | 建筑物 |
| MapElementType.ROAD | 道路 |
| MapElementType.BUS | 公交 |
| MapElementType.RAILWAY | 铁路 |
| MapElementTypeADMIN_DIVISION | 行政区划 |

## CustomMapStyleOptions（自定义地图样式）

| 属性名 | 类型 | 是否可选 | 说明 |
|--------|------|----------|------|
| styleId | string | 是 | 自定义样式ID |
| styleJson | string | 是 | 自定义样式JSON字符串 |
| styleData | Uint8Array | 是 | 自定义样式数据 |
