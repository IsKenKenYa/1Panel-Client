---
name: hmos-map-kit-dyntrajectories
description: 在地图上绘制动态轨迹,支持轨迹回放/暂停/删除操作,支持自定义动画时长和轨迹样式,适用于物流跟踪/出行导航/运动监测场景
---

# 动态轨迹技能

## 功能描述

在地图上绘制动态轨迹,实时展示车辆行驶路径、用户运动轨迹等行程信息。支持轨迹回放、暂停、删除等操作,支持自定义轨迹颜色、宽度和动画时长,支持相机跟随轨迹移动,支持添加移动标记并设置动画效果。

## 使用场景

### 触发词
- "绘制动态轨迹"
- "轨迹回放"
- "运动轨迹"
- "物流轨迹"
- "车辆轨迹"
- "路径动画"

### 能做
- 绘制动态轨迹并设置轨迹样式(颜色、宽度)
- 设置轨迹动画时长和相机跟随效果
- 添加移动标记并设置帧动画
- 控制轨迹回放、暂停、恢复、删除
- 监听轨迹动画进度并触发自定义回调
- 支持最多100000个轨迹点

### 绝不做
- 不处理超出100000点的轨迹数据
- 不支持实时定位数据采集(需预先准备轨迹点数据)
- 不处理轨迹数据的持久化存储
- 不支持轨迹编辑和修改功能

### 补充
- 轨迹点数据需使用WGS84坐标系
- 建议轨迹点间隔合理,避免过于密集影响性能
- 标记动画图片需存放在resources/base/media目录
- 起始版本:5.0.0(12),支持元服务API

## 调用规范和规则

### 输入约束
- 轨迹点数量:最大100000个点
- 轨迹点坐标:latitude范围[-90,90],longitude范围[-180,180)
- 轨迹宽度:范围[0,512],单位px
- 动画时长:最小100ms,默认5000ms
- 标记数量:建议不超过10个标记

### 执行约束
- 最大动画时长:建议不超过30秒
- 轨迹绘制完成时间:取决于轨迹点数量和动画时长
- 标记动画帧数:建议不超过30帧
- 相机移动频率:每帧更新一次

### 内容约束
- 禁止生成:超出坐标范围的轨迹点
- 禁止使用:不支持的图片格式(仅支持jpg/jpeg/png/gif/webp/svg)
- 禁止操作:在轨迹动画过程中修改轨迹点数据

### 降级约束
- 轨迹点过多:提示用户减少轨迹点数量或分批处理
- 动画时长过短:自动调整为最小值100ms
- 标记加载失败:使用默认图标替代
- 网络异常:不影响本地轨迹绘制

## 调用流程和步骤

### 步骤1:准备阶段

**前置校验**:
1. 检查轨迹点数据是否有效(latitude和longitude在有效范围内)
2. 检查轨迹点数量是否超过上限(100000)
3. 检查地图控制器是否已初始化
4. 检查标记图片资源是否存在

**参数准备**:
```typescript
import { mapCommon, map, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

// 准备轨迹点数据
let points: Array<mapCommon.LatLng> = [
  { latitude: 31.99685233070878, longitude: 118.75846023442728 },
  { latitude: 31.99671325810786, longitude: 118.75846738985165 },
  // ... 更多轨迹点
];

// 准备轨迹参数
let traceOptions: mapCommon.TraceOverlayParams = {
  points: points,
  animationDuration: 5000,
  isMapMoving: true,
  color: 0xAAFFAA00,
  width: 20,
  animationCallback: (pointIndex) => {
    console.info(`Current point index: ${pointIndex}`);
  }
};
```

### 步骤2:创建移动标记

**示例代码**:
```typescript
// 创建标记1
let markerOptions1: mapCommon.MarkerOptions = {
  position: {
    latitude: points[0].latitude,
    longitude: points[0].longitude
  },
  icon: $r("app.media.marker_icon"),
  anchorU: 0.5,
  anchorV: 1,
  visible: true
};

let marker1 = await this.mapController.addMarker(markerOptions1);

// 创建帧动画
let animation: map.PlayImageAnimation = new map.PlayImageAnimation();
animation.setDuration(1000);

let frames: Array<Resource> = [
  $r("app.media.frame_0"),
  $r("app.media.frame_1"),
  // ... 更多帧
];
await animation.addImages(frames);
animation.setRepeatCount(-1);

// 设置动画并启动
marker1.setAnimation(animation);
marker1.startAnimation();
```

### 步骤3:绘制动态轨迹

**示例代码**:
```typescript
// 准备标记数组
let markers: Array<map.Marker> = [marker1];

// 绘制动态轨迹
try {
  let traceOverlay = await this.mapController.addTraceOverlay(traceOptions, markers);
  console.info('Trace overlay created successfully');
} catch (error) {
  console.error(`Failed to create trace overlay: code=${error.code}, message=${error.message}`);
}
```

### 步骤4:轨迹控制操作

