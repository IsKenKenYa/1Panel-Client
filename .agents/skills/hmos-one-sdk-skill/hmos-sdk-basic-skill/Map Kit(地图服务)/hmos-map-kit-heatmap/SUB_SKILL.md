---
name: hmos-map-kit-heatmap
description: 在地图上添加热力图层展示数据分布密度，支持自定义颜色、强度、透明度和半径，建议数据量小于10000条，适用于人流分布、热点区域等大数据密度可视化场景
---

# 热力图技能

## 功能描述

热力图功能用于在地图上添加热力图层，通过不同颜色的区块展示数据的分布密度情况。支持自定义热力图的ID、数据、颜色、强度、透明度、半径等参数，可以直观地描述地图上某个区域内人群或车辆的密度和分布情况。热力图适用于大数据密度可视化场景，如人流分布、热点区域等。

**核心特性**：
- 支持添加、更新、删除热力图
- 支持设置热力图的颜色渐变、强度、透明度、半径
- 支持按不同地图层级配置不同参数
- 建议数据量小于10000条以确保性能

**API版本要求**：6.0.0(20)及以上版本

## 使用场景

### 触发词
- "添加热力图"
- "显示热力图"
- "热力图层"
- "地图热力图"
- "数据密度可视化"
- "人流分布热力图"
- "热点区域可视化"

### 能做
- 在地图上添加热力图层展示数据分布
- 设置热力图的颜色渐变方案（ARGB格式）
- 配置热力图的强度、透明度、半径参数
- 支持按不同地图层级设置不同参数
- 更新热力图的数据和样式
- 删除已添加的热力图
- 控制热力图的可见性

### 绝不做
- 不处理超过10000条数据的热力图（性能限制）
- 不处理坐标范围异常的数据（纬度需在[-90,90]，经度需在[-180,180))
- 不处理非法的颜色值（必须为ARGB格式）
- 不处理非法的强度值（必须大于0）
- 不处理非法的透明度值（必须在[0,1]范围内）
- 不处理非法的半径值（必须大于等于1）

### 补充
- 热力图数据使用WeightedLatLng类型，包含经纬度坐标和强度权重
- 颜色参数使用Record<number, number>类型，key为数据密度[0,1]，value为ARGB颜色值
- 强度、透明度、半径参数支持number类型（所有层级相同）或Record<number, number>类型（不同层级不同值）
- 半径单位支持像素（PIXEL_UNIT）或米（METER_UNIT）

## 调用规范和规则

### 输入约束
- **数据量限制**：建议数据量小于10000条，确保渲染性能
- **坐标范围**：纬度取值范围[-90, 90]，经度取值范围[-180, 180)
- **颜色格式**：ARGB格式，例如0xFFFF0000表示红色
- **强度范围**：大于0，小于等于0按默认值1处理
- **透明度范围**：[0, 1]，0表示不透明，1表示透明，超出范围自动调整
- **半径范围**：大于等于1，单位为像素或米
- **层级范围**：[2, 20]，超出范围自动调整
- **密度范围**：[0, 1]，超出范围的key会被移除

### 执行约束
- **最大耗时**：添加热力图建议在地图初始化回调后执行，避免阻塞UI
- **API调用频次**：避免频繁更新热力图数据，建议批量更新
- **异步调用**：addHeatmap方法返回Promise，需要使用await或then处理

### 内容约束
- **禁止生成**：禁止生成超过10000条数据的示例代码
- **禁止使用高危函数**：禁止使用eval、exec等高危函数
- **禁止操作**：禁止在热力图未初始化时调用setData等更新方法

### 降级约束
- **数据量过大**：提示用户数据量超过10000条会影响性能，建议减少数据量
- **坐标异常**：过滤掉坐标范围异常的数据点，仅处理有效数据
- **参数非法**：非法参数自动按默认值处理或移除，不影响热力图添加
- **热力图ID重复**：返回错误码1002600015，提示用户使用不同的ID

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 验证地图控制器是否已初始化
2. 验证数据量是否小于10000条
3. 验证坐标范围是否合法（纬度[-90,90]，经度[-180,180))
4. 验证热力图ID是否唯一

