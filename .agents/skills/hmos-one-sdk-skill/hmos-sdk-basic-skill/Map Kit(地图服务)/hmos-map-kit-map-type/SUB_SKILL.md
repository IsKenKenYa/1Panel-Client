---
name: hmos-map-kit-map-type
description: 切换地图显示类型，支持标准地图、空地图、地形图、卫星图、混合地图五种类型，可在初始化或运行时动态切换，适用于导航、地理信息展示、卫星图像查看场景
---

# 切换地图类型技能

## 功能描述

本技能实现HarmonyOS Map Kit地图类型切换功能。支持五种地图类型：标准地图(STANDARD)、空地图(NONE)、地形图(TERRAIN)、卫星图(SATELLITE)、混合地图(HYBRID)。可通过两种方式设置地图类型：初始化时通过MapOptions配置，或运行时通过setMapType方法动态切换。地形图需在特定缩放层级(5-14)才能显示效果，卫星图和混合地图从API 6.0.0(20)开始支持。

## 使用场景

### 触发词
- "切换地图类型"
- "显示卫星图"
- "显示地形图"
- "设置标准地图"
- "切换混合地图"
- "map type"
- "卫星地图"
- "地形地图"

### 能做
- 初始化时设置地图类型
- 运行时动态切换地图类型
- 查询当前地图类型
- 支持五种地图类型切换：标准、空、地形、卫星、混合

### 绝不做
- 不支持地形图在智能表设备上显示效果
- 不支持卫星图和混合地图在API版本低于6.0.0(20)的环境
- 不支持地形图在缩放层级不在5-14范围时显示效果

### 补充
- 地形图仅在缩放层级大于5且小于14时才能看到效果
- 卫星图和混合地图从API 6.0.0(20)版本开始支持
- 卫星图只支持中国区域
- 地形图在智能表设备上不显示效果

## 调用规范和规则

### 输入约束
- 地图类型参数必须为mapCommon.MapType枚举值之一
- 缩放层级设置：地形图建议设置在5-14之间
- API版本要求：基本功能需4.1.0(11)以上，卫星图和混合地图需6.0.0(20)以上

### 执行约束
- setMapType方法调用为同步执行，无返回值
- 地图类型切换立即生效
- 不支持动画过渡效果

### 内容约束
- 禁止使用非法的MapType值
- 禁止在API版本不支持的情况下使用卫星图和混合地图
- 禁止在智能表设备上期望地形图显示效果

### 降级约束
- API版本低于6.0.0(20)时，不支持SATELLITE和HYBRID类型，降级使用STANDARD类型
- 地形图在缩放层级不在5-14范围时，无法看到地形效果，但仍会切换为TERRAIN类型
- 智能表设备上地形图不显示效果时，建议使用STANDARD或SATELLITE类型

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查API版本是否支持所需的地图类型
2. 确认设备类型（是否为智能表设备）
3. 验证地图控制器是否已初始化

**参数准备**：
```typescript
import { mapCommon } from '@kit.MapKit';

const mapType: mapCommon.MapType = mapCommon.MapType.STANDARD;
```

### 步骤2：初始化时设置地图类型

**方式一：通过MapOptions初始化**

```typescript
import { mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct MapTypeDemo {
  private mapOptions?: mapCommon.MapOptions;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;

  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 31.984410259206815,
          longitude: 118.76625379397866
        },
        zoom: 15
      },
      mapType: mapCommon.MapType.STANDARD
    };

    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        console.info('Map initialized with STANDARD type');
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
}
```

### 步骤3：运行时动态切换地图类型

**方式二：通过setMapType方法**

```typescript
async function switchMapType(mapController: map.MapComponentController, targetType: mapCommon.MapType): void {
  try {
    if (!mapController) {
      console.error('Map controller is not initialized');
      return;
    }

    mapController.setMapType(targetType);
    
    const currentType = mapController.getMapType();
    console.info(`Map type switched to: ${currentType}`);
  } catch (error) {
    console.error('Failed to switch map type:', error);
  }
}

async function setTerrainMap(mapController: map.MapComponentController): void {
  const currentZoom = mapController.getCameraPosition().zoom;
  
  if (currentZoom >= 5 && currentZoom <= 14) {
    mapController.setMapType(mapCommon.MapType.TERRAIN);
    console.info('Terrain map enabled at optimal zoom level');
  } else {
    console.warn('Terrain map requires zoom level between 5 and 14 for best visibility');
    mapController.setMapType(mapCommon.MapType.TERRAIN);
  }
}
```

### 步骤4：错误处理

```typescript
function handleMapTypeSwitch(mapController: map.MapComponentController, mapType: mapCommon.MapType): void {
  try {
    if (!mapController) {
      throw new Error('MapController is null or undefined');
    }

    const supportedTypes = [
      mapCommon.MapType.STANDARD,
      mapCommon.MapType.NONE,
      mapCommon.MapType.TERRAIN
    ];

    if (mapType === mapCommon.MapType.SATELLITE || mapType === mapCommon.MapType.HYBRID) {
      console.warn('SATELLITE and HYBRID types require API 6.0.0(20) or higher');
    }

    mapController.setMapType(mapType);
    console.info('Map type set successfully');
  } catch (error) {
    console.error('Error setting map type:', error.message);
  }
}
```

