# 创建地图组件 (MapComponent)

在应用中显示地图并获取控制器。

## 基础用法

```typescript
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct HuaweiMapDemo {
  private TAG = "HuaweiMapDemo";
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
        // 返回地图组件的监听事件管理接口
        this.mapEventManager = this.mapController.getEventManager();
        let callback = () => {
          console.info(this.TAG, `on-mapLoad`);
        }
        this.mapEventManager.on("mapLoad", callback);

        // 执行自定义的方法
        this.customizedMethod();
      }
    };
  }

  // 自定义的方法
  private customizedMethod() {
    // ...
  }

  build() {
    Stack() {
      // 调用MapComponent组件初始化地图
      MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
        .width('100%')
        .height('100%')
    }.height('100%')
  }
}
```

## 地图配置参数说明

| 参数                        | 说明                          | 默认值      |
|---------------------------|-----------------------------|----------|
| position.target           | 地图中心点经纬度                    | 必填       |
| position.zoom             | 缩放级别（2-20）                  | 2        |
| position.tilt             | 倾斜角度（0-75）                  | 0        |
| position.bearing          | 旋转角度（0-360）                 | 0        |
| mapType                   | 地图类型（STANDARD/NONE/TERRAIN） | STANDARD |
| maxZoom                   | 最大缩放级别（2-20）                | 20       |
| minZoom                   | 最小缩放级别（2-20）                | 2        |
| rotateGesturesEnabled     | 是否启用旋转手势                    | true     |
| scrollGesturesEnabled     | 是否启用滑动手势                    | true     |
| zoomGesturesEnabled       | 是否启用缩放手势                    | true     |
| tiltGesturesEnabled       | 是否启用倾斜手势                    | true     |
| zoomControlsEnabled       | 是否显示缩放控制器                   | true     |
| myLocationControlsEnabled | 是否显示我的位置控制器                 | false    |
| compassControlsEnabled    | 是否显示指南针控制器                  | true     |
| scaleControlsEnabled      | 是否显示比例尺控制器                  | false    |
