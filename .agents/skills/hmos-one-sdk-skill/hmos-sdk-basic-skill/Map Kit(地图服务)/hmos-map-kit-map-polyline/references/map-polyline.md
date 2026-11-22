# 折线
---
# 折线
#### 场景介绍
本章节将向您介绍如何在地图上绘制折线、设置折线分段颜色、设置折线可渐变、绘制纹理。
折线主要用于展示步行、驾车、骑行等各类导航路线，同时可记录并呈现用户的运动轨迹及历史行程信息。此外，在区域边界标注、距离测量、管网线路布局以及活动路径可视化等场景中也有广泛应用。
5.0.3(15)开始，支持折线绘制纹理功能。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/ae/v3/agjY-fliR4q7jursvRjcmg/zh-cn_image_0000002659221021.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105233Z&HW-CC-Expire=86400&HW-CC-Sign=497314548A75FC2F0CD95FAF7D48FB7A9FF2DB673DCBD00398294AD0B4560559)
#### 接口说明
添加折线功能主要由 [MapPolylineOptions](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md) 、 [addPolyline](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 和 [MapPolyline](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mappolyline.md) 提供，更多接口及使用方法请参见 [接口文档](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mappolyline.md) 。
| 接口名 | 描述 |
| --- | --- |
| [MapPolylineOptions](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md) | 折线参数。 |
| [addPolyline](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md)(options:[mapCommon.MapPolylineOptions](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md)): Promise<[MapPolyline](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mappolyline.md)> | 在地图上添加一条折线。 |
| [MapPolyline](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mappolyline.md) | 折线，支持更新和查询相关属性。 |
#### 开发步骤
#### 添加折线
1.
导入相关模块。
```typescript
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
```
2.
添加折线，在callback方法中创建初始化参数并新建 [MapPolyline](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mappolyline.md) 。
```
@Entry
@Component
struct MapPolylineDemo {
  // ...
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapPolyline?: map.MapPolyline;
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
        // polyline初始化参数
        let polylineOption: mapCommon.MapPolylineOptions = {
          points: [
            { longitude: 118.78, latitude: 31.975 },
            { longitude: 118.78, latitude: 31.982 },
            { longitude: 118.79, latitude: 31.985 }
          ],
          clickable: true,
          startCap: mapCommon.CapStyle.BUTT,
          endCap: mapCommon.CapStyle.BUTT,
          geodesic: false,
          jointType: mapCommon.JointType.BEVEL,
          visible: true,
          width: 10,
          zIndex: 10,
          gradient: false
        }
        // 创建polyline
        try {
          this.mapPolyline = await this.mapController.addPolyline(polylineOption);
        } catch (e) {
          console.error(`Failed to create the mapPolyline, code is：${e.code}, message is ${e.message}`);
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
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/e4/v3/HET3kyRYQwKF58KdB3q8cA/zh-cn_image_0000002628701830.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105233Z&HW-CC-Expire=86400&HW-CC-Sign=17C3CF361C0D1AC4ACEFFF68E289D2F6DFDD74871852C10E44431611F57D3D80)
#### 设置折线分段颜色
方法一：新建折线时在 [MapPolylineOptions](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md) 的colors属性中设置折线分段颜色值。
```
let polylineOption: mapCommon.MapPolylineOptions = {
  points: [
    { longitude: 118.78, latitude: 31.975 },
    { longitude: 118.78, latitude: 31.982 },
    { longitude: 118.79, latitude: 31.985 }
  ],
  clickable: true,
  startCap: mapCommon.CapStyle.BUTT,
  endCap: mapCommon.CapStyle.BUTT,
  geodesic: false,
  jointType: mapCommon.JointType.BEVEL,
  visible: true,
  width: 10,
  zIndex: 10,
  // 设置颜色
  colors: [0xffffff00, 0xff000000],
  gradient: false
};
```
方法二：调用 [MapPolyline](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mappolyline.md) 的 [setColors](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mappolyline.md) ()方法。
```typescript
let colors = [0xffffff00, 0xff000000];
this.mapPolyline.setColors(colors);
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/fd/v3/KzTrpYdzRwSZGBrPt-rGcA/zh-cn_image_0000002659101061.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105233Z&HW-CC-Expire=86400&HW-CC-Sign=55946C52A625426BF664ACF8E7187A9A0F1530493F99ED178331C70F59F86625)
#### 设置折线可渐变
方法一： [MapPolylineOptions](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md) 的gradient属性设置为true。
```
let polylineOption: mapCommon.MapPolylineOptions = {
  points: [
    { longitude: 118.78, latitude: 31.975 },
    { longitude: 118.78, latitude: 31.982 },
    { longitude: 118.79, latitude: 31.985 }
  ],
  clickable: true,
  startCap: mapCommon.CapStyle.BUTT,
  endCap: mapCommon.CapStyle.BUTT,
  geodesic: false,
  jointType: mapCommon.JointType.BEVEL,
  visible: true,
  width: 10,
  zIndex: 10,
  colors: [0xffffff00, 0xff000000],
  // 设置颜色折线可渐变
  gradient: true
};
```
方法二：调用 [MapPolyline](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mappolyline.md) 的 [setGradient](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mappolyline.md) ()方法。
```typescript
this.mapPolyline.setGradient(true);
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/4f/v3/BXeKNVIwQlCzDk_B6IcN4w/zh-cn_image_0000002628861710.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105233Z&HW-CC-Expire=86400&HW-CC-Sign=DB2CEA80EABDFCF584E156A71D6259D08244A732EE947A338D7C38AF41C239FB)
#### 绘制纹理
方法一：新建折线时在 [MapPolylineOptions](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md) 的customTexture属性设置折线纹理。
```
let polylineOption: mapCommon.MapPolylineOptions = {
  points: [
    { latitude: 32.220750, longitude: 118.788765 },
    { latitude: 32.120750, longitude: 118.788765 },
    { latitude: 32.020750, longitude: 118.788765 },
    { latitude: 31.920750, longitude: 118.788765 },
    { latitude: 31.820750, longitude: 118.788765 }
  ],
  clickable: true,
  jointType: mapCommon.JointType.DEFAULT,
  width: 20,
  // 图标需存放在resources/rawfile目录下
  customTexture: 'icon/naviline_arrow.png'
}
```
方法二：调用 [MapPolyline](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mappolyline.md) 的 [setCustomTexture](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mappolyline.md) 方法。
```
await this.mapPolyline.setCustomTexture('icon/naviline_arrow.png');
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/b/v3/HGzEqZ0vS4qfTvvtHh_cOg/zh-cn_image_0000002659221023.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105233Z&HW-CC-Expire=86400&HW-CC-Sign=E0B1C5E6D471D82E50B19637FC0584230EEFA4E96252A67A9926338562F025F9)
#### 折线设置分段纹理
新建折线时利用在 [MapPolylineOptions](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md) 的customTextures和customTextureIndexes属性设置折线分段纹理。
```
import { image } from '@kit.ImageKit';
// ...
// 数组存放图片内容
let customTextures: (ResourceStr | image.PixelMap)[] = [];
// 图标存放在resources/rawfile，'icon/img.png'参数值传入rawfile文件夹下的相对路径
customTextures.push('icon/img.png');
customTextures.push('icon/img_1.png');
let cusIndexNumber: number[] = [];
// cusIndexNumber数组长度与折线点数量必须相同，数组元素内容与customTextures下标相对应，图片从数组第二个元素开始选择
cusIndexNumber.push(0, 0, 1);
// polyline初始化参数
let polylineOption: mapCommon.MapPolylineOptions = {
  points: [
    { longitude: 118.78, latitude: 31.975 },
    { longitude: 118.78, latitude: 31.982 },
    { longitude: 118.79, latitude: 31.985 }
  ],
  clickable: true,
  startCap: mapCommon.CapStyle.BUTT,
  endCap: mapCommon.CapStyle.BUTT,
  jointType: mapCommon.JointType.BEVEL,
  width: 30,
  // 图标需存放在resources/rawfile目录下
  customTextures: customTextures,
  customTextureIndexes: cusIndexNumber
};
let mapPolyline = await this.mapController.addPolyline(polylineOption);
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/a1/v3/Dp_PCjtsScKkDzXgQNXGdA/zh-cn_image_0000002628701832.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105233Z&HW-CC-Expire=86400&HW-CC-Sign=7BA554C9D1430E498CB10D2ED6185F681778ECE7978F0C2E025FF4629EC43414)