---
name: hmos-map-kit-map-presenting
description: 在HarmonyOS应用中显示地图组件，支持设置地图中心点、缩放级别、地图类型、3D建筑、深色模式、室内图等属性，适用于地图导航、位置展示、POI标记场景
---

# 显示地图技能

## 功能描述

本技能用于在HarmonyOS应用中显示地图组件。通过MapComponent组件和MapComponentController控制器，实现地图的初始化、显示和交互控制。支持设置地图中心点坐标、缩放级别、地图类型、3D建筑图层、深色模式、室内图、Logo缩放、3D地球等功能。

**核心功能**：
- 地图组件初始化和显示
- 地图属性设置（中心点、缩放级别、地图类型等）
- 地图前后台切换生命周期管理
- 3D建筑图层、深色模式、室内图等高级功能
- 地图事件监听（加载完成、室内图进出等）

## 使用场景

### 触发词
- "显示地图"
- "创建地图组件"
- "初始化地图"
- "MapComponent"
- "展示地图"
- "地图显示"
- "打开地图"

### 能做
- 在HarmonyOS应用中显示地图组件
- 设置地图的中心点坐标和缩放级别
- 配置地图类型（标准地图、空地图等）
- 开启3D建筑图层、深色模式、室内图等功能
- 设置地图控件的显示状态（指南针、比例尺、缩放控件等）
- 处理地图前后台切换的生命周期
- 监听地图加载完成等事件

### 绝不做
- 不处理地图定位功能（需要使用Location Kit）
- 不处理地图搜索功能（需要使用Site Kit）
- 不处理地图导航功能（需要使用Navigation Kit）
- 不直接处理地图覆盖物的添加（Marker、Circle等，需要使用MapComponentController的相关方法）
- 不处理超出地图显示范围的其他功能

### 补充
- 仅支持Stage模型
- 需要导入@kit.MapKit模块
- 需要在页面显示/隐藏时调用show/hide方法管理生命周期
- 支持元服务API（从版本4.1.0(11)开始）
- 需要配置地图初始化参数mapOptions

## 调用规范和规则

### 输入约束
- 地图中心点坐标：latitude范围[-90, 90]，longitude范围[-180, 180)
- 缩放级别：有效范围[2, 20]，默认值为10
- 地图类型：支持STANDARD、NONE等类型
- 建筑图层：需缩放至16级或以上才能看到3D建筑效果
- 室内图：需缩放至17级或以上才能看到室内图和楼层调节控件
- Logo缩放比例：范围[0.8, 1]，默认值为1
- 3D地球：需缩放至4级以下才能清晰看到3D地球效果

### 执行约束
- 必须在aboutToAppear生命周期中初始化mapOptions和callback
- 必须在onPageShow中调用mapController.show()
- 必须在onPageHide中调用mapController.hide()
- 地图初始化回调中必须处理error情况
- 地图组件必须在build方法中渲染

### 内容约束
- 禁止在地图初始化前调用MapComponentController的方法
- 禁止使用无效的坐标值（超出范围的latitude/longitude）
- 禁止在回调函数外直接操作mapController
- 禁止省略mapOptions的必填参数（position）

### 降级约束
- 地图加载失败：记录错误日志，提示用户检查网络和权限
- 地图不显示：参考地图不显示FAQ文档排查问题
- 3D建筑不显示：确保缩放级别>=16且已开启setBuildingEnabled
- 室内图不显示：确保缩放级别>=17且已开启indoorMapEnabled

## 调用流程和步骤

### 步骤1：导入必要模块

**导入模块**：
```typescript
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
```

### 步骤2：初始化地图参数

**前置校验**：
1. 确认当前为Stage模型
2. 确认已安装@kit.MapKit模块
3. 确认应用具有地图访问权限

**参数准备**：
```typescript
@Entry
@Component
struct MapPresentingDemo {
  private TAG = 'MapPresentingDemo';
  private mapOptions?: mapCommon.MapOptions;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;
  private mapEventManager?: map.MapEventManager;

  aboutToAppear(): void {
    // 地图初始化参数，设置地图中心点坐标及层级
    this.mapOptions = {
      position: {
        target: {
          latitude: 39.9,  // 纬度，范围[-90, 90]
          longitude: 116.4  // 经度，范围[-180, 180)
        },
        zoom: 10  // 缩放级别，范围[2, 20]
      },
      mapType: mapCommon.MapType.STANDARD,  // 地图类型，默认STANDARD
      rotateGesturesEnabled: true,  // 是否支持旋转手势
      scrollGesturesEnabled: true,  // 是否支持滑动手势
      zoomGesturesEnabled: true,  // 是否支持缩放手势
      tiltGesturesEnabled: true,  // 是否支持倾斜手势
      zoomControlsEnabled: true,  // 是否展示缩放控件
      myLocationControlsEnabled: false,  // 是否展示我的位置按钮
      compassControlsEnabled: true,  // 是否展示指南针控件
      scaleControlsEnabled: false,  // 是否展示比例尺
      minZoom: 2,  // 最小缩放级别
      maxZoom: 20  // 最大缩放级别
    };
  }
}
```

