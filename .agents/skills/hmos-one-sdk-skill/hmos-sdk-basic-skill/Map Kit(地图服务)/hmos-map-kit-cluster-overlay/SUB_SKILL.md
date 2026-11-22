---
name: hmos-map-kit-cluster-overlay
description: 实现地图点聚合功能,支持按距离聚合ClusterItem、自定义聚合图标、监听点击事件、添加删除聚合节点,适用于地图标记密集场景优化显示效果
---

# 点聚合技能

## 功能描述

本技能实现HarmonyOS Map Kit的点聚合(Cluster Overlay)功能,用于优化地图上大量标记点的显示效果。通过距离聚合算法,将相近的标记点聚合为一个聚合图标,支持缩放自适应聚合效果、自定义图标、点击事件监听等能力。

**核心功能**:
- 支持按距离聚合ClusterItem节点
- 支持绘制聚合覆盖物的默认图标和自定义图标
- 支持监听聚合覆盖物的点击事件和标记点击事件
- 支持动态添加单个ClusterItem到聚合覆盖物
- 支持删除聚合覆盖物
- 支持移动地图时重绘聚合覆盖物

**适用API版本**: 5.0.0(12)及以上

**元服务支持**: 从版本5.0.0(12)开始支持在元服务中使用

## 使用场景

### 触发词
- "地图点聚合"
- "聚合标记"
- "Cluster Overlay"
- "密集标记优化"
- "聚合地图标记"
- "点聚合功能"

### 能做
- 创建聚合图层,批量添加多个待聚合节点
- 设置聚合距离参数,控制聚合粒度
- 自定义聚合图标样式(PixelMap或绘制图标)
- 监听聚合点点击事件,获取被聚合的节点列表
- 监听聚合标记点击事件,获取标记信息和聚合节点
- 动态添加新的聚合节点
- 删除聚合图层

### 绝不做
- 不处理非地图标记密集场景的聚合需求
- 不提供离线地图聚合功能
- 不支持跨地图组件的聚合图层共享
- 不处理聚合算法的深度定制需求

### 补充
- 聚合效果随地图缩放级别自适应变化
- 聚合距离单位为vp(虚拟像素),建议设置范围40-200vp
- 支持Stage模型,不支持FA模型
- 聚合节点数量建议不超过1000个,过多会影响性能

## 调用规范和规则

### 输入约束
- **ClusterItem数量**: 建议不超过1000个节点
- **聚合距离**: 单位vp,建议取值范围40-200
- **坐标精度**: 纬度[-90, 90],经度[-180, 180)
- **自定义图标尺寸**: 建议62x62像素

### 执行约束
- **初始化时机**: 必须在地图组件初始化完成后调用
- **异步调用**: addClusterOverlay、addItem、remove等方法均为异步方法,需使用await或Promise处理
- **错误捕获**: 必须使用try-catch捕获可能的异常

### 内容约束
- 禁止在非地图组件中使用聚合功能
- 禁止使用无效的ClusterItem坐标(超出纬度经度范围)
- 禁止在聚合图层未创建时调用addItem方法
- 禁止重复监听同一事件而不取消之前的监听

### 降级约束
- **网络异常**: 地图组件初始化失败时,提示用户检查网络连接
- **节点过多**: 超过1000个节点时,建议分批次加载或提示用户优化数据
- **自定义图标失败**: 图标生成失败时使用默认聚合图标

## 调用流程和步骤

### 步骤1: 导入必要模块

```typescript
import { map, mapCommon, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit'; // 如果需要自定义图标
```

### 步骤2: 创建地图组件并初始化

**前置校验**:
1. 确认已申请地图相关权限
2. 确认地图组件已正确初始化
3. 确认获取到MapComponentController对象

