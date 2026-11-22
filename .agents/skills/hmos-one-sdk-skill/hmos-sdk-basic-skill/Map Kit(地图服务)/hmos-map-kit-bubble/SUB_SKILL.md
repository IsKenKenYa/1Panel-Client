---
name: hmos-map-kit-bubble
description: 在地图指定位置添加气泡，支持四方向图标、碰撞规则、位置优化、动画和点击事件，适用于道路测速、拥堵情况显示场景
---

# 气泡技能

## 功能描述

气泡用于在地图道路上的指定位置显示测速、拥堵情况等信息。支持设置四个方向的图标（传入的图标宽高需相同），支持设置图标碰撞规则，支持设置候选坐标段使气泡在最佳线段位置上，支持设置图标动画，支持添加点击事件。

**核心能力**：
- 在地图指定位置添加气泡覆盖物
- 支持设置四个方向的图标（必须提供4个图标）
- 支持碰撞规则设置（forceVisible、priority）
- 支持显示层级控制（minZoom、maxZoom）
- 支持缩放动画效果
- 支持点击事件监听

## 使用场景

### 触发词
- "添加气泡"
- "地图气泡"
- "道路测速显示"
- "拥堵情况标注"
- "限速标志"
- "Map Kit气泡"

### 能做
- 在地图上添加单个或多个气泡
- 设置气泡的四个方向图标
- 配置气泡的碰撞优先级和显示规则
- 设置气泡的显示层级范围
- 为气泡添加缩放动画效果
- 监听气泡的点击事件

### 绝不做
- 不支持在非道路位置添加气泡
- 不支持少于4个方向的图标
- 不支持宽高不同的图标
- 不处理地图初始化失败的情况（需用户自行处理）

### 补充
- 图标必须存放在resources/rawfile目录下
- 图标宽高必须相同
- 气泡位置基于多个候选坐标段计算最佳位置
- 需要在地图初始化回调中添加气泡

## 调用规范和规则

### 输入约束
- 图标数量：必须提供4个方向的图标
- 图标宽高：必须相同
- 图标格式：支持jpg、jpeg、png、gif、webp、svg
- 图标路径：必须存放在resources/rawfile目录下
- 坐标范围：纬度[-90, 90]，经度[-180, 180]
- 层级范围：minZoom和maxZoom范围[2, 20]
- priority范围：number类型，数值越大优先级越低

### 执行约束
- 必须在地图初始化完成后添加气泡
- 每次调用addBubble添加一个气泡
- 异步API调用，使用Promise回调
- 设置动画需先调用setAnimation再调用startAnimation

### 内容约束
- 禁止使用虚假的API名称
- 禁止推测API参数类型
- 禁止使用高危函数（eval、exec等）
- 必须进行参数校验和异常捕获
- 必须处理错误码返回

### 降级约束
- 图标加载失败：记录错误日志，使用默认图标
- 气泡创建失败：记录错误码和message，提示用户
- 地图未初始化：提示用户等待地图初始化完成
- 网络异常：重试最多3次，记录失败原因

## 调用流程和步骤

### 步骤1：准备阶段

**导入模块**：
```typescript
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
```

**初始化地图组件**：
```typescript
@Entry
@Component
struct BubbleDemo {
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private bubble?: map.Bubble;
  
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
  }
}
```

**参数校验**：
```typescript
function validateBubbleParams(params: mapCommon.BubbleParams): boolean {
  if (!params.positions || params.positions.length === 0) {
    console.error('positions参数不能为空');
    return false;
  }
  if (!params.icons || params.icons.length !== 4) {
    console.error('必须提供4个方向的图标');
    return false;
  }
  if (params.minZoom < 2 || params.maxZoom > 20 || params.minZoom > params.maxZoom) {
    console.error('minZoom和maxZoom必须在[2, 20]范围内，且minZoom <= maxZoom');
    return false;
  }
  return true;
}
```

### 步骤2：创建气泡参数

**定义气泡参数**：
```typescript
let bubbleOptions: mapCommon.BubbleParams = {
  positions: [[{
    latitude: 39.918,
    longitude: 116.397
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
```

### 步骤3：调用API添加气泡

**添加气泡示例代码**：
```typescript
this.callback = async (err, mapController) => {
  if (!err) {
    this.mapController = mapController;
    
    if (!validateBubbleParams(bubbleOptions)) {
      console.error('气泡参数校验失败');
      return;
    }
    
    try {
      this.bubble = await this.mapController.addBubble(bubbleOptions);
      console.info('气泡添加成功');
    } catch (e) {
      console.error(`Failed to create the bubble, code is：${e.code}, message is ${e.message}`);
    }
  } else {
    console.error(`Failed to initialize the map, code is：${err.code}, message is ${err.message}`);
  }
};
```

### 步骤4：监听气泡点击事件

**设置点击事件监听**：
```typescript
let callback = (bubble: map.Bubble) => {
  console.info("bubbleClick", `callback bubble = ${bubble.getId()}`);
};
this.mapController?.on("bubbleClick", callback);
```

### 步骤5：设置气泡动画

**创建缩放动画**：
```typescript
let animation: map.ScaleAnimation = new map.ScaleAnimation(1, 3, 1, 3);
animation.setDuration(3000);

let callbackStart = () => {
  console.info("animationStart", `callback`);
};
animation.on("animationStart", callbackStart);

let callbackEnd = () => {
  console.info("animationEnd", `callback`);
};
animation.on("animationEnd", callbackEnd);

animation.setFillMode(map.AnimationFillMode.BACKWARDS);
animation.setRepeatMode(map.AnimationRepeatMode.REVERSE);
animation.setInterpolator(Curve.Linear);
animation.setRepeatCount(100);
```

**设置并启动动画**：
```typescript
this.bubble.setAnimation(animation);
this.bubble.startAnimation();
```

