---
name: hmos-map-kit-map-marker
description: 在地图指定位置添加标记Marker,支持自定义图标/动画/信息窗等功能,适用于位置标识/商家标记/POI展示场景
---

# 标记(Marker)技能

## 功能描述

本技能提供在HarmonyOS地图上添加标记(Marker)的完整实现方案。Marker用于在地图上标识位置、商家、建筑等任何带有位置属性的事物。支持丰富的功能特性:

- **基础功能**: 添加标记、设置位置、旋转角度、透明度、锚点等属性
- **自定义图标**: 支持自定义图标资源、PixelMap、Resource以及自定义组件实现
- **信息窗**: 支持标题、子标题的信息窗展示,可自定义信息窗组件
- **文字标注**: 支持添加文字注释(5.1.1(19)+),可控制文字显隐
- **碰撞检测**: 支持设置标记与地图POI之间的冲突处理规则(5.0.3(15)+)
- **交互事件**: 支持点击、长按(6.1.1(24)+)、拖拽等事件监听
- **动画效果**: 支持旋转、缩放、平移、透明、图片播放、组合动画
- **性能优化**: 支持碰撞检测、层级控制、可见性管理

**核心API**:
- [MarkerOptions](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common): 标记参数配置
- [addMarker](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller): 添加标记到地图
- [Marker](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-marker): 标记对象操作接口

**适用场景**: 用户位置标记、店铺位置标记、车辆位置标记、POI兴趣点展示、路径节点标识等。

## 使用场景

### 触发词
- "添加标记"
- "在地图上标记位置"
- "创建Marker"
- "显示位置标记"
- "地图标注"
- "POI标记"
- "自定义地图图标"
- "信息窗"
- "标记动画"

### 能做
- 在地图指定位置添加单个或多个标记
- 自定义标记图标(图片、PixelMap、Resource、自定义组件)
- 设置标记的各种属性(位置、旋转、透明度、锚点、层级等)
- 添加信息窗并自定义信息窗内容
- 监听标记的点击、拖拽、长按等交互事件
- 为标记添加动画效果(旋转、缩放、平移、透明、图片播放)
- 控制标记的可见性、文字显隐、碰撞检测
- 动态更新标记的位置和属性

### 绝不做
- 不支持添加超出地图范围的标记(经纬度必须在有效范围内)
- 不处理非地图组件的标记功能(仅适用于MapComponent)
- 不提供地图定位功能(仅处理标记显示,不获取用户位置)
- 不支持离线地图标记(需要联网加载地图数据)

### 补充
- **API版本要求**:
  - 基础功能: 4.1.0(11)+
  - 文字显隐控制: 5.1.1(19)+
  - 自定义组件图标: 6.0.0(20)+
  - 长按事件监听: 6.1.1(24)+
- **性能建议**: 大量标记时建议使用聚合功能或碰撞检测优化显示
- **图标要求**: 图片格式支持jpg/jpeg/png/gif/webp/svg,建议使用透明背景图片

## 调用规范和规则

### 输入约束
- **经纬度范围**: latitude [-90, 90], longitude [-180, 180)
- **图标文件大小**: 建议不超过200KB,大图标会影响性能
- **图标尺寸**: 建议不超过128x128px,过大图标会遮挡地图内容
- **文字注解长度**: 最小长度1,最大长度3(annotations数组)
- **标题长度**: 超长字符串会显示为省略号"..."
- **透明度范围**: [0, 1], 0完全透明,1完全不透明
- **旋转角度范围**: [0, 360),超出范围会自动换算
- **锚点范围**: [0, 1],建议在此范围内取值
- **层级范围**: zIndex为整数,建议范围[0, 100]

### 执行约束
- **地图初始化**: 必须在MapComponent初始化完成后的callback中调用addMarker
- **异步调用**: addMarker返回Promise,必须使用async/await或then/catch处理
- **事件监听**: 必须在地图EventManager上注册事件监听,不能直接在Marker上监听
- **动画设置**: 设置动画后必须调用startAnimation()启动,clearAnimation()清除
- **错误处理**: 必须捕获Promise异常,处理错误码(401/1002601001/1002601005)

### 内容约束
- **禁止生成**: 不生成超出API版本范围的代码(如在不支持的版本使用新功能)
- **禁止高危**: 不使用eval、动态代码执行等高危函数
- **禁止操作**: 不直接操作DOM元素,不修改地图底层实现
- **图标路径**: 图标必须存放在resources/rawfile或resources/base/media目录
- **自定义组件**: iconBuilder必须在MapComponent初始化时传入,不能动态修改

