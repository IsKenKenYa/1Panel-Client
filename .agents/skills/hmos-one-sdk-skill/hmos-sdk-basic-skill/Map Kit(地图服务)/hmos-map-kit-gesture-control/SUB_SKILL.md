---
name: hmos-map-kit-gesture-control
description: 控制地图手势交互的启用与禁用，支持缩放、滚动、旋转、倾斜手势的独立控制，适用于地图交互定制、权限限制、特定场景锁定场景，API版本从4.1.0(11)开始支持
---

# 地图手势控制技能

## 功能描述

本技能提供地图手势交互的精细化控制能力，通过MapComponentController类提供的接口，可以独立启用或禁用缩放、滚动、旋转、倾斜等手势，以及通过setAllGesturesEnabled方法一键控制所有手势的启用状态。手势控制不影响缩放控件和相机移动接口的正常使用。

**核心能力**：
- 缩放手势控制：单指双击放大、双指单击缩小、双指捏合缩放
- 滚动手势控制：单指拖动平移地图
- 旋转手势控制：双指旋转改变地图方向
- 倾斜手势控制：双指上下滑动调整视角
- 全局手势控制：一键启用/禁用所有手势

## 使用场景

### 触发词
- "启用地图缩放手势"
- "禁用地图滚动手势"
- "控制地图旋转手势"
- "设置地图倾斜手势"
- "禁用所有地图手势"
- "地图手势控制"
- "地图交互限制"

### 能做
- 启用或禁用特定的地图手势（缩放、滚动、旋转、倾斜）
- 一键启用或禁用所有地图手势
- 在地图初始化时通过MapOptions配置手势状态
- 运行时动态切换手势的启用状态
- 获取当前手势的启用状态

### 绝不做
- 不控制缩放控件（缩放按钮）的显示状态
- 不限制通过API接口（如animateCamera、moveCamera）移动相机
- 不处理地图Marker、Circle等覆盖物的交互
- 不控制指南针点击重置相机方向的行为

### 补充
- 默认情况下所有手势均处于启用状态
- 禁用手势后，用户无法通过手势操作地图，但可通过API接口或控件操作
- 手势控制需要在地图初始化完成后调用（mapController对象获取后）
- 仅支持Stage模型，元服务API从版本4.1.0(11)开始支持

## 调用规范和规则

### 输入约束
- mapController对象：必须已初始化并成功获取
- enabled参数：boolean类型，true表示启用，false表示禁用
- 调用时机：必须在地图初始化回调中或自定义方法中调用

### 执行约束
- API调用频次：无限制，可随时调用
- 执行模式：同步执行，立即生效
- 前置条件：MapComponent已成功初始化

### 内容约束
- 禁止在地图初始化前调用手势控制方法
- 禁止传入非boolean类型的参数
- 禁止在null或undefined的mapController对象上调用方法

### 降级约束
- mapController未初始化：提示用户等待地图加载完成
- 参数类型错误：自动转换为boolean类型或使用默认值
- 调用失败：记录错误日志，不影响地图其他功能

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认已导入@kit.MapKit模块
2. 确认已创建MapComponent组件
3. 确认已定义mapController变量用于存储控制器对象
4. 确认已定义地图初始化回调函数

**参数准备**：
```typescript
import { map, mapCommon } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct MapGestureDemo {
  private mapOptions?: mapCommon.MapOptions;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;
  
  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: { latitude: 39.9, longitude: 116.4 },
        zoom: 10
      }
    };
    
    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        this.configureGestures();
      }
    };
  }
}
```

### 步骤2：控制缩放手势

**示例代码**：
```typescript
private configureGestures(): void {
  if (!this.mapController) {
    console.error('MapController not initialized');
    return;
  }
  
  try {
    this.mapController.setZoomGesturesEnabled(true);
    console.info('Zoom gestures enabled');
  } catch (error) {
    console.error('Failed to set zoom gestures:', error);
  }
}
```

**功能说明**：
- 启用缩放手势后，支持单指双击放大、双指单击缩小、双指捏合操作
- 禁用后手势无效，但缩放控件和API接口仍可使用

### 步骤3：控制滚动手势

