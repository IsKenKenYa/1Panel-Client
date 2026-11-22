---
name: hmos-map-kit-map-polygon
description: 在地图上绘制多边形覆盖物+支持填充颜色、边框样式、空心洞+仅支持Stage模型+适用于标识封闭区域、行政区域边界场景
---

# 地图多边形绘制技能

## 功能描述

在HarmonyOS地图上绘制多边形覆盖物，用于标识小区、学校、商圈等封闭区域范围，以及呈现省、市、区县等行政区域边界。支持自定义填充颜色、边框颜色、边框宽度、拐角样式，支持设置空心洞，支持大地曲线绘制模式。

**核心能力**：
- 绘制多边形覆盖物
- 自定义填充和边框样式
- 设置空心洞
- 支持点击事件
- 支持大地曲线模式

## 使用场景

### 触发词
- "绘制多边形"
- "添加多边形"
- "地图多边形"
- "标识区域范围"
- "行政区域边界"

### 能做
- 在地图上绘制封闭多边形区域
- 设置多边形填充颜色和边框样式
- 在多边形内设置空心洞
- 更新已添加多边形的属性（顶点、颜色、样式等）
- 查询多边形属性（顶点、颜色、样式等）
- 设置多边形点击事件响应

### 绝不做
- 不绘制非封闭区域（少于3个顶点的多边形）
- 不在非Stage模型环境下使用
- 不处理超出纬度范围[-85.2, 85.2]的顶点坐标
- 不绘制顶点坐标异常的多边形

### 补充
- 仅支持Stage模型
- 需要先初始化MapComponent并获取MapComponentController
- 多边形顶点纬度必须在[-85.2, 85.2]范围内
- API起始版本：4.1.0(11)，支持元服务API

## 调用规范和规则

### 输入约束
- **顶点数量**：至少3个顶点组成封闭多边形
- **纬度范围**：顶点纬度必须在[-85.2, 85.2]范围内
- **颜色格式**：ARGB格式（如0xff00DE00），异常值按默认值处理
- **边框宽度**：取值范围[0, ∞)，单位px，默认值10
- **zIndex范围**：整数，默认值0，异常值按默认值处理

### 执行约束
- **调用模式**：异步Promise调用
- **执行时机**：必须在MapComponent初始化回调中或自定义方法中执行
- **错误处理**：必须捕获Promise异常并处理错误码

### 内容约束
- **禁止生成**：禁止在未初始化地图控制器前调用addPolygon
- **禁止操作**：禁止使用超出纬度范围的顶点坐标
- **禁止依赖**：禁止使用未声明的模块（必须导入@kit.MapKit和@kit.BasicServicesKit）

### 降级约束
- **地图初始化失败**：提示用户检查地图配置参数
- **多边形添加失败**：检查顶点坐标是否合法，检查参数格式是否正确
- **权限不足**：提示用户申请必要权限

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 验证MapComponent是否已初始化完成
2. 验证MapComponentController是否可用
3. 验证顶点坐标数组是否包含至少3个点
4. 验证顶点纬度是否在[-85.2, 85.2]范围内

**参数准备**：
```typescript
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

let polygonOptions: mapCommon.MapPolygonOptions = {
  points: [
    { longitude: 118.78, latitude: 31.975 },
    { longitude: 118.78, latitude: 31.985 },
    { longitude: 118.79, latitude: 31.985 },
    { longitude: 118.79, latitude: 31.975 }
  ],
  clickable: true,
  fillColor: 0xff00DE00,
  geodesic: false,
  strokeColor: 0xff000000,
  jointType: mapCommon.JointType.DEFAULT,
  strokeWidth: 10,
  visible: true,
  zIndex: 10
};
```

### 步骤2：添加多边形

**示例代码**：
```typescript
async function addMapPolygon(
  mapController: map.MapComponentController,
  options: mapCommon.MapPolygonOptions
): Promise<map.MapPolygon> {
  try {
    const mapPolygon = await mapController.addPolygon(options);
    console.info('MapPolygon added successfully');
    return mapPolygon;
  } catch (error) {
    console.error(`Failed to add mapPolygon, code: ${error.code}, message: ${error.message}`);
    throw error;
  }
}
```

### 步骤3：更新多边形属性

**更新顶点示例**：
```typescript
function updatePolygonPoints(
  mapPolygon: map.MapPolygon,
  newPoints: Array<mapCommon.LatLng>
): void {
  try {
    mapPolygon.setPoints(newPoints);
    console.info('Polygon points updated successfully');
  } catch (error) {
    console.error(`Failed to update points: ${error.message}`);
  }
}
```

**更新颜色示例**：
```typescript
function updatePolygonColors(
  mapPolygon: map.MapPolygon,
  fillColor: number,
  strokeColor: number
): void {
  mapPolygon.setFillColor(fillColor);
  mapPolygon.setStrokeColor(strokeColor);
}
```

### 步骤4：错误处理

```typescript
try {
  let mapPolygon = await this.mapController.addPolygon(polygonOptions);
} catch (error) {
  switch (error.code) {
    case 401:
      console.error('Invalid input parameter: check polygon options format');
      break;
    case 1002601001:
      console.error('The object to be operated does not exist: check mapController state');
      break;
    default:
      console.error(`Unknown error: code ${error.code}, message ${error.message}`);
  }
}
```

### 步骤5：降级处理

