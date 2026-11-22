---
name: hmos-map-kit-controls-interaction
description: 控制地图控件显示位置状态，支持缩放控件、比例尺、指南针、Logo、审图号设置，适用于地图UI定制场景
---

# 地图控件交互技能

## 功能描述

本技能提供HarmonyOS Map Kit地图控件的控制能力，包括缩放控件、比例尺、指南针、定位按钮、地图Logo、审图号的显示隐藏、位置调整、样式设置等功能。地图控件是指浮在地图组件上的一系列用于操作地图的组件，开发者可根据应用需求定制控件的显示状态和位置。

**功能范围**：
- 缩放控件：控制缩放按钮的显示隐藏
- 比例尺：控制比例尺显示、位置、常显模式
- 指南针：控制指南针显示、位置
- 定位按钮：控制"我的位置"按钮显示
- 地图Logo：控制Logo对齐方式、间距
- 审图号：控制审图号显示（从6.1.0(23)开始支持）

## 使用场景

### 触发词
- "地图控件"
- "缩放按钮"
- "比例尺"
- "指南针"
- "定位按钮"
- "地图Logo"
- "审图号"
- "地图UI定制"

### 能做
- 开启/关闭缩放控件
- 开启/关闭比例尺并设置位置
- 开启/关闭指南针并设置位置
- 开启/关闭"我的位置"按钮
- 设置地图Logo对齐方式和间距
- 显示/隐藏审图号（地图在中国境内时生效）
- 获取比例尺尺寸和当前层级比例尺大小

### 绝不做
- 不处理地图数据相关操作（如添加标记、绘制覆盖物）
- 不处理地图相机移动相关操作（如动画移动、缩放）
- 不处理地图事件监听相关操作
- 不处理超出控件范围的其他地图功能

### 补充
- 审图号功能从API版本6.1.0(23)开始支持，仅在地图路由在中国境内时显示
- Logo不允许被遮挡，需通过setLogoPadding设置边界避免遮挡
- 比例尺常显功能需要先通过setScaleControlsEnabled开启比例尺控件
- 所有控件方法需要在地图初始化回调中或自定义方法中调用

## 调用规范和规则

### 输入约束
- mapController对象：必须已初始化，类型为map.MapComponentController
- 控件位置参数：MapPoint对象，positionX和positionY为number类型，单位px
- Logo对齐参数：LogoAlignment枚举值，可选BOTTOM_START、BOTTOM_END、TOP_START、TOP_END、TOP_CENTER、BOTTOM_CENTER
- Logo间距参数：Padding对象，left、top、right、bottom为number类型，单位px
- Boolean参数：true表示开启/显示，false表示关闭/隐藏

### 执行约束
- 最大耗时：单次控件设置操作不超过100ms
- API调用顺序：部分功能有依赖顺序，如setAlwaysShowScaleEnabled需先调用setScaleControlsEnabled
- 异常值处理：传入异常值时系统按默认值处理或不处理

### 内容约束
- 禁止使用：不存在的控件方法名称
- 禁止操作：遮挡或隐藏地图Logo（违反合规要求）
- 禁止假设：不要假设控件默认状态，应通过is方法查询或参考文档确认

### 降级约束
- mapController未初始化：提示用户先完成地图初始化，参考显示地图章节
- 控件位置超出边界：位置参数不生效，控件保持原位置
- 版本不支持：提示用户当前API版本不支持该功能（如审图号功能）

## 调用流程和步骤

### 步骤1：准备阶段

**前置条件**：
1. 已完成Map Kit集成和权限配置
2. 已创建MapComponent组件并获取mapController对象
3. mapController对象在地图初始化回调中获取