### 降级约束
- **网络失败**: 网络异常时标记可能无法正常显示,提供友好提示
- **图标加载失败**: 图标加载失败时使用默认图标,记录日志
- **参数错误**: 参数校验失败时返回错误码,不继续执行
- **地图未初始化**: 地图未初始化完成时不能添加标记,等待初始化完成
- **大量标记**: 标记数量过多时建议使用聚合功能或分页加载

## 调用流程和步骤

### 步骤1: 准备阶段(导入模块和初始化地图)

**前置校验**:
1. 确认HarmonyOS API版本>=4.1.0(11)
2. 确认已导入@kit.MapKit模块
3. 确认MapComponent已正确初始化
4. 确认mapController和mapEventManager已获取

**模块导入**:
```typescript
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
```

**地图初始化**:
```typescript
@Entry
@Component
struct MapMarkerDemo {
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapEventManager?: map.MapEventManager;
  
  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 31.984410259206815,
          longitude: 118.76625379397866
        },
        zoom: 15
      }
    };
    
    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        this.mapEventManager = this.mapController.getEventManager();
      } else {
        console.error(`Failed to initialize map: ${err.code}, ${err.message}`);
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

### 步骤2: 创建Marker基础标记

**参数准备**:
```typescript
let markerOptions: mapCommon.MarkerOptions = {
  position: {
    latitude: 31.984410259206815,
    longitude: 118.76625379397866
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
```

**添加标记**:
```typescript
try {
  let marker: map.Marker = await this.mapController.addMarker(markerOptions);
  console.info('Marker added successfully');
} catch (e) {
  console.error(`Failed to create marker: ${e.code}, ${e.message}`);
}
```

**参数说明**:
- `position`: 标记位置(必填),latitude范围[-90, 90], longitude范围[-180, 180)
- `rotation`: 旋转角度,默认0,范围[0, 360)
- `visible`: 是否可见,默认true
- `zIndex`: 层级,默认0,数值大的绘制在上层
- `alpha`: 透明度,默认1,范围[0, 1]
- `anchorU/V`: 锚点位置,默认(0.5, 1),建议范围[0, 1]
- `clickable`: 是否可点击,默认false
- `draggable`: 是否可拖拽,默认false
- `flat`: 是否平贴地图,默认false

### 步骤3: 自定义Marker图标

**使用自定义图片**:
```typescript
let markerOptions: mapCommon.MarkerOptions = {
  position: {
    latitude: 31.984410259206815,
    longitude: 118.76625379397866
  },
  icon: 'test.png'
};
```

**使用PixelMap**(5.0.0(12)+):
```typescript
import { image } from '@kit.ImageKit';

let mContext = this.getUIContext().getHostContext();
const fileData: Uint8Array = await mContext.resourceManager.getRawFileContent('icon/icon.png');
let imageSource: image.ImageSource = image.createImageSource(fileData.buffer);
let pixelMap: PixelMap = await imageSource.createPixelMap();

let markerOptions: mapCommon.MarkerOptions = {
  position: { latitude: 32.0, longitude: 118.8 },
  icon: pixelMap
};
```

**使用Resource**(5.0.0(12)+):
```typescript
let markerOptions: mapCommon.MarkerOptions = {
  position: { latitude: 32.0, longitude: 118.8 },
  icon: $r('app.media.icon')
};
```

**使用自定义组件**(6.0.0(20)+):
```typescript
let markerOptions: mapCommon.MarkerOptions = {
  position: { latitude: 32.120750, longitude: 118.788765 },
  iconBuilder: () => {
    this.renderBuilder();
  }
};

@Builder
renderBuilder() {
  Stack({ alignContent: Alignment.Center }) {
    Image($r('app.media.icon'))
      .syncLoad(true)
  }
  .height(50)
  .width(50)
}
```

### 步骤4: 添加信息窗

**基础信息窗**:
```typescript
let markerOptions: mapCommon.MarkerOptions = {
  position: { latitude: 31.984, longitude: 118.766 },
  title: '南京',
  snippet: '华东地区',
  clickable: true
};

let marker = await this.mapController.addMarker(markerOptions);
marker.setInfoWindowAnchor(0.5, 1);
marker.setInfoWindowVisible(true);
```

**自定义信息窗**:
```typescript
@Entry
@Component
struct MapMarkerDemo {
  @BuilderParam customInfoWindow: ($$: map.MarkerDelegate) => void = this.customInfoWindowBuilder;
  
  @Builder
  customInfoWindowBuilder($$: map.MarkerDelegate) {
    if ($$.marker) {
      Text($$.marker.getTitle())
        .width('50%')
        .height(50)
        .backgroundColor(Color.Green)
        .textAlign(TextAlign.Center)
        .fontColor(Color.Black)
        .font({ size: 25, weight: 10, style: FontStyle.Italic })
        .border({
          width: 3,
          color: Color.Black,
          radius: 25,
          style: BorderStyle.Dashed
        })
    }
  }
  
  build() {
    MapComponent({
      mapOptions: this.mapOptions,
      mapCallback: this.callback,
      customInfoWindow: this.customInfoWindow
    });
  }
}
```

### 步骤5: 添加文字标注(5.1.1(19)+)

**设置文字标注**:
```typescript
let markerOptions: mapCommon.MarkerOptions = {
  position: { latitude: 31.984, longitude: 118.766 },
  annotations: [{
    content: 'text',
    fontStyle: 1,
    strokeWidth: 3,
    fontSize: 15
  }]
};

let marker = await this.mapController.addMarker(markerOptions);
marker.setAnnotationVisible(false);
let isVisible: boolean = marker.isAnnotationVisible();
```

### 步骤6: 碰撞检测设置(5.0.3(15)+)

**设置碰撞规则**:
```typescript
let markerOptions: mapCommon.MarkerOptions = {
  position: { latitude: 31.984, longitude: 118.766 },
  icon: 'icon.png',
  annotations: [{
    content: 'Test',
    fontStyle: 1,
    strokeWidth: 3,
    fontSize: 15
  }],
  collisionRule: mapCommon.CollisionRule.ALL,
  annotationPosition: mapCommon.TextPosition.TOP
};
```

### 步骤7: 监听标记事件

**监听点击事件**:
```typescript
let callback = (marker: map.Marker) => {
  console.info(`on-markerClick marker = ${marker.getId()}`);
};
this.mapEventManager.on('markerClick', callback);
```

**监听拖拽事件**:
```typescript
marker.setDraggable(true);

let markerDragStartCallback = (marker: map.Marker) => {
  console.info(`on-markerDragStart marker = ${marker.getId()}`);
};
this.mapEventManager.on('markerDragStart', markerDragStartCallback);

let markerDragCallback = (marker: map.Marker) => {
  console.info(`on-markerDrag marker = ${marker.getId()}`);
};
this.mapEventManager.on('markerDrag', markerDragCallback);

let markerDragEndCallback = (marker: map.Marker) => {
  console.info(`on-markerDragEnd marker = ${marker.getId()}`);
};
this.mapEventManager.on('markerDragEnd', markerDragEndCallback);
```

**监听长按事件**(6.1.1(24)+):
```typescript
let callback = (markerLong: map.Marker) => {
  console.info(`markerLongClick marker = ${markerLong.getId()}`);
};
this.mapEventManager.onMarkerLongClick(callback);
```

### 步骤8: 添加标记动画

**旋转动画**:
```typescript
import { map, mapCommon, MapComponent } from '@kit.MapKit';

let animation = new map.RotateAnimation(0, 270);
animation.setDuration(2000);
animation.setFillMode(map.AnimationFillMode.BACKWARDS);
animation.setRepeatMode(map.AnimationRepeatMode.REVERSE);
animation.setRepeatCount(100);

let callbackStart = () => {
  console.info('animationStart');
};
animation.on('animationStart', callbackStart);

let callbackEnd = () => {
  console.info('animationEnd');
};
animation.on('animationEnd', callbackEnd);

marker.setAnimation(animation);
marker.startAnimation();
```

**图片动画播放**:
```typescript
import { image } from '@kit.ImageKit';

let images: (ResourceStr | image.PixelMap)[] = [
  'icon/avocado.png',
  'icon/20231027.png',
  $r('app.media.icon')
];

let mContext = this.getUIContext().getHostContext();
if (mContext) {
  const fileData = await mContext.resourceManager.getRawFileContent('icon/icon.png');
  let imageSource = image.createImageSource(fileData.buffer);
  let pixelMap = await imageSource.createPixelMap();
  images.push(pixelMap);
}

let animation: map.PlayImageAnimation = new map.PlayImageAnimation();
await animation.addImages(images);
animation.setDuration(3000);
animation.setFillMode(map.AnimationFillMode.BACKWARDS);
animation.setRepeatMode(map.AnimationRepeatMode.REVERSE);
animation.setRepeatCount(100);

animation.on('animationStart', () => {
  console.info('animationStart');
});
animation.on('animationEnd', () => {
  console.info('animationEnd');
});

marker.setAnimation(animation);
marker.startAnimation();
```

### 步骤9: 动态更新标记属性

**更新位置**:
```typescript
let newPosition: mapCommon.LatLng = {
  latitude: 32.0,
  longitude: 118.8
};
marker.setPosition(newPosition);
```

**更新透明度**:
```typescript
marker.setAlpha(0.5);
```

**更新旋转角度**:
```typescript
marker.setRotation(30);
```

**更新图标**:
```typescript
await marker.setIcon('new_icon.png');
```

### 步骤10: 错误处理

**完整错误处理示例**:
```typescript
try {
  let markerOptions: mapCommon.MarkerOptions = {
    position: {
      latitude: 31.984410259206815,
      longitude: 118.76625379397866
    }
  };
  
  let marker: map.Marker = await this.mapController.addMarker(markerOptions);
  console.info('Marker created successfully');
  
  marker.setDraggable(true);
  marker.setClickable(true);
  
} catch (error) {
  switch (error.code) {
    case 401:
      console.error('Invalid input parameter. Check marker options.');
      break;
    case 1002601001:
      console.error('The object to be operated does not exist. Map may not be initialized.');
      break;
    case 1002601005:
      console.error('Failed to generate the icon of the customized component.');
      break;
    default:
      console.error(`Unknown error: ${error.code}, ${error.message}`);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Invalid input parameter | 检查MarkerOptions参数是否合法,经纬度范围、参数类型等 |
| 1002601001 | The object to be operated does not exist | 确认MapComponent已初始化完成,在callback中调用addMarker |
| 1002601005 | Failed to generate the icon of the customized component | 检查自定义组件iconBuilder的实现,确认组件可正常渲染 |
| 其他错误 | 网络或系统异常 | 检查网络连接,查看日志详细信息,重试或降级处理 |

## 编译和修复问题

### 依赖声明

**oh-package.json5**:
```json
{
  "dependencies": {
    "@kit.MapKit": "^4.1.0",
    "@kit.BasicServicesKit": "^4.1.0",
    "@kit.ImageKit": "^5.0.0"
  }
}
```

**module.json5权限配置**:
```json
{
  "module": {
    "abilities": [
      {
        "name": "EntryAbility",
        "permissions": [
          "ohos.permission.LOCATION",
          "ohos.permission.APPROXIMATELY_LOCATION"
        ]
      }
    ]
  }
}
```

### 环境要求
- HarmonyOS API: >=4.1.0(11)
- DevEco Studio: >=3.1
- Node.js: >=14.19
- 设备支持: 支持地图显示的HarmonyOS设备

### 常见编译问题

**问题1: 模块导入失败**
```
Error: Cannot find module '@kit.MapKit'
```
**解决方法**: 
- 确认HarmonyOS API版本>=4.1.0
- 在oh-package.json5中添加依赖声明
- 重新编译项目

**问题2: MapComponent未初始化**
```
Error: this.mapController is undefined
```
**解决方法**: 
- 确保在MapComponent的callback中获取mapController
- 不要在aboutToAppear中直接调用addMarker
- 使用async/await确保初始化完成

**问题3: 图标加载失败**
```
Error: Failed to load icon 'test.png'
```
**解决方法**: 
- 确认图标文件存放在resources/rawfile目录
- 检查文件路径和文件名是否正确
- 确认图标格式支持(jpg/jpeg/png/gif/webp/svg)

**问题4: 自定义组件不显示**
```
Error: iconBuilder not working
```
**解决方法**: 
- 确认API版本>=6.0.0(20)
- 检查自定义组件实现是否正确
- 确保iconBuilder在MarkerOptions中正确传入

**问题5: 事件监听无效**
```
Error: markerClick event not triggered
```
**解决方法**: 
- 确认marker.setClickable(true)已设置
- 检查事件监听是否注册在mapEventManager上
- 确认事件名称正确('markerClick', 'markerDragStart'等)

## 常见问题与解决方法

### Q1: 标记不显示在地图上
**原因**: 
- 地图未初始化完成
- 经纬度超出范围
- visible设置为false
- 图标加载失败

**解决方法**:
- 确保在MapComponent callback中调用addMarker
- 检查经纬度是否在有效范围内
- 设置visible: true
- 检查图标路径和格式

### Q2: 标记图标显示为默认图标
**原因**: 
- icon参数未设置或为空
- 图标文件不存在或格式不支持
- 图标路径错误

**解决方法**:
- 正确设置icon参数
- 确认图标文件存在且格式正确
- 使用正确的相对路径或绝对路径

### Q3: 信息窗不显示
**原因**: 
- title或snippet未设置
- clickable未设置为true
- setInfoWindowVisible未调用

**解决方法**:
- 设置title和snippet参数
- 设置clickable: true
- 调用marker.setInfoWindowVisible(true)

### Q4: 标记动画不播放
**原因**: 
- 动画未设置
- startAnimation未调用
- 动画参数设置错误

**解决方法**:
- 创建动画对象并设置参数
- 调用marker.setAnimation(animation)
- 调用marker.startAnimation()

### Q5: 拖拽事件不触发
**原因**: 
- draggable未设置为true
- 事件监听未注册

**解决方法**:
- 设置marker.setDraggable(true)
- 在mapEventManager上注册事件监听

### Q6: 长按事件不触发(6.1.1(24)+)
**原因**: 
- API版本不支持
- 事件监听方法错误

**解决方法**:
- 确认API版本>=6.1.1(24)
- 使用mapEventManager.onMarkerLongClick注册监听

### Q7: 大量标记导致性能下降
**原因**: 
- 标记数量过多(建议不超过100个)
- 未使用碰撞检测
- 图标过大

**解决方法**:
- 使用标记聚合功能
- 设置collisionRule碰撞检测
- 优化图标大小(建议不超过128x128px)
- 分页加载标记

## 输出结果报告

执行完成后输出以下信息:

```typescript
{
  "status": "success",
  "markerId": "marker_001",
  "markerPosition": {
    "latitude": 31.984410259206815,
    "longitude": 118.76625379397866
  },
  "markerProperties": {
    "visible": true,
    "clickable": true,
    "draggable": true,
    "hasIcon": true,
    "hasInfoWindow": false,
    "hasAnimation": false
  },
  "apiUsed": [
    "mapCommon.MarkerOptions",
    "map.MapComponentController.addMarker",
    "map.Marker.setDraggable",
    "map.Marker.setClickable"
  ]
}
```

## 参考文档

- [API开发指南 - 标记](references/map-marker.md)
- [API参考 - MarkerOptions](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common)
- [API参考 - addMarker](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller)
- [API参考 - Marker](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-marker)

## 完整示例代码

- [基础标记示例](assets/basic_marker.ets): 添加简单标记的基本用法
- [自定义图标示例](assets/custom_icon_marker.ets): 自定义图标、PixelMap、Resource示例
- [信息窗示例](assets/info_window_marker.ets): 信息窗和自定义信息窗示例
- [事件监听示例](assets/event_listener_marker.ets): 点击、拖拽、长按事件监听
- [动画示例](assets/animation_marker.ets): 旋转、缩放、平移、图片动画示例
- [完整功能示例](assets/complete_marker_demo.ets): 所有功能的完整示例

## 测试用例

### 正向测试用例
- [测试基础标记添加](tests/test_basic_marker.ets): 验证基本标记能否正确添加和显示
- [测试自定义图标](tests/test_custom_icon.ets): 验证自定义图标能否正确加载
- [测试信息窗](tests/test_info_window.ets): 验证信息窗能否正确显示和交互
- [测试事件监听](tests/test_event_listener.ets): 验证事件监听能否正确触发

### 边界测试用例
- [测试经纬度边界值](tests/test_boundary_position.ets): 测试经纬度边界值(-90/90/-180/180)
- [测试透明度边界值](tests/test_boundary_alpha.ets): 测试透明度边界值(0/1)
- [测试旋转角度边界值](tests/test_boundary_rotation.ets): 测试旋转角度边界值(0/360)
- [测试大量标记](tests/test_many_markers.ets): 测试添加大量标记的性能

### 异常测试用例
- [测试无效经纬度](tests/test_invalid_position.ets): 测试超出范围的经纬度(错误码401)
- [测试无效图标路径](tests/test_invalid_icon.ets): 测试不存在的图标文件
- [测试地图未初始化](tests/test_no_map_init.ets): 测试地图未初始化时添加标记(错误码1002601001)
- [测试自定义组件失败](tests/test_icon_builder_fail.ets): 测试自定义组件生成失败(错误码1002601005)