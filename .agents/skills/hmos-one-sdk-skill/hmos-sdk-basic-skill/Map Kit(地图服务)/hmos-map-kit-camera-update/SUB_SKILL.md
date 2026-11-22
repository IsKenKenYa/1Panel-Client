---
name: hmos-map-kit-camera-update
description: 移动地图相机位置控制可见区域，支持动画和非动画方式，可设置缩放级别和边界限制，适用于地图导航、位置定位场景
---

# 更改地图位置技能

## 功能描述

本技能实现通过移动地图相机来控制地图可见区域。地图的移动是通过模拟相机移动的方式实现，通过改变地图相机位置，可以精确控制地图的显示范围、缩放级别、倾斜角度和旋转角度。

**核心能力**：
- 相机移动：支持动画和非动画两种方式移动相机
- 缩放控制：设置地图缩放级别、最大/最小缩放级别限制
- 边界约束：设置地图相机边界，限制用户移动范围
- 多种移动方式：支持经纬度移动、像素滚动、区域显示等多种方式

**适用范围**：
- Map Kit 地图服务
- HarmonyOS API 4.1.0(11) 及以上版本
- ArkTS 语言开发

**限制条件**：
- 仅支持 Stage 模型
- 需要先初始化地图并获取 MapComponentController
- 缩放级别范围 [2, 20]
- 倾斜角度范围 [0, 75]
- 旋转角度范围 [0, 360)

**典型场景**：
- 地图导航：移动地图显示导航路线
- 位置定位：移动相机到目标位置
- 区域展示：显示特定地理区域
- 地图交互：响应用户操作移动地图

## 使用场景

### 触发词
- "移动地图相机"
- "更改地图位置"
- "设置地图缩放级别"
- "移动到指定位置"
- "显示地图区域"
- "设置相机边界"

### 能做
- 以动画或非动画方式移动地图相机
- 设置地图缩放级别（放大、缩小、指定级别）
- 设置相机最大/最小缩放级别限制
- 设置相机边界，限制地图移动范围
- 通过多种方式创建 CameraUpdate 对象
- 滚动地图（按像素移动）
- 设置可见区域范围

### 绝不做
- 不处理地图标记、覆盖物的添加（需使用其他技能）
- 不处理地图样式设置
- 不处理定位功能（需配合 Location Kit）
- 不处理地图事件监听
- 不处理多地图实例管理

### 补充
- 动画方式移动相机时可设置动画持续时间（默认250ms）
- animateCameraStatus 方法可返回动画结果（是否完成、是否取消）
- 设置缩放级别限制时，传入值超出范围会自动调整为边界值
- 设置边界时，西南角纬度不能大于东北角纬度

## 调用规范和规则

### 输入约束
- 经纬度值范围：
  - latitude: [-90, 90]
  - longitude: [-180, 180)
- 缩放级别范围: [2, 20]
- 倾斜角度范围: [0, 75]
- 旋转角度范围: [0, 360)
- 动画持续时间: >0 ms，默认250ms
- 像素值: 可为任意数值（正负均可）

### 执行约束
- 必须先初始化地图并获取 MapComponentController 对象
- 所有相机操作必须在地图初始化回调中或自定义方法中执行
- animateCameraStatus 方法返回 Promise，需要异步处理
- 设置边界前需验证西南角纬度小于东北角纬度

### 内容约束
- 禁止直接修改地图控制器对象的内部属性
- 禁止在未初始化地图时调用相机移动方法
- 禁止使用超出范围的参数值（虽然系统会自动调整，但不推荐）
- 禁止在同一动画执行期间再次调用动画方法（需先停止）

### 降级约束
- 网络失败：地图加载失败时，相机操作无效，需等待地图加载完成
- 参数异常：超出范围的参数会被系统自动调整为边界值
- 边界设置失败：西南角纬度大于东北角纬度时不生效
- 动画中断：可通过 stopAnimation 方法停止当前动画

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认已导入 MapKit 模块
2. 确认地图已初始化并获取 MapComponentController
3. 确认参数值在有效范围内

**参数准备**：
```typescript
// 导入必要模块
import { MapComponent, mapCommon, map } from '@kit.MapKit';

// 准备相机位置参数
let cameraPosition: mapCommon.CameraPosition = {
  target: {
    latitude: 32.0,    // 目标位置纬度
    longitude: 118.0   // 目标位置经度
  },
  zoom: 10,            // 缩放级别
  tilt: 0,             // 倾斜角度（可选）
  bearing: 0           // 旋转角度（可选）
};
```

### 步骤2：创建 CameraUpdate 对象

