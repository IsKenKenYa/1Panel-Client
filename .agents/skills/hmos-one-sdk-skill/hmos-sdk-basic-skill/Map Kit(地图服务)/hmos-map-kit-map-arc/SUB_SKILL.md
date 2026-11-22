---
name: hmos-map-kit-map-arc
description: 在地图上绘制弧线，支持设置起点/终点/中心点坐标、宽度、颜色等参数，适用于展示飞机/轮船出行路线、指示转向方向等场景
---

# 弧线绘制技能

## 功能描述

本技能用于在HarmonyOS地图上绘制弧线覆盖物。弧线是一种特殊的地图覆盖物，通过起点、终点和中心点三个坐标点定义弧形轨迹，主要用于直观展示飞机航线、轮船航线等出行路线，以及在交叉路口等位置指示转向方向。

**核心能力**：
- 设置弧线的起点、终点和中心点坐标（必填参数）
- 配置弧线的颜色（ARGB格式）
- 配置弧线的宽度（像素单位）
- 设置弧线的可见性和叠加层级
- 动态更新弧线属性（颜色、宽度）

**适用范围**：
- 需要在地图上展示弧形轨迹的场景
- 飞机航线、轮船航线可视化
- 交叉路口转向指示
- 地图路径规划辅助展示

**技术限制**：
- 仅支持Stage模型
- 需要地图组件已初始化
- API版本要求：5.0.0(12)及以上
- 元服务支持：从版本5.0.0(12)开始

## 使用场景

### 触发词
- "绘制弧线"
- "添加弧线"
- "地图弧线"
- "航线绘制"
- "弧形轨迹"
- "MapArc"
- "addArc"

### 能做
- 在地图上添加一条弧线覆盖物
- 设置弧线的起点、终点和中心点坐标
- 配置弧线的颜色（支持ARGB格式）
- 配置弧线的宽度（像素单位）
- 设置弧线的可见性和叠加层级
- 动态更新已添加弧线的颜色和宽度
- 查询弧线的当前颜色和宽度值

### 绝不做
- 不处理直线或多边形覆盖物（使用其他技能）
- 不涉及地图相机移动或缩放
- 不处理弧线的点击事件监听
- 不支持多条弧线的批量添加（需逐条添加）

### 补充
- 弧线需要三个坐标点（起点、终点、中心点）才能正确绘制
- 弧线继承自BaseOverlayOptions，支持visible和zIndex属性
- 弧线颜色默认为白色（0xFFFFFFFF），宽度默认为10像素
- 弧线的宽度和颜色可以在添加后动态更新

## 调用规范和规则

### 输入约束
- **起点坐标**：必填，纬度范围[-90, 90]，经度范围[-180, 180)
- **终点坐标**：必填，纬度范围[-90, 90]，经度范围[-180, 180)
- **中心点坐标**：必填，纬度范围[-90, 90]，经度范围[-180, 180)
- **颜色值**：可选，ARGB格式数值，默认0xFFFFFFFF（白色）
- **宽度值**：可选，数值类型，单位px，默认10，取值范围≥0
- **可见性**：可选，布尔值，默认true
- **叠加层级**：可选，数值类型，默认0

### 执行约束
- 必须在地图组件初始化完成后再添加弧线
- 必须在MapComponentController回调中或自定义方法中调用addArc
- 三个坐标点必须在合理范围内，否则绘制失败
- 地图控制器对象必须有效，否则返回错误码1002601001

### 内容约束
- 禁止使用非法坐标值（超出范围的纬度/经度）
- 禁止在地图控制器为null时调用addArc
- 禁止使用非法的颜色值格式（必须为ARGB数值）
- 禁止设置负数的宽度值

### 降级约束
- 坐标值超出范围：提示用户输入合法坐标值
- 地图控制器为null：提示等待地图初始化完成
- 参数格式错误：返回错误码401，提示检查参数格式
- 弧线添加失败：返回错误码1002601001，提示检查地图状态

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认地图组件已初始化完成
2. 确认MapComponentController对象有效
3. 确认三个坐标点（起点、终点、中心点）已准备
4. 确认坐标值在合理范围内（纬度[-90, 90]，经度[-180, 180)）

**参数准备**：
```typescript
import { map, mapCommon, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

// 弧线参数配置
let mapArcParams: mapCommon.MapArcParams = {
  // 弧线起点坐标（必填）
  startPoint: {
    latitude: 39.913138,   // 纬度，范围[-90, 90]
    longitude: 116.415112  // 经度，范围[-180, 180)
  },
  // 弧线终点坐标（必填）
  endPoint: {
    latitude: 28.239473,
    longitude: 112.954094
  },
  // 弧线中心点坐标（必填）
  centerPoint: {
    latitude: 33.86970399048567,
    longitude: 112.08633528544145
  },
  // 弧线宽度（可选），单位px，默认10
  width: 10,
  // 弧线颜色（可选），ARGB格式，默认白色
  color: 0xffff0000,      // 红色
  // 是否可见（可选），默认true
  visible: true,
  // 叠加层级（可选），默认0
  zIndex: 100
};
```

