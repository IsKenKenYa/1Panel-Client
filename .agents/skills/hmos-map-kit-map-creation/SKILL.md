---
name: hmos-map-kit-map-creation
description: >
  HarmonyOS Map Kit地图创建开发指南，支持地图组件创建、覆盖物管理、相机控制、图层配置等能力。
  适用情形：用户要求创建/绘制/展示地图、添加地图标记、绘制图形、管理覆盖物交互、控制相机位置等。
version: 1.0.0
license: MIT
homepage: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/map-presenting
---

# HarmonyOS Map Kit 地图创建开发指南

本技能提供华为地图Map Kit SDK的地图创建与覆盖物管理功能开发指南。

## 领域知识

地图创建Skill覆盖MapComponent组件创建、覆盖物添加删除、相机动画控制等核心能力。

关键Note：
- **MapComponent是基础**：必须先在UI中创建MapComponent组件，才能获取Controller进行后续操作
- **Controller空检查必须**：通过mapCallback获取的MapComponentController使用前必须进行空检查
- **坐标系统一**：geoLocationManager返回WGS84坐标系，地图显示使用GCJ02坐标系，必须转换
- **异步处理**：除TileOverlay和MvtOverlay外，所有地图API返回Promise，必须使用async/await

扩展知识 → references/（可按需查阅）
- 坐标系转换规则 → references/utility.md
- 覆盖物选项参数 → references/common.md

## 工具定义（Tools）

本Skill使用HarmonyOS Map Kit SDK提供的系统预置工具。


### 接口导入

```typescript
import { map, mapCommon, MapComponent } from '@kit.MapKit';
```

### Controller定义

```typescript
private mapController?: map.MapComponentController;
```

### 核心API

| API | 说明 | 返回类型 |
|-----|-----|---------|
| `mapComponentController.addMarker()` | 添加标记 | Promise |
| `mapComponentController.removeMarker()` | 移除标记 | Promise |
| `mapComponentController.addCircle()` | 添加圆形 | Promise |
| `mapComponentController.addPolygon()` | 添加多边形 | Promise |
| `mapComponentController.addPolyline()` | 添加折线 | Promise |
| `mapComponentController.animateCamera()` | 相机动画 | Promise |
| `mapComponentController.setMyLocationEnabled()` | 开启定位 | void |
| `map.convertCoordinate()` | 坐标转换 | Promise\<mapCommon.LatLng\> |
| `map.newLatLng()` | 创建CameraUpdate | CameraUpdate |

## 经验攻略（Exemplar Playbook）

| 用户输入 | 调用能力 | 要点（隐含推理）                         |
|---------|---------|----------------------------------|
| 在地图上显示北京大学 | addMarker | "显示某地"→创建标记；必须先获取北京大学真实坐标        |
| 显示我的位置 | setMyLocationEnabled | "我的位置"→开启定位→获取当前位置→转换坐标→设置位置     |
| 在地图上标注方圆1公里 | addCircle | "方圆X公里"→圆形覆盖物；需先获取中心点坐标          |
| 移动镜头到国贸位置 | animateCamera | "移动到"→获取目标坐标→创建CameraUpdate→执行动画 |
| 画一条从天安门到北京站的线 | addPolyline | "画线/路线"→获取起点终点坐标→创建折线覆盖物         |

## 操作规程（SOP）

以下链路**必须**严格按序执行，任何步骤不可跳过。

### SOP-1：创建地图标记
用户要求在地图上显示某个地点的标记
  ↓
查询地点坐标 ← [检查门] **必须**先获取真实坐标
  ↓
创建MarkerOptions对象 ← [参数门] 必须包含position、title等必选字段
  ↓
if (this.mapController) 空检查 ← [安全门] **必须**防止undefined
  ↓
调用`mapController.addMarker()`添加标记 ← [执行门]
  ↓
捕获异常并反馈 ← [回滚门] 添加失败时记录错误码