```typescript
@Entry
@Component
struct ClusterOverlayDemo {
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  
  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 31.98,
          longitude: 118.7
        },
        zoom: 7
      }
    };
    
    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        console.info('Map initialized successfully');
      } else {
        console.error(`Failed to initialize map: code=${err.code}, message=${err.message}`);
      }
    };
  }
  
  build() {
    Stack() {
      Column() {
        MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
          .width('100%')
          .height('100%');
      }.width('100%')
    }.height('100%')
  }
}
```

### 步骤3: 创建待聚合节点数组

```typescript
function createClusterItems(): Array<mapCommon.ClusterItem> {
  let clusterItem1: mapCommon.ClusterItem = {
    position: {
      latitude: 31.98,
      longitude: 118.7
    }
  };
  
  let clusterItem2: mapCommon.ClusterItem = {
    position: {
      latitude: 32.99,
      longitude: 118.9
    }
  };
  
  let clusterItem3: mapCommon.ClusterItem = {
    position: {
      latitude: 31.5,
      longitude: 118.7
    }
  };
  
  return [clusterItem1, clusterItem2, clusterItem3];
}
```

### 步骤4: 创建聚合图层参数并调用addClusterOverlay

**示例代码**:

```typescript
async function createClusterOverlay(mapController: map.MapComponentController): Promise<map.ClusterOverlay> {
  try {
    let clusterItems = createClusterItems();
    
    let clusterOverlayParams: mapCommon.ClusterOverlayParams = {
      distance: 100, // 聚合距离,单位vp
      clusterItems: clusterItems
    };
    
    let clusterOverlay = await mapController.addClusterOverlay(clusterOverlayParams);
    console.info('Cluster overlay created successfully');
    return clusterOverlay;
  } catch (error) {
    console.error(`Failed to create cluster overlay: code=${error.code}, message=${error.message}`);
    throw error;
  }
}
```

### 步骤5: 自定义聚合图标(可选)

如果需要自定义聚合图标,需要实现ClusterOverlayParams的getCustomIcon方法:

```typescript
export class CustomClusterOverlayParams implements mapCommon.ClusterOverlayParams {
  clusterItems: mapCommon.ClusterItem[] = [];
  distance: number = 100;
  private offCanvas: OffscreenCanvas = new OffscreenCanvas(62, 62);
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  
  constructor(clusterItems: mapCommon.ClusterItem[], distance: number) {
    this.clusterItems = clusterItems;
    this.distance = distance;
  }
  
  async getCustomIcon(clusterItems: mapCommon.ClusterItem[]): Promise<image.PixelMap> {
    let offContext = this.offCanvas.getContext("2d", this.settings);
    offContext.clearRect(0, 0, 62, 62);
    
    // 绘制圆形背景
    offContext.fillStyle = 0xff990000;
    offContext.beginPath();
    offContext.arc(31, 31, 30, 0, 6.28);
    offContext.stroke();
    offContext.fill();
    offContext.save();
    
    // 绘制聚合数量文本
    offContext.font = '20vp sans-serif';
    offContext.textAlign = 'center';
    offContext.textBaseline = 'middle';
    offContext.fillStyle = 0xffffffff;
    offContext.fillText(String(clusterItems.length), 31, 31);
    offContext.restore();
    
    let iconPixelMap = offContext.getPixelMap(0, 0, 62, 62);
    return iconPixelMap;
  }
}
```

使用自定义图标创建聚合图层:

```typescript
async function createCustomClusterOverlay(mapController: map.MapComponentController): Promise<map.ClusterOverlay> {
  try {
    let clusterItems = createClusterItems();
    let customParams = new CustomClusterOverlayParams(clusterItems, 100);
    
    let clusterOverlay = await mapController.addClusterOverlay(customParams);
    console.info('Custom cluster overlay created successfully');
    return clusterOverlay;
  } catch (error) {
    console.error(`Failed to create custom cluster overlay: code=${error.code}, message=${error.message}`);
    throw error;
  }
}
```

### 步骤6: 监听聚合点击事件