**暂停轨迹**:
```typescript
traceOverlay.pause();
console.info('Trace overlay paused');
```

**恢复轨迹**:
```typescript
traceOverlay.resume();
console.info('Trace overlay resumed');
```

**删除轨迹**:
```typescript
traceOverlay.remove();
console.info('Trace overlay removed');
```

### 步骤5:错误处理

```typescript
try {
  let traceOverlay = await this.mapController.addTraceOverlay(traceOptions, markers);
} catch (error) {
  switch (error.code) {
    case 401:
      console.error('Invalid input parameter');
      break;
    case 1002601001:
      console.error('The object to be operated does not exist');
      break;
    default:
      console.error(`Unknown error: ${error.message}`);
  }
}
```

### 步骤6:降级处理

```typescript
// 检查轨迹点数量
if (points.length > 100000) {
  console.warn('Too many trace points, please reduce to less than 100000');
  return;
}

// 检查动画时长
if (traceOptions.animationDuration < 100) {
  console.warn('Animation duration too short, adjusted to minimum value 100ms');
  traceOptions.animationDuration = 100;
}

// 降级方案:不使用标记动画
if (!markerAnimationSupported) {
  markers = [];
  let traceOverlay = await this.mapController.addTraceOverlay(traceOptions, markers);
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Invalid input parameter | 检查输入参数是否有效,轨迹点坐标是否在范围内 |
| 1002601001 | The object to be operated does not exist | 检查地图控制器是否已初始化 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.MapKit": ">=5.0.0",
    "@kit.BasicServicesKit": ">=5.0.0"
  }
}
```

### 环境要求
- HarmonyOS SDK:最低版本5.0.0(12)
- Stage模型:仅支持Stage模型
- 元服务:从版本5.0.0(12)开始支持

### 常见编译问题

**问题1:模块导入失败**
```
Error: Cannot find module '@kit.MapKit'
```
**解决方法**:确保HarmonyOS SDK版本不低于5.0.0(12),在oh-package.json5中添加依赖

**问题2:类型定义错误**
```
Error: Property 'addTraceOverlay' does not exist on type 'MapComponentController'
```
**解决方法**:确保导入map和mapCommon模块,检查SDK版本是否支持该API

**问题3:标记动画失败**
```
Error: Failed to load image resources
```
**解决方法**:确保图片资源存放在resources/base/media目录,使用$r()引用资源

## 常见问题与解决方法

### Q1:轨迹动画卡顿或不流畅
**原因**:轨迹点过于密集或动画时长过短
**解决方法**:
- 适当增加轨迹点间隔,减少点数量
- 增加动画时长,降低移动速度
- 优化标记动画帧数,减少每帧图片大小

### Q2:标记动画不显示或显示异常
**原因**:图片资源未正确加载或动画参数设置错误
**解决方法**:
- 检查图片是否存放在resources/base/media目录
- 检查图片格式是否支持(jpg/jpeg/png/gif/webp/svg)
- 检查动画时长和重复次数是否正确设置

### Q3:相机不跟随轨迹移动
**原因**:isMapMoving参数未设置为true
**解决方法**:
- 在TraceOverlayParams中设置isMapMoving为true
- 检查地图相机是否被其他操作锁定

### Q4:轨迹颜色或宽度显示不正确
**原因**:颜色格式错误或宽度超出范围
**解决方法**:
- 确保颜色值为ARGB格式(如0xAARRGGBB)
- 确保宽度在[0,512]范围内

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "traceOverlayId": "string",
  "tracePointsCount": 26,
  "animationDuration": 5000,
  "markersCount": 2,
  "apiUsed": [
    "addMarker",
    "PlayImageAnimation",
    "addTraceOverlay",
    "pause",
    "resume",
    "remove"
  ]
}
```

## 参考文档

- [动态轨迹开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/map-dyntrajectories)
- [TraceOverlayParams API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common)
- [addTraceOverlay API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller)
- [Marker API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-marker)
- [TraceOverlay API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-traceoverlay)

## 完整示例代码

- [ArkTS示例](assets/TraceOverlayDemo.ets)
- [配置文件示例](assets/oh-package.json5)

## 测试用例

### 正向测试用例
- [基本轨迹绘制测试](tests/test_basic_trace.py):测试基本轨迹绘制功能
- [标记动画测试](tests/test_marker_animation.py):测试标记动画效果
- [轨迹控制测试](tests/test_trace_control.py):测试暂停/恢复/删除操作

### 边界测试用例
- [最大轨迹点测试](tests/test_max_points.py):测试100000轨迹点边界
- [最小动画时长测试](tests/test_min_duration.py):测试100ms最小动画时长
- [轨迹宽度边界测试](tests/test_trace_width.py):测试轨迹宽度边界值

### 异常测试用例
- [无效坐标测试](tests/test_invalid_coords.py):测试超出范围的坐标
- [缺失资源测试](tests/test_missing_resources.py):测试图片资源缺失情况
- [参数错误测试](tests/test_invalid_params.py):测试无效参数输入