### 步骤3：创建地图初始化回调

**回调函数**：
```typescript
aboutToAppear(): void {
  // ... mapOptions初始化代码 ...
  
  // 地图初始化的回调
  this.callback = async (err, mapController) => {
    if (!err) {
      // 获取地图的控制器类，用来操作地图
      this.mapController = mapController;
      this.mapEventManager = this.mapController.getEventManager();
      
      // 监听地图加载完成事件
      let callback = () => {
        console.info(this.TAG, 'on-mapLoad');
      };
      this.mapEventManager.on('mapLoad', callback);
      
      // 可以在这里执行其他初始化操作
      // 例如：开启3D建筑图层
      this.mapController.setBuildingEnabled(true);
    } else {
      console.error(`Failed to initialize the map, code is: ${err.code}, message is ${err.message}`);
    }
  };
}
```

### 步骤4：渲染地图组件

**组件渲染**：
```typescript
build() {
  Stack() {
    // 调用MapComponent组件初始化地图
    MapComponent({ 
      mapOptions: this.mapOptions, 
      mapCallback: this.callback 
    })
    .width('100%')
    .height('100%');
  }
  .height('100%');
}
```

### 步骤5：管理前后台切换

**生命周期管理**：
```typescript
// 页面每次显示时触发一次，包括路由过程、应用进入前台等场景
onPageShow(): void {
  // 建议页面切换到前台，调用地图组件的show方法
  if (this.mapController) {
    this.mapController.show();
  }
}

// 页面每次隐藏时触发一次，包括路由过程、应用进入后台等场景
onPageHide(): void {
  // 建议页面切换到后台，调用地图组件的hide方法
  if (this.mapController) {
    this.mapController.hide();
  }
}
```

### 步骤6：设置高级功能（可选）

**开启3D建筑图层**：
```typescript
// 在地图初始化回调中或自定义方法中调用
this.mapController.setBuildingEnabled(true);
// 需要将缩放层级调整为16级或以上才能看到3D建筑效果
```

**设置深色模式**：
```typescript
// 方式一：在mapOptions中设置
this.mapOptions = {
  position: {
    target: { latitude: 39.9, longitude: 116.4 },
    zoom: 10
  },
  dayNightMode: mapCommon.DayNightMode.NIGHT  // 设置为夜间模式
};

// 方式二：创建地图后动态设置
this.mapController.setDayNightMode(mapCommon.DayNightMode.AUTO);
```

**开启室内图**：
```typescript
// 方式一：在mapOptions中设置
this.mapOptions = {
  position: {
    target: { latitude: 31.979227, longitude: 118.762245 },
    zoom: 18  // 需17级及以上才能看到室内图
  },
  indoorMapEnabled: true
};

// 方式二：创建地图后动态设置
this.mapController.setIndoorMapEnabled(true);
// 设置楼层调节控件位置
this.mapController.setFloorControlsPosition({
  positionX: 500,
  positionY: 500
});
```

**开启3D地球**：
```typescript
// 方式一：在mapOptions中设置
this.mapOptions = {
  position: {
    target: { latitude: 39.9, longitude: 116.4 },
    zoom: 2  // 需4级以下才能清晰看到3D地球
  },
  sphereEnabled: true
};

// 方式二：创建地图后动态设置
this.mapController.setSphereEnabled(true);
```

### 步骤7：错误处理

**错误处理代码**：
```typescript
this.callback = async (err, mapController) => {
  if (err) {
    // 根据错误码进行不同的处理
    switch (err.code) {
      case 401:
        console.error('Invalid input parameter');
        break;
      case 1002601001:
        console.error('The object to be operated does not exist');
        break;
      default:
        console.error(`Map initialization failed: code=${err.code}, message=${err.message}`);
    }
    return;
  }
  
  // 正常处理逻辑
  this.mapController = mapController;
};
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Invalid input parameter | 检查输入参数是否正确，确保latitude/longitude在有效范围内 |
| 1002601001 | The object to be operated does not exist | 确保mapController已正确初始化，在回调中获取 |
| 1002601005 | Failed to generate the icon of the customized component | 检查自定义图标资源是否正确，确保图标文件存在于resources/rawfile目录 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.MapKit": "HarmonyOS SDK",
    "@kit.BasicServicesKit": "HarmonyOS SDK"
  }
}
```