```typescript
function setupClusterClickListener(clusterOverlay: map.ClusterOverlay): void {
  let callback = (clusterItems: Array<mapCommon.ClusterItem>) => {
    console.info(`Cluster clicked, contains ${clusterItems.length} items`);
    // 处理聚合点点击逻辑,例如放大地图显示聚合内的节点
  };
  
  clusterOverlay.on("click", callback);
}

function removeClusterClickListener(clusterOverlay: map.ClusterOverlay, callback: any): void {
  clusterOverlay.off("click", callback);
}
```

### 步骤7: 监听聚合标记点击事件

```typescript
function setupMarkerClusterClickListener(clusterOverlay: map.ClusterOverlay): void {
  let callback = (markerClusterInfo: map.MarkerClusterInfo) => {
    console.info(`Marker clicked, marker info:`, markerClusterInfo.marker);
    console.info(`Cluster items count: ${markerClusterInfo.clusterItems.length}`);
    // 处理标记点击逻辑
  };
  
  clusterOverlay.on("markerClusterClick", callback);
}
```

### 步骤8: 动态添加聚合节点

```typescript
async function addClusterItem(clusterOverlay: map.ClusterOverlay, newItem: mapCommon.ClusterItem): Promise<void> {
  try {
    await clusterOverlay.addItem(newItem);
    console.info('New cluster item added successfully');
  } catch (error) {
    console.error(`Failed to add cluster item: code=${error.code}, message=${error.message}`);
  }
}
```

### 步骤9: 删除聚合图层

```typescript
async function removeClusterOverlay(clusterOverlay: map.ClusterOverlay): Promise<void> {
  try {
    await clusterOverlay.remove();
    console.info('Cluster overlay removed successfully');
  } catch (error) {
    console.error(`Failed to remove cluster overlay: code=${error.code}, message=${error.message}`);
  }
}
```

### 步骤10: 错误处理和降级方案

