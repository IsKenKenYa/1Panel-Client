---
name: hmos-map-kit-draw-circle
description: 在地图上绘制圆形覆盖物+指定圆心经纬度和半径+圆心纬度范围[-85.051119, 85.051119]+适用于表示服务覆盖范围、地理围栏、兴趣点影响区域
---

# 在地图上绘制圆形技能

## 功能描述

本技能用于在HarmonyOS地图上添加圆形覆盖物，通过指定圆心经纬度和半径来绘制圆形区域。圆形常用于表示特定区域的服务覆盖范围、地理围栏或兴趣点的影响区域。支持自定义圆的样式，包括填充颜色、边框颜色、边框宽度、边框样式等属性，并支持设置圆形的点击事件和层级顺序。

## 使用场景

### 触发词
- "在地图上画圆"
- "绘制圆形"
- "添加圆形覆盖物"
- "显示服务覆盖范围"
- "创建地理围栏"
- "标注影响区域"

### 能做
- 在地图上添加一个圆形覆盖物
- 设置圆形的中心点位置（经纬度坐标）
- 设置圆形的半径（单位：米）
- 自定义圆形的填充颜色和边框样式
- 设置圆形的点击响应
- 设置圆形的层级顺序（zIndex）
- 动态更新圆形的位置、大小和样式
- 查询圆形的当前属性值

### 绝不做
- 不绘制超出纬度范围的圆形（纬度必须在[-85.051119, 85.051119]范围内）
- 不处理地图初始化之前添加圆形的请求
- 不提供地理围栏的业务逻辑判断（仅绘制圆形）
- 不自动计算最优半径值

### 补充
- 圆心纬度为-85.051119或85.051119时，仅能画出半径为1米的圆
- 圆形的半径单位为米，需要根据实际需求设置合适的数值
- 颜色值为ARGB格式，例如0xFFFFC100表示黄色
- 圆形属于地图覆盖物，可通过clear()方法清除所有覆盖物

## 调用规范和规则

### 输入约束
- 圆心纬度范围：[-85.051119, 85.051119]，超出范围将无法正确绘制
- 圆心经度范围：[-180, 180)
- 圆形半径：大于等于0，单位：米，异常值按默认值（0）处理
- 边框宽度：大于等于0，单位：px，异常值按默认值（10）处理
- 颜色值：ARGB格式数值，异常值按默认值处理
- zIndex层级：数值类型，异常值按默认值（0）处理

### 执行约束
- 必须在地图初始化完成后调用addCircle方法
- 使用异步Promise方式调用，需要等待返回结果
- 圆形添加操作耗时：预计小于100ms
- 建议在地图回调函数中执行圆形添加逻辑

### 内容约束
- 禁止使用无效的经纬度坐标
- 禁止在地图控制器未初始化时调用addCircle
- 禁止使用负数作为半径或边框宽度
- 禁止在圆形对象创建前调用属性更新方法

### 降级约束
- 参数无效（错误码401）：检查参数类型和取值范围，修正后重新调用
- 地图对象不存在（错误码1002601001）：确保地图控制器已正确初始化
- 纬度超出范围：提示用户调整圆心纬度至有效范围
- 圆形添加失败：捕获异常并记录错误日志，提供用户友好的提示信息

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 验证地图控制器已初始化（mapController不为null或undefined）
2. 验证圆心坐标的纬度在有效范围内（[-85.051119, 85.051119]）
3. 验证半径值为正数或0

**参数准备**：
```typescript
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct MapCircleDemo {
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapCircle?: map.MapCircle;
  
  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 39.918,
          longitude: 116.397
        },
        zoom: 14
      }
    };
    
    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
      } else {
        console.error(`Map initialization failed: code=${err.code}, message=${err.message}`);
      }
    };
  }
}
```

### 步骤2：调用API添加圆形

**示例代码**：
```typescript
async addMapCircle(): Promise<void> {
  if (!this.mapController) {
    console.error('Map controller is not initialized');
    return;
  }
  
  let mapCircleOptions: mapCommon.MapCircleOptions = {
    center: {
      latitude: 39.918,
      longitude: 116.397
    },
    radius: 500,
    clickable: true,
    fillColor: 0xFFFFC100,
    strokeColor: 0xFFFF0000,
    strokeWidth: 10,
    visible: true,
    zIndex: 15
  };
  
  try {
    this.mapCircle = await this.mapController.addCircle(mapCircleOptions);
    console.info('Map circle added successfully');
  } catch (e) {
    console.error(`Failed to add map circle: code=${e.code}, message=${e.message}`);
  }
}
```

