---
name: hmos-map-kit-point-annotation
description: 在地图指定位置添加点注释标识位置商家建筑等,支持图标文字碰撞规则设置,可通过信息窗口展示详细信息,适用于地图标注场景
---

# 点注释技能

## 功能描述

在地图的指定位置添加点注释以标识位置、商家、建筑等,并可以通过信息窗口展示详细信息。点注释支持设置图标、文字、碰撞规则等属性,支持添加点击事件监听,支持设置缩放动画和标题动画效果。

**主要功能**:
- 在地图指定位置添加点注释标识
- 支持自定义图标、文字标题样式
- 支持碰撞规则设置(NAME/ALL/NONE)
- 支持点击事件监听
- 支持缩放动画和标题动画
- 支持更新点注释属性(显示层级、优先级等)

**技术特点**:
- 使用PointAnnotationParams配置点注释参数
- 通过MapComponentController的addPointAnnotation方法创建点注释
- 支持异步创建(Promise返回)
- 仅支持Stage模型
- 元服务API支持(从4.1.0(11)版本开始)

## 使用场景

### 触发词
- "添加点注释"
- "地图标注"
- "添加地图标记"
- "地图POI标注"
- "地图注释"
- "点注释"

### 能做
- 在地图指定坐标位置添加点注释标识
- 设置点注释的图标、标题文字样式
- 配置点注释的碰撞规则和优先级
- 设置点注释的显示层级范围
- 监听点注释的点击事件
- 设置点注释的缩放动画效果
- 设置点注释标题的字体大小动画
- 更新点注释属性(显示层级、优先级等)

### 绝不做
- 不支持在非Stage模型下使用
- 不支持添加超过3个标题
- 不支持使用非WGS84坐标系
- 不支持在碰撞规则为NONE时设置repeatable
- 不支持未设置priority时使用碰撞规则ALL
- 不直接处理地图导航功能
- 不替代Marker组件(两者功能不同)

### 补充
- 点注释图标需存放在resources/rawfile目录下
- icon参数支持相对路径和toDataURL格式(从5.0.0(12)版本开始支持PixelMap和Resource类型)
- 标题数组长度最小为1,最大为3
- fontSize取值范围[0,100],超出范围按最大值或最小值处理
- strokeWidth取值范围[0,10],超出范围按最大值或最小值处理
- 碰撞规则为ALL时必须设置priority属性
- 最小层级不大于最大层级,不小于2
- 最大层级不大于20,不小于最小层级
- 支持API版本: 4.1.0(11)及以上
- 元服务API从版本4.1.0(11)开始支持

## 调用规范和规则

### 输入约束
- 经纬度坐标: latitude范围[-90, 90], longitude范围[-180, 180)
- 标题数组长度: 最小1,最大3
- fontSize范围: [0, 100]
- strokeWidth范围: [0, 10]
- minZoom范围: [2, 20],且不大于maxZoom
- maxZoom范围: [2, 20],且不小于minZoom
- priority: 数值越大优先级越低,默认值为Number.MAX_VALUE
- anchorU/anchorV范围: [0, 1],建议值[0, 1]
- zIndex: BasePriorityOverlayParams的zIndex向下取整
- 图标格式: jpg/jpeg/png/gif/webp/svg

### 执行约束
- 必须在地图初始化回调中或自定义方法中执行
- 异步创建点注释(Promise模式)
- 碰撞规则为ALL时必须设置priority
- 碰撞规则为NONE时不支持设置repeatable
- 动画设置需要在创建点注释后执行

### 内容约束
- 禁止使用非WGS84坐标系坐标
- 禁止标题数组长度超过3
- 禁止fontSize/strokeWidth超出取值范围
- 禁止minZoom大于maxZoom
- 禁止图标路径不存在(相对路径需在resources/rawfile下)
- 禁止在碰撞规则NONE时设置repeatable=true

### 降级约束
- 地图初始化失败: 提示错误信息,不创建点注释
- 点注释创建失败: 捕获异常,记录错误码和错误信息
- 参数校验失败: 按默认值处理或抛出401错误码
- 图标加载失败: 使用默认图标
- 网络问题: 本地地图资源不影响点注释创建

## 调用流程和步骤

### 步骤1: 准备阶段