```typescript
async function createClusterOverlayWithErrorHandling(mapController: map.MapComponentController): Promise<map.ClusterOverlay | null> {
  try {
    let clusterItems = createClusterItems();
    
    if (clusterItems.length > 1000) {
      console.warn('Too many cluster items, may affect performance. Consider batch loading.');
      clusterItems = clusterItems.slice(0, 1000); // 降级方案:限制节点数量
    }
    
    let clusterOverlayParams: mapCommon.ClusterOverlayParams = {
      distance: 100,
      clusterItems: clusterItems
    };
    
    let clusterOverlay = await mapController.addClusterOverlay(clusterOverlayParams);
    return clusterOverlay;
    
  } catch (error) {
    switch (error.code) {
      case 401:
        console.error('Invalid input parameter, check ClusterItem coordinates');
        return null;
      case 1002601001:
        console.error('Map controller object does not exist, ensure map is initialized');
        return null;
      default:
        console.error(`Unknown error: ${error.message}`);
        return null;
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Invalid input parameter | 检查ClusterOverlayParams参数是否正确,ClusterItem坐标是否在有效范围内 |
| 1002601001 | The object to be operated does not exist | 确保地图组件已初始化,MapComponentController对象有效 |
| 1002601005 | Failed to generate the icon of the customized component | 检查自定义图标生成逻辑,确保OffscreenCanvas配置正确 |

## 编译和修复问题

### 依赖声明

```json
{
  "dependencies": {
    "@kit.MapKit": "5.0.0(12)",
    "@kit.BasicServicesKit": "5.0.0(12)",
    "@kit.ImageKit": "5.0.0(12)"
  }
}
```

### 环境要求
- HarmonyOS SDK: 5.0.0(12)及以上
- DevEco Studio: 5.0及以上
- 应用模型: Stage模型

### 常见编译问题

**问题1: 导入模块失败**
```
Error: Cannot find module '@kit.MapKit'
```
**解决方法**: 确保在module.json5中声明了Map Kit依赖,并且SDK版本不低于5.0.0(12)

**问题2: ClusterItem坐标无效**
```
Error: 401 - Invalid input parameter
```
**解决方法**: 检查纬度范围[-90, 90],经度范围[-180, 180),确保坐标值在有效范围内

**问题3: 地图组件未初始化**
```
Error: 1002601001 - The object to be operated does not exist
```
**解决方法**: 确保在地图初始化回调成功后再调用聚合相关方法

## 常见问题与解决方法

### Q1: 聚合效果不明显,节点没有聚合
**原因**: 聚合距离设置过小,或节点分布过于稀疏
**解决方法**:
- 增大distance参数,建议设置为100-200vp
- 检查节点分布密度,确保有相近的节点可以聚合
- 调整地图缩放级别,观察聚合效果随缩放变化

### Q2: 自定义聚合图标无法显示
**原因**: getCustomIcon方法实现有误,或图标生成失败
**解决方法**:
- 检查OffscreenCanvas尺寸配置,建议使用62x62像素
- 确认绘制逻辑正确,包括圆形背景和文本绘制
- 使用默认图标测试聚合功能是否正常

### Q3: 聚合点击事件无法触发
**原因**: 未正确注册点击监听事件
**解决方法**:
- 确保使用clusterOverlay.on("click", callback)注册监听
- 确认callback函数签名正确,接收Array<ClusterItem>参数
- 检查是否在聚合图层创建后才注册监听

### Q4: 动态添加节点后聚合效果未更新
**原因**: addItem方法调用失败,或地图未刷新
**解决方法**:
- 使用await等待addItem异步操作完成
- 检查新添加的节点坐标是否在有效范围内
- 尝试移动地图触发重绘

### Q5: 聚合图层删除后再次创建失败
**原因**: 未正确清理之前的聚合图层对象
**解决方法**:
- 确保调用remove方法删除聚合图层
- 取消所有注册的事件监听
- 重新创建聚合图层前确保MapComponentController有效

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "clusterOverlayCreated": true,
  "clusterItemCount": 150,
  "clusterDistance": 100,
  "customIconEnabled": false,
  "eventListeners": {
    "clusterClick": true,
    "markerClusterClick": true
  },
  "apiUsed": [
    "mapCommon.ClusterItem",
    "mapCommon.ClusterOverlayParams",
    "MapComponentController.addClusterOverlay",
    "ClusterOverlay.on",
    "ClusterOverlay.addItem",
    "ClusterOverlay.remove"
  ]
}
```

## 参考文档

- [点聚合开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/map-aggregate)
- [ClusterItem API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common)
- [ClusterOverlayParams API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common)
- [ClusterOverlay API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-clusteroverlay)
- [MapComponentController.addClusterOverlay API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller)

## 完整示例代码

- [ArkTS基础聚合示例](assets/cluster-overlay-basic.ets)
- [自定义图标聚合示例](assets/cluster-overlay-custom-icon.ets)
- [事件监听完整示例](assets/cluster-overlay-events.ets)

## 测试用例

### 正向测试用例
- [基础聚合功能测试](tests/test_cluster_basic.py): 测试创建聚合图层、添加节点、监听点击事件
- [自定义图标测试](tests/test_custom_icon.py): 测试自定义聚合图标生成和显示
- [动态添加节点测试](tests/test_add_item.py): 测试动态添加聚合节点功能

### 边界测试用例
- [大量节点性能测试](tests/test_large_scale.py): 测试1000+节点的聚合性能
- [聚合距离边界测试](tests/test_distance_boundary.py): 测试distance参数边界值(40-200vp)
- [坐标边界测试](tests/test_coordinate_boundary.py): 测试纬度经度边界值

### 异常测试用例
- [无效参数测试](tests/test_invalid_params.py): 测试无效ClusterItem坐标、distance参数
- [未初始化测试](tests/test_not_initialized.py): 测试地图未初始化时调用聚合方法
- [重复删除测试](tests/test_duplicate_remove.py): 测试重复删除聚合图层