### 步骤2：添加弧线

**示例代码**：
```typescript
@Entry
@Component
struct MapArcDemo {
  private TAG = "MapArcDemo";
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapArc?: map.MapArc;

  aboutToAppear(): void {
    // 地图初始化参数
    this.mapOptions = {
      position: {
        target: {
          latitude: 34.757975,
          longitude: 113.665412
        },
        zoom: 6
      }
    };

    // 地图初始化回调
    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        if (!this.mapController) {
          console.error(this.TAG, "mapController is null");
          return;
        }

        // 设置弧线参数
        let mapArcParams: mapCommon.MapArcParams = {
          startPoint: {
            latitude: 39.913138,
            longitude: 116.415112
          },
          endPoint: {
            latitude: 28.239473,
            longitude: 112.954094
          },
          centerPoint: {
            latitude: 33.86970399048567,
            longitude: 112.08633528544145
          },
          width: 10,
          color: 0xffff0000,
          visible: true,
          zIndex: 100
        };

        // 添加弧线
        try {
          this.mapArc = await this.mapController.addArc(mapArcParams);
          console.info(this.TAG, "Arc added successfully");
        } catch (e) {
          console.error(this.TAG, `Failed to add arc, code: ${e.code}, message: ${e.message}`);
        }
      } else {
        console.error(this.TAG, `Failed to initialize map, code: ${err.code}, message: ${err.message}`);
      }
    };
  }

  build() {
    Stack() {
      Column() {
        MapComponent({
          mapOptions: this.mapOptions,
          mapCallback: this.callback
        })
          .width('100%')
          .height('100%');
      }.width('100%')
    }.height('100%')
  }
}
```

### 步骤3：动态更新弧线属性

**更新颜色示例**：
```typescript
// 更新弧线颜色
if (this.mapArc) {
  this.mapArc.setColor(0xff00ff00);  // 设置为绿色
  console.info(this.TAG, "Arc color updated");
}
```

**更新宽度示例**：
```typescript
// 更新弧线宽度
if (this.mapArc) {
  this.mapArc.setWidth(20);  // 设置宽度为20px
  console.info(this.TAG, "Arc width updated");
}
```

**查询属性示例**：
```typescript
// 查询弧线属性
if (this.mapArc) {
  let color: number = this.mapArc.getColor();
  let width: number = this.mapArc.getWidth();
  console.info(this.TAG, `Arc color: ${color}, width: ${width}`);
}
```

### 步骤4：错误处理

```typescript
// 错误处理代码
try {
  this.mapArc = await this.mapController.addArc(mapArcParams);
} catch (error) {
  switch (error.code) {
    case 401:
      console.error(this.TAG, "Invalid input parameter. Check coordinate values and parameter format.");
      break;
    case 1002601001:
      console.error(this.TAG, "The object to be operated does not exist. Check map controller status.");
      break;
    default:
      console.error(this.TAG, `Unknown error: ${error.message}`);
  }
}
```

### 步骤5：降级处理

```typescript
// 降级处理代码
async function addArcWithFallback(mapController: map.MapComponentController, params: mapCommon.MapArcParams): Promise<void> {
  try {
    // 尝试添加弧线
    let mapArc = await mapController.addArc(params);
    console.info("Arc added successfully");
  } catch (error) {
    if (error.code === 401) {
      // 参数错误降级：使用默认值重新尝试
      console.warn("Using default color and width");
      let fallbackParams = {
        ...params,
        color: 0xFFFFFFFF,  // 使用默认白色
        width: 10           // 使用默认宽度
      };
      try {
        await mapController.addArc(fallbackParams);
      } catch (e) {
        console.error("Fallback failed:", e.message);
      }
    } else if (error.code === 1002601001) {
      // 地图控制器不存在降级：提示用户等待
      console.warn("Map controller not ready. Please wait for map initialization.");
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Invalid input parameter | 检查坐标值是否在合理范围，参数格式是否正确 |
| 1002601001 | The object to be operated does not exist | 确认地图控制器对象是否有效，地图是否已初始化 |

**错误码详细说明**：
- **401**：输入参数无效。可能原因：
  - 坐标值超出范围（纬度不在[-90, 90]，经度不在[-180, 180)）
  - 参数格式不正确（非LatLng类型）
  - 缺少必填参数（startPoint、endPoint、centerPoint）
  
- **1002601001**：操作对象不存在。可能原因：
  - 地图控制器为null或已销毁
  - 地图组件未初始化完成
  - 在错误的时机调用addArc方法

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
- HarmonyOS SDK：版本5.0.0(12)及以上
- 开发环境：DevEco Studio 5.0及以上
- 运行环境：HarmonyOS 5.0及以上设备
- 模型约束：仅支持Stage模型

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.MapKit'
```
**解决方法**：
- 确认项目SDK版本≥5.0.0(12)
- 在module.json5中添加依赖声明
- 检查DevEco Studio版本是否≥5.0