```typescript
async function addPolygonWithFallback(
  mapController: map.MapComponentController,
  options: mapCommon.MapPolygonOptions
): Promise<map.MapPolygon | null> {
  try {
    return await mapController.addPolygon(options);
  } catch (error) {
    if (error.code === 401) {
      console.warn('Parameter invalid, using default values');
      const defaultOptions: mapCommon.MapPolygonOptions = {
        points: options.points,
        fillColor: 0x00000000,
        strokeColor: 0xff000000,
        strokeWidth: 10,
        visible: true,
        zIndex: 0
      };
      try {
        return await mapController.addPolygon(defaultOptions);
      } catch (fallbackError) {
        console.error('Fallback failed, cannot add polygon');
        return null;
      }
    }
    console.error('Failed to add polygon');
    return null;
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Invalid input parameter | 检查polygonOptions参数格式是否正确，顶点数组是否合法 |
| 1002601001 | The object to be operated does not exist | 确认MapComponentController已正确初始化，地图已加载完成 |

**错误码详细信息**：
- **401**：输入参数无效，可能原因：
  - points数组为空或少于3个顶点
  - 顶点纬度超出[-85.2, 85.2]范围
  - 参数类型错误
  
- **1002601001**：操作对象不存在，可能原因：
  - MapComponentController未初始化
  - 地图组件未加载完成
  - 地图控制器已被销毁

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.MapKit": ">=4.1.0(11)",
    "@kit.BasicServicesKit": ">=4.1.0(11)"
  }
}
```

### 环境要求
- **HarmonyOS版本**：>=4.1.0(11)
- **模型约束**：仅支持Stage模型
- **系统能力**：SystemCapability.Map.Core
- **元服务支持**：从版本4.1.0(11)开始支持元服务API

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.MapKit'
```
**解决方法**：确保项目配置正确，HarmonyOS SDK版本>=4.1.0(11)，在module.json5中声明依赖

**问题2：MapComponentController未定义**
```
TypeError: Cannot read property 'addPolygon' of undefined
```
**解决方法**：确保在MapComponent初始化回调中执行addPolygon，验证mapController已正确赋值

**问题3：顶点坐标类型错误**
```
Type 'number' is not assignable to type 'LatLng'
```
**解决方法**：确保顶点坐标使用mapCommon.LatLng类型，包含latitude和number属性

## 常见问题与解决方法

### Q1：多边形不显示在地图上
**原因**：可能visible属性设置为false或顶点坐标超出地图可视范围
**解决方法**：
- 检查polygonOptions.visible是否为true
- 检查顶点坐标是否在地图当前可视区域内
- 调用mapController.moveCamera调整地图视角到多边形区域

### Q2：多边形颜色设置无效
**原因**：颜色值格式错误或使用了错误的颜色格式
**解决方法**：
- 使用ARGB格式颜色值（如0xff00DE00）
- 确保颜色值使用number类型
- 不要使用RGB格式（如#00DE00）

### Q3：空心洞渲染异常
**原因**：空心洞坐标贴合多边形边缘
**解决方法**：
- 确保空心洞坐标与多边形边缘保持一定距离
- 验证空心洞坐标数组格式正确
- 避免空心洞顶点与多边形顶点重合

### Q4：点击事件不触发
**原因**：clickable属性未设置为true
**解决方法**：
- 设置polygonOptions.clickable = true
- 使用MapEventManager注册polygon点击事件监听

### Q5：多边形顶点更新后不刷新
**原因**：setPoints方法调用后地图未刷新
**解决方法**：
- 确认setPoints参数格式正确
- 检查新顶点数组是否合法
- 验证地图控制器状态正常

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "polygonId": "MapPolygon对象引用",
  "pointsCount": 4,
  "properties": {
    "fillColor": "0xff00DE00",
    "strokeColor": "0xff000000",
    "strokeWidth": 10,
    "visible": true,
    "clickable": true
  },
  "apiUsed": [
    "mapCommon.MapPolygonOptions",
    "map.MapComponentController.addPolygon",
    "map.MapPolygon"
  ],
  "apiVersion": ">=4.1.0(11)"
}
```

## 参考文档

- [API开发指南](references/api-guide.md)
- [API参考 - MapPolygonOptions](references/map-common.md)
- [API参考 - MapComponentController](references/map-map-mapcomponentcontroller.md)
- [API参考 - MapPolygon](references/map-map-mappolygon.md)

## 完整示例代码

- [ArkTS完整示例 - 基本多边形](assets/map_polygon_demo.ets)
- [ArkTS完整示例 - 带空心洞多边形](assets/map_polygon_with_holes_demo.ets)

## 测试用例

### 正向测试用例
- [基本多边形绘制测试](tests/test_positive.ts)：测试添加包含4个顶点的矩形多边形，验证多边形成功添加和属性设置正确

### 边界测试用例
- [最小顶点测试](tests/test_boundary.ts)：测试添加包含3个顶点的三角形多边形，验证最小顶点数量边界
- [纬度边界测试](tests/test_boundary.ts)：测试顶点纬度在[-85.2, 85.2]边界值，验证纬度范围约束

### 异常测试用例
- [无效顶点测试](tests/test_exception.ts)：测试顶点少于3个时的错误处理，验证错误码401返回
- [超出纬度范围测试](tests/test_exception.ts)：测试顶点纬度超出范围的错误处理，验证异常值处理逻辑
- [地图未初始化测试](tests/test_exception.ts)：测试地图控制器未初始化时的错误处理，验证错误码1002601001返回