**示例代码**：
```typescript
private configureScrollGesture(): void {
  if (!this.mapController) {
    console.error('MapController not initialized');
    return;
  }
  
  try {
    this.mapController.setScrollGesturesEnabled(true);
    console.info('Scroll gestures enabled');
  } catch (error) {
    console.error('Failed to set scroll gestures:', error);
  }
}
```

**功能说明**：
- 启用滚动手势后，用户可通过滑动平移地图
- 禁用后滑动无效，但moveCamera等API接口仍可使用

### 步骤4：控制旋转手势

**示例代码**：
```typescript
private configureRotateGesture(): void {
  if (!this.mapController) {
    console.error('MapController not initialized');
    return;
  }
  
  try {
    this.mapController.setRotateGesturesEnabled(true);
    console.info('Rotate gestures enabled');
  } catch (error) {
    console.error('Failed to set rotate gestures:', error);
  }
}
```

**功能说明**：
- 启用旋转手势后，用户可通过双指旋转改变地图方向
- 禁用后手势无效，但点击指南针重置方向仍有效

### 步骤5：控制倾斜手势

**示例代码**：
```typescript
private configureTiltGesture(): void {
  if (!this.mapController) {
    console.error('MapController not initialized');
    return;
  }
  
  try {
    this.mapController.setTiltGesturesEnabled(true);
    console.info('Tilt gestures enabled');
  } catch (error) {
    console.error('Failed to set tilt gestures:', error);
  }
}
```

**功能说明**：
- 启用倾斜手势后，用户可通过双指上下滑动调整视角
- 禁用后无法通过手势倾斜地图

### 步骤6：全局手势控制

**示例代码**：
```typescript
private disableAllGestures(): void {
  if (!this.mapController) {
    console.error('MapController not initialized');
    return;
  }
  
  try {
    this.mapController.setAllGesturesEnabled(false);
    console.info('All gestures disabled');
  } catch (error) {
    console.error('Failed to disable gestures:', error);
  }
}

private enableAllGestures(): void {
  if (!this.mapController) {
    console.error('MapController not initialized');
    return;
  }
  
  try {
    this.mapController.setAllGesturesEnabled(true);
    console.info('All gestures enabled');
  } catch (error) {
    console.error('Failed to enable gestures:', error);
  }
}
```

**功能说明**：
- setAllGesturesEnabled(false)一键禁用所有手势
- setAllGesturesEnabled(true)一键启用所有手势
- 不影响缩放控件、指南针点击、API接口的使用

### 步骤7：查询手势状态

**示例代码**：
```typescript
private checkGestureStatus(): void {
  if (!this.mapController) {
    console.error('MapController not initialized');
    return;
  }
  
  try {
    const zoomEnabled: boolean = this.mapController.isZoomGesturesEnabled();
    const scrollEnabled: boolean = this.mapController.isScrollGesturesEnabled();
    const rotateEnabled: boolean = this.mapController.isRotateGesturesEnabled();
    const tiltEnabled: boolean = this.mapController.isTiltGesturesEnabled();
    
    console.info(`Gesture status:
      Zoom: ${zoomEnabled}
      Scroll: ${scrollEnabled}
      Rotate: ${rotateEnabled}
      Tilt: ${tiltEnabled}`);
  } catch (error) {
    console.error('Failed to check gesture status:', error);
  }
}
```

### 步骤8：地图初始化配置手势

**示例代码**：
```typescript
aboutToAppear(): void {
  this.mapOptions = {
    position: {
      target: { latitude: 39.9, longitude: 116.4 },
      zoom: 10
    },
    rotateGesturesEnabled: false,
    scrollGesturesEnabled: true,
    zoomGesturesEnabled: true,
    tiltGesturesEnabled: false
  };
  
  this.callback = async (err, mapController) => {
    if (!err) {
      this.mapController = mapController;
    }
  };
}

build() {
  Stack() {
    MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
      .width('100%')
      .height('100%')
  }.height('100%')
}
```