### 步骤5：降级处理

```typescript
function safeSetMapType(mapController: map.MapComponentController, desiredType: mapCommon.MapType): void {
  const fallbackType = mapCommon.MapType.STANDARD;
  
  try {
    if (desiredType === mapCommon.MapType.SATELLITE || desiredType === mapCommon.MapType.HYBRID) {
      console.warn('Satellite/Hybrid map requires API 6.0.0(20)+, using STANDARD as fallback');
      mapController.setMapType(fallbackType);
    } else {
      mapController.setMapType(desiredType);
    }
  } catch (error) {
    console.error('Failed to set map type, using fallback:', error);
    mapController.setMapType(fallbackType);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Invalid input parameter | 检查MapType参数是否为有效的枚举值 |
| API_VERSION_ERROR | API版本不支持该地图类型 | 升级API版本至6.0.0(20)以上以支持卫星图和混合地图 |
| DEVICE_NOT_SUPPORTED | 设备不支持此地图类型显示效果 | 智能表设备不支持地形图效果，建议使用其他地图类型 |
| ZOOM_LEVEL_WARNING | 缩放层级不在最佳范围 | 调整缩放层级至5-14之间以获得最佳地形图效果 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.MapKit": ">=4.1.0(11)"
  }
}
```

### 环境要求
- HarmonyOS API：最低版本4.1.0(11)，卫星图和混合地图需6.0.0(20)
- 设备类型：全类型支持，智能表设备地形图不显示效果
- 开发环境：DevEco Studio 3.1及以上

### 常见编译问题

**问题1：MapType枚举值未定义**
```
Error: 'MapType' is not defined
```
**解决方法**：确保导入mapCommon模块：`import { mapCommon } from '@kit.MapKit';`

**问题2：setMapType方法不存在**
```
Error: Property 'setMapType' does not exist on type 'MapComponentController'
```
**解决方法**：确认API版本是否为5.0.0(12)以上，setMapType方法从此版本开始支持

**问题3：卫星图类型不支持**
```
Runtime Error: SATELLITE map type is not supported
```
**解决方法**：升级API版本至6.0.0(20)以上，或使用其他地图类型

## 常见问题与解决方法

### Q1：地形图显示不出来怎么办？
**原因**：缩放层级不在最佳范围(5-14)，或设备为智能表
**解决方法**：
- 调整地图缩放层级至5-14之间
- 检查设备类型，智能表不支持地形图效果
- 使用其他地图类型替代

### Q2：切换到卫星图时报错？
**原因**：API版本低于6.0.0(20)，卫星图和混合地图从此版本开始支持
**解决方法**：
- 升级HarmonyOS API版本至6.0.0(20)以上
- 使用标准地图或地形图作为替代方案

### Q3：如何判断当前地图类型？
**原因**：需要查询当前地图显示类型
**解决方法**：
- 使用getMapType()方法查询当前地图类型
- 确保API版本为5.0.0(12)以上

### Q4：切换地图类型后地图显示异常？
**原因**：地图类型参数错误或地图控制器未正确初始化
**解决方法**：
- 验证mapController是否已成功初始化
- 检查MapType参数是否为有效枚举值
- 确认相机位置和缩放层级设置合理

### Q5：如何在初始化时就设置卫星图？
**原因**：需要在创建地图时直接显示卫星图
**解决方法**：
- 在MapOptions中设置mapType属性为mapCommon.MapType.SATELLITE
- 确保API版本为6.0.0(20)以上
- 注意卫星图只支持中国区域

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "mapType": "TERRAIN",
  "previousMapType": "STANDARD",
  "apiUsed": [
    "mapCommon.MapType",
    "MapOptions.mapType",
    "setMapType",
    "getMapType"
  ],
  "deviceSupport": "full",
  "zoomLevel": 10,
  "terrainOptimal": true
}
```

## 参考文档

- [API开发指南-切换地图类型](map-type)
- [API参考说明-mapCommon](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common)
- [API参考说明-MapComponentController](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller)

## 完整示例代码

- [ArkTS示例-初始化设置地图类型](assets/map_type_init_example.ets)
- [ArkTS示例-动态切换地图类型](assets/map_type_switch_example.ets)
- [ArkTS示例-地形图最佳实践](assets/terrain_map_example.ets)
- [配置文件示例](assets/map_config.json)

## 测试用例

### 正向测试用例
- [初始化设置标准地图](tests/test_standard_map_init.py)：验证初始化时设置STANDARD类型成功
- [动态切换地形图](tests/test_terrain_switch.py)：验证运行时切换为TERRAIN类型成功
- [查询地图类型](tests/test_get_map_type.py)：验证getMapType方法正确返回当前类型

### 边界测试用例
- [地形图缩放层级边界](tests/test_terrain_zoom_boundary.py)：验证地形图在缩放层级5和14边界时的显示
- [API版本兼容性](tests/test_api_version_compatibility.py)：验证不同API版本下的地图类型支持情况

### 异常测试用例
- [无效地图类型参数](tests/test_invalid_map_type.py)：验证传入非法MapType值的错误处理
- [空地图控制器](tests/test_null_controller.py)：验证mapController为空时的错误处理
- [智能表设备地形图](tests/test_wearable_terrain.py)：验证智能表设备上地形图的降级处理