### 环境要求
- HarmonyOS SDK：4.1.0(11)或更高版本
- 开发环境：DevEco Studio
- 运行环境：HarmonyOS设备或模拟器
- Stage模型：仅支持Stage模型应用

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.MapKit'
```
**解决方法**：确保已安装HarmonyOS SDK，并在ohpm.json中正确配置依赖

**问题2：MapComponent未找到**
```
Error: MapComponent is not defined
```
**解决方法**：确保正确导入MapComponent模块：`import { MapComponent } from '@kit.MapKit';`

**问题3：类型错误**
```
Error: Type 'mapCommon.MapOptions' is not assignable
```
**解决方法**：确保mapOptions参数类型正确，所有必填字段都已设置

## 常见问题与解决方法

### Q1：地图不显示
**原因**：
- 地图初始化参数设置错误
- 网络连接失败
- 权限未配置
- SDK版本不兼容

**解决方法**：
- 检查mapOptions的position参数是否正确
- 确认网络连接正常
- 检查应用是否具有地图访问权限
- 确认SDK版本>=4.1.0(11)
- 参考[地图不显示](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/map-faq-1)文档

### Q2：3D建筑不显示
**原因**：
- 缩放级别不足
- 未开启3D建筑图层
- 地图类型不支持

**解决方法**：
- 确保缩放级别>=16
- 调用setBuildingEnabled(true)开启3D建筑图层
- 使用两个手指向上滑动倾斜地图

### Q3：室内图不显示
**原因**：
- 缩放级别不足
- 未开启室内图功能
- 当前位置没有室内图数据

**解决方法**：
- 确保缩放级别>=17
- 在mapOptions中设置indoorMapEnabled: true
- 移动到有室内图数据的建筑位置（如购物中心、博物馆）

### Q4：地图加载慢
**原因**：
- 网络连接慢
- 地图数据量大
- 设备性能限制

**解决方法**：
- 检查网络连接质量
- 降低缩放级别减少数据加载
- 在onPageHide中调用hide()释放资源

### Q5：地图显示位置错误
**原因**：
- latitude/longitude参数设置错误
- 坐标系不一致

**解决方法**：
- 确认latitude范围[-90, 90]，longitude范围[-180, 180)
- 使用正确的坐标系（WGS84）
- 检查position.target参数是否正确设置

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "component": "MapComponent",
  "controller": "MapComponentController",
  "mapOptions": {
    "position": {
      "latitude": 39.9,
      "longitude": 116.4,
      "zoom": 10
    },
    "mapType": "STANDARD"
  },
  "featuresEnabled": [
    "rotateGestures",
    "scrollGestures",
    "zoomGestures",
    "compassControls"
  ],
  "apiUsed": [
    "MapComponent",
    "MapComponentController",
    "MapOptions",
    "MapEventManager"
  ]
}
```

## 参考文档

- [API开发指南 - 显示地图](references/map-presenting.md)
- [API参考说明 - MapComponent](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-mapcomponent)
- [API参考说明 - MapComponentController](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller)
- [API参考说明 - MapOptions](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common)
- [地图不显示FAQ](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/map-faq-1)

## 完整示例代码

- [ArkTS完整示例 - 显示地图](assets/map-presenting-demo.ets)

## 测试用例

### 正向测试用例
- [测试正常显示地图](tests/test_positive_map_display.py)：验证地图组件能正常初始化和显示
- [测试设置中心点坐标](tests/test_positive_set_position.py)：验证能正确设置地图中心点
- [测试开启3D建筑](tests/test_positive_3d_building.py)：验证能正确开启3D建筑图层

### 边界测试用例
- [测试最小缩放级别](tests/test_boundary_min_zoom.py)：验证zoom=2时地图能正常显示
- [测试最大缩放级别](tests/test_boundary_max_zoom.py)：验证zoom=20时地图能正常显示
- [测试边界坐标值](tests/test_boundary_coordinates.py)：验证latitude=-90/90, longitude=-180时地图能正常显示

### 异常测试用例
- [测试无效坐标](tests/test_exception_invalid_coordinates.py)：验证latitude/longitude超出范围时的错误处理
- [测试网络失败](tests/test_exception_network_failure.py)：验证网络连接失败时的降级处理
- [测试权限不足](tests/test_exception_permission_denied.py)：验证权限不足时的错误提示