**参数准备**：
```typescript
// 导入必要模块
import { map, mapCommon, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

// 准备热力图数据
let data: mapCommon.WeightedLatLng[] = [];
for (let i = 0; i < 500; i++) {
  const latitude = 31.000000 + Math.random() * 1 - 0.25;
  const longitude = 118.000000 + Math.random() * 1 - 0.25;
  
  // 校验坐标范围
  if (latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude < 180) {
    data.push({
      point: {
        longitude: longitude,
        latitude: latitude
      },
      intensity: 1
    });
  }
}

// 准备热力图参数
let heatMapOptions: mapCommon.HeatmapParams = {
  id: 'heatmap0001',
  data: data,
  radius: 20,
  intensity: {
    2: 1,
    5: 5,
    8: 10
  },
  opacity: 0.5,
  color: {
    0: 0x00026C39,
    0.15: 0xAA138C4A,
    0.3: 0xFF82CB67,
    0.45: 0xFFE3F399,
    0.6: 0xFFFEDE89,
    0.75: 0xFFF67C4A,
    0.9: 0xFFBE1827,
    1: 0xFFA90426
  },
  radiusUnit: mapCommon.RadiusUnit.PIXEL_UNIT,
  visible: true
};
```

### 步骤2：添加热力图

**示例代码**：
```typescript
@Entry
@Component
struct HeatMapDemo {
  private TAG = "OHMapSDK_HeatMapDemo";
  private mapOption?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private heatmap?: map.Heatmap;

  aboutToAppear(): void {
    this.mapOption = {
      position: {
        target: {
          latitude: 31.000000,
          longitude: 118.000000
        },
        zoom: 11
      }
    }

    this.callback = async (err, mapController) => {
      console.info(this.TAG, "mapCallback err=" + JSON.stringify(err) +
        "; mapController=" + JSON.stringify(mapController));
      if (!err) {
        this.mapController = mapController;
        
        // 准备数据
        let data: mapCommon.WeightedLatLng[] = [];
        for (let i = 0; i < 500; i++) {
          const latitude = 31.000000 + Math.random() * 1 - 0.25;
          const longitude = 118.000000 + Math.random() * 1 - 0.25;
          
          if (latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude < 180) {
            data.push({
              point: {
                longitude: longitude,
                latitude: latitude
              },
              intensity: 1
            });
          }
        }

        let heatMapOptions: mapCommon.HeatmapParams = {
          id: 'heatmap0001',
          data: data,
          radius: 20,
          intensity: {
            2: 1,
            5: 5,
            8: 10
          }
        }

        try {
          // 添加热力图
          this.heatmap = await this.mapController?.addHeatmap(heatMapOptions);
          console.info(this.TAG, 'Heatmap added successfully');
        } catch (e) {
          console.error(this.TAG, `Failed to add heatmap, code:${e.code}, message:${e.message}`);
        }
      } else {
        console.error(this.TAG, `Failed to initialize map, code:${err.code}, message:${err.message}`);
      }
    }
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

### 步骤3：更新热力图

**更新数据**：
```typescript
// 更新热力图数据
let newData: mapCommon.WeightedLatLng[] = [
  {
    point: {
      longitude: 118.5,
      latitude: 31.5
    },
    intensity: 2.3
  }
];
this.heatmap?.setData(newData);
console.info(this.TAG, 'Heatmap data updated');
```

**更新样式**：
```typescript
// 更新颜色
let color: Record<number, number> = {
  0: 0x26C3999,
  0.15: 0xFF4D4DFF,
  0.3: 0xFF9999FF,
  0.45: 0xFFE6E6FF,
  0.6: 0xFFFFCCFF,
  0.75: 0xFFFF99FF,
  0.9: 0xFFFF66FF,
  1: 0xFFFF00FF
};
this.heatmap?.setColor(color);