**前置校验**:
1. 确认已在Stage模型下开发
2. 确认已导入MapKit模块: `import { MapComponent, mapCommon, map } from '@kit.MapKit'`
3. 确认已导入BasicServicesKit: `import { AsyncCallback } from '@kit.BasicServicesKit'`
4. 确认地图已初始化完成(在回调中执行)
5. 确认经纬度坐标使用WGS84坐标系
6. 确认图标文件已存放在resources/rawfile目录下(如使用相对路径)

**参数准备**:
```typescript
// 定义点注释参数
let pointAnnotationOptions: mapCommon.PointAnnotationParams = {
  // 必填: 点注释图标锚点坐标
  position: {
    latitude: 32.020750,  // 纬度范围[-90, 90]
    longitude: 118.788765  // 经度范围[-180, 180)
  },
  
  // 可选: 点注释名称与地图POI名称相同时是否支持去重
  repeatable: true,  // 默认false,碰撞规则NONE时不支持设置
  
  // 可选: 点注释的碰撞规则
  collisionRule: mapCommon.CollisionRule.NAME,  // 默认NAME,可选NONE/ALL
  
  // 必填: 点注释的标题,数组长度最小1最大3
  titles: [{
    content: "南京夫子庙",  // 标题内容
    color: 0xFF000000,  // 字体颜色ARGB格式,默认0xFF000000(黑色)
    fontSize: 15,  // 字体大小[0,100],默认15
    strokeColor: 0xFFFFFFFF,  // 描边颜色ARGB格式,默认0xFFFFFFFF(白色)
    strokeWidth: 2,  // 描边宽度[0,10],默认2
    fontStyle: mapCommon.FontStyle.ITALIC  // 字体样式,默认REGULAR
  }],
  
  // 可选: 点注释图标
  icon: "",  // 相对路径或toDataURL格式,不传使用默认图标
  
  // 可选: 是否展示图标
  showIcon: true,  // 默认true
  
  // 可选: 锚点水平位置[0,1],默认0.5
  anchorU: 0.5,
  
  // 可选: 锚点垂直位置[0,1],默认1
  anchorV: 1,
  
  // 可选: 碰撞后是否仍能显示,默认false
  forceVisible: false,
  
  // 可选: 碰撞优先级(数值越大优先级越低),默认Number.MAX_VALUE
  // 碰撞规则ALL时必须设置
  priority: 3,
  
  // 可选: 展示最小层级[2,20],默认2
  minZoom: 2,
  
  // 可选: 展示最大层级[2,20],默认20
  maxZoom: 20,
  
  // 可选: 是否可见,默认true
  visible: true,
  
  // 可选: 叠加层级属性,zIndex向下取整,默认0
  zIndex: 10
};
```

### 步骤2: 创建点注释

**示例代码**:
```typescript
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct PointAnnotationDemo {
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapEventManager?: map.MapEventManager;
  private pointAnnotation?: map.PointAnnotation;

  aboutToAppear(): void {
    // 初始化地图参数
    this.mapOptions = {
      position: {
        target: {
          latitude: 32.020750,
          longitude: 118.788765
        },
        zoom: 14
      }
    };

    // 地图初始化回调
    this.callback = async (err, mapController) => {
      if (!err) {
        // 获取地图控制器
        this.mapController = mapController;
        // 获取事件管理器
        this.mapEventManager = this.mapController.getEventManager();

        // 准备点注释参数
        let pointAnnotationOptions: mapCommon.PointAnnotationParams = {
          position: {
            latitude: 32.020750,
            longitude: 118.788765
          },
          repeatable: true,
          collisionRule: mapCommon.CollisionRule.NAME,
          titles: [{
            content: "南京夫子庙",
            color: 0xFF000000,
            fontSize: 15,
            strokeColor: 0xFFFFFFFF,
            strokeWidth: 2,
            fontStyle: mapCommon.FontStyle.ITALIC
          }],
          icon: "",
          showIcon: true,
          anchorU: 0.5,
          anchorV: 1,
          forceVisible: false,
          priority: 3,
          minZoom: 2,
          maxZoom: 20,
          visible: true,
          zIndex: 10
        };

        // 创建点注释
        try {
          this.pointAnnotation = await this.mapController.addPointAnnotation(pointAnnotationOptions);
          console.info('PointAnnotation created successfully');
        } catch (e) {
          console.error(`Failed to create pointAnnotation, code: ${e.code}, message: ${e.message}`);
        }
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

### 步骤3: 更新点注释属性

**示例代码**:
```typescript
// 设置点注释的显示层级为3~14级
this.pointAnnotation.setZoom(3, 14);

