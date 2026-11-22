---
name: hmos-map-kit-map-polyline
description: 在地图上绘制折线、设置折线分段颜色、渐变效果、纹理样式，支持导航路线、运动轨迹、区域边界标注等场景
---

# 折线绘制技能

## 功能描述

本技能提供在HarmonyOS地图上绘制折线的完整功能实现，包括：
- 基础折线绘制：支持设置折线顶点、宽度、颜色等基本属性
- 分段颜色：支持为折线不同段设置不同颜色
- 渐变效果：支持折线颜色渐变显示
- 纹理绘制：支持使用图片纹理绘制折线（5.0.3(15)版本开始）
- 分段纹理：支持为折线不同段设置不同纹理图片

适用于展示步行、驾车、骑行等各类导航路线，记录并呈现用户运动轨迹及历史行程信息，以及区域边界标注、距离测量、管网线路布局等场景。

## 使用场景

### 触发词
- "在地图上绘制折线"
- "添加地图折线"
- "绘制导航路线"
- "显示运动轨迹"
- "地图折线分段颜色"
- "折线渐变效果"
- "折线纹理绘制"

### 能做
- 在地图上绘制一条或多条折线
- 设置折线的宽度、颜色、透明度等样式属性
- 为折线设置分段颜色，实现不同段显示不同颜色
- 启用折线渐变效果，使颜色平滑过渡
- 使用图片纹理绘制折线，增强视觉效果
- 为折线设置分段纹理，实现不同段显示不同纹理
- 设置折线的起点和终点样式（BUTT、ROUND、SQUARE）
- 设置折线的拐角样式（DEFAULT、BEVEL、ROUND）
- 设置折线是否可点击、是否可见等交互属性
- 动态更新折线的各项属性

### 绝不做
- 不绘制圆形、多边形等其他地图覆盖物（使用专门的技能）
- 不处理地图标注、点注释等（使用专门的技能）
- 不处理地图相机移动、缩放等操作（使用专门的技能）
- 不处理地图事件监听（使用专门的技能）

### 补充
- 折线顶点数量无明确限制，但建议不超过1000个点以保证性能
- 折线宽度取值范围：[0, 512]px，超过512按512处理
- 纹理功能需要API版本5.0.0(12)及以上
- 分段纹理功能需要API版本5.0.3(15)及以上
- 纹理图片建议使用透明背景的PNG图片
- 分段纹理时，customTextureIndexes数组长度必须与points数组长度一致

## 调用规范和规则

### 输入约束
- 折线顶点坐标：必填，数组形式，每个点包含latitude和longitude
- latitude取值范围：[-90, 90]
- longitude取值范围：[-180, 180)
- 折线宽度：可选，取值范围[0, 512]px，默认10px
- 颜色值：ARGB格式，如0xff000000（黑色）
- 纹理图片路径：相对路径格式，存放在resources/rawfile目录下

### 执行约束
- 必须在地图初始化回调中或地图加载完成后执行
- 折线添加为异步操作，使用Promise处理结果
- 最大折线数量无明确限制，建议不超过100条以保证性能
- 纹理图片加载可能耗时，建议预加载纹理资源

### 内容约束
- 禁止使用无效的坐标值（超出范围的latitude/longitude）
- 禁止使用无效的颜色值（非ARGB格式）
- 禁止使用不存在或路径错误的纹理图片
- 禁止在地图未初始化时添加折线

### 降级约束
- 坐标值异常：不处理，跳过该折线
- 纹理图片加载失败：使用默认颜色绘制折线
- 参数验证失败：返回错误码401，提示用户修正参数
- 地图未初始化：返回错误码1002601001，提示用户等待地图加载

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认地图组件已初始化并加载完成
2. 确认mapController已获取
3. 验证折线顶点坐标数组不为空且坐标值在有效范围内
4. 验证颜色值为ARGB格式（如使用颜色）
5. 验证纹理图片路径正确且文件存在（如使用纹理）

