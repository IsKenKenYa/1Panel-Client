---
name: hmos-map-kit-image-overlay
description: 在地图上添加图片覆盖物图层,支持设置位置范围透明度旋转角度点击事件,最大支持200MB图片,适用于地图标注、区域展示、可视化叠加场景
---

# 地图覆盖物技能

## 功能描述

本技能实现HarmonyOS地图组件的图片覆盖物功能。覆盖物是固定在地图表面的图像图层,不会遮挡地图上的文字和图标标注,可随地图的平移、缩放、旋转等操作自动调整位置和大小。

核心功能:
- 通过`ImageOverlayParams`配置覆盖物参数
- 使用`addImageOverlay`API添加覆盖物到地图
- 支持设置覆盖物的矩形区域范围(`bounds`)或中心位置(`position`)
- 可配置透明度、旋转角度、锚点位置、点击事件等属性
- 覆盖物图片支持多种格式:jpg、jpeg、png、gif、webp、svg

## 使用场景

### 触发词
- "添加地图覆盖物"
- "在地图上显示图片"
- "地图图片叠加"
- "地图覆盖图层"
- "ImageOverlay"

### 能做
- 在地图指定区域添加图片覆盖物
- 设置覆盖物的透明度、旋转角度、尺寸
- 配置覆盖物的点击事件监听
- 动态更新覆盖物的位置、图片、属性
- 查询覆盖物的当前状态信息

### 绝不做
- 不支持添加视频或动态内容覆盖物
- 不处理超出200MB大小的图片文件
- 不支持覆盖物的复杂动画效果
- 不替代地图底图或样式设置
- 不处理超出地图范围的覆盖物坐标

### 补充
- 覆盖物图片需存放在`resources/rawfile`目录下
- 覆盖物的`bounds`和`position`参数必须至少设置其中一个
- 使用`bounds`时无需设置`width`,使用`position`时必须设置`width`
- 建议覆盖物图片使用透明背景,避免遮挡地图内容

## 调用规范和规则

### 输入约束
- 图片大小:最大200MB
- 图片格式:jpg、jpeg、png、gif、webp、svg
- 经纬度范围:latitude [-90, 90], longitude [-180, 180)
- 透明度范围:[0, 1],0表示不透明,1表示全透明
- 旋转角度范围:[0, 360),超出范围自动换算
- 锚点范围:anchorU/anchorV [0, 1]

### 执行约束
- 最大耗时:5秒(添加覆盖物操作)
- 最大迭代次数:无限制(可多次添加覆盖物)
- API调用频次:无限制
- 必须在地图初始化回调中执行添加操作

### 内容约束
- 禁止生成:超出地图范围的覆盖物坐标
- 禁止使用高危函数:无
- 禁止操作:删除非当前技能创建的覆盖物

### 降级约束
- 图片加载失败:提示用户检查图片路径和格式,使用默认占位图
- 坐标无效:自动调整为有效范围或提示用户修正
- 内存不足:提示用户减少覆盖物数量或减小图片大小
- 权限不足:提示用户申请必要的地图权限

## 调用流程和步骤

### 步骤1:准备阶段

**前置校验**:
1. 验证图片文件存在于`resources/rawfile`目录
2. 验证图片格式符合要求(jpg/jpeg/png/gif/webp/svg)
3. 验证经纬度坐标在有效范围内
4. 验证透明度和旋转角度参数在取值范围内

**参数准备**:
```typescript
import { map, mapCommon, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

let imageOverlayParams: mapCommon.ImageOverlayParams = {
  bounds: {
    southwest: { latitude: 32, longitude: 118 },
    northeast: { latitude: 32.4, longitude: 118.4 }
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
```

### 步骤2:初始化地图并添加覆盖物