// 更新强度
let intensity: Record<number, number> = {
  2: 0.1,
  5: 0.5,
  10: 1.0
};
this.heatmap?.setIntensity(intensity);

// 更新透明度
let opacity: Record<number, number> = {
  2: 0.1,
  10: 0.8
};
this.heatmap?.setOpacity(opacity);

// 更新半径
let radius: Record<number, number> = {
  2: 10,
  10: 50
};
this.heatmap?.setRadius(radius);
```

### 步骤4：错误处理

```typescript
try {
  this.heatmap = await this.mapController?.addHeatmap(heatMapOptions);
  console.info(this.TAG, 'Heatmap added successfully');
} catch (error) {
  switch (error.code) {
    case 1002601001:
      console.error(this.TAG, 'The object to be operated does not exist');
      // 降级处理：检查mapController是否初始化
      if (!this.mapController) {
        console.warn(this.TAG, 'Map controller is not initialized, retry after map loaded');
      }
      break;
    case 1002600015:
      console.error(this.TAG, 'The heatmap ID already exists');
      // 降级处理：使用不同的ID重新添加
      heatMapOptions.id = 'heatmap0002';
      try {
        this.heatmap = await this.mapController?.addHeatmap(heatMapOptions);
      } catch (retryError) {
        console.error(this.TAG, 'Retry failed:', retryError.message);
      }
      break;
    case 401:
      console.error(this.TAG, 'Invalid input parameter');
      // 降级处理：检查参数合法性
      console.warn(this.TAG, 'Please check HeatmapParams parameters');
      break;
    default:
      console.error(this.TAG, `Unknown error: code=${error.code}, message=${error.message}`);
  }
}
```

### 步骤5：删除热力图

```typescript
// 删除热力图
this.heatmap?.remove();
console.info(this.TAG, 'Heatmap removed');
this.heatmap = undefined;
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1002601001 | The object to be operated does not exist | 确保地图控制器已初始化，在地图初始化回调后调用addHeatmap方法 |
| 1002600015 | The heatmap ID already exists | 使用唯一的热力图ID，避免重复添加相同ID的热力图 |
| 401 | Invalid input parameter | 检查HeatmapParams参数是否合法：数据不能为空，坐标范围合法，颜色格式正确等 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.MapKit": "^6.0.0",
    "@kit.BasicServicesKit": "^6.0.0"
  }
}
```

### 环境要求
- **HarmonyOS SDK**：6.0.0(20)及以上版本
- **DevEco Studio**：推荐使用最新版本
- **API版本**：mapCommon.HeatmapParams、map.Heatmap需要API 6.0.0(20)及以上

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.MapKit'
```
**解决方法**：
1. 确保HarmonyOS SDK版本为6.0.0(20)及以上
2. 在module.json5中添加依赖声明
3. 同步项目依赖：DevEco Studio -> File -> Sync Project with Gradle Files

**问题2：API不存在**
```
Error: Property 'addHeatmap' does not exist on type 'MapComponentController'
```
**解决方法**：
1. 检查HarmonyOS SDK版本是否为6.0.0(20)及以上
2. 更新SDK到最新版本
3. 重新导入模块：import { map, mapCommon } from '@kit.MapKit';

**问题3：类型定义错误**
```
Error: Type 'HeatmapParams' is not defined
```
**解决方法**：
1. 确保导入mapCommon模块：import { mapCommon } from '@kit.MapKit';
2. 使用完整类型名称：mapCommon.HeatmapParams
3. 检查SDK版本是否支持该类型

**问题4：坐标数据异常**
```
Error: Invalid latitude or longitude value
```
**解决方法**：
1. 检查坐标范围：纬度[-90, 90]，经度[-180, 180)
2. 使用数据校验函数过滤异常坐标
3. 参考步骤1中的坐标校验代码