// 设置点注释的碰撞优先级为10
this.pointAnnotation.setPriority(10);
```

### 步骤4: 监听点注释点击事件

**示例代码**:
```typescript
// 设置点注释点击事件监听
let callback = (pointAnnotation: map.PointAnnotation) => {
  console.info("pointAnnotationClick", `pointAnnotationClick: ${pointAnnotation.getId()}`);
};
this.mapEventManager.on("pointAnnotationClick", callback);

// 取消监听(可选)
this.mapEventManager.off("pointAnnotationClick", callback);
```

### 步骤5: 设置点注释动画

**示例代码**:
```typescript
// 创建缩放动画
let animation: map.ScaleAnimation = new map.ScaleAnimation(1, 3, 1, 3);

// 设置动画单次时长(单位ms)
animation.setDuration(3000);

// 设置动画开始监听
let callbackStart = () => {
  console.info("animationStart", `callback`);
};
animation.on("animationStart", callbackStart);

// 设置动画结束监听
let callbackEnd = () => {
  console.info("animationEnd", `callback`);
};
animation.on("animationEnd", callbackEnd);

// 设置动画执行完成的状态
animation.setFillMode(map.AnimationFillMode.BACKWARDS);

// 设置动画重复方式
animation.setRepeatMode(map.AnimationRepeatMode.REVERSE);

// 设置动画插值器
animation.setInterpolator(Curve.Linear);

// 设置动画重复次数
animation.setRepeatCount(100);

// 设置并启动动画
this.pointAnnotation.setAnimation(animation);
this.pointAnnotation.startAnimation();
```

### 步骤6: 设置标题动画

**示例代码**:
```typescript
// 创建字体大小动画
let animation: map.FontSizeAnimation = new map.FontSizeAnimation(15, 45);

// 设置动画时长
animation.setDuration(3000);

// 设置动画监听
animation.on("animationStart", () => {
  console.info("animationStart");
});
animation.on("animationEnd", () => {
  console.info("animationEnd");
});

// 设置动画属性
animation.setFillMode(map.AnimationFillMode.FORWARDS);
animation.setRepeatMode(map.AnimationRepeatMode.REVERSE);
animation.setInterpolator(Curve.Linear);
animation.setRepeatCount(100);