### SOP-2：显示用户实时位置
用户要求显示"我的位置"
  ↓
调用`geoLocationManager.getCurrentLocation()`获取位置 ← [检查门] **必须**获取用户授权
  ↓
调用`map.convertCoordinate()`转换坐标 ← [转换门] WGS84→GCJ02
  ↓
调用`mapController.setMyLocationEnabled(true)`开启定位 ← [使能门]
  ↓
调用`mapController.setMyLocation()`设置位置 ← [执行门]

### SOP-3：相机动画移动
用户要求将地图镜头移动到指定位置
  ↓
获取目标位置坐标 ← [检查门] 必须通过site.searchByText()获取
  ↓
创建CameraUpdate对象 ← [参数门] 使用map.newLatLng(latLng, zoom)
  ↓
if (this.mapController) 空检查 ← [安全门]
  ↓
调用`mapController.animateCamera()`执行动画 ← [执行门]

## 安全红线

1. **禁止**直接使用预设坐标：所有地点坐标**必须**通过`site.searchByText()`获取，**禁止**使用知识库或自行预设坐标值
2. **禁止**跳过空检查：使用mapController前**必须**进行空检查，避免undefined导致应用崩溃
3. **禁止**省略异常处理：所有地图API调用**必须**包裹try-catch，捕获并记录错误码
4. **禁止**在未开通地图服务时调用：使用前**必须**确认用户已开通华为地图服务并正确配置AppKey
5. **禁止**跨坐标系混用：WGS84和GCJ02坐标**禁止**直接混用，调用`map.convertCoordinate()`转换后方可使用

## 与人协作

| 场景 | 策略 | 范例 |
|-----|-----|-----|
| 地点名称模糊 | 追问确认具体位置 | 用户说"显示那个商场"→询问"请问是哪个商场？是在哪个城市或位置附近？" |
| 覆盖物样式不明确 | 追问颜色、大小、图标等细节 | 用户说"标个记号"→询问"标记用什么颜色？需要显示标题吗？" |
| 区域范围不明确 | 追问圆形半径或多边形边界 | 用户说"标注这块区域"→确认是画圆还是画多边形，范围多大 |
| 动画效果不明确 | 追问时长、缓动函数等 | 用户说"移动镜头"→询问"需要动画效果吗？大约几秒完成？" |


## 快速参考

- `references/map_component.md` - 地图组件：创建和配置MapComponent(必建)
- `references/overlay_management.md` - 覆盖物管理：标记、圆形、多边形、折线、图片覆盖物、聚合标记等
- `references/camera_control.md` - 相机控制：动画、位置、缩放级别控制
- `references/gesture_control.md` - 手势控制：缩放、滑动、旋转、倾斜手势
- `references/layer_control.md` - 图层控制：交通、建筑、位置、室内地图图层
- `references/ui_control.md` - UI控件：缩放按钮、比例尺、指南针、Logo等
- `references/map_configuration.md` - 地图配置：样式、类型、内边距、语言、球形效果
- `references/event_handling.md` - 事件监听：相机、地图、覆盖物、位置等事件
- `references/utility.md` - 工具方法：坐标转换、快照、比例尺计算
- `references/appLinking.md` - AppLinking：跳转花瓣地图查看位置详情、导航等场景
- `references/common.md` - 通用常量：错误码、状态码、覆盖物选项

### Demo示例代码

- `assets/appLinkingDemo.md` - AppLinking示例
- `assets/mapComponentDemo.md` - 地图组件示例
- `assets/overlayManagementDemo.md` - 覆盖物管理示例
- `assets/cameraControlDemo.md` - 相机控制示例
- `assets/gestureControlDemo.md` - 手势控制示例
- `assets/layerControlDemo.md` - 图层控制示例
- `assets/uiControlDemo.md` - UI控件示例
- `assets/mapConfigurationDemo.md` - 地图配置示例
- `assets/eventHandlingDemo.md` - 事件监听示例
- `assets/utilityDemo.md` - 工具方法示例