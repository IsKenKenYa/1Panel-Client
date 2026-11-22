---
name: hmos-map-kit-flow-field-overlay
description: 在地图上添加流场图层，可视化显示动态流动信息如风场、洋流等，支持GRIB2格式数据，适用于气象展示、海洋监测场景
---

# 流场图层技能

## 功能描述

本技能用于在HarmonyOS地图上添加流场图层（FlowFieldOverlay），实现动态流体运动状态的可视化展示。流场图层可以在基础地图之上叠加矢量数据，以粒子动画形式展示流体（如风场、洋流）的运动方向和速度。

**核心能力**：
- 添加流场图层到地图组件
- 配置粒子样式（数量、颜色、速度等）
- 设置GRIB2格式的流场数据
- 动态更新粒子样式

**技术特点**：
- 支持GRIB2规范的JSON数据格式
- 粒子动画可视化流体运动
- 可自定义粒子数量、颜色、速度等参数
- 需要API版本6.0.0(20)及以上

## 使用场景

### 触发词
- "添加流场图层"
- "显示风场"
- "展示洋流"
- "流场可视化"
- "动态流体显示"
- "风场图层"
- "FlowFieldOverlay"

### 能做
- 在地图上添加流场图层显示风场数据
- 在地图上添加流场图层显示洋流数据
- 配置流场粒子的样式（颜色、数量、速度）
- 动态更新流场粒子样式
- 展示实时流体运动状态

### 绝不做
- 不处理非GRIB2格式的流场数据
- 不在API版本低于6.0.0(20)的环境中使用
- 不添加超过10000个粒子的流场图层（性能限制）
- 不在非Stage模型中使用（仅支持Stage模型）
- 不处理实时流场数据获取（仅负责展示，数据需开发者自行获取）

### 补充
- 流场数据需符合GRIB2规范的JSON格式
- 粒子数量建议小于10000以保证性能
- 需要提前准备好流场数据（风场或洋流的U/V方向数据）
- 数据格式参见流场数据格式参考

## 调用规范和规则

### 输入约束
- **数据格式**：必须为GRIB2规范的JSON字符串格式
- **数据完整性**：必须包含U方向（横向）和V方向（纵向）两个数据对象
- **粒子数量**：建议小于10000，默认2000
- **颜色格式**：ARGB格式（如0xff0000ff）
- **最大速度**：建议小于255 m/s，默认70 m/s
- **速度因子**：取值范围[0, 1]，默认0.2

### 执行约束
- **API版本**：必须 >= 6.0.0(20)
- **模型类型**：仅支持Stage模型
- **系统能力**：需要SystemCapability.Map.Core.EnhancedOverlay
- **前置条件**：必须先初始化MapComponentController
- **异步调用**：所有API调用都是异步的，需要使用async/await

### 内容约束
- **禁止空数据**：data参数不能为空字符串
- **禁止无效JSON**：data必须是有效的JSON字符串
- **禁止超大数据**：粒子数量超过10000可能导致性能问题
- **禁止非法颜色**：颜色值必须是有效的ARGB格式数字
- **禁止非法速度因子**：speedFactor必须在[0, 1]范围内

### 降级约束
- **API版本不满足**：提示用户需要API版本6.0.0(20)及以上
- **数据格式错误**：提示用户检查GRIB2数据格式，提供格式参考文档
- **性能问题**：建议减少粒子数量至2000以下
- **添加失败**：检查mapController是否正确初始化，检查数据有效性

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查API版本是否 >= 6.0.0(20)
2. 检查是否在Stage模型下运行
3. 验证MapComponentController已正确初始化
4. 确认流场数据已准备好且符合GRIB2格式

**模块导入**：
```typescript
import { mapCommon, map, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
```

### 步骤2：准备流场数据

**GRIB2数据格式准备**：
```typescript
// 流场数据必须包含U方向和V方向两个对象
const flowFieldData = `[
  {
    "header": {
      "parameterUnit": "m.s-1",
      "parameterNumber": 2,       // 2为U方向（横向）
      "dx": 10,                   // 横向步长（经度）
      "dy": 20,                   // 纵向步长（纬度）
      "parameterNumberName": "U-component-wind",
      "la2": -90,                 // 纬度范围终点
      "la1": 90,                  // 纬度范围起点
      "parameterCategory": 2,
      "lo1": 0,                   // 经度范围起点
      "lo2": 359.75,              // 经度范围终点
      "nx": 4,                    // 横向格子数量
      "ny": 4,                    // 纵向格子数量
      "numberPoints": 16          // 数据点数量
    },
    "data": [2, 2, 2, 2, 2, 2, 2, 2, -10, -10, -1, -1, -1, -1, -3, 2]  // 横向速度数据
  },
  {
    "header": {
      "parameterUnit": "m.s-1",
      "parameterNumber": 3,       // 3为V方向（纵向）
      "dx": 4,
      "dy": 4,
      "parameterNumberName": "V-component-wind",
      "la2": -90,
      "la1": 90,
      "parameterCategory": 2,
      "lo1": 0,
      "lo2": 359.75,
      "nx": 4,
      "ny": 4,
      "numberPoints": 16
    },
    "data": [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -1, -1, -2, -3, -1]  // 纵向速度数据
  }
]`;
```

