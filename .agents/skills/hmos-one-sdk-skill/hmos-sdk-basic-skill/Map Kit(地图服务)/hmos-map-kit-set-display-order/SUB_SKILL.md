---
name: hmos-map-kit-set-display-order
description: 设置地图元素的显示顺序（压盖关系），支持OVERLAY/POI/CUSTOM_POI/MARKER四类元素，数组长度必须为4，适用于地图元素层级管理场景
---

# 设置地图元素压盖顺序技能

## 功能描述

本技能用于设置地图元素的层级压盖关系，通过调用`setDisplayOrder`方法，可以自定义地图元素（覆盖物、POI、自定义POI、标记）的显示顺序。按照从低到高排列，后面的地图元素会压盖前面的地图元素。

主要功能：
- 定义地图元素的显示层级顺序
- 控制不同类型地图元素的压盖关系
- 支持自定义地图元素的显示优先级

关键API：
- `mapCommon.MapElementType`：地图元素类型枚举，包含OVERLAY、POI、CUSTOM_POI、MARKER四个值
- `setDisplayOrder(types: Array<mapCommon.MapElementType>)`：设置地图元素的显示顺序方法

API版本要求：
- 起始版本：5.0.0(12)
- 元服务API：从版本5.0.0(12)开始支持在元服务中使用

## 使用场景

### 触发词
- "设置地图元素压盖顺序"
- "调整地图元素层级"
- "控制地图覆盖物显示顺序"
- "设置地图元素显示优先级"
- "地图元素压盖关系"

### 能做
- 设置OVERLAY（覆盖物）的显示层级
- 设置POI（底图POI）的显示层级
- 设置CUSTOM_POI（自定义POI）的显示层级
- 设置MARKER（标记）的显示层级
- 自定义四类地图元素的压盖关系（从底层到顶层排列）

### 绝不做
- 不能设置少于或多于4个元素类型的顺序（数组长度必须为4）
- 不能使用非MapElementType枚举值的参数
- 不能在不初始化地图的情况下调用setDisplayOrder方法
- 不能在地图控制器未获取的情况下调用该方法

### 补充
- 默认显示顺序为[OVERLAY, POI, CUSTOM_POI, MARKER]，对应数值[1, 2, 3, 4]
- 数组中的元素顺序代表从底层到顶层的显示顺序，后面的元素会压盖前面的元素
- 必须在地图初始化完成后才能调用此方法
- 该方法仅影响元素的压盖关系，不影响元素的可见性

## 调用规范和规则

### 输入约束
- 参数类型：必须是Array<mapCommon.MapElementType>类型
- 数组长度：必须为4，不能少于或多于4个元素
- 枚举值：数组必须包含MapElementType的全部4个枚举值（OVERLAY、POI、CUSTOM_POI、MARKER）
- 值范围：只能使用mapCommon.MapElementType枚举的合法值

### 执行约束
- 前置条件：必须先初始化MapComponent并获取MapComponentController
- 调用位置：必须在地图初始化回调函数中或地图初始化完成后调用
- 执行时机：建议在添加地图元素之前设置显示顺序
- 最大耗时：无明确限制，属于即时生效的方法

### 内容约束
- 禁止操作：不能传递空数组、不能传递长度不为4的数组
- 禁止重复：数组中的4个枚举值必须唯一，不能重复
- 禁止顺序：虽然可以自定义顺序，但建议按照逻辑层级排列（底层→顶层）
- 禁止场景：不能在地图未初始化或控制器未获取时调用

### 降级约束
- 参数错误：如果传入参数不符合约束（长度不为4或包含非法值），返回错误码401
- 控制器不存在：如果mapController未初始化，调用会失败，需先完成地图初始化
- 版本不支持：如果API版本低于5.0.0(12)，该方法不可用，需升级系统版本

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认系统API版本是否≥5.0.0(12)
2. 确认已导入必要的模块：`import { mapCommon, map, MapComponent } from '@kit.MapKit';`
3. 确认已导入回调类型：`import { AsyncCallback } from '@kit.BasicServicesKit';`
4. 确认已创建MapComponent组件并获取MapComponentController

**参数准备**：
```typescript
// 导入必要模块
import { mapCommon, map, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

// 定义地图控制器
private mapController?: map.MapComponentController;
```

### 步骤2：初始化地图并获取控制器