**问题2：类型定义错误**
```
Error: Property 'addArc' does not exist on type 'MapComponentController'
```
**解决方法**：
- 确认API版本≥5.0.0(12)，addArc从该版本开始支持
- 检查导入的map模块版本
- 更新SDK到最新版本

**问题3：坐标值类型错误**
```
Error: Type 'number' is not assignable to type 'LatLng'
```
**解决方法**：
- 确保坐标点使用正确的LatLng对象格式
- 检查latitude和longitude字段是否存在
- 使用mapCommon.LatLng类型定义

## 常见问题与解决方法

### Q1：弧线没有显示在地图上
**原因**：
- visible属性设置为false
- 弧线颜色与地图背景色相同
- 弧线宽度设置为0
- 坐标点设置不合理导致弧线绘制失败

**解决方法**：
- 检查visible属性是否为true
- 设置明显的颜色值（如红色0xffff0000）
- 设置合理的宽度值（如10px）
- 检查三个坐标点是否在合理范围内

### Q2：弧线绘制位置不正确
**原因**：
- 起点坐标设置错误
- 终点坐标设置错误
- 中心点坐标设置错误

**解决方法**：
- 重新确认三个坐标点的纬度和经度值
- 确保坐标点在合理范围内
- 使用地图工具验证坐标位置

### Q3：添加弧线时返回错误码401
**原因**：
- 参数格式不正确
- 坐标值超出范围
- 缺少必填参数

**解决方法**：
- 检查MapArcParams对象格式
- 确认startPoint、endPoint、centerPoint都已设置
- 确认坐标值在合理范围（纬度[-90, 90]，经度[-180, 180)）

### Q4：添加弧线时返回错误码1002601001
**原因**：
- 地图控制器为null
- 地图组件未初始化完成
- 在错误的时机调用addArc

**解决方法**：
- 确认在MapComponent回调中调用addArc
- 检查mapController是否有效
- 确保地图初始化完成后再添加弧线

### Q5：如何动态更新弧线的颜色和宽度？
**原因**：
需要实时调整弧线的显示效果

**解决方法**：
- 使用MapArc对象的setColor方法更新颜色
- 使用MapArc对象的setWidth方法更新宽度
- 使用getColor和getWidth方法查询当前值

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "arcId": "MapArc对象引用",
  "parameters": {
    "startPoint": {
      "latitude": 39.913138,
      "longitude": 116.415112
    },
    "endPoint": {
      "latitude": 28.239473,
      "longitude": 112.954094
    },
    "centerPoint": {
      "latitude": 33.86970399048567,
      "longitude": 112.08633528544145
    },
    "width": 10,
    "color": 0xffff0000,
    "visible": true,
    "zIndex": 100
  },
  "apiUsed": [
    "mapCommon.MapArcParams",
    "map.MapComponentController.addArc",
    "map.MapArc"
  ],
  "apiVersion": "5.0.0(12)"
}
```

## 参考文档

- [API开发指南](references/map-arc.md)
- [MapArcParams参数定义](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common)
- [addArc方法说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller)
- [MapArc对象说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-maparc)

## 完整示例代码

- [ArkTS示例代码](assets/map_arc_example.ets)

## 测试用例

### 正向测试用例
- [添加弧线-标准参数](tests/test_positive.py)：使用合理的坐标点和参数添加弧线
- [动态更新弧线属性](tests/test_positive.py)：测试setColor和setWidth方法

### 边界测试用例
- [坐标值边界测试](tests/test_boundary.py)：测试纬度和经度的边界值
- [宽度边界测试](tests/test_boundary.py)：测试宽度为0和最大值的情况

### 异常测试用例
- [无效坐标值测试](tests/test_exception.py)：测试超出范围的坐标值
- [空参数测试](tests/test_exception.py)：测试缺少必填参数的情况
- [地图控制器无效测试](tests/test_exception.py)：测试地图控制器为null的情况