**数据格式验证**：
```typescript
// 验证数据格式
function validateFlowFieldData(data: string): boolean {
  try {
    const parsedData = JSON.parse(data);
    if (!Array.isArray(parsedData) || parsedData.length !== 2) {
      return false;
    }
    for (const item of parsedData) {
      if (!item.header || !item.data) {
        return false;
      }
      if (item.data.length !== item.header.numberPoints) {
        return false;
      }
    }
    return true;
  } catch (error) {
    return false;
  }
}
```

### 步骤3：添加流场图层

**核心API调用**：
```typescript
async function addFlowFieldOverlay(
  mapController: map.MapComponentController,
  flowData: string
): Promise<map.FlowFieldOverlay> {
  try {
    // 构建流场参数
    const params: mapCommon.FlowFieldOverlayParams = {
      data: flowData,
      style: {
        count: 2000,              // 粒子数量
        color: 0xff0000ff,        // 粒子颜色（ARGB格式）
        maxSpeed: 100,            // 最大速度 m/s
        speedFactor: 1            // 速度因子
      }
    };
    
    // 添加流场图层
    const fieldOverlay = await mapController.addFlowFieldOverlay(params);
    console.info('Flow field overlay added successfully');
    return fieldOverlay;
  } catch (error) {
    console.error('Failed to add flow field overlay:', error);
    throw error;
  }
}
```

### 步骤4：动态更新粒子样式

**更新粒子样式**：
```typescript
async function updateFlowFieldStyle(
  fieldOverlay: map.FlowFieldOverlay,
  newStyle: mapCommon.ParticleStyle
): Promise<void> {
  try {
    // 设置新的粒子样式
    fieldOverlay.setStyle(newStyle);
    console.info('Flow field style updated successfully');
    
    // 获取当前样式验证
    const currentStyle = fieldOverlay.getStyle();
    console.info('Current particle count:', currentStyle.count);
    console.info('Current particle color:', currentStyle.color);
  } catch (error) {
    console.error('Failed to update flow field style:', error);
    throw error;
  }
}
```

### 步骤5：完整示例集成

**完整组件示例**：
```typescript
@Entry
@Component
struct MapFlowFieldOverlayDemo {
  private TAG = "MapFlowFieldOverlayDemo";
  private mapOption?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private fieldOverlay?: map.FlowFieldOverlay;

  aboutToAppear(): void {
    // 初始化地图配置
    this.mapOption = {
      position: {
        target: {
          latitude: 31.984410259206815,
          longitude: 118.76625379397866
        },
        zoom: 4
      },
      scaleControlsEnabled: true
    };

    // 地图初始化回调
    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        
        // 准备流场数据
        const flowData = `[{
          "header": {
            "parameterUnit": "m.s-1",
            "parameterNumber": 2,
            "dx": 10,
            "dy": 20,
            "parameterNumberName": "U-component-wind",
            "la2": -90,
            "la1": 90,
            "parameterCategory": 2,
            "lo1": 0,
            "lo2": 359.75,
            "ny": 4,
            "nx": 4,
            "numberPoints": 16
          },
          "data": [2, 2, 2, 2, 2, 2, 2, 2, -10, -10, -1, -1, -1, -1, -3, 2]
        }, {
          "header": {
            "parameterUnit": "m.s-1",
            "parameterNumber": 3,
            "dx": 4,
            "dy": 4,
            "parameterNumberName": "V-component-wind",
            "la2": -90,
            "la1": 90,
            "parameterCategory": 2,
            "lo1": 0,
            "lo2": 359.75,
            "ny": 4,
            "nx": 4,
            "numberPoints": 16
          },
          "data": [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -1, -1, -2, -3, -1]
        }]`;

        // 构建流场参数
        const params: mapCommon.FlowFieldOverlayParams = {
          data: flowData,
          style: {
            count: 2000,
            color: 0xff0000ff,
            maxSpeed: 100,
            speedFactor: 1
          }
        };

        try {
          // 添加流场图层
          this.fieldOverlay = await this.mapController?.addFlowFieldOverlay(params);
          console.info(this.TAG, 'Flow field overlay added');
        } catch (e) {
          console.error(this.TAG, `Add failed, code:${e.code}, message:${e.message}`);
        }
      } else {
        console.error(this.TAG, `Map init failed, code:${err.code}, message:${err.message}`);
      }
    };
  }

  build() {
    Stack() {
      Column() {
        MapComponent({ mapOptions: this.mapOption, mapCallback: this.callback })
          .width('100%')
          .height('100%');
      }.width('100%')
    }.height('100%')
  }
}
```