**示例代码**：
```typescript
@Entry
@Component
struct MapDisplayOrderDemo {
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  
  aboutToAppear(): void {
    // 地图初始化参数
    this.mapOptions = {
      position: {
        target: {
          latitude: 31.984410259206815,
          longitude: 118.26625379397866
        },
        zoom: 10
      }
    };
    
    // 地图初始化回调
    this.callback = async (err, mapController) => {
      if (!err) {
        // 获取地图控制器
        this.mapController = mapController;
        console.info('Map initialized successfully');
        
        // 在地图初始化完成后调用setDisplayOrder
        this.setMapDisplayOrder();
      } else {
        console.error(`Failed to initialize map, code: ${err.code}, message: ${err.message}`);
      }
    };
  }
  
  build() {
    Stack() {
      Column() {
        MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback });
      }.width('100%')
    }.height('100%')
  }
}
```

### 步骤3：设置地图元素显示顺序

**示例代码**：
```typescript
// 设置地图元素显示顺序的方法
private setMapDisplayOrder(): void {
  if (!this.mapController) {
    console.error('Map controller is not initialized');
    return;
  }
  
  // 定义地图元素显示顺序数组
  // 从底层到顶层排列：OVERLAY(覆盖物) -> POI(底图POI) -> CUSTOM_POI(自定义POI) -> MARKER(标记)
  let mapElementTypeArr: Array<mapCommon.MapElementType> = [
    mapCommon.MapElementType.OVERLAY,      // 1 - 最底层
    mapCommon.MapElementType.POI,          // 2 - 第二层
    mapCommon.MapElementType.CUSTOM_POI,   // 3 - 第三层
    mapCommon.MapElementType.MARKER        // 4 - 最顶层
  ];
  
  // 调用setDisplayOrder方法设置显示顺序
  try {
    this.mapController.setDisplayOrder(mapElementTypeArr);
    console.info('Map display order set successfully');
  } catch (error) {
    console.error(`Failed to set display order, code: ${error.code}, message: ${error.message}`);
  }
}
```

### 步骤4：添加地图元素（可选）

**示例代码**：
```typescript
// 添加Marker示例
private async addMarker(): Promise<void> {
  if (!this.mapController) {
    console.error('Map controller is not initialized');
    return;
  }
  
  let markerOptions: mapCommon.MarkerOptions = {
    position: {
      latitude: 31.984410259206815,
      longitude: 118.26625379397866
    },
    rotation: 0,
    visible: true,
    zIndex: 0,
    alpha: 1,
    anchorU: 0.5,
    anchorV: 1,
    clickable: true,
    draggable: true,
    flat: false
  };
  
  try {
    let marker = await this.mapController.addMarker(markerOptions);
    console.info('Marker added successfully');
  } catch (error) {
    console.error(`Failed to add marker, code: ${error.code}, message: ${error.message}`);
  }
}

// 添加Bubble示例
private async addBubble(): Promise<void> {
  if (!this.mapController) {
    console.error('Map controller is not initialized');
    return;
  }
  
  let bubbleOptions: mapCommon.BubbleParams = {
    positions: [[{
      latitude: 32.384410259206815,
      longitude: 118.26625379397866
    }]],
    icons: [
      'speed_limit_10.png',
      'speed_limit_20.png',
      'speed_limit_30.png',
      'speed_limit_40.png'
    ],
    forceVisible: true,
    priority: 3,
    minZoom: 2,
    maxZoom: 20,
    visible: true,
    zIndex: 1
  };
  
  try {
    let bubble = await this.mapController.addBubble(bubbleOptions);
    console.info('Bubble added successfully');
  } catch (error) {
    console.error(`Failed to add bubble, code: ${error.code}, message: ${error.message}`);
  }
}

// 添加ImageOverlay示例
private async addImageOverlay(): Promise<void> {
  if (!this.mapController) {
    console.error('Map controller is not initialized');
    return;
  }
  
  let imageOverlayParams: mapCommon.ImageOverlayParams = {
    bounds: {
      southwest: {
        latitude: 32,
        longitude: 118
      },
      northeast: {
        latitude: 32.4,
        longitude: 118.4
      }
    },
    image: 'icon/icon.png',
    transparency: 0.3,
    zIndex: 101,
    anchorU: 0.5,
    anchorV: 0.5,
    clickable: true,
    visible: true,
    bearing: 0
  };
  
  try {
    await this.mapController.addImageOverlay(imageOverlayParams);
    console.info('ImageOverlay added successfully');
  } catch (error) {
    console.error(`Failed to add imageOverlay, code: ${error.code}, message: ${error.message}`);
  }
}
```

### 步骤5：错误处理

