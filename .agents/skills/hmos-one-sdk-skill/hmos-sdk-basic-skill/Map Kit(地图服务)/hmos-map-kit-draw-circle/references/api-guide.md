# 圆形开发指南
---
# 圆形
#### 场景介绍
本章节将向您介绍如何在地图上绘制圆形。
圆形通常用于表示特定区域的服务覆盖范围、地理围栏或兴趣点的影响区域。通过设置中心点和半径，可以直观地展示某一地点周边一定距离内的范围。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/ae/v3/3TTbJ3ROQ0yk-FSgG6lI2A/zh-cn_image_0000002659101065.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105233Z&HW-CC-Expire=86400&HW-CC-Sign=E837C8021017E3D729BB0B0DC0EDE049AF737F899D80604C45BBD340321238FF)
#### 接口说明
添加圆形功能主要由 [MapCircleOptions](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common) 、 [addCircle](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller) 和 [MapCircle](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcircle) 提供，更多接口及使用方法请参见 [接口文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcircle) 。
| 接口名 | 描述 |
| --- | --- |
| [MapCircleOptions](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common) | 圆形参数。 |
| [addCircle](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller)(options:[mapCommon.MapCircleOptions](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common)): Promise<[MapCircle](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcircle)> | 在地图上添加一个圆，指定圆心经纬度和圆的半径，用于表示某个位置的周边范围。 |
| [MapCircle](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcircle) | 圆形，支持更新和查询相关属性。 |
#### 开发步骤
1.
导入相关模块。
```typescript
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
```
2.
添加圆，在callback方法中创建初始化参数并新建Circle。
```typescript
@Entry
@Component
struct MapCircleDemo {
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapCircle?: map.MapCircle;
  aboutToAppear(): void {
    // 地图初始化参数
    this.mapOptions = {
      position: {
        target: {
          latitude: 39.918,
          longitude: 116.397
        },
        zoom: 14
      }
    };
    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        // Circle初始化参数
        let mapCircleOptions: mapCommon.MapCircleOptions = {
          center: {
            latitude: 39.918,
            longitude: 116.397
          },
          radius: 500,
          clickable: true,
          fillColor: 0xFFFFC100,
          strokeColor: 0xFFFF0000,
          strokeWidth: 10,
          visible: true,
          zIndex: 15
        }
        // 创建Circle
        try {
          this.mapCircle = await this.mapController.addCircle(mapCircleOptions);
        } catch (e) {
          console.error(`Failed to create the mapCircle, code is：${e.code}, message is ${e.message}`);
        }
      } else {
        console.error(`Failed to initialize the map, code is：${err.code}, message is ${err.message}`);
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
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/d9/v3/SbfrBY2MSQ--W6ufpe_wvg/zh-cn_image_0000002628861714.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105233Z&HW-CC-Expire=86400&HW-CC-Sign=E64DEFF97C2CCE4725771F66AE7360B8A8E557371802F3645D7E00D574C73609)