### 步骤3：错误处理

```typescript
async addMapCircleWithErrorHandling(): Promise<map.MapCircle | null> {
  if (!this.mapController) {
    console.error('Map controller is not initialized');
    return null;
  }
  
  let mapCircleOptions: mapCommon.MapCircleOptions = {
    center: {
      latitude: 39.918,
      longitude: 116.397
    },
    radius: 500
  };
  
  try {
    let mapCircle = await this.mapController.addCircle(mapCircleOptions);
    return mapCircle;
  } catch (error) {
    switch (error.code) {
      case 401:
        console.error('Invalid input parameter. Please check circle options.');
        break;
      case 1002601001:
        console.error('The object to be operated does not exist. Map controller may be invalid.');
        break;
      default:
        console.error(`Unknown error: code=${error.code}, message=${error.message}`);
    }
    return null;
  }
}
```

### 步骤4：更新圆形属性

```typescript
updateCircleProperties(): void {
  if (!this.mapCircle) {
    console.error('Map circle is not created');
    return;
  }
  
  this.mapCircle.setCenter({
    latitude: 40.0,
    longitude: 116.5
  });
  
  this.mapCircle.setRadius(1000);
  this.mapCircle.setFillColor(0xFF00FF00);
  this.mapCircle.setStrokeColor(0xFF0000FF);
  this.mapCircle.setStrokeWidth(15);
  this.mapCircle.setClickable(true);
  
  console.info('Circle properties updated successfully');
}
```

### 步骤5：查询圆形属性

```typescript
queryCircleProperties(): void {
  if (!this.mapCircle) {
    console.error('Map circle is not created');
    return;
  }
  
  let center = this.mapCircle.getCenter();
  let radius = this.mapCircle.getRadius();
  let fillColor = this.mapCircle.getFillColor();
  let strokeColor = this.mapCircle.getStrokeColor();
  let strokeWidth = this.mapCircle.getStrokeWidth();
  let clickable = this.mapCircle.isClickable();
  
  console.info(`Circle center: lat=${center.latitude}, lon=${center.longitude}`);
  console.info(`Circle radius: ${radius} meters`);
  console.info(`Fill color: ${fillColor}`);
  console.info(`Stroke color: ${strokeColor}`);
  console.info(`Stroke width: ${strokeWidth} px`);
  console.info(`Clickable: ${clickable}`);
}
```

### 步骤6：降级处理

```typescript
async addCircleWithFallback(): Promise<void> {
  let mapCircleOptions: mapCommon.MapCircleOptions = {
    center: {
      latitude: 39.918,
      longitude: 116.397
    },
    radius: 500
  };
  
  try {
    if (this.mapController) {
      this.mapCircle = await this.mapController.addCircle(mapCircleOptions);
    } else {
      console.warn('Map controller not ready, circle will be added later');
    }
  } catch (error) {
    console.warn(`Circle addition failed: ${error.message}`);
    console.info('Fallback: Displaying area information without visual circle');
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 输入参数无效 | 检查MapCircleOptions参数类型和取值范围，确保center和radius为必填参数且值有效 |
| 1002601001 | 操作对象不存在 | 确保地图控制器已正确初始化，在地图回调函数中调用addCircle方法 |
| 纬度超范围 | 圆心纬度不在[-85.051119, 85.051119]范围内 | 调整圆心纬度至有效范围内，接近边界值时半径限制为1米 |
| 半径无效 | 半径值为负数或非数值类型 | 设置半径为大于等于0的正数，单位为米 |
| 颜色格式错误 | 颜色值不符合ARGB格式 | 使用正确的ARGB格式，如0xFFFFC100 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.MapKit": "4.1.0(11)",
    "@kit.BasicServicesKit": "4.1.0(11)"
  }
}
```

