# 多边形
---
# 多边形
#### 场景介绍
本章节将向您介绍如何在地图上绘制多边形。
多边形主要用于标识小区、学校、商圈等封闭区域范围，同时可呈现省、市、区县等行政区域边界。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/60/v3/S1MPkGt4RVi2z93auDZD1A/zh-cn_image_0000002659221025.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105233Z&HW-CC-Expire=86400&HW-CC-Sign=71FE4DE3200C02D53093EE1CE2D87D2477C9C0CD0FF050EC3C0F9CA484A455D8)
#### 接口说明
添加多边形功能主要由 [MapPolygonOptions](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common) 、 [addPolygon](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller) 和 [MapPolygon](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mappolygon) 提供，更多接口及使用方法请参见 [接口文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mappolygon) 。
| 接口名 | 描述 |
| --- | --- |
| [MapPolygonOptions](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common) | 多边形参数。 |
| [addPolygon](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller)(options:[mapCommon.MapPolygonOptions](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common)): Promise<[MapPolygon](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mappolygon)> | 在地图上添加一个多边形。 |
| [MapPolygon](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mappolygon) | 多边形，支持更新和查询相关属性。 |
#### 开发步骤
1.
导入相关模块。
```typescript
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
```
2.
添加多边形，在callback方法中创建初始化参数并新建polygon。
```
@Entry
@Component
struct MapPolygonDemo {
  // ...
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapPolygon?: map.MapPolygon;
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
    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        // 多边形初始化参数
        let polygonOptions: mapCommon.MapPolygonOptions = {
          points: [
            { longitude: 118.78, latitude: 31.975 },
            { longitude: 118.78, latitude: 31.985 },
            { longitude: 118.79, latitude: 31.985 },
            { longitude: 118.79, latitude: 31.975 }
          ],
          clickable: true,
          fillColor: 0xff00DE00,
          geodesic: false,
          strokeColor: 0xff000000,
          jointType: mapCommon.JointType.DEFAULT,
          strokeWidth: 10,
          visible: true,
          zIndex: 10
        }
        // 创建多边形
        try {
          this.mapPolygon = await this.mapController.addPolygon(polygonOptions);
        } catch (e) {
          console.error(`Failed to create the mapPolygon, code is：${e.code}, message is ${e.message}`);
        }
      } else {
        console.error(`Failed to initialize the map, code is：${err.code}, message is ${err.message}`);
      }
    };
  }
  build() {
    // ...
      Stack() {
        Column() {
          MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback });
        }.width('100%')
      }.height('100%')
      // ...
  }
}
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/fe/v3/YAot7XkkQBqbIp3yMQ36WQ/zh-cn_image_0000002628701834.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105233Z&HW-CC-Expire=86400&HW-CC-Sign=66FABEE8C69ACB65CC8C38B90EE66FD78E20459C8ED5AC86ACE4FC86FAE8E074)