### 步骤6：错误处理

**错误处理代码**：
```typescript
try {
  this.bubble = await this.mapController.addBubble(bubbleOptions);
} catch (error) {
  switch (error.code) {
    case 401:
      console.error('Invalid input parameter');
      break;
    case 1002601001:
      console.error('The object to be operated does not exist');
      break;
    default:
      console.error('Unknown error:', error.message);
  }
}
```

### 步骤7：降级处理

**图标加载失败降级**：
```typescript
async function loadBubbleWithFallback(mapController: map.MapComponentController, options: mapCommon.BubbleParams): Promise<map.Bubble | null> {
  try {
    return await mapController.addBubble(options);
  } catch (e) {
    if (e.code === 1002601001) {
      console.warn('图标加载失败，尝试使用默认图标');
      const defaultIcons = ['default1.png', 'default2.png', 'default3.png', 'default4.png'];
      options.icons = defaultIcons;
      try {
        return await mapController.addBubble(options);
      } catch (retryError) {
        console.error('降级方案失败:', retryError.message);
        return null;
      }
    }
    console.error('气泡创建失败:', e.message);
    return null;
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Invalid input parameter | 检查参数类型和取值范围，确保positions非空，icons包含4个元素 |
| 1002601001 | The object to be operated does not exist | 确保地图已初始化完成，mapController不为空 |
| 1002601005 | Failed to generate the icon of the customized component | 检查图标路径和格式，确保图标存在于resources/rawfile目录 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.MapKit": "^4.1.0",
    "@kit.BasicServicesKit": "^4.1.0"
  }
}
```

### 环境要求
- HarmonyOS版本：4.1.0(11)及以上
- 开发环境：DevEco Studio
- 运行环境：Stage模型
- 图标资源：必须存放在resources/rawfile目录

### 常见编译问题

**问题1：图标路径找不到**
```
Error: Cannot find module 'speed_limit_10.png'
```
**解决方法**：确保图标文件存放在resources/rawfile目录下，使用相对路径引用

**问题2：API导入失败**
```
Error: Cannot find name 'mapCommon'
```
**解决方法**：确保正确导入模块：`import { mapCommon } from '@kit.MapKit';`

**问题3：气泡不可见**
```
气泡添加成功但地图上不显示
```
**解决方法**：检查visible属性为true，minZoom和maxZoom范围是否包含当前地图层级，检查priority和forceVisible设置

## 常见问题与解决方法

### Q1：图标显示不正确
**原因**：图标路径错误或图标格式不支持
**解决方法**：
- 确认图标存放在resources/rawfile目录下
- 检查图标格式是否为支持的格式（jpg、jpeg、png、gif、webp、svg）
- 确认图标宽高相同

### Q2：气泡不显示
**原因**：visible属性设置错误或层级范围不匹配
**解决方法**：
- 设置visible为true
- 确认minZoom和maxZoom范围包含当前地图缩放层级
- 检查priority和forceVisible碰撞规则设置

### Q3：碰撞规则不生效
**原因**：priority设置错误或forceVisible未设置
**解决方法**：
- priority数值越大优先级越低，合理设置优先级
- 设置forceVisible为true使气泡碰撞后仍能显示

### Q4：动画不播放
**原因**：未调用startAnimation或动画参数设置错误
**解决方法**：
- 设置动画后必须调用startAnimation()
- 检查动画duration、repeatCount等参数设置
- 确认setAnimation已调用

### Q5：点击事件不触发
**原因**：未设置事件监听或事件类型错误
**解决方法**：
- 使用mapController.on("bubbleClick", callback)设置监听
- 确认事件类型为"bubbleClick"

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "bubbleId": "气泡唯一标识",
  "positions": "[[{latitude: 39.918, longitude: 116.397}]]",
  "icons": ["speed_limit_10.png", "speed_limit_20.png", "speed_limit_30.png", "speed_limit_40.png"],
  "visible": true,
  "minZoom": 2,
  "maxZoom": 20,
  "priority": 3,
  "apiUsed": [
    "mapCommon.BubbleParams",
    "map.MapComponentController.addBubble",
    "map.Bubble"
  ]
}
```

## 参考文档

- [API开发指南 - 气泡](references/map-bubble.md)
- [BubbleParams API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common)
- [addBubble API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller)
- [Bubble API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-bubble)
- [BasePriorityOverlay API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-basepriorityoverlay)

## 完整示例代码

- [ArkTS完整示例](assets/bubble_demo.ets)
- [动画示例](assets/bubble_animation.ets)
- [点击事件示例](assets/bubble_click.ets)

## 测试用例

### 正向测试用例
- [添加单个气泡](tests/test_add_single_bubble.ets)：测试添加单个气泡的基本功能
- [添加多个气泡](tests/test_add_multiple_bubbles.ets)：测试添加多个气泡的功能
- [设置动画](tests/test_bubble_animation.ets)：测试气泡动画设置和播放
- [点击事件](tests/test_bubble_click.ets)：测试气泡点击事件监听

### 边界测试用例
- [层级范围边界](tests/test_zoom_boundary.ets)：测试minZoom=2和maxZoom=20的边界情况
- [坐标范围边界](tests/test_coordinate_boundary.ets)：测试纬度和经度的边界值
- [priority边界](tests/test_priority_boundary.ets)：测试priority的极限值

### 异常测试用例
- [图标数量错误](tests/test_icon_count_error.ets)：测试少于4个图标的情况
- [图标路径错误](tests/test_icon_path_error.ets)：测试图标路径不存在的情况
- [地图未初始化](tests/test_map_not_initialized.ets)：测试地图未初始化时添加气泡
- [参数类型错误](tests/test_param_type_error.ets)：测试参数类型不正确的情况