**参数准备**：
```typescript
// 导入必要模块
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';

// 准备折线参数
let polylineOption: mapCommon.MapPolylineOptions = {
  // 折线顶点坐标（必填）
  points: [
    { longitude: 118.78, latitude: 31.975 },
    { longitude: 118.78, latitude: 31.982 },
    { longitude: 118.79, latitude: 31.985 }
  ],
  // 是否可点击（可选，默认false）
  clickable: true,
  // 折线颜色（可选，默认黑色0xff000000）
  color: 0xff000000,
  // 折线宽度（可选，默认10px）
  width: 10,
  // 是否可见（可选，默认true）
  visible: true,
  // z轴层级（可选，默认0）
  zIndex: 10,
  // 起点样式（可选，默认BUTT）
  startCap: mapCommon.CapStyle.BUTT,
  // 终点样式（可选，默认BUTT）
  endCap: mapCommon.CapStyle.BUTT,
  // 是否大地曲线（可选，默认false）
  geodesic: false,
  // 拐角样式（可选，默认DEFAULT）
  jointType: mapCommon.JointType.BEVEL,
  // 是否渐变（可选，默认false）
  gradient: false
};
```

### 步骤2：添加基础折线

**示例代码**：
```typescript
@Entry
@Component
struct MapPolylineDemo {
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapPolyline?: map.MapPolyline;

  aboutToAppear(): void {
    // 地图初始化参数
    this.mapOptions = {
      position: {
        target: {
          latitude: 31.98,
          longitude: 118.78
        },
        zoom: 14
      }
    };

    // 地图初始化回调
    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        
        // 准备折线参数
        let polylineOption: mapCommon.MapPolylineOptions = {
          points: [
            { longitude: 118.78, latitude: 31.975 },
            { longitude: 118.78, latitude: 31.982 },
            { longitude: 118.79, latitude: 31.985 }
          ],
          clickable: true,
          startCap: mapCommon.CapStyle.BUTT,
          endCap: mapCommon.CapStyle.BUTT,
          geodesic: false,
          jointType: mapCommon.JointType.BEVEL,
          visible: true,
          width: 10,
          zIndex: 10,
          gradient: false
        };

        // 创建折线
        try {
          this.mapPolyline = await this.mapController.addPolyline(polylineOption);
          console.info('MapPolyline created successfully');
        } catch (e) {
          console.error(`Failed to create the mapPolyline, code: ${e.code}, message: ${e.message}`);
        }
      } else {
        console.error(`Failed to initialize the map, code: ${err.code}, message: ${err.message}`);
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

### 步骤3：设置折线分段颜色

**方法一：创建时设置**：
```typescript
let polylineOption: mapCommon.MapPolylineOptions = {
  points: [
    { longitude: 118.78, latitude: 31.975 },
    { longitude: 118.78, latitude: 31.982 },
    { longitude: 118.79, latitude: 31.985 }
  ],
  clickable: true,
  width: 10,
  // 设置分段颜色（黄色、黑色）
  colors: [0xffffff00, 0xff000000],
  gradient: false
};
let mapPolyline = await this.mapController.addPolyline(polylineOption);
```

**方法二：动态设置**：
```typescript
// 设置分段颜色
let colors = [0xffffff00, 0xff000000];
this.mapPolyline.setColors(colors);
```

### 步骤4：设置折线渐变效果

**方法一：创建时设置**：
```typescript
let polylineOption: mapCommon.MapPolylineOptions = {
  points: [
    { longitude: 118.78, latitude: 31.975 },
    { longitude: 118.78, latitude: 31.982 },
    { longitude: 118.79, latitude: 31.985 }
  ],
  clickable: true,
  width: 10,
  colors: [0xffffff00, 0xff000000],
  // 启用渐变
  gradient: true
};
let mapPolyline = await this.mapController.addPolyline(polylineOption);
```

**方法二：动态设置**：
```typescript
// 启用渐变效果
this.mapPolyline.setGradient(true);
```

### 步骤5：绘制纹理折线

**前提条件**：API版本5.0.0(12)及以上

**方法一：创建时设置**：
```typescript
let polylineOption: mapCommon.MapPolylineOptions = {
  points: [
    { latitude: 32.220750, longitude: 118.788765 },
    { latitude: 32.120750, longitude: 118.788765 },
    { latitude: 32.020750, longitude: 118.788765 },
    { latitude: 31.920750, longitude: 118.788765 },
    { latitude: 31.820750, longitude: 118.788765 }
  ],
  clickable: true,
  jointType: mapCommon.JointType.DEFAULT,
  width: 20,
  // 纹理图片路径（存放在resources/rawfile目录下）
  customTexture: 'icon/naviline_arrow.png'
};
let mapPolyline = await this.mapController.addPolyline(polylineOption);
```

**方法二：动态设置**：
```typescript
// 设置折线纹理
await this.mapPolyline.setCustomTexture('icon/naviline_arrow.png');
```

### 步骤6：绘制分段纹理折线

**前提条件**：API版本5.0.3(15)及以上

**示例代码**：
```typescript
// 准备纹理图片数组
let customTextures: (ResourceStr | image.PixelMap)[] = [];
customTextures.push('icon/img.png');     // 第一个纹理图片
customTextures.push('icon/img_1.png');   // 第二个纹理图片