// 设置并启动标题动画
this.pointAnnotation.setTitleAnimation(animation);
this.pointAnnotation.startTitleAnimation();
```

### 步骤7: 错误处理

**示例代码**:
```typescript
try {
  // 创建点注释
  this.pointAnnotation = await this.mapController.addPointAnnotation(pointAnnotationOptions);
  console.info('Success: PointAnnotation created');
} catch (error) {
  // 错误处理
  switch (error.code) {
    case 401:
      console.error('Error: Invalid input parameter');
      // 降级处理:检查参数是否符合约束
      if (pointAnnotationOptions.position.latitude < -90 || pointAnnotationOptions.position.latitude > 90) {
        console.error('Latitude out of range');
      }
      if (pointAnnotationOptions.titles.length < 1 || pointAnnotationOptions.titles.length > 3) {
        console.error('Titles array length invalid');
      }
      break;
    default:
      console.error(`Error: ${error.message}`);
      // 降级方案:使用默认参数重新创建
      let defaultOptions: mapCommon.PointAnnotationParams = {
        position: { latitude: 32.020750, longitude: 118.788765 },
        titles: [{ content: "Default Title" }]
      };
      this.pointAnnotation = await this.mapController.addPointAnnotation(defaultOptions);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Invalid input parameter | 检查参数是否符合约束条件:经纬度范围、标题数组长度、层级范围等 |
| 地图初始化失败 | Map initialization failed | 检查MapOptions参数是否正确,确认网络连接正常 |
| 点注释创建失败 | Failed to create pointAnnotation | 检查PointAnnotationParams参数,确认地图已初始化 |
| 动画设置失败 | Animation setup failed | 确认点注释已成功创建,检查动画参数范围 |

**常见错误场景**:
1. 经纬度超出范围: latitude不在[-90,90]或longitude不在[-180,180)
2. 标题数组长度错误: 长度小于1或大于3
3. 层级范围错误: minZoom大于maxZoom,或超出[2,20]范围
4. 碰撞规则配置错误: collisionRule为ALL时未设置priority
5. repeatable配置错误: collisionRule为NONE时设置repeatable=true
6. 地图未初始化: 在地图初始化回调外创建点注释
7. 图标路径错误: 图标文件不存在于resources/rawfile目录

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
- HarmonyOS SDK: 4.1.0(11)及以上
- DevEco Studio: 3.1及以上
- Stage模型开发环境
- 元服务支持: 从版本4.1.0(11)开始

### 常见编译问题

**问题1: 导入模块失败**
```
Error: Cannot find module '@kit.MapKit'
```
**解决方法**: 
- 确认HarmonyOS SDK版本不低于4.1.0(11)
- 在oh-package.json5中添加依赖声明
- 同步项目依赖: DevEco Studio -> File -> Sync Project with Gradle Files

**问题2: 类型错误**
```
Error: Type 'PointAnnotationParams' is not defined
```
**解决方法**: 
- 确认已正确导入mapCommon模块
- 检查导入语句: `import { mapCommon } from '@kit.MapKit'`
- 确认SDK版本支持该类型(4.1.0(11)及以上)

**问题3: Stage模型限制**
```
Error: This interface can only be used in Stage model
```
**解决方法**: 
- 确认项目使用Stage模型
- 在module.json5中配置: `"type": "page"`
- 不支持FA模型

**问题4: 地图初始化失败**
```
Error: Failed to initialize map
```
**解决方法**: 
- 检查MapOptions参数是否正确
- 确认网络连接正常
- 确认地图API key已正确配置
- 检查设备是否支持地图功能

**问题5: 点注释创建失败**
```
Error: Failed to create pointAnnotation, code: 401
```
**解决方法**: 
- 检查经纬度坐标范围
- 检查标题数组长度(1-3)
- 检查层级范围(minZoom <= maxZoom)
- 检查碰撞规则配置(collisionRule为ALL时必须设置priority)
- 检查字体大小和描边宽度范围

## 常见问题与解决方法

### Q1: 点注释图标不显示
**原因**: 
- 图标路径错误
- 图标文件格式不支持
- showIcon设置为false
- 图标文件未存放在resources/rawfile目录

**解决方法**: 
- 确认图标文件存在于resources/rawfile目录
- 使用相对路径格式: `icon: 'icon.png'`
- 确认图标格式为jpg/jpeg/png/gif/webp/svg
- 设置showIcon为true
- 从5.0.0(12)版本开始支持PixelMap和Resource类型

### Q2: 点注释标题文字样式不生效
**原因**: 
- fontSize超出范围[0,100]
- strokeWidth超出范围[0,10]
- color/strokeColor格式错误
- fontStyle值错误

**解决方法**: 
- 使用ARGB格式颜色值: `0xFF000000`
- 确保fontSize在[0,100]范围内
- 确保strokeWidth在[0,10]范围内
- 使用mapCommon.FontStyle枚举值(REGULAR/BOLD/ITALIC/BOLD_ITALIC)

### Q3: 点注释碰撞规则不生效
**原因**: 
- collisionRule设置为ALL但未设置priority
- collisionRule设置为NONE但设置了repeatable
- priority值设置不合理

**解决方法**: 
- collisionRule为ALL时必须设置priority属性
- collisionRule为NONE时不支持设置repeatable
- priority数值越大优先级越低,根据需求合理设置

### Q4: 点注释在特定层级不显示
**原因**: 
- minZoom设置过大
- maxZoom设置过小
- 当前地图层级不在[minZoom, maxZoom]范围内
- visible设置为false

**解决方法**: 
- 检查minZoom和maxZoom设置是否合理
- 确保minZoom <= maxZoom,范围在[2,20]
- 使用setZoom方法动态调整显示层级
- 设置visible为true

### Q5: 点注释点击事件不触发
**原因**: 
- 未设置事件监听器
- 事件监听器设置时机错误(在点注释创建前)
- 点注释被碰撞隐藏

**解决方法**: 
- 在点注释创建成功后设置事件监听
- 使用mapEventManager.on("pointAnnotationClick", callback)
- 设置forceVisible为true保证点击事件可触发

### Q6: 动画效果不显示
**原因**: 
- 点注释未成功创建
- 动画参数设置错误
- 未调用startAnimation或startTitleAnimation方法

**解决方法**: 
- 确认点注释创建成功后再设置动画
- 检查动画参数范围是否正确
- 调用startAnimation()或startTitleAnimation()启动动画
- 设置合理的动画时长和重复次数

### Q7: 在元服务中使用点注释报错
**原因**: 
- 元服务API版本不支持
- 未配置元服务权限

**解决方法**: 
- 确认元服务API版本不低于4.1.0(11)
- 在module.json5中配置元服务权限
- 检查元服务是否支持地图功能

### Q8: 多个点注释重叠显示混乱
**原因**: 
- 碰撞规则设置不当
- priority设置不合理
- zIndex设置不当
- forceVisible设置冲突

**解决方法**: 
- 使用collisionRule.NAME避免名称重复
- 合理设置priority值区分优先级
- 设置不同的zIndex值控制叠加顺序
- 根据需求设置forceVisible属性

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "pointAnnotationId": "string",
  "position": {
    "latitude": 32.020750,
    "longitude": 118.788765
  },
  "titles": [
    {
      "content": "南京夫子庙",
      "fontSize": 15,
      "color": "0xFF000000"
    }
  ],
  "collisionRule": "NAME",
  "visible": true,
  "minZoom": 2,
  "maxZoom": 20,
  "animationEnabled": false,
  "clickEventEnabled": true,
  "apiUsed": [
    "MapComponent",
    "MapComponentController.addPointAnnotation",
    "PointAnnotationParams",
    "PointAnnotation",
    "MapEventManager.on",
    "ScaleAnimation",
    "FontSizeAnimation"
  ],
  "apiVersion": "4.1.0(11)",
  "supportedInMetaService": true
}
```

## 参考文档

- [API开发指南: 点注释](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/map-annotation)
- [API参考: PointAnnotation](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-pointannotation)
- [API参考: PointAnnotationParams](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common)
- [API参考: MapComponentController](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller)
- [API参考: ScaleAnimation](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-scaleanimation)
- [API参考: FontSizeAnimation](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-fontsizeanimation)

## 完整示例代码

- [ArkTS示例: 添加点注释](assets/point_annotation_demo.ets)
- [ArkTS示例: 点注释动画](assets/point_annotation_animation.ets)
- [ArkTS示例: 点注释点击事件](assets/point_annotation_click.ets)

## 测试用例

### 正向测试用例
- [添加基础点注释](tests/test_add_basic_point_annotation.ets): 测试添加包含必填参数的点注释
- [添加带图标点注释](tests/test_add_point_annotation_with_icon.ets): 测试添加自定义图标点注释
- [添加带标题点注释](tests/test_add_point_annotation_with_titles.ets): 测试添加多标题点注释
- [设置点注释动画](tests/test_point_annotation_animation.ets): 测试缩放动画和标题动画
- [监听点击事件](tests/test_point_annotation_click_event.ets): 测试点击事件监听功能

### 边界测试用例
- [经纬度边界值](tests/test_point_annotation_latlng_boundary.ets): 测试经纬度在边界值[-90,90]和[-180,180)时的表现
- [标题数组边界值](tests/test_point_annotation_titles_boundary.ets): 测试标题数组长度为1和3时的表现
- [层级边界值](tests/test_point_annotation_zoom_boundary.ets): 测试minZoom和maxZoom在边界值[2,20]的表现
- [字体大小边界值](tests/test_point_annotation_fontsize_boundary.ets): 测试fontSize在[0,100]范围的表现
- [描边宽度边界值](tests/test_point_annotation_stroke_boundary.ets): 测试strokeWidth在[0,10]范围的表现

### 异常测试用例
- [经纬度超出范围](tests/test_point_annotation_invalid_latlng.ets): 测试经纬度超出范围时的错误处理
- [标题数组长度错误](tests/test_point_annotation_invalid_titles_length.ets): 测试标题数组长度小于1或大于3时的错误处理
- [碰撞规则配置错误](tests/test_point_annotation_collision_rule_error.ets): 测试collisionRule为ALL时未设置priority的错误处理
- [图标路径不存在](tests/test_point_annotation_icon_not_found.ets): 测试图标文件不存在时的降级处理
- [地图未初始化](tests/test_point_annotation_map_not_initialized.ets): 测试在地图初始化前创建点注释的错误处理
- [参数格式错误](tests/test_point_annotation_invalid_params.ets): 测试参数格式错误时的错误处理(错误码401)