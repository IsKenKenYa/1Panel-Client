# 显示地图
---
# 显示地图
#### 场景介绍
从5.0.3(15)开始，支持Logo缩放功能和3D地球功能；从5.1.1(19)开始，支持室内图功能和设置比例尺单位功能；从6.0.0(20)开始，支持设置地图语言功能；从6.1.0(23)开始，支持设置3D地图城市灯光效果。
本章节将向您介绍如何使用地图组件 [MapComponent](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS组件/map-mapcomponent.md) 和 [MapComponentController](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 呈现地图，效果如下图所示。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/82/v3/ud41TkoOSraR6hKqydTNug/zh-cn_image_0000002628861678.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105231Z&HW-CC-Expire=86400&HW-CC-Sign=78B670C35DF6D3B9AA030B49CB6D810FD6768EDE221F4CBA3103C7811A7F4775)
#### 接口说明
显示地图功能主要由 [MapComponent](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS组件/map-mapcomponent.md) 提供，更多接口及使用方法请参见 [接口文档](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS组件/map-mapcomponent.md) 。
| 接口 | 接口描述 |
| --- | --- |
| [mapCommon.MapOptions](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md) | 提供Map组件初始化的属性。 |
| [MapComponent](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS组件/map-mapcomponent.md)(mapOptions:[mapCommon.MapOptions](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md), mapCallback: AsyncCallback<[map.MapComponentController](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md)>) | 地图组件。 |
| [map.MapComponentController](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) | 地图组件的主要功能入口类，用来操作地图，与地图有关的所有方法从此处接入。它所承载的工作包括：地图类型切换（如标准地图、空地图）、改变地图状态（中心点坐标和缩放级别）、添加点标记（Marker）、绘制几何图形（如MapPolyline、MapPolygon、MapCircle）、监听各类事件等。 |
#### 开发步骤
#### 地图显示
1.
导入Map Kit相关模块。
```typescript
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
```
2.
新建地图初始化参数mapOptions，设置地图中心点坐标及层级。
通过callback回调的方式获取 [MapComponentController](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 对象，用来操作地图。
调用 [MapComponent](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS组件/map-mapcomponent.md) 组件，传入mapOptions和mapCallback参数，初始化地图。
```
@Entry
@Component
struct MapPresentingDemo {
  // ...
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
          latitude: 39.9,
          longitude: 116.4
        },
        zoom: 10
      }
    };
    // 地图初始化的回调
    this.callback = async (err, mapController) => {
      if (!err) {
        // 获取地图的控制器类，用来操作地图
        this.mapController = mapController;
        this.mapEventManager = this.mapController.getEventManager();
        let callback = () => {
          console.info(this.TAG, `on-mapLoad`);
        }
        this.mapEventManager.on('mapLoad', callback);
      } else {
        console.error(`Failed to initialize the map, code is：${err.code}, message is ${err.message}`);
      }
    };
  }
  // 页面每次显示时触发一次，包括路由过程、应用进入前台等场景，仅@Entry装饰的自定义组件生效
  onPageShow(): void {
    // 建议页面切换到前台，调用地图组件的show方法
    if (this.mapController) {
      this.mapController.show();
    }
  }
  // 页面每次隐藏时触发一次，包括路由过程、应用进入后台等场景，仅@Entry装饰的自定义组件生效
  onPageHide(): void {
    // 建议页面切换到后台，调用地图组件的hide方法
    if (this.mapController) {
      this.mapController.hide();
    }
  }
  build() {
    // ...
      Stack() {
        // 调用MapComponent组件初始化地图
        MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback }).width('100%').height('100%');
      }
      // ...
  }
}
```
3.
运行您刚完成的工程就可以在您的APP中看到地图了，运行后的效果如下图所示。
如果没有成功加载地图，请参见 [地图不显示](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Map Kit（地图服务）/Map Kit常见问题/地图不显示/map-faq-1.md) 。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/4f/v3/21pa_MlfTxqqOllKHaSeEQ/zh-cn_image_0000002659220991.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105231Z&HW-CC-Expire=86400&HW-CC-Sign=B8B887732E912679FB889F1894401A883BA5D1D62883D88725627AB132CCD27B)
#### 设置地图属性
[MapOptions](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md) 包含以下属性。
| 属性 | 描述 |
| --- | --- |
| mapType | 地图类型，默认值：[MapType](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md).STANDARD。 |
| position | 地图相机位置。 |
| bounds | 地图展示框。 |
| minZoom | 地图最小层级，有效范围[2, 20]，默认值：2。 |
| maxZoom | 地图最大层级，有效范围[2, 20]，默认值：20。 |
| rotateGesturesEnabled | 是否支持旋转手势，默认值：true。 |
| scrollGesturesEnabled | 是否支持滑动手势，默认值：true。 |
| zoomGesturesEnabled | 是否支持缩放手势，默认值：true。 |
| tiltGesturesEnabled | 是否支持倾斜手势，默认值：true。 |
| zoomControlsEnabled | 是否展示缩放控件，默认值：true。 |
| myLocationControlsEnabled | 是否展示我的位置按钮，默认值：false。 |
| compassControlsEnabled | 是否展示指南针控件，默认值：true。 |
| scaleControlsEnabled | 是否展示比例尺，默认值：false。 |
| alwaysShowScaleEnabled | 是否始终显示比例尺，默认值：false。 |
| padding | 设置地图和边界的距离。 |
| styleId | 自定义样式ID。 |
| dayNightMode | 日间夜间模式，默认值：[DayNightMode](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md).DAY（日间模式）。 |
| logoScale | Logo缩放比例，取值范围是[0.8, 1]，默认值：1。 |
| sphereEnabled | 是否开启3D地球效果，默认值为false。 |
| indoorMapEnabled | 是否开启室内图，默认值：false。 |
| scaleUnit | 地图比例尺公英制单位，默认值：[ScaleUnit](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md).METRIC_UNIT（公制单位）。 |
1.
设置mapType， [切换地图类型](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Map Kit（地图服务）/创建地图/切换地图类型/map-type.md) 章节中有详细讲解。
2.
设置myLocationControlsEnabled，展示我的位置按钮。
在mapOptions中设置myLocationControlsEnabled属性为true，可展示我的位置按钮 ![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/fe/v3/TG4DJ9y5TzyNxD779_2kGQ/zh-cn_image_0000002628701800.png?HW-CC-KV=V1&HW-CC-Date=20260701T105231Z&HW-CC-Expire=86400&HW-CC-Sign=D646A86A5F6232BFD9356B46A432F873320C2AEF5E75600AEBA8B62FEB3A3FE5) ，显示效果如下图所示。
也可通过调用 [MapComponentController](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 对象的方法展示我的位置按钮，详情见 [显示我的位置](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Map Kit（地图服务）/创建地图/显示我的位置/map-location.md) 章节。
```typescript
this.mapOptions = {
  position: {
    target: {
      latitude: 39.9,
      longitude: 116.4
    },
    zoom: 10
  },
  myLocationControlsEnabled: true
};
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/6d/v3/4ytojysGQvOCq7QlV--XcQ/zh-cn_image_0000002659101031.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105231Z&HW-CC-Expire=86400&HW-CC-Sign=D1F8AADF4D863C3A23EED7C273D878275F4A9C3BD5492971A7B0C928C106F981)
3.
展示比例尺。
在mapOptions中设置scaleControlsEnabled属性为true，可展示比例尺，显示效果如下图所示。
```typescript
this.mapOptions = {
  position: {
    target: {
      latitude: 39.9,
      longitude: 116.4
    },
    zoom: 10
  },
  scaleControlsEnabled: true
};
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/c7/v3/v0Qo-Fl-Th2oW1zZ80LZ3w/zh-cn_image_0000002628861680.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105231Z&HW-CC-Expire=86400&HW-CC-Sign=E5EC0282494EE99201746627C73A88AD1F57C3A02A129C164D15364EFC45F452)
#### 开启3D建筑图层
调用 [MapComponentController](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 对象的 [setBuildingEnabled](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 方法开启3D建筑图层，把缩放层级调整为16级或以上，将两个手指放在地图上，向上滑动倾斜地图可看到3D建筑图层的效果。
```typescript
this.mapController.setBuildingEnabled(true);
```
显示效果如下：
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/b5/v3/rvD3z2uHQ7CPC5SmnswM4Q/zh-cn_image_0000002659220993.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105231Z&HW-CC-Expire=86400&HW-CC-Sign=01DA99008EE191F2CAAF6305FF32AA5D8A1864AD8B771D98FB000831690F36D1)
#### 地图前后台切换
您可以通过 [MapComponentController](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 对象来控制地图页面前后台切换的生命周期。应用触发前后台切换时，可以在Page生命周期里调用show/hide，以便申请/释放资源。
**地图切换至前台：**
```
// 页面每次显示时触发一次，包括路由过程、应用进入前台等场景，仅@Entry装饰的自定义组件生效
onPageShow(): void {
  // 建议页面切换到前台，调用地图组件的show方法
  if (this.mapController) {
    this.mapController.show();
  }
}
```
**地图切换至后台：**
```typescript
// 页面每次隐藏时触发一次，包括路由过程、应用进入后台等场景，仅@Entry装饰的自定义组件生效
onPageHide(): void {
  // 建议页面切换到后台，调用地图组件的hide方法
  if (this.mapController) {
    this.mapController.hide();
  }
}
```
#### 深色模式
Map Kit提供2种方式设置地图的夜间模式：初始化地图时和创建地图后。
方式一：初始化地图时
在地图初始化参数中设置dayNightMode参数，参数可选值包括DAY（日间模式）、NIGHT（夜间模式）、AUTO（自动模式）。如果将参数值设置为AUTO，地图的深色模式会跟随系统，打开系统深色开关，显示夜间模式，否则显示日间模式。
```typescript
this.mapOptions = {
  position: {
    target: {
      latitude: 39.9,
      longitude: 116.4
    },
    zoom: 10
  },
  myLocationControlsEnabled: true,
  // 设置地图为夜间模式
  dayNightMode: mapCommon.DayNightMode.NIGHT
};
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/d8/v3/Bam02KDFQX6igLK8XTVsQg/zh-cn_image_0000002628701802.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105231Z&HW-CC-Expire=86400&HW-CC-Sign=36D6E6A365F9DB3A8B6945F3AC2CB7BD4B658813092FFABE7CAEB4BCF31DD7AD)
方式二：创建地图后
创建地图后，可调用 [MapComponentController](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 对象的 [setDayNightMode](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 方法设置夜间模式。下面的例子中将参数值设置为AUTO，在设置完之后，打开系统的深色开关，地图会自动变为夜间模式。
```typescript
// 设置地图为自动模式
this.mapController.setDayNightMode(mapCommon.DayNightMode.AUTO);
```
#### 室内图
使用室内图可查看楼层平面图，如查看购物中心、博物馆和医院等地点的内部情况。
Map Kit提供2种方式开启地图的室内图功能：初始化地图时和创建地图后。
方式一：初始化地图时
在地图初始化参数中设置将 [MapOptions](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md) 中的indoorMapEnabled参数设置为true即可开启室内图功能，而且仅17级及以上地图层级可见室内图和楼层调节控件，通过左下角的楼层调节控件可以切换当前室内图楼层。
```typescript
this.mapOptions = {
  position: {
    target: {
      latitude: 31.979227,
      longitude: 118.762245
    },
    zoom: 18
  },
  // 开启室内图功能
  indoorMapEnabled: true
};
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/10/v3/f_KnJyRQSSmvtIrvKFjhLw/zh-cn_image_0000002659101033.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105231Z&HW-CC-Expire=86400&HW-CC-Sign=E658F6F5C862DBB3C502A74AB12D6EB573530FDB52B4FEA587E68DBE3AE916CD)
方式二：创建地图后
创建地图后，可调用 [MapComponentController](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 对象的 [setIndoorMapEnabled](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 方法来开启或关闭室内图功能。下面的例子中将室内图开启后，调用 [isIndoorMapEnabled](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 方法来查询当前室内图功能的开启状态，调用 [setFloorControlsPosition](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 方法可以设置楼层调节控件的位置。室内图功能还提供了 [switchIndoorMapFloor](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 方法，可以切换到指定的室内建筑和指定的楼层。
```typescript
// 开启室内图功能
this.mapController.setIndoorMapEnabled(true);
// 查询当前室内图开启状态
let isIndoorMapEnabled: boolean = this.mapController.isIndoorMapEnabled();
console.info('indoorMapEnabled is:' + isIndoorMapEnabled);
// 设置楼层调节控件的位置
this.mapController.setFloorControlsPosition({
  positionX: 500,
  positionY: 500
});
// 切换楼层,需要将第一个入参替换成用户需要的建筑物id，第二个参数替换成当前楼层，如'1F'、'B1'等等
this.mapController.switchIndoorMapFloor('822588304363886720', '3F');
```
通过调用 [on('indoorMapEnter')](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapeventmanager.md) 方法和 [on('indoorMapExit')](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapeventmanager.md) 可以分别设置进入和退出室内图的监听事件。
```
let callbackEnter = (indoorMapInfo: map.IndoorMapInfo) => {
  console.info(this.TAG, `on-indoorMapEnter`);
};
let callbackExit = () => {
  console.info(this.TAG, `on-indoorMapExit`);
};
// 进入室内图监听回调
this.mapEventManager.on('indoorMapEnter', callbackEnter);
// 退出室内图监听回调
this.mapEventManager.on('indoorMapExit', callbackExit);
```
#### Logo缩放比例
Map Kit提供2种方式设置地图的Logo缩放比例：初始化地图时和创建地图后。
方式一：初始化地图时
在地图初始化参数中设置logoScale参数，取值范围是[0.8, 1]，默认值是1。
```
// 方式一：初始化地图时
this.mapOptions = {
  position: {
    target: {
      latitude: 39.9,
      longitude: 116.4
    },
    zoom: 10
  },
  myLocationControlsEnabled: true,
  // 设置logo缩放比例为0.9
  logoScale: 0.9
};
```
方式二：创建地图后
1.
创建地图后，调用 [MapComponentController](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 对象的 [setLogoScale](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 方法设置Logo缩放比例。
```
// 设置Logo缩放比例为0.9
this.mapController.setLogoScale(0.9);
```
2.
获取Logo缩放比例。
通过调用 [MapComponentController](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 对象的 [getLogoScale](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 方法获取当前Logo缩放比例。
```
// 获取Logo缩放比例
let logoScale: number = this.mapController.getLogoScale();
```
#### 开启3D地球
Map Kit提供2种方式开启3D地球：初始化地图时和创建地图后。
开启3D地球后，当层级缩小到小于4时，可以清晰地看到3D地球。
方式一：初始化地图时
在地图初始化参数中设置3D地球的开启状态，默认值是false。
```
// 方式一：初始化地图时
this.mapOptions = {
  position: {
    target: {
      latitude: 39.9,
      longitude: 116.4
    },
    zoom: 2
  },
  // 开启3D地球
  sphereEnabled: true
};
```
方式二：创建地图后
创建地图后，调用 [MapComponentController](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 对象的 [setSphereEnabled](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 方法开启3D地球，通过调用 [MapComponentController](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 对象的 [isSphereEnabled](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 方法可获取3D地球的开启状态。
```typescript
// 开启3D地球
this.mapController.setSphereEnabled(true);
// 获取3D地球的开启状态
let result: boolean = this.mapController.isSphereEnabled();
```
显示效果如下：
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/bf/v3/XJl5ivZnQlWekEjFIMmuOg/zh-cn_image_0000002628861682.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105231Z&HW-CC-Expire=86400&HW-CC-Sign=DC214C071D99E29BC6286E7023A4F8E4F29C6BBB24BE54C312000E0923EFE229)
开启城市灯光效果
调用 [MapComponentController](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 对象的 [setSphereEnabled](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) (enabled: boolean, animateDuration: number, cityLight: boolean)方法开启城市灯光效果。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/8/v3/XjTDS9CaSGiMy-JRJutLvA/zh-cn_image_0000002659220995.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105231Z&HW-CC-Expire=86400&HW-CC-Sign=1DC9F42F6DECED4F4EBA28CC25570719D07DB6813DD1A9C7385EE09200949948)