**错误处理代码**：
```typescript
// 错误处理示例
private setMapDisplayOrderWithErrorHandling(): void {
  if (!this.mapController) {
    console.error('Map controller is not initialized');
    return;
  }
  
  try {
    // 正确的参数
    let correctOrder: Array<mapCommon.MapElementType> = [
      mapCommon.MapElementType.OVERLAY,
      mapCommon.MapElementType.POI,
      mapCommon.MapElementType.CUSTOM_POI,
      mapCommon.MapElementType.MARKER
    ];
    
    this.mapController.setDisplayOrder(correctOrder);
    console.info('Display order set successfully');
    
  } catch (error) {
    // 处理不同错误码
    switch (error.code) {
      case 401:
        console.error('Invalid input parameter: array length must be 4 and contain all MapElementType values');
        break;
      default:
        console.error(`Unknown error: code ${error.code}, message ${error.message}`);
    }
  }
}
```

### 步骤6：降级处理

**降级处理代码**：
```typescript
// 降级处理示例 - 使用默认顺序
private setMapDisplayOrderWithFallback(): void {
  if (!this.mapController) {
    console.warn('Map controller not available, display order will use default: [OVERLAY, POI, CUSTOM_POI, MARKER]');
    return;
  }
  
  try {
    // 尝试设置自定义顺序
    let customOrder: Array<mapCommon.MapElementType> = [
      mapCommon.MapElementType.OVERLAY,
      mapCommon.MapElementType.POI,
      mapCommon.MapElementType.CUSTOM_POI,
      mapCommon.MapElementType.MARKER
    ];
    
    this.mapController.setDisplayOrder(customOrder);
    console.info('Custom display order applied');
    
  } catch (error) {
    if (error.code === 401) {
      // 降级方案：使用默认顺序
      console.warn('Custom order invalid, using default order: [OVERLAY, POI, CUSTOM_POI, MARKER]');
      // 默认顺序为[1, 2, 3, 4]，系统会自动使用默认值
    } else {
      console.error(`Failed to set display order: ${error.message}`);
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Invalid input parameter - 参数无效 | 检查数组长度是否为4，是否包含所有MapElementType枚举值，确保无重复值 |
| - | Map controller未初始化 | 确保在地图初始化回调成功后才调用setDisplayOrder方法 |
| - | API版本不支持 | 确认系统版本≥5.0.0(12)，升级系统或使用其他方案 |

**错误码详细说明**：

**错误码401**：
- 原因：传入参数不符合规范
- 具体情况：
  - 数组长度不为4
  - 数组包含非MapElementType枚举值
  - 数组中的值重复
  - 数组为空或null
- 解决方法：
  - 确保数组长度为4
  - 使用mapCommon.MapElementType枚举的合法值（OVERLAY、POI、CUSTOM_POI、MARKER）
  - 确保数组中的4个值唯一且完整

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.MapKit": "^5.0.0",
    "@kit.BasicServicesKit": "^5.0.0"
  }
}
```

### 环境要求
- HarmonyOS系统版本：≥5.0.0(12)
- DevEco Studio版本：≥5.0.0
- ArkTS API版本：≥12
- Stage模型：仅支持Stage模型，不支持FA模型

### 常见编译问题

**问题1：MapElementType未定义**
```
Error: Cannot find name 'MapElementType'
```
**解决方法**：确保正确导入模块
```typescript
import { mapCommon } from '@kit.MapKit';
```

**问题2：setDisplayOrder方法不存在**
```
Error: Property 'setDisplayOrder' does not exist on type 'MapComponentController'
```
**解决方法**：确认系统版本≥5.0.0(12)，该方法从API 12开始支持

**问题3：类型不匹配**
```
Error: Type 'number[]' is not assignable to type 'MapElementType[]'
```
**解决方法**：使用mapCommon.MapElementType枚举值，而不是数值
```typescript
// 正确用法
let order: Array<mapCommon.MapElementType> = [
  mapCommon.MapElementType.OVERLAY,
  mapCommon.MapElementType.POI,
  mapCommon.MapElementType.CUSTOM_POI,
  mapCommon.MapElementType.MARKER
];

// 错误用法（不要使用数值）
let order = [1, 2, 3, 4];  // 类型错误
```

## 常见问题与解决方法

### Q1：setDisplayOrder方法调用后报401错误
**原因**：传入参数不符合规范（数组长度不为4或包含非法值）
**解决方法**：
- 确保数组长度为4
- 使用mapCommon.MapElementType枚举的全部4个值
- 检查是否有重复值
- 示例：
```typescript
// 正确
let order: Array<mapCommon.MapElementType> = [
  mapCommon.MapElementType.OVERLAY,
  mapCommon.MapElementType.POI,
  mapCommon.MapElementType.CUSTOM_POI,
  mapCommon.MapElementType.MARKER
];

// 错误 - 长度不为4
let wrongOrder1 = [mapCommon.MapElementType.OVERLAY];  // 长度1

// 错误 - 值重复
let wrongOrder2 = [
  mapCommon.MapElementType.OVERLAY,
  mapCommon.MapElementType.OVERLAY,
  mapCommon.MapElementType.POI,
  mapCommon.MapElementType.MARKER
];
```