### 步骤6：错误处理

**错误处理代码**：
```typescript
async function addFlowFieldWithErrorHandling(
  mapController: map.MapComponentController,
  flowData: string
): Promise<map.FlowFieldOverlay | null> {
  try {
    // 前置校验
    if (!validateFlowFieldData(flowData)) {
      throw new Error('Invalid GRIB2 data format');
    }
    
    const params: mapCommon.FlowFieldOverlayParams = {
      data: flowData,
      style: {
        count: 2000,
        color: 0xff0000ff,
        maxSpeed: 100,
        speedFactor: 1
      }
    };
    
    const fieldOverlay = await mapController.addFlowFieldOverlay(params);
    return fieldOverlay;
    
  } catch (error: any) {
    // 错误码处理
    switch (error.code) {
      case 1022100001:
        console.error('Operation object does not exist. Check mapController initialization.');
        break;
      case 401:
        console.error('Invalid input parameter. Check data format and style values.');
        break;
      default:
        console.error('Unknown error:', error.message);
    }
    return null;
  }
}
```

### 步骤7：降级处理

**降级方案**：
```typescript
async function addFlowFieldWithFallback(
  mapController: map.MapComponentController,
  flowData: string
): Promise<void> {
  try {
    // 尝试添加流场图层
    const params: mapCommon.FlowFieldOverlayParams = {
      data: flowData,
      style: {
        count: 2000,
        color: 0xff0000ff,
        maxSpeed: 100,
        speedFactor: 1
      }
    };
    
    const fieldOverlay = await mapController.addFlowFieldOverlay(params);
    console.info('Flow field overlay added successfully');
    
  } catch (error: any) {
    console.warn('Failed to add flow field overlay, using fallback strategy');
    
    // 降级方案1：减少粒子数量
    try {
      const fallbackParams: mapCommon.FlowFieldOverlayParams = {
        data: flowData,
        style: {
          count: 1000,  // 减少粒子数量
          color: 0xff0000ff,
          maxSpeed: 50,  // 降低最大速度
          speedFactor: 0.5
        }
      };
      
      await mapController.addFlowFieldOverlay(fallbackParams);
      console.warn('Flow field overlay added with reduced particle count');
      
    } catch (fallbackError) {
      // 降级方案2：完全失败时提示用户
      console.error('All fallback strategies failed');
      console.error('Please check:');
      console.error('1. API version >= 6.0.0(20)');
      console.error('2. GRIB2 data format is correct');
      console.error('3. MapComponentController is properly initialized');
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1022100001 | 操作对象不存在 | 检查mapController是否正确初始化，确保在MapComponent回调中获取 |
| 401 | 输入参数无效 | 检查FlowFieldOverlayParams参数：data格式、style各参数取值范围 |
| 数据格式错误 | GRIB2数据格式不正确 | 检查数据是否包含U/V两个方向，header字段是否完整，data数组长度是否匹配numberPoints |
| API版本不满足 | API版本低于6.0.0(20) | 升级HarmonyOS SDK至6.0.0(20)或以上版本 |
| 系统能力不足 | 缺少SystemCapability.Map.Core.EnhancedOverlay | 检查设备是否支持EnhancedOverlay系统能力 |

## 编译和修复问题

### 依赖声明

**oh-package.json5**：
```json
{
  "dependencies": {
    "@kit.MapKit": "^6.0.0",
    "@kit.BasicServicesKit": "^6.0.0"
  }
}
```

### 环境要求
- **HarmonyOS SDK**：最低版本6.0.0(20)
- **开发模型**：Stage模型
- **系统能力**：SystemCapability.Map.Core.EnhancedOverlay
- **DevEco Studio**：推荐版本5.0+

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.MapKit'
```
**解决方法**：
1. 检查oh-package.json5中是否正确声明依赖
2. 运行`ohpm install`安装依赖
3. 确认HarmonyOS SDK版本 >= 6.0.0(20)

**问题2：API不存在**
```
Error: Property 'addFlowFieldOverlay' does not exist on type 'MapComponentController'
```
**解决方法**：
1. 确认API版本 >= 6.0.0(20)
2. 检查导入语句：`import { map, mapCommon, MapComponent } from '@kit.MapKit'`
3. 确认mapController类型为`map.MapComponentController`

