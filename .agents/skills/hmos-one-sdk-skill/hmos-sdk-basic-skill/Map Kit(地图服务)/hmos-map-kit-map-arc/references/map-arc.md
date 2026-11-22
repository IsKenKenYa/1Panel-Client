# 弧线
---
# 弧线
#### 场景介绍
本章节将向您介绍如何在地图上绘制弧线，通过 [MapArcParams](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md) 类设置弧线的位置、宽度、颜色等参数。
弧线主要用于展示飞机、轮船等出行路线，直观呈现弧形轨迹，同时可在交叉路口等位置指示转向方向。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/14/v3/-day49U3QQSwfePD5TebrA/zh-cn_image_0000002659101063.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105233Z&HW-CC-Expire=86400&HW-CC-Sign=D2D34DECE073DD77227BF609EF148EF919A5A7D4764F2E7188ED286FF5062BCA)
#### 接口说明
添加弧线功能主要由 [MapArcParams](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md) 、 [addArc](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 和 [MapArc](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-maparc.md) 提供，更多接口及使用方法请参见 [接口文档](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-maparc.md) 。
| 接口名 | 描述 |
| --- | --- |
| [MapArcParams](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md) | 弧线参数。 |
| [addArc](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md)(params:[mapCommon.MapArcParams](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md)):[MapArc](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-maparc.md) | 添加一条弧线。 |
| [MapArc](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-maparc.md) | 弧线，支持更新和查询相关属性。 |
#### 开发步骤
#### 添加弧线
1.
导入相关模块。
```typescript
import { map, mapCommon, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
```
2.
添加弧线，在callback方法中创建初始化参数并新建MapArc。
```typescript
@Entry
@Component
struct MapArcDemo {
  private TAG = "OHMapSDK_MapArcDemo";
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapArc?: map.MapArc;
  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 34.757975,
          longitude: 113.665412
        },
        zoom: 6
      }
    }
    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        if (!this.mapController) {
          console.error(this.TAG, "mapController is null");
          return;
        }
        // 设置弧线参数
        let mapArcParams: mapCommon.MapArcParams = {
          // 弧线起点坐标
          startPoint: {
            latitude: 39.913138,
            longitude: 116.415112
          },
          // 弧线终点坐标
          endPoint: {
            latitude: 28.239473,
            longitude: 112.954094
          },
          // 弧线中心点坐标
          centerPoint: {
            latitude: 33.86970399048567,
            longitude: 112.08633528544145
          },
          width: 10,
          color: 0xffff0000,
          visible: true,
          zIndex: 100
        };
        // 添加弧线
        try {
          this.mapArc = await this.mapController.addArc(mapArcParams);
        } catch (e) {
          console.error(`Failed to create the mapArc, code is：${e.code}, message is ${e.message}`);
        }
      } else {
        console.error(`Failed to initialize the map, code is：${err.code}, message is ${err.message}`);
      }
    }
  }
  build() {
    Stack() {
      Column() {
        MapComponent({
          mapOptions: this.mapOptions,
          mapCallback: this.callback
        })
          .width('100%')
          .height('100%');
      }.width('100%')
    }.height('100%')
  }
}
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/90/v3/vHu795IFQ--XQe5-vW0Tlw/zh-cn_image_0000002628861712.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105233Z&HW-CC-Expire=86400&HW-CC-Sign=4DEB0C5B00573BC49E37201EA65B75FF27F2F1C126EDBF0826437046E0A00FBB)