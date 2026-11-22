# 手势控制（Gesture Control）

## 概述

手势控制接口用于启用或禁用地图的各种交互手势，包括缩放、滑动、旋转、倾斜等操作。

## 接口说明

### 基础手势控制

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| setZoomGesturesEnabled(enabled: boolean) | enabled: 是否启用缩放手势 | void | 设置是否启用缩放手势 |
| isZoomGesturesEnabled() | 无 | boolean | 获取缩放手势启用状态 |
| setScrollGesturesEnabled(enabled: boolean) | enabled: 是否启用滑动手势 | void | 设置是否启用滑动手势 |
| isScrollGesturesEnabled() | 无 | boolean | 获取滑动手势启用状态 |
| setRotateGesturesEnabled(enabled: boolean) | enabled: 是否启用旋转手势 | void | 设置是否启用旋转手势 |
| isRotateGesturesEnabled() | 无 | boolean | 获取旋转手势启用状态 |
| setTiltGesturesEnabled(enabled: boolean) | enabled: 是否启用倾斜手势 | void | 设置是否启用倾斜手势 |
| isTiltGesturesEnabled() | 无 | boolean | 获取倾斜手势启用状态 |
| setAllGesturesEnabled(enabled: boolean) | enabled: 是否启用所有手势 | void | 设置是否启用所有手势 |

### 缩放手势控制

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| setGestureScaleByMapCenter(enabled: boolean) | enabled: 是否以地图中心点缩放 | void | 设置是否以地图中心点缩放 |
| isGestureScaleByMapCenter() | 无 | boolean | 获取是否以地图中心点缩放 |