**问题3：类型错误**
```
Error: Type 'string' is not assignable to type 'FlowFieldOverlayParams'
```
**解决方法**：
1. 检查params对象结构是否正确
2. 确认style对象包含所有必需字段（count, color, maxSpeed, speedFactor）
3. 验证data字段为string类型

**问题4：异步调用错误**
```
Error: await is only allowed in async function
```
**解决方法**：
1. 确认函数声明包含`async`关键字
2. 在MapComponent回调中使用`async (err, mapController) => {...}`
3. 所有API调用使用`await`

## 常见问题与解决方法

### Q1：流场图层不显示或显示异常
**原因**：
- GRIB2数据格式不正确
- 数据点数量与header.numberPoints不匹配
- 粒子数量设置过大导致性能问题

**解决方法**：
- 检查数据是否包含U和V两个方向的对象
- 确认data数组长度等于header.numberPoints
- 将粒子数量减少至2000以下测试

### Q2：添加流场图层时报错1022100001
**原因**：mapController未正确初始化或已失效

**解决方法**：
- 确保在MapComponent回调中获取mapController
- 检查回调中`err`参数是否为null
- 确认mapController不为undefined或null

### Q3：粒子动画速度不正确
**原因**：
- maxSpeed或speedFactor设置不合理
- 流场数据速度值超出范围

**解决方法**：
- 调整maxSpeed参数（建议70-100）
- 调整speedFactor参数（范围[0, 1]）
- 检查数据中速度值是否合理

### Q4：颜色显示不正确
**原因**：颜色格式错误或值超出ARGB范围

**解决方法**：
- 确认颜色为ARGB格式（如0xff0000ff）
- 检查颜色值是否为有效的number类型
- 参考示例中的颜色值格式

### Q5：性能问题导致卡顿
**原因**：粒子数量过大或数据量过多

**解决方法**：
- 减少粒子数量至1000-2000
- 减少数据网格密度（降低nx和ny）
- 优化数据更新频率

### Q6：如何在非Stage模型中使用
**原因**：FlowFieldOverlay仅支持Stage模型

**解决方法**：
- 无法在FA模型中使用该API
- 必须迁移至Stage模型
- 参考HarmonyOS Stage模型开发文档

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "overlayId": "FlowFieldOverlay实例对象",
  "particleCount": 2000,
  "particleColor": "0xff0000ff",
  "maxSpeed": 100,
  "speedFactor": 1,
  "dataFormat": "GRIB2 JSON",
  "apiUsed": [
    "mapCommon.FlowFieldOverlayParams",
    "map.MapComponentController.addFlowFieldOverlay",
    "map.FlowFieldOverlay.setStyle",
    "map.FlowFieldOverlay.getStyle"
  ],
  "apiVersion": "6.0.0(20)",
  "modelType": "Stage",
  "systemCapability": "SystemCapability.Map.Core.EnhancedOverlay"
}
```

## 参考文档

- [流场图层开发指南](references/map-flow-field.md)
- [FlowFieldOverlayParams API参考](references/map-common.md)
- [addFlowFieldOverlay API参考](references/map-map-mapcomponentcontroller.md)
- [FlowFieldOverlay API参考](references/map-map-flowfieldoverlay.md)

## 完整示例代码

- [ArkTS完整示例](assets/example_arkts.ets)
- [流场数据示例](assets/flow_field_data.json)

## 测试用例

### 正向测试用例
- [添加基本流场图层](tests/test_positive_01.ets)：使用标准GRIB2数据添加流场图层
- [自定义粒子样式](tests/test_positive_02.ets)：自定义粒子数量、颜色、速度参数
- [动态更新样式](tests/test_positive_03.ets)：添加后动态更新粒子样式

### 边界测试用例
- [最大粒子数量](tests/test_boundary_01.ets)：测试粒子数量10000的性能
- [最小粒子数量](tests/test_boundary_02.ets)：测试粒子数量为1的情况
- [速度因子边界值](tests/test_boundary_03.ets)：测试speedFactor为0和1的情况

### 异常测试用例
- [空数据测试](tests/test_exception_01.ets)：传入空字符串数据
- [无效JSON格式](tests/test_exception_02.ets)：传入非JSON格式字符串
- [数据点数量不匹配](tests/test_exception_03.ets)：data长度与numberPoints不一致
- [未初始化mapController](tests/test_exception_04.ets)：mapController为null时调用
- [颜色格式错误](tests/test_exception_05.ets)：传入非法颜色值