## 常见问题与解决方法

### Q1：热力图无法显示
**原因**：
- 数据量过大导致渲染性能问题
- 坐标范围异常
- 热力图参数设置错误
- 地图控制器未初始化

**解决方法**：
- 减少数据量至10000条以下
- 校验坐标范围，过滤异常数据
- 检查HeatmapParams参数是否合法
- 确保在地图初始化回调后添加热力图

### Q2：热力图颜色不符合预期
**原因**：
- 颜色参数格式错误
- 数据密度key范围错误
- ARGB颜色值设置错误

**解决方法**：
- 确保颜色参数为Record<number, number>类型
- key取值范围应为[0, 1]
- 使用正确的ARGB格式颜色值（例如0xFFFF0000）
- 参考默认颜色值设置：{ 0: 0x00026C39, ..., 1: 0xFFA90426 }

### Q3：热力图性能问题
**原因**：
- 数据量超过10000条
- 频繁更新热力图数据
- 半径参数设置过大

**解决方法**：
- 减少数据量至推荐范围内
- 批量更新数据，避免频繁调用setData
- 适当减小半径参数值
- 使用PIXEL_UNIT单位而非METER_UNIT

### Q4：热力图ID重复错误
**原因**：
- 使用了已存在的热力图ID
- 未删除旧热力图就添加新热力图

**解决方法**：
- 使用唯一的热力图ID
- 在添加新热力图前先删除旧热力图
- 使用错误码1002600015的降级处理方案

### Q5：热力图在不同层级显示效果不一致
**原因**：
- intensity、opacity、radius参数未按层级配置
- 地图缩放层级变化导致热力图渲染效果变化

**解决方法**：
- 使用Record<number, number>类型按层级配置参数
- key为地图层级[2, 20]，value为参数值
- 例如：intensity: { 2: 1, 5: 5, 8: 10 }

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "heatmapId": "heatmap0001",
  "dataCount": 500,
  "visible": true,
  "apiUsed": [
    "map.MapComponentController.addHeatmap",
    "mapCommon.HeatmapParams",
    "mapCommon.WeightedLatLng",
    "map.Heatmap.setData",
    "map.Heatmap.setColor",
    "map.Heatmap.setIntensity",
    "map.Heatmap.setOpacity",
    "map.Heatmap.setRadius",
    "map.Heatmap.remove"
  ]
}
```

## 参考文档

- [API开发指南](references/map-heat-guide.md) - 热力图开发指南原始文档
- [HeatmapParams API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common) - 热力图参数定义
- [addHeatmap API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller) - 添加热力图方法
- [Heatmap API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-heatmap) - 热力图对象方法

## 完整示例代码

- [ArkTS完整示例](assets/HeatMapDemo.ets) - 包含热力图添加、更新、删除的完整示例
- [配置示例](assets/heatmap-config.json) - 热力图参数配置示例

## 测试用例

### 正向测试用例
- [添加热力图测试](tests/test_positive.py) - 正常添加热力图功能测试
- [更新热力图测试](tests/test_positive.py) - 更新热力图数据和样式测试
- [删除热力图测试](tests/test_positive.py) - 删除热力图功能测试

### 边界测试用例
- [最大数据量测试](tests/test_boundary.py) - 测试10000条数据边界
- [坐标范围边界测试](tests/test_boundary.py) - 测试纬度[-90,90]，经度[-180,180)边界
- [参数范围边界测试](tests/test_boundary.py) - 测试强度、透明度、半径等参数边界值

### 异常测试用例
- [坐标异常测试](tests/test_exception.py) - 测试坐标超出范围的异常处理
- [参数格式异常测试](tests/test_exception.py) - 测试颜色、强度等参数格式错误处理
- [ID重复异常测试](tests/test_exception.py) - 测试热力图ID重复错误处理
- [地图未初始化异常测试](tests/test_exception.py) - 测试地图控制器未初始化时的错误处理