// 准备纹理索引数组
let customTextureIndexes: number[] = [];
// 数组长度必须与points数组长度一致
// 每个元素对应points中该点使用的纹理索引
customTextureIndexes.push(0, 0, 1);  // 第1、2个点用纹理0，第3个点用纹理1

let polylineOption: mapCommon.MapPolylineOptions = {
  points: [
    { longitude: 118.78, latitude: 31.975 },
    { longitude: 118.78, latitude: 31.982 },
    { longitude: 118.79, latitude: 31.985 }
  ],
  clickable: true,
  startCap: mapCommon.CapStyle.BUTT,
  endCap: mapCommon.CapStyle.BUTT,
  jointType: mapCommon.JointType.BEVEL,
  width: 30,
  // 纹理图片数组
  customTextures: customTextures,
  // 纹理索引数组
  customTextureIndexes: customTextureIndexes
};

let mapPolyline = await this.mapController.addPolyline(polylineOption);
```

### 步骤7：错误处理

**错误码处理**：
```typescript
try {
  let mapPolyline = await this.mapController.addPolyline(polylineOption);
  console.info('Polyline added successfully');
} catch (error) {
  switch (error.code) {
    case 401:
      console.error('Invalid input parameter:', error.message);
      // 检查参数是否正确
      break;
    case 1002601001:
      console.error('The object to be operated does not exist:', error.message);
      // 检查地图是否已初始化
      break;
    default:
      console.error('Unknown error:', error.code, error.message);
  }
}
```

### 步骤8：降级处理

**降级方案**：
```typescript
// 添加折线的降级处理
async function addPolylineWithFallback(
  mapController: map.MapComponentController,
  polylineOption: mapCommon.MapPolylineOptions
): Promise<map.MapPolyline | null> {
  try {
    // 尝试添加折线
    let mapPolyline = await mapController.addPolyline(polylineOption);
    return mapPolyline;
  } catch (error) {
    console.warn('Failed to add polyline with original options:', error.message);
    
    // 降级方案1：使用简化参数
    try {
      let simpleOption: mapCommon.MapPolylineOptions = {
        points: polylineOption.points,
        visible: true,
        width: 10
      };
      let mapPolyline = await mapController.addPolyline(simpleOption);
      console.info('Polyline added with simplified options');
      return mapPolyline;
    } catch (fallbackError) {
      console.error('Failed to add polyline even with simplified options:', fallbackError.message);
      return null;
    }
  }
}

// 使用降级方案添加折线
let mapPolyline = await addPolylineWithFallback(this.mapController, polylineOption);
if (mapPolyline) {
  console.info('Polyline rendering successful');
} else {
  console.warn('Polyline rendering failed, consider using alternative visualization');
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 输入参数无效 | 检查points数组是否为空、坐标值是否在有效范围内、颜色值是否为ARGB格式、纹理索引数组长度是否与points数组长度一致 |
| 1002601001 | 操作对象不存在 | 确认地图已初始化、mapController已获取、地图组件已加载完成 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.MapKit": "系统Kit，无需声明版本",
    "@kit.BasicServicesKit": "系统Kit，无需声明版本",
    "@kit.ImageKit": "系统Kit，无需声明版本"
  }
}
```

### 环境要求
- HarmonyOS API版本：4.1.0(11)及以上（基础功能）
- HarmonyOS API版本：5.0.0(12)及以上（纹理功能）
- HarmonyOS API版本：5.0.3(15)及以上（分段纹理功能）
- 开发环境：DevEco Studio 3.1及以上
- 运行环境：HarmonyOS设备或模拟器

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.MapKit'
```
**解决方法**：确认项目配置正确，SDK版本支持Map Kit

**问题2：类型定义错误**
```
Error: Property 'addPolyline' does not exist on type 'MapComponentController'
```
**解决方法**：确认SDK版本不低于4.1.0(11)，map模块已正确导入