**示例代码**：
```typescript
// 方式1：使用 newCameraPosition 创建
let cameraUpdate = map.newCameraPosition(cameraPosition);

// 方式2：使用 newLatLng 创建（指定经纬度和缩放）
let latLng: mapCommon.LatLng = {
  latitude: 31.5,
  longitude: 118.9
};
let cameraUpdate2 = map.newLatLng(latLng, 10);

// 方式3：使用 zoomTo 创建（指定缩放级别）
let cameraUpdate3 = map.zoomTo(8.0);

// 方式4：使用 zoomIn/zoomOut 创建（放大/缩小一级）
let cameraUpdate4 = map.zoomIn();
let cameraUpdate5 = map.zoomOut();

// 方式5：使用 zoomBy 创建（指定增量）
let point: mapCommon.MapPoint = {
  positionX: 31,
  positionY: 118
};
let cameraUpdate6 = map.zoomBy(2.0, point);

// 方式6：使用 scrollBy 创建（像素滚动）
let cameraUpdate7 = map.scrollBy(100.0, 100.0);

// 方式7：使用 newLatLngBounds 创建（显示区域）
let latLngBounds: mapCommon.LatLngBounds = {
  northeast: {
    latitude: 32.5,
    longitude: 119.9
  },
  southwest: {
    latitude: 31.5,
    longitude: 118.9
  }
};
let cameraUpdate8 = map.newLatLngBounds(latLngBounds, 5);
```

### 步骤3：移动相机

**非动画方式移动**：
```typescript
// 立即移动相机（无动画）
this.mapController.moveCamera(cameraUpdate);
console.info('Camera moved immediately');
```

**动画方式移动**：
```typescript
// 以动画方式移动相机（1000ms）
this.mapController.animateCamera(cameraUpdate, 1000);
console.info('Camera animation started');
```

**动画方式移动并返回结果**：
```typescript
// 以动画方式移动相机并返回结果
try {
  let animateResult = await this.mapController.animateCameraStatus(cameraUpdate, 1000);
  if (animateResult.isFinished) {
    console.info('Camera animation completed successfully');
  } else if (animateResult.isCanceled) {
    console.warn('Camera animation was canceled');
  }
} catch (error) {
  console.error('Camera animation failed:', error.message);
}
```

### 步骤4：设置缩放级别限制

**示例代码**：
```typescript
// 设置最小缩放级别（范围 [2, 20]）
this.mapController.setMinZoom(6);
console.info('Min zoom set to 6');

// 设置最大缩放级别（范围 [2, 20]）
this.mapController.setMaxZoom(14);
console.info('Max zoom set to 14');

// 获取当前缩放级别限制
let minZoom = this.mapController.getMinZoom();
let maxZoom = this.mapController.getMaxZoom();
console.info(`Zoom range: ${minZoom} - ${maxZoom}`);
```

### 步骤5：设置相机边界

**示例代码**：
```typescript
// 设置相机边界（限制地图移动范围）
let bounds: mapCommon.LatLngBounds = {
  northeast: {
    latitude: 31,
    longitude: 118
  },
  southwest: {
    latitude: 30,
    longitude: 113
  }
};

// 验证边界有效性（西南角纬度必须小于东北角纬度）
if (bounds.southwest.latitude < bounds.northeast.latitude) {
  this.mapController.setLatLngBounds(bounds);
  console.info('Camera bounds set successfully');
} else {
  console.error('Invalid bounds: southwest latitude must be less than northeast latitude');
}
```

### 步骤6：错误处理

**错误处理代码**：
```typescript
// 错误处理
try {
  let animateResult = await this.mapController.animateCameraStatus(cameraUpdate, 1000);
  if (!animateResult.isFinished) {
    console.warn('Animation did not finish properly');
  }
} catch (error) {
  switch (error.code) {
    case 401:
      console.error('Invalid input parameter');
      break;
    default:
      console.error('Unknown error:', error.message);
  }
}
```

### 步骤7：降级处理

**降级处理代码**：
```typescript
// 降级处理：动画失败时使用非动画方式
async function moveCameraWithFallback(mapController: map.MapComponentController, 
                                       cameraUpdate: map.CameraUpdate): void {
  try {
    // 尝试动画方式
    let result = await mapController.animateCameraStatus(cameraUpdate, 1000);
    if (result.isFinished) {
      console.info('Animation succeeded');
    } else {
      console.warn('Animation canceled, using non-animation mode');
      mapController.moveCamera(cameraUpdate);
    }
  } catch (error) {
    console.error('Animation failed, using non-animation mode:', error.message);
    mapController.moveCamera(cameraUpdate);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Invalid input parameter | 检查参数类型和取值范围，确保参数有效 |
| - | 边界设置不生效 | 确保西南角纬度小于东北角纬度 |
| - | 缩放级别自动调整 | 传入值超出 [2, 20] 范围，系统自动调整为边界值 |
| - | 动画被中断 | 调用 stopAnimation 或新动画启动导致中断 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.MapKit": "HarmonyOS SDK"
  }
}
```

### 环境要求
- HarmonyOS API: 4.1.0(11) 及以上
- 开发模型: Stage 模型
- 开发语言: ArkTS

### 常见编译问题

**问题1：导入模块失败**
```
Cannot find module '@kit.MapKit'
```
**解决方法**：确保项目已配置 HarmonyOS SDK，并在 oh-package.json5 中添加依赖

**问题2：MapComponentController 未初始化**
```
Cannot read property 'moveCamera' of undefined
```
**解决方法**：确保在地图初始化回调中获取 mapController 对象后再调用方法

**问题3：参数类型错误**
```
Argument of type 'X' is not assignable to parameter of type 'CameraUpdate'
```
**解决方法**：确保使用 map 命名空间的创建方法生成 CameraUpdate 对象

## 常见问题与解决方法

### Q1：动画移动相机时如何判断是否完成？
**原因**：animateCamera 方法不返回结果，无法判断动画状态
**解决方法**：
- 使用 animateCameraStatus 方法，返回 AnimateResult 对象
- AnimateResult 包含 isFinished 和 isCanceled 属性
- 可通过 Promise 异步等待动画完成

### Q2：设置缩放级别后为什么实际值不同？
**原因**：传入值超出范围或小于当前 minZoom/大于当前 maxZoom
**解决方法**：
- 确保传入值在 [2, 20] 范围内
- 先获取当前的 minZoom 和 maxZoom 值
- 如果传入值小于 minZoom，则 minZoom 和 maxZoom 都会被设置为传入值
- 如果传入值大于 maxZoom，则 minZoom 和 maxZoom 都会被设置为传入值

### Q3：设置的相机边界不生效？
**原因**：西南角纬度大于东北角纬度，或参数异常
**解决方法**：
- 确保 southwest.latitude < northeast.latitude
- 检查经纬度值是否在有效范围内
- 使用空参数可清除已设置的边界

### Q4：如何停止正在执行的动画？
**原因**：需要中断当前动画或开始新动画
**解决方法**：
- 调用 stopAnimation() 方法立即停止动画
- 停止后相机保持当前位置
- 可在动画执行期间调用，立即生效

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "cameraPosition": {
    "target": {
      "latitude": 32.0,
      "longitude": 118.0
    },
    "zoom": 10,
    "tilt": 0,
    "bearing": 0
  },
  "animationResult": {
    "isFinished": true,
    "isCanceled": false
  },
  "zoomLimits": {
    "minZoom": 6,
    "maxZoom": 14
  },
  "bounds": {
    "northeast": { "latitude": 31, "longitude": 118 },
    "southwest": { "latitude": 30, "longitude": 113 }
  },
  "apiUsed": [
    "map.newCameraPosition",
    "mapController.moveCamera",
    "mapController.animateCamera",
    "mapController.animateCameraStatus",
    "mapController.setMinZoom",
    "mapController.setMaxZoom",
    "mapController.setLatLngBounds"
  ]
}
```

## 参考文档

- [API开发指南：更改地图位置](references/map-camera-guide.md)
- [API参考：MapComponentController](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller)
- [API参考：CameraUpdate](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-cameraupdate)
- [API参考：map-common](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common)
- [API参考：newCameraPosition](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-newcameraposition)
- [API参考：newLatLng](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-newlatlng)
- [API参考：zoomTo](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-zoomto)
- [API参考：zoomIn](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-zoomin)
- [API参考：zoomOut](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-zoomout)
- [API参考：zoomBy](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-zoomby)
- [API参考：scrollBy](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-scrollby)
- [API参考：newLatLngBounds](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-newlatlngbounds-1)
- [开发指南：显示地图](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/map-presenting)

## 完整示例代码

- [ArkTS示例：移动相机基本示例](assets/map_camera_basic.ets)
- [ArkTS示例：多种CameraUpdate创建方式](assets/map_camera_update_methods.ets)
- [ArkTS示例：设置缩放级别和边界](assets/map_camera_limits.ets)
- [ArkTS示例：完整地图页面示例](assets/map_camera_complete.ets)

## 测试用例

### 正向测试用例
- [测试：动画移动相机到指定位置](tests/test_animate_camera_position.py)：验证动画方式移动相机功能
- [测试：设置缩放级别限制](tests/test_zoom_limits.py)：验证最小/最大缩放级别设置
- [测试：设置相机边界](tests/test_camera_bounds.py)：验证相机边界设置功能

### 边界测试用例
- [测试：缩放级别边界值](tests/test_zoom_boundary.py)：验证缩放级别边界值处理
- [测试：经纬度边界值](tests/test_latlng_boundary.py)：验证经纬度边界值处理
- [测试：动画时间边界值](tests/test_animation_duration_boundary.py)：验证动画时间参数处理

### 异常测试用例
- [测试：无效参数错误](tests/test_invalid_parameters.py)：验证无效参数错误处理
- [测试：边界设置失败](tests/test_invalid_bounds.py)：验证边界设置失败情况
- [测试：未初始化地图](tests/test_uninitialized_map.py)：验证未初始化地图时的错误处理