**示例代码**:
```typescript
@Entry
@Component
struct ImageOverlayDemo {
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapEventManager?: map.MapEventManager;

  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: { latitude: 32.2, longitude: 118.2 },
        zoom: 10
      }
    };

    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        this.mapEventManager = this.mapController.getEventManager();
        
        try {
          let imageOverlay = await this.mapController?.addImageOverlay(imageOverlayParams);
          console.info('ImageOverlay added successfully');
        } catch (e) {
          console.error(`Failed to add imageOverlay, code: ${e.code}, message: ${e.message}`);
        }
      } else {
        console.error(`Failed to initialize map, code: ${err.code}, message: ${err.message}`);
      }
    };
  }

  build() {
    Stack() {
      Column() {
        MapComponent({
          mapOptions: this.mapOptions,
          mapCallback: this.callback,
        })
          .width('100%')
          .height('100%');
      }.width('100%')
    }.height('100%')
  }
}
```

### 步骤3:设置点击监听事件

```typescript
let imageOverlayCallback: Callback<map.ImageOverlay> = (imageOverlay: map.ImageOverlay) => {
  console.info('ImageOverlay clicked');
  let bounds = imageOverlay.getBounds();
  let position = imageOverlay.getPosition();
  console.info(`Bounds: SW(${bounds.southwest.latitude}, ${bounds.southwest.longitude}), NE(${bounds.northeast.latitude}, ${bounds.northeast.longitude})`);
};

this.mapEventManager.on('imageOverlayClick', imageOverlayCallback);
```

### 步骤4:动态更新覆盖物属性

```typescript
async function updateImageOverlay(imageOverlay: map.ImageOverlay) {
  try {
    imageOverlay.setBearing(180);
    imageOverlay.setTransparency(0.5);
    imageOverlay.setClickable(true);
    
    let newBounds: mapCommon.LatLngBounds = {
      southwest: { latitude: 32.1, longitude: 118.1 },
      northeast: { latitude: 32.5, longitude: 118.5 }
    };
    imageOverlay.setBounds(newBounds);
    
    await imageOverlay.setImage('icon/new_icon.png');
    console.info('ImageOverlay updated successfully');
  } catch (error) {
    console.error('Failed to update imageOverlay:', error.message);
  }
}
```

### 步骤5:错误处理

```typescript
try {
  let imageOverlay = await this.mapController?.addImageOverlay(imageOverlayParams);
} catch (error) {
  switch (error.code) {
    case 401:
      console.error('Invalid input parameter. Check bounds/position and image path.');
      break;
    case 1002601001:
      console.error('Map controller does not exist. Initialize map first.');
      break;
    default:
      console.error(`Unknown error: code ${error.code}, message ${error.message}`);
  }
}
```

### 步骤6:降级处理