**问题3：纹理功能不可用**
```
Error: Property 'customTexture' does not exist on type 'MapPolylineOptions'
```
**解决方法**：确认API版本不低于5.0.0(12)，升级SDK版本

## 常见问题与解决方法

### Q1：折线不显示或显示位置不正确
**原因**：
- 地图未初始化或未加载完成
- 折线顶点坐标值错误或超出范围
- visible属性设置为false
- 折线颜色与地图背景色相同

**解决方法**：
- 确保在地图初始化回调中或地图加载完成后添加折线
- 验证latitude在[-90, 90]范围内，longitude在[-180, 180)范围内
- 检查visible属性设置为true
- 使用明显不同的颜色值

### Q2：分段颜色或渐变效果不生效
**原因**：
- colors数组未设置或为空
- gradient属性设置为false
- colors数组元素数量不足

**解决方法**：
- 设置colors数组，至少包含2个颜色值
- 启用gradient属性设置为true
- colors数组元素数量应与折线段数匹配

### Q3：纹理折线显示异常
**原因**：
- 纹理图片路径错误或文件不存在
- 纹理图片格式不支持或尺寸不合适
- API版本不支持纹理功能

**解决方法**：
- 确认纹理图片存放在resources/rawfile目录下
- 使用PNG格式透明背景的纹理图片
- 确认API版本不低于5.0.0(12)

### Q4：分段纹理设置失败
**原因**：
- customTextureIndexes数组长度与points数组长度不一致
- customTextureIndexes元素值超出customTextures数组索引范围
- API版本不支持分段纹理功能

**解决方法**：
- 确保customTextureIndexes数组长度与points数组长度完全一致
- customTextureIndexes每个元素值应在0到customTextures.length-1范围内
- 确认API版本不低于5.0.3(15)

### Q5：折线点击事件不响应
**原因**：
- clickable属性设置为false
- 未注册折线点击事件监听
- 折线宽度太小，难以点击

**解决方法**：
- 设置clickable属性为true
- 注册折线点击事件监听器
- 增加折线宽度（建议至少10px）

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "message": "折线绘制完成",
  "polylineId": "MapPolyline实例对象",
  "pointsCount": "折线顶点数量",
  "features": {
    "gradient": "是否启用渐变",
    "segmentColors": "是否设置分段颜色",
    "texture": "是否使用纹理",
    "segmentTextures": "是否使用分段纹理"
  },
  "apiUsed": [
    "MapPolylineOptions",
    "addPolyline",
    "MapPolyline",
    "setColors",
    "setGradient",
    "setCustomTexture",
    "setCustomTextureIndexes"
  ]
}
```

## 参考文档

- [API开发指南：折线](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/map-polyline)
- [API参考：MapPolylineOptions](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common)
- [API参考：addPolyline方法](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller)
- [API参考：MapPolyline对象](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mappolyline)

## 完整示例代码

- [ArkTS示例：基础折线绘制](assets/basic_polyline.ets)
- [ArkTS示例：分段颜色折线](assets/segment_colors_polyline.ets)
- [ArkTS示例：渐变折线](assets/gradient_polyline.ets)
- [ArkTS示例：纹理折线](assets/texture_polyline.ets)
- [ArkTS示例：分段纹理折线](assets/segment_texture_polyline.ets)

## 测试用例

### 正向测试用例
- [基础折线绘制测试](tests/test_basic_polyline.ets)：验证基本折线绘制功能
- [分段颜色测试](tests/test_segment_colors.ets)：验证分段颜色设置功能
- [渐变效果测试](tests/test_gradient.ets)：验证渐变效果功能
- [纹理绘制测试](tests/test_texture.ets)：验证纹理绘制功能

### 边界测试用例
- [坐标边界测试](tests/test_coordinate_boundary.ets)：验证坐标边界值处理
- [宽度边界测试](tests/test_width_boundary.ets)：验证宽度边界值处理
- [顶点数量测试](tests/test_points_count.ets)：验证大量顶点性能

### 异常测试用例
- [无效参数测试](tests/test_invalid_params.ets)：验证参数校验和错误处理
- [纹理加载失败测试](tests/test_texture_load_failure.ets)：验证纹理加载失败降级方案
- [地图未初始化测试](tests/test_map_not_initialized.ets)：验证地图未初始化时的处理