**参数准备**：
```typescript
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct MapControlsDemo {
  private TAG = "MapControlsDemo";
  private mapOptions?: mapCommon.MapOptions;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;
  
  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: { latitude: 39.9, longitude: 116.4 },
        zoom: 10
      }
    };
    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        this.setupMapControls();
      }
    };
  }
  
  private setupMapControls() {
    // 在此处调用控件设置方法
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

### 步骤2：缩放控件设置

**示例代码**：
```typescript
private setupZoomControls() {
  // 开启缩放控件（默认开启）
  this.mapController?.setZoomControlsEnabled(true);
  
  // 查询缩放控件状态
  let isEnabled: boolean = this.mapController?.isZoomControlsEnabled();
  console.info(this.TAG, `Zoom controls enabled: ${isEnabled}`);
}
```

### 步骤3：比例尺控件设置

**示例代码**：
```typescript
private setupScaleControls() {
  // 开启比例尺控件（默认关闭）
  this.mapController?.setScaleControlsEnabled(true);
  
  // 设置比例尺位置
  let point: mapCommon.MapPoint = {
    positionX: 100,
    positionY: 100
  };
  this.mapController?.setScalePosition(point);
  
  // 设置比例尺常显（需先开启比例尺）
  this.mapController?.setAlwaysShowScaleEnabled(true);
  
  // 获取比例尺尺寸
  let height: number = this.mapController?.getScaleControlsHeight();
  let width: number = this.mapController?.getScaleControlsWidth();
  console.info(this.TAG, `Scale controls size: ${width}x${height}`);
  
  // 获取当前层级比例尺大小
  let level: number = this.mapController?.getScaleLevel();
  console.info(this.TAG, `Current scale level: ${level} meters`);
  
  // 查询比例尺常显状态
  let isAlwaysShow: boolean = this.mapController?.isAlwaysShowScaleEnabled();
  console.info(this.TAG, `Always show scale: ${isAlwaysShow}`);
}
```

### 步骤4：指南针控件设置

**示例代码**：
```typescript
private setupCompassControls() {
  // 开启指南针控件（默认开启）
  this.mapController?.setCompassControlsEnabled(true);
  
  // 设置指南针位置（左上角偏移）
  let point: mapCommon.MapPoint = {
    positionX: 10,
    positionY: 10
  };
  this.mapController?.setCompassPosition(point);
  
  // 查询指南针状态
  let isEnabled: boolean = this.mapController?.isCompassControlsEnabled();
  console.info(this.TAG, `Compass enabled: ${isEnabled}`);
}
```

### 步骤5：定位按钮设置

**示例代码**：
```typescript
private setupMyLocationControls() {
  // 开启"我的位置"按钮（默认关闭）
  this.mapController?.setMyLocationControlsEnabled(true);
  
  // 开启"我的位置"图层（需配合定位按钮使用）
  this.mapController?.setMyLocationEnabled(true);
  
  // 查询定位按钮状态
  let isEnabled: boolean = this.mapController?.isMyLocationControlsEnabled();
  console.info(this.TAG, `My location controls enabled: ${isEnabled}`);
  
  // 查询定位图层状态
  let isLocationEnabled: boolean = this.mapController?.isMyLocationEnabled();
  console.info(this.TAG, `My location enabled: ${isLocationEnabled}`);
}
```

### 步骤6：地图Logo设置

**示例代码**：
```typescript
private setupMapLogo() {
  // 设置Logo对齐方式（右下角）
  this.mapController?.setLogoAlignment(mapCommon.LogoAlignment.BOTTOM_END);
  
  // 设置Logo间距
  let padding: mapCommon.Padding = {
    left: 0,
    top: 0,
    right: 50,
    bottom: 50
  };
  this.mapController?.setLogoPadding(padding);
}
```

### 步骤7：审图号设置

**示例代码**：
```typescript
private setupApproveNumber() {
  // 显示审图号（从6.1.0(23)开始支持）
  this.mapController?.setApproveNumberEnabled(true);
}
```

### 步骤8：错误处理

```typescript
private setupMapControlsWithErrorHandling() {
  try {
    if (!this.mapController) {
      console.error(this.TAG, 'MapController is not initialized');
      return;
    }
    
    this.setupZoomControls();
    this.setupScaleControls();
    this.setupCompassControls();
    this.setupMyLocationControls();
    this.setupMapLogo();
    
  } catch (error) {
    console.error(this.TAG, `Failed to setup controls: ${error.message}`);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Invalid input parameter | 检查参数类型和取值范围是否正确 |
| 1002601001 | The object to be operated does not exist | 确认mapController对象已初始化 |
| 无响应 | 方法调用无效 | 检查API版本是否支持该功能，检查前置依赖是否满足 |

**常见错误场景**：
- mapController未初始化：所有控件方法调用无效
- setAlwaysShowScaleEnabled无效：需先调用setScaleControlsEnabled(true)
- 审图号不显示：地图不在中国境内或API版本低于6.1.0(23)

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.MapKit": "API版本4.1.0(11)及以上"
  }
}
```

### 环境要求
- HarmonyOS API：4.1.0(11)及以上（基础控件功能）
- HarmonyOS API：5.0.0(12)及以上（比例尺位置、尺寸获取、常显功能）
- HarmonyOS API：6.1.0(23)及以上（审图号功能）
- 系统能力：SystemCapability.Map.Core
- 模型约束：仅可在Stage模型下使用

### 常见编译问题

**问题1：MapKit模块导入失败**
```
Error: Cannot find module '@kit.MapKit'
```
**解决方法**：确保HarmonyOS SDK版本支持Map Kit，检查项目配置

**问题2：LogoAlignment枚举值不存在**
```
Error: Property 'TOP_CENTER' does not exist on type 'LogoAlignment'
```
**解决方法**：TOP_CENTER和BOTTOM_CENTER从5.1.1(19)开始支持，升级SDK版本

**问题3：setApproveNumberEnabled方法不存在**
```
Error: Property 'setApproveNumberEnabled' does not exist
```
**解决方法**：该方法从6.1.0(23)开始支持，升级SDK版本

## 常见问题与解决方法

### Q1：比例尺不显示？
**原因**：比例尺默认关闭，或位置设置超出边界
**解决方法**：
- 先调用setScaleControlsEnabled(true)开启比例尺
- 检查setScalePosition的参数值是否在合理范围内
- 确认地图已加载完成

### Q2：指南针不显示？
**原因**：地图指向正北方向且未倾斜时指南针自动隐藏
**解决方法**：
- 旋转地图或倾斜地图后指南针会显示
- 调用setCompassControlsEnabled(true)确认开启状态

### Q3：Logo位置调整无效？
**原因**：设置的padding值超出范围（负值或超出边界）
**解决方法**：
- 使用合理的padding值（正值，不超出组件边界）
- 根据Logo对齐位置选择对应的padding参数生效

### Q4：定位按钮点击没反应？
**原因**：只显示了按钮，但未开启"我的位置"图层
**解决方法**：
- 同时调用setMyLocationEnabled(true)开启定位图层
- 配置定位权限ohos.permission.APPROXIMATELY_LOCATION

### Q5：审图号不显示？
**原因**：地图不在中国境内或API版本过低
**解决方法**：
- 确认地图路由在中国境内
- 确认API版本为6.1.0(23)及以上
- 调用setApproveNumberEnabled(true)

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "controlsSetup": {
    "zoomControls": "enabled",
    "scaleControls": "enabled with position",
    "compassControls": "enabled",
    "myLocationControls": "enabled",
    "logo": "aligned to BOTTOM_END",
    "approveNumber": "enabled (if supported)"
  },
  "apiUsed": [
    "setZoomControlsEnabled",
    "setScaleControlsEnabled",
    "setScalePosition",
    "setAlwaysShowScaleEnabled",
    "setCompassControlsEnabled",
    "setCompassPosition",
    "setMyLocationControlsEnabled",
    "setMyLocationEnabled",
    "setLogoAlignment",
    "setLogoPadding",
    "setApproveNumberEnabled"
  ]
}
```

## 参考文档

- [控件交互开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/map-controls-and-interaction)
- [显示地图开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/map-presenting)
- [MapComponentController API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller)
- [mapCommon API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common)

## 完整示例代码

- [ArkTS示例](assets/map_controls_example.ets)

## 测试用例

### 正向测试用例
- [开启所有控件](tests/test_positive.py)：测试所有控件的开启功能
- [设置控件位置](tests/test_positive.py)：测试比例尺和指南针位置设置
- [Logo对齐设置](tests/test_positive.py)：测试不同Logo对齐方式

### 边界测试用例
- [控件位置边界值](tests/test_boundary.py)：测试控件位置的最小最大值
- [Logo间距边界值](tests/test_boundary.py)：测试padding边界值

### 异常测试用例
- [mapController未初始化](tests/test_exception.py)：测试mapController为null的场景
- [异常参数值](tests/test_exception.py)：测试传入异常参数的处理
- [版本不支持](tests/test_exception.py)：测试低版本调用新API的场景