```typescript
async function addImageOverlayWithFallback(params: mapCommon.ImageOverlayParams) {
  try {
    let overlay = await this.mapController?.addImageOverlay(params);
    return overlay;
  } catch (error) {
    if (error.code === 401) {
      console.warn('Invalid parameters, using fallback configuration');
      let fallbackParams: mapCommon.ImageOverlayParams = {
        bounds: {
          southwest: { latitude: 30, longitude: 110 },
          northeast: { latitude: 35, longitude: 120 }
        },
        image: 'icon/default_icon.png',
        transparency: 0.5,
        visible: true
      };
      return await this.mapController?.addImageOverlay(fallbackParams);
    } else {
      console.error('Failed to add imageOverlay even with fallback');
      return null;
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Invalid input parameter | 检查bounds/position参数是否有效,image路径是否正确 |
| 1002601001 | The object to be operated does not exist | 确保mapController已初始化,地图组件已加载 |
| 1002601005 | Failed to load image | 检查图片路径、格式、大小是否符合要求 |

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
- HarmonyOS API版本:>=5.0.0(12)
- 开发环境:DevEco Studio >=3.1
- 模型约束:Stage模型

### 常见编译问题

**问题1:导入模块失败**
```
Error: Cannot find module '@kit.MapKit'
```
**解决方法**:检查项目SDK版本配置,确保HarmonyOS SDK版本>=5.0.0(12)

**问题2:地图组件未加载**
```
Error: MapController is undefined
```
**解决方法**:确保在地图初始化回调中执行添加覆盖物操作,不要在组件构造函数中调用

**问题3:图片路径无效**
```
Error: Image file not found
```
**解决方法**:确保图片存放在`resources/rawfile`目录,使用相对路径格式(如'icon/icon.png')

## 常见问题与解决方法

### Q1:覆盖物不显示在地图上
**原因**:图片路径错误、透明度设置为1、visible设置为false、bounds范围超出地图可视区域
**解决方法**:
- 检查图片路径是否正确(应存放在resources/rawfile目录)
- 检查transparency参数(0表示不透明,1表示全透明)
- 检查visible参数是否为true
- 确保bounds范围在地图可视区域内或调整地图相机位置

### Q2:覆盖物位置不正确
**原因**:经纬度坐标错误、bounds参数设置错误、锚点位置设置不当
**解决方法**:
- 验证经纬度坐标在有效范围内(latitude [-90,90], longitude [-180,180))
- 检查bounds的southwest和northeast是否正确(southwest纬度应小于northeast纬度)
- 检查anchorU和anchorV参数(默认0.5表示居中)

### Q3:点击事件无响应
**原因**:clickable参数设置为false、事件监听未正确设置
**解决方法**:
- 确保ImageOverlayParams的clickable设置为true
- 确保使用mapEventManager.on('imageOverlayClick', callback)设置监听
- 确保回调函数参数类型为Callback<map.ImageOverlay>

### Q4:如何动态更新覆盖物图片
**原因**:需要使用setImage方法异步更新
**解决方法**:
```typescript
await imageOverlay.setImage('icon/new_icon.png');
```
注意:setImage是异步方法,需要使用await等待完成

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "imageOverlayId": "overlay_xxx",
  "bounds": {
    "southwest": { "latitude": 32, "longitude": 118 },
    "northeast": { "latitude": 32.4, "longitude": 118.4 }
  },
  "transparency": 0.3,
  "clickable": true,
  "visible": true,
  "apiUsed": [
    "mapCommon.ImageOverlayParams",
    "map.MapComponentController.addImageOverlay",
    "map.ImageOverlay",
    "map.MapEventManager.on"
  ]
}
```

## 参考文档

- [覆盖物开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/map-coverings)
- [ImageOverlayParams API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common)
- [addImageOverlay API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller)
- [ImageOverlay API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-imageoverlay)

## 完整示例代码

- [ArkTS完整示例](assets/ImageOverlayDemo.ets)
- [配置文件示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [添加标准覆盖物](tests/test_positive.ts):验证正常添加覆盖物功能
- [使用bounds设置范围](tests/test_bounds.ts):验证通过bounds设置覆盖物区域
- [使用position设置位置](tests/test_position.ts):验证通过position和width设置覆盖物
- [设置点击事件](tests/test_click.ts):验证覆盖物点击事件监听

### 边界测试用例
- [最小透明度](tests/test_transparency_min.ts):验证transparency=0时的显示效果
- [最大透明度](tests/test_transparency_max.ts):验证transparency=1时的显示效果
- [最大旋转角度](tests/test_bearing_max.ts):验证bearing接近360时的旋转效果
- [边界坐标](tests/test_bounds_limit.ts):验证经纬度在边界值时的覆盖物显示

### 异常测试用例
- [无效图片路径](tests/test_invalid_image.ts):验证图片路径错误时的错误处理
- [无效坐标范围](tests/test_invalid_bounds.ts):验证bounds参数错误时的错误处理
- [超出大小限制](tests/test_large_image.ts):验证图片大小超限时的降级处理
- [权限不足](tests/test_no_permission.ts):验证地图权限未申请时的错误提示