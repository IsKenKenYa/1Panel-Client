# UI控件控制（UI Control）

## 概述

UI控件控制接口用于管理地图上各种内置控件的显示与位置，包括缩放控制器、位置控制器、比例尺、指南针、Logo等。

## 接口说明

### 缩放控制器

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| setZoomControlsEnabled(enabled: boolean) | enabled: 是否显示缩放控制器 | void | 设置是否显示缩放控制器 |
| isZoomControlsEnabled() | 无 | boolean | 获取缩放控制器显示状态 |

### 位置控制器

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| setMyLocationControlsEnabled(enabled: boolean) | enabled: 是否显示我的位置控制器 | void | 设置是否显示我的位置控制器 |
| isMyLocationControlsEnabled() | 无 | boolean | 获取我的位置控制器显示状态 |

### 比例尺控制器

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| setScaleControlsEnabled(enabled: boolean) | enabled: 是否显示比例尺控制器 | void | 设置是否显示比例尺控制器 |
| isScaleControlsEnabled() | 无 | boolean | 获取比例尺控制器显示状态 |
| setScalePosition(point: mapCommon.MapPoint) | point: 比例尺控制器位置 | void | 设置比例尺控制器位置（5.0.0+） |
| setAlwaysShowScaleEnabled(enabled: boolean) | enabled: 是否始终显示比例尺 | void | 设置是否始终显示比例尺（5.0.0+） |
| isAlwaysShowScaleEnabled() | 无 | boolean | 获取是否始终显示比例尺（5.0.0+） |
| getScaleControlsHeight() | 无 | number | 获取比例尺控制器高度（vp）（5.0.0+） |
| getScaleControlsWidth() | 无 | number | 获取比例尺控制器宽度（vp）（5.0.0+） |
| getScaleLevel() | 无 | number | 获取比例尺等级（米） |

### 指南针控制器

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| setCompassControlsEnabled(enabled: boolean) | enabled: 是否显示指南针控制器 | void | 设置是否显示指南针控制器 |
| isCompassControlsEnabled() | 无 | boolean | 获取指南针控制器显示状态 |
| setCompassPosition(point: mapCommon.MapPoint) | point: 指南针控制器位置 | void | 设置指南针控制器位置（5.0.0+） |

### Logo控制

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| setLogoAlignment(alignment: mapCommon.LogoAlignment) | alignment: Logo对齐方式 | void | 设置地图Logo对齐方式 |
| setLogoPadding(padding: mapCommon.Padding) | padding: Logo内边距 | void | 设置地图Logo内边距 |
| setLogoScale(logoScale: number) | logoScale: Logo缩放比例（范围0.8-1） | void | 设置Logo缩放比例 |
| getLogoScale() | 无 | number | 获取Logo缩放比例 |

### 审图号

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| setApproveNumberEnabled(enabled: boolean) | enabled: 是否显示地图审图号 | void | 设置是否显示地图审图号（6.1.0+） |
| isApproveNumberEnabled() | 无 | boolean | 获取地图审图号显示状态（6.1.0+） |

## LogoAlignment（Logo对齐方式）

| 枚举值 | 说明 |
|--------|------|
| LogoAlignment.TOP_LEFT | 左上对齐 |
| LogoAlignment.TOP_RIGHT | 右上对齐 |
| LogoAlignment.BOTTOM_LEFT | 左下对齐 |
| LogoAlignment.BOTTOM_RIGHT | 右下对齐 |
