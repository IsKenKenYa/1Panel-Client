# 切换地图类型
---
# 切换地图类型
#### 场景介绍
从6.0.0(20)开始，支持卫星图和混合地图功能。
Map Kit支持以下地图类型：
-
STANDARD：标准地图，展示道路、建筑物以及河流等重要的自然特征。
-
NONE：空地图，没有加载任何数据的地图。
-
TERRAIN：地形图，在保留了行政区划边界、POI、楼块等地图要素的基础上，呈现完整清晰描绘地形走势的标准地图。
-
SATELLITE：卫星图，显示卫星照片的地图，只支持中国。适用于需要高精度地理信息的场景。
-
HYBRID：混合地图，在显示卫星照片的同时也显示路网信息。适用于需要结合卫星图像于路网信息的导航应用等，以增强实用性与指导性。
**图1** 标准地图
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/67/v3/RkYT4id5ScmPB9fFnGq7sw/zh-cn_image_0000002628701804.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105231Z&HW-CC-Expire=86400&HW-CC-Sign=FD8582DF665320AFEE240AA07C417C8DE6136F42C4EEE54A2755786AF0229A5C)
**图2** 空地图
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/e0/v3/Z06XsP8XSsiDcNojkyanhw/zh-cn_image_0000002659101035.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105231Z&HW-CC-Expire=86400&HW-CC-Sign=69AD15FE7AA97F110F6EEE92DD0752BA062F9636C607CB5364116AF37D8B8C2C)
**图3** 地形图
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/f9/v3/M8RTQYyFQfWobqDUDut6Pg/zh-cn_image_0000002628861684.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105231Z&HW-CC-Expire=86400&HW-CC-Sign=F20E021AFF2D66BEF22E3BE3E2AF9EF620B1DB4F86201CF74DD6B162C8057D04)
**图4** 卫星图
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/e5/v3/qUe-wN1iTk2xMw4SOaE_Og/zh-cn_image_0000002659220997.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105231Z&HW-CC-Expire=86400&HW-CC-Sign=1DFEDD0747E06A113BCEF0CD894CCBB35C49E3F7D6B0D95D5B5921B1EF2FA380)
**图5** 混合地图
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/a1/v3/oB3FKC8vTNaAVOUPo9wCfg/zh-cn_image_0000002628701806.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105231Z&HW-CC-Expire=86400&HW-CC-Sign=0433891336B54748507A2E91C0BEF971D454E31B4CC26DE2D95B4A6320B5D963)
#### 接口说明
Map Kit提供2种方式设置地图类型：
方式一：在初始化的时候，通过设置 [MapOptions](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md) 中的mapType属性来控制展示不同地图类型。
| 属性名 | 描述 |
| --- | --- |
| mapCommon.MapOptions.mapType | 地图初始化参数中的MapType地图类型。 |
方式二：地图创建后，可通过 [setMapType](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 方法动态设置地图类型。
| 接口名 | 描述 |
| --- | --- |
| [setMapType](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md)(mapType:[mapCommon.MapType](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md)): void | 设置地图类型。 |
#### 开发步骤
1.
导入相关模块。
```typescript
import { mapCommon } from '@kit.MapKit';
```
2.
设置地图类型。
方式一：
在地图初始化的时候，在mapOptions参数中新增mapType属性： [mapCommon.MapType](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md) .STANDARD（标准地图）。
```typescript
this.mapOptions = {
  position: {
    target: {
      latitude: 31.984410259206815,
      longitude: 118.76625379397866
    },
    zoom: 15
  },
  mapType: mapCommon.MapType.STANDARD
};
```
显示效果如下：
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/e1/v3/BFGNxRbRRn2s51V-DUmzSQ/zh-cn_image_0000002659101037.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105231Z&HW-CC-Expire=86400&HW-CC-Sign=7F5B42AF30FE19669593102783A42A55536D55B7802F43DCB90AB84618109ADE)
方式二：地图创建后，调用 [setMapType](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 方法设置地图类型为地形图。设置为地形图时，为了获得最佳显示效果，推荐将地图缩放层级保持在5至14之间。
```typescript
this.mapController.setMapType(mapCommon.MapType.TERRAIN);
```
显示效果如下：
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/df/v3/wtTT0meNTjOMR40gmFyL4w/zh-cn_image_0000002628861686.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105231Z&HW-CC-Expire=86400&HW-CC-Sign=C9B8B623F3B1A91F34D7630855CABFE6368863B99AF504C986C33176C56689D0)