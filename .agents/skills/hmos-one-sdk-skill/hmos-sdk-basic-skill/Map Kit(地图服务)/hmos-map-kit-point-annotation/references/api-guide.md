# 点注释
---
# 点注释
#### 场景介绍
本章节将向您介绍如何在地图的指定位置添加点注释以标识位置、商家、建筑等，并可以通过信息窗口展示详细信息。
点注释支持功能：
-
支持设置图标、文字、碰撞规则等。
-
支持添加点击事件。
[PointAnnotation](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-pointannotation.md) 有默认风格，同时也支持自定义。由于内容丰富，以下只展示一些基础功能的使用，详细内容可参见 [接口文档](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-pointannotation.md) 。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/f5/v3/LjBVVVfSSkKYpbHUempMkw/zh-cn_image_0000002659221027.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105233Z&HW-CC-Expire=86400&HW-CC-Sign=7C3DCFFE1716E70BE8E0643B27410B3848C5774F7EF1FA90C60D6FA9929BA8D2)
#### 接口说明
添加点注释功能主要由 [PointAnnotationParams](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md) 、 [addPointAnnotation](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md) 、 [PointAnnotation](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-pointannotation.md) 、 [on](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapeventmanager.md) 、 [off](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapeventmanager.md) 提供，更多接口及使用方法请参见 [接口文档](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-pointannotation.md) 。
| 接口名 | 描述 |
| --- | --- |
| [PointAnnotationParams](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md) | 点注释参数。 |
| [addPointAnnotation](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapcomponentcontroller.md)(params:[mapCommon.PointAnnotationParams](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-common.md)): Promise<[PointAnnotation](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-pointannotation.md)> | 在地图上添加点注释。 |
| [PointAnnotation](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-pointannotation.md) | 点注释，支持更新和查询相关属性。 |
| [on](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapeventmanager.md)(type: 'pointAnnotationClick', callback: Callback<[PointAnnotation](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-pointannotation.md)>): void | 设置点注释点击事件监听器。 |
| [off](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-mapeventmanager.md)(type: 'pointAnnotationClick', callback?: Callback<[PointAnnotation](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-pointannotation.md)>): void | 取消监听点注释点击事件。 |
#### 开发步骤
#### 添加点注释
1.
导入相关模块。
```typescript
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
```
2.
添加点注释，在callback方法中创建初始化参数并新建点注释。
```typescript
@Entry
@Component
struct PointAnnotationDemo {
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapEventManager?: map.MapEventManager;
  private pointAnnotation?: map.PointAnnotation;
  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 32.020750,
          longitude: 118.788765
        },
        zoom: 14
      }
    };
    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        this.mapEventManager = this.mapController.getEventManager();
        let pointAnnotationOptions: mapCommon.PointAnnotationParams = {
          // 定义点注释图标锚点
          position: {
            latitude: 32.020750,
            longitude: 118.788765
          },
          // 定义点注释名称与地图POI名称相同时，是否支持去重
          repeatable: true,
          // 定义点注释的碰撞规则
          collisionRule: mapCommon.CollisionRule.NAME,
          // 定义点注释的标题，数组长度最小为1，最大为3
          titles: [{
            // 定义标题内容
            content: "南京夫子庙",
            // 定义标题字体颜色
            color: 0xFF000000,
            // 定义标题字体大小
            fontSize: 15,
            // 定义标题描边颜色
            strokeColor: 0xFFFFFFFF,
            // 定义标题描边宽度
            strokeWidth: 2,
            // 定义标题字体样式
            fontStyle: mapCommon.FontStyle.ITALIC
          }],
          // 定义点注释的图标，图标存放在resources/rawfile
          icon: "",
          // 定义点注释是否展示图标
          showIcon: true,
          // 定义点注释的锚点在水平方向上的位置
          anchorU: 0.5,
          // 定义点注释的锚点在垂直方向上的位置
          anchorV: 1,
          // 定义点注释的显示属性，为true时，在被碰撞后仍能显示
          forceVisible: false,
          // 定义碰撞优先级，数值越大，优先级越低
          priority: 3,
          // 定义点注释展示的最小层级
          minZoom: 2,
          // 定义点注释展示的最大层级
          maxZoom: 20,
          // 定义点注释是否可见
          visible: true,
          // 定义点注释叠加层级属性
          zIndex: 10
        }
        // 创建pointAnnotation
        try {
          this.pointAnnotation = await this.mapController.addPointAnnotation(pointAnnotationOptions);
        } catch (e) {
          console.error(`Failed to create the pointAnnotation, code is：${e.code}, message is ${e.message}`);
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
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/c0/v3/0gWcqcoeSFSKk4FCVdqnng/zh-cn_image_0000002628701836.jpg?HW-CC-KV=V1&HW-CC-Date=20260701T105233Z&HW-CC-Expire=86400&HW-CC-Sign=A42AFB04E9379A94B559BD3B9A49C55E8556F6B235C9197FE547EF022E0642D9)
3.
在添加点注释之后，修改已经设置的点注释属性。
```typescript
// 设置点注释的显示层级为3~14级
this.pointAnnotation.setZoom(3,14);
// 设置点注释的碰撞优先级为10
this.pointAnnotation.setPriority(10);
```
#### 设置监听点注释点击事件
```typescript
let callback = (pointAnnotation: map.PointAnnotation) => {
  console.info("pointAnnotationClick", `pointAnnotationClick: ${pointAnnotation.getId()}`);
};
this.mapEventManager.on("pointAnnotationClick", callback);
```
#### 点注释动画
使用 [PointAnnotation](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-pointannotation.md) 的 [setAnimation](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-basepriorityoverlay.md) 方法设置动画。
调用 [PointAnnotation](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-pointannotation.md) 的 [startAnimation](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-basepriorityoverlay.md) 方法启动动画。
```typescript
let animation: map.ScaleAnimation = new map.ScaleAnimation(1, 3, 1, 3);
// 设置动画单次的时长
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
// 设置动画重复的方式
animation.setRepeatMode(map.AnimationRepeatMode.REVERSE);
// 设置动画插值器
animation.setInterpolator(Curve.Linear);
// 设置动画的重复次数
animation.setRepeatCount(100);
this.pointAnnotation.setAnimation(animation);
this.pointAnnotation.startAnimation();
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/23/v3/1Yap4gUFQWG0VrNykJ-s4A/zh-cn_image_0000002659101067.gif?HW-CC-KV=V1&HW-CC-Date=20260701T105233Z&HW-CC-Expire=86400&HW-CC-Sign=1C463BD69AF7BF978ECA4B7B743B196297617AB26D83AA2B469CBCCDE7F2F9EA)
#### 点注释标题动画
使用 [PointAnnotation](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-pointannotation.md) 的 [setTitleAnimation](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-pointannotation.md) 方法设置标题动画。
调用 [PointAnnotation](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-pointannotation.md) 的 [startTitleAnimation](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map（地图显示功能）/map-map-pointannotation.md) 方法启动标题动画。
```typescript
let animation: map.FontSizeAnimation = new map.FontSizeAnimation(15, 45);
// 设置动画单次的时长
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
animation.setFillMode(map.AnimationFillMode.FORWARDS);
// 设置动画重复的方式
animation.setRepeatMode(map.AnimationRepeatMode.REVERSE);
// 设置动画插值器
animation.setInterpolator(Curve.Linear);
// 设置动画的重复次数
animation.setRepeatCount(100);
this.pointAnnotation.setTitleAnimation(animation);
this.pointAnnotation.startTitleAnimation();
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/c6/v3/ykgSpT-1ScuVTayCF_iYBQ/zh-cn_image_0000002628861716.gif?HW-CC-KV=V1&HW-CC-Date=20260701T105233Z&HW-CC-Expire=86400&HW-CC-Sign=5863844FBDF81BF749B19AE752F828A339FE4339D2C9691895991D6BF92C0F97)