### 环境要求
- HarmonyOS SDK：最低版本4.1.0(11)
- 开发环境：DevEco Studio 4.1或更高版本
- 运行环境：HarmonyOS设备或模拟器（支持Stage模型）

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.MapKit'
```
**解决方法**：确保项目依赖已正确配置，在oh-package.json5中添加@kit.MapKit依赖，并执行npm install或ohpm install。

**问题2：类型定义错误**
```
Error: Property 'addCircle' does not exist on type 'MapComponentController'
```
**解决方法**：检查导入语句是否包含map模块，使用`import { map, mapCommon } from '@kit.MapKit'`。

**问题3：异步调用未等待**
```
Warning: Promise returned from addCircle is ignored
```
**解决方法**：使用async/await或.then()处理Promise返回值，确保异步操作完成。

**问题4：地图控制器未初始化**
```
Runtime Error: Cannot read property 'addCircle' of undefined
```
**解决方法**：在地图初始化回调函数中获取mapController，确保回调执行后再调用addCircle。

## 常见问题与解决方法

### Q1：圆形无法显示在地图上
**原因**：
- 地图控制器未正确初始化
- 圆心纬度超出有效范围
- 圆形半径设置过小或为0
- visible属性设置为false
- zIndex层级被其他覆盖物遮挡

**解决方法**：
- 在地图回调函数中确认mapController已初始化
- 检查圆心纬度是否在[-85.051119, 85.051119]范围内
- 设置合理的半径值（建议大于100米）
- 确保visible属性为true
- 调整zIndex值确保圆形不被遮挡

### Q2：圆形点击事件无响应
**原因**：clickable属性未设置为true

**解决方法**：
- 在MapCircleOptions中设置clickable: true
- 添加圆形点击事件监听器（需要使用MapEventManager）

### Q3：圆形颜色不符合预期
**原因**：颜色值格式错误或使用错误的颜色值

**解决方法**：
- 使用ARGB格式颜色值，如0xFFFFC100（黄色）
- fillColor为填充颜色，strokeColor为边框颜色
- 注意颜色值的透明度（Alpha通道）

### Q4：圆形半径单位混淆
**原因**：误将半径单位理解为像素而非米

**解决方法**：
- radius参数单位为米，与实际地理距离对应
- 根据实际需求设置半径，如500表示500米范围
- 可通过getScalePerPixel()方法换算像素和米的对应关系

### Q5：圆形添加后立即被清除
**原因**：调用了mapController.clear()方法

**解决方法**：
- 避免在添加圆形后立即调用clear()方法
- clear()会清除所有覆盖物，包括Marker、Circle、Polyline等
- 如需单独清除圆形，使用mapCircle对象的方法或重新添加

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "circleId": "MapCircle对象实例",
  "center": {
    "latitude": 39.918,
    "longitude": 116.397
  },
  "radius": 500,
  "properties": {
    "fillColor": "0xFFFFC100",
    "strokeColor": "0xFFFF0000",
    "strokeWidth": 10,
    "clickable": true,
    "visible": true,
    "zIndex": 15
  },
  "apiUsed": [
    "mapCommon.MapCircleOptions",
    "map.MapComponentController.addCircle",
    "map.MapCircle"
  ]
}
```

## 参考文档

- [圆形开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/map-circle)
- [MapCircleOptions API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common)
- [addCircle API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller)
- [MapCircle API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcircle)

## 完整示例代码

- [ArkTS完整示例](assets/map-circle-demo.ets)
- [圆形样式配置示例](assets/circle-style-config.json)

## 测试用例

### 正向测试用例
- [添加圆形基本功能](tests/test_add_circle_positive.ets)：测试正常添加圆形的基本功能
- [圆形属性更新](tests/test_update_circle_properties.ets)：测试更新圆形的各项属性
- [圆形属性查询](tests/test_query_circle_properties.ets)：测试查询圆形的当前属性值

### 边界测试用例
- [极限纬度测试](tests/test_latitude_boundary.ets)：测试纬度接近边界值（85.051119）时的圆形绘制
- [最小半径测试](tests/test_minimum_radius.ets)：测试半径为0和1米时的圆形绘制
- [最大层级测试](tests/test_zindex_boundary.ets)：测试zIndex的边界值效果

### 异常测试用例
- [无效圆心坐标](tests/test_invalid_center.ets)：测试超出范围的经纬度坐标
- [未初始化地图控制器](tests/test_uninitialized_controller.ets)：测试在地图未初始化时添加圆形
- [参数类型错误](tests/test_invalid_parameter_type.ets)：测试参数类型不符合要求的场景