### Q2：地图元素压盖顺序不符合预期
**原因**：数组顺序理解错误，或者未在添加元素前调用setDisplayOrder
**解决方法**：
- 理解数组顺序含义：数组中的元素顺序代表从底层到顶层
- 建议在添加地图元素之前调用setDisplayOrder
- 示例：
```typescript
// 设置顺序：OVERLAY(底层) -> POI -> CUSTOM_POI -> MARKER(顶层)
let order = [
  mapCommon.MapElementType.OVERLAY,    // 最底层
  mapCommon.MapElementType.POI,        // 第二层
  mapCommon.MapElementType.CUSTOM_POI, // 第三层
  mapCommon.MapElementType.MARKER      // 最顶层，会压盖其他所有元素
];
```

### Q3：mapController为undefined导致调用失败
**原因**：地图未初始化完成或回调中未正确获取controller
**解决方法**：
- 确保在地图初始化回调成功后调用
- 检查回调函数中的错误处理
- 示例：
```typescript
this.callback = async (err, mapController) => {
  if (!err && mapController) {
    this.mapController = mapController;
    // 在这里调用setDisplayOrder
    this.setMapDisplayOrder();
  } else {
    console.error('Map initialization failed');
  }
};
```

### Q4：如何改变默认的显示顺序
**原因**：系统默认顺序为[OVERLAY, POI, CUSTOM_POI, MARKER]
**解决方法**：
- 通过setDisplayOrder自定义顺序
- 例如，让MARKER显示在底层：
```typescript
// MARKER在底层，OVERLAY在顶层
let customOrder: Array<mapCommon.MapElementType> = [
  mapCommon.MapElementType.MARKER,      // 最底层
  mapCommon.MapElementType.CUSTOM_POI,  // 第二层
  mapCommon.MapElementType.POI,         // 第三层
  mapCommon.MapElementType.OVERLAY      // 最顶层
];
this.mapController.setDisplayOrder(customOrder);
```

### Q5：setDisplayOrder方法是否立即生效
**原因**：方法调用后立即生效，但已添加的元素需要重新渲染
**解决方法**：
- 建议在添加地图元素之前设置显示顺序
- 如果元素已添加，设置后会自动重新渲染
- 设置顺序不会影响元素的可见性（visible属性）

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "methodName": "setDisplayOrder",
  "displayOrder": [
    {
      "type": "OVERLAY",
      "value": 1,
      "description": "覆盖物（最底层）"
    },
    {
      "type": "POI",
      "value": 2,
      "description": "底图POI（第二层）"
    },
    {
      "type": "CUSTOM_POI",
      "value": 3,
      "description": "自定义POI（第三层）"
    },
    {
      "type": "MARKER",
      "value": 4,
      "description": "标记（最顶层）"
    }
  ],
  "apiUsed": [
    "mapCommon.MapElementType",
    "MapComponentController.setDisplayOrder"
  ],
  "apiVersion": "5.0.0(12)",
  "message": "地图元素显示顺序设置成功"
}
```

## 参考文档

- [API开发指南](references/map-display-order.md) - 设置地图元素压盖顺序开发指南
- [MapElementType API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common) - 地图元素类型枚举定义
- [setDisplayOrder API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller) - 设置显示顺序方法

## 完整示例代码

- [ArkTS完整示例](assets/map-display-order-demo.ets) - 包含地图初始化、设置显示顺序、添加地图元素的完整示例

## 测试用例

### 正向测试用例
- [测试正常顺序设置](tests/test_positive.ets) - 测试设置正确的四元素顺序
- [测试自定义顺序](tests/test_custom_order.ets) - 测试自定义元素显示顺序

### 边界测试用例
- [测试默认顺序](tests/test_default_order.ets) - 测试不调用setDisplayOrder时的默认顺序
- [测试所有枚举值组合](tests/test_all_combinations.ets) - 测试MapElementType的所有排列组合

### 异常测试用例
- [测试数组长度错误](tests/test_invalid_length.ets) - 测试数组长度不为4时的错误处理
- [测试重复值](tests/test_duplicate_values.ets) - 测试数组包含重复值时的错误处理
- [测试非法值](tests/test_invalid_values.ets) - 测试数组包含非法值时的错误处理
- [测试控制器未初始化](tests/test_no_controller.ets) - 测试mapController未初始化时的处理