**功能说明**：
- 通过MapOptions在地图初始化时配置手势状态
- 各手势默认值为true（启用状态）

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Invalid input parameter | 检查参数类型是否为boolean |
| 1002601001 | The object to be operated does not exist | 确认mapController对象已初始化 |
| - | MapController未初始化 | 等待地图初始化回调完成后再调用 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.MapKit": "^4.1.0",
    "@kit.BasicServicesKit": "^4.1.0"
  }
}
```

### 环境要求
- HarmonyOS API版本：>= 4.1.0(11)
- 运行环境：Stage模型
- 元服务支持：从版本4.1.0(11)开始

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.MapKit'
```
**解决方法**：确保项目已配置HarmonyOS SDK，并在oh-package.json5中添加依赖声明

**问题2：MapComponent未找到**
```
Error: MapComponent is not defined
```
**解决方法**：确保已正确导入map和mapCommon模块

**问题3：mapController为undefined**
```
TypeError: Cannot read property 'setZoomGesturesEnabled' of undefined
```
**解决方法**：确保在地图初始化回调中获取mapController对象，避免在初始化完成前调用

## 常见问题与解决方法

### Q1：禁用手势后缩放控件还能用吗？
**原因**：手势控制仅禁用手势操作，不影响缩放控件
**解决方法**：
- 如需同时禁用缩放控件，调用setZoomControlsEnabled(false)
- 如需禁用所有用户交互，结合手势和控件控制

### Q2：如何恢复被禁用的手势？
**原因**：调用set方法传入true参数即可恢复
**解决方法**：
- 调用setZoomGesturesEnabled(true)恢复缩放手势
- 调用setAllGesturesEnabled(true)恢复所有手势

### Q3：地图初始化时如何设置手势？
**原因**：MapOptions支持手势参数配置
**解决方法**：
- 在MapOptions中设置rotateGesturesEnabled等参数
- 参数默认值为true，设置为false可禁用对应手势

### Q4：旋转手势禁用后指南针还能用吗？
**原因**：指南针点击重置方向不受旋转手势控制影响
**解决方法**：
- 如需禁用指南针交互，调用setCompassControlsEnabled(false)
- 旋转手势仅控制双指旋转手势

### Q5：调用时机错误导致无效？
**原因**：mapController对象未初始化完成
**解决方法**：
- 确保在地图初始化回调(err, mapController)中调用
- 避免在aboutToAppear中直接调用（应在回调中调用）

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "gestureConfig": {
    "zoom": boolean,
    "scroll": boolean,
    "rotate": boolean,
    "tilt": boolean
  },
  "apiUsed": [
    "MapComponentController.setZoomGesturesEnabled",
    "MapComponentController.setScrollGesturesEnabled",
    "MapComponentController.setRotateGesturesEnabled",
    "MapComponentController.setTiltGesturesEnabled",
    "MapComponentController.setAllGesturesEnabled",
    "MapComponentController.isZoomGesturesEnabled",
    "MapComponentController.isScrollGesturesEnabled",
    "MapComponentController.isRotateGesturesEnabled",
    "MapComponentController.isTiltGesturesEnabled"
  ],
  "apiVersion": "4.1.0(11)",
  "modelConstraint": "Stage模型",
  "metaServiceSupport": "从版本4.1.0(11)开始支持"
}
```

## 参考文档

- [API开发指南 - 手势交互](references/map-controls-and-gestures.md)
- [API参考说明 - MapComponentController](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller)
- [API参考说明 - mapCommon](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common)
- [开发指南 - 显示地图](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/map-presenting)

## 完整示例代码

- [ArkTS示例 - 地图手势控制](assets/map_gesture_control.ets)

## 测试用例

### 正向测试用例
- [启用所有手势](tests/test_enable_all_gestures.ets)：验证所有手势可正常启用
- [禁用单个手势](tests/test_disable_single_gesture.ets)：验证单个手势禁用后其他手势仍可用

### 边界测试用例
- [重复启用已启用的手势](tests/test_repeated_enable.ets)：验证重复调用不产生错误
- [mapController未初始化调用](tests/test_uninitialized_controller.ets)：验证错误处理机制

### 异常测试用例
- [传入非boolean参数](tests/test_invalid_parameter.ets)：验证参数类型错误的处理
- [null mapController调用](tests/test_null_controller.ets)：验证空对象调用的错误处理