import { map, mapCommon, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct MapArcExample {
  private TAG = "MapArcExample";
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapArc?: map.MapArc;
  @State arcColor: number = 0xffff0000;  // 红色
  @State arcWidth: number = 10;

  aboutToAppear(): void {
    // 地图初始化参数
    this.mapOptions = {
      position: {
        target: {
          latitude: 34.757975,
          longitude: 113.665412
        },
        zoom: 6
      }
    };

    // 地图初始化回调
    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        if (!this.mapController) {
          console.error(this.TAG, "mapController is null");
          return;
        }

        // 添加初始弧线
        this.addArcToMap();
      } else {
        console.error(this.TAG, `Failed to initialize map, code: ${err.code}, message: ${err.message}`);
      }
    };
  }

  // 添加弧线到地图
  private async addArcToMap(): Promise<void> {
    if (!this.mapController) {
      console.error(this.TAG, "mapController is null, cannot add arc");
      return;
    }

    // 设置弧线参数
    let mapArcParams: mapCommon.MapArcParams = {
      // 弧线起点坐标 - 北京
      startPoint: {
        latitude: 39.913138,
        longitude: 116.415112
      },
      // 弧线终点坐标 - 长沙
      endPoint: {
        latitude: 28.239473,
        longitude: 112.954094
      },
      // 弧线中心点坐标 - 郑州附近
      centerPoint: {
        latitude: 33.86970399048567,
        longitude: 112.08633528544145
      },
      width: this.arcWidth,
      color: this.arcColor,
      visible: true,
      zIndex: 100
    };

    // 添加弧线
    try {
      this.mapArc = await this.mapController.addArc(mapArcParams);
      console.info(this.TAG, "Arc added successfully");
      
      // 查询弧线属性
      let color = this.mapArc.getColor();
      let width = this.mapArc.getWidth();
      console.info(this.TAG, `Arc properties: color=${color}, width=${width}`);
    } catch (e) {
      console.error(this.TAG, `Failed to add arc, code: ${e.code}, message: ${e.message}`);
    }
  }

  // 更新弧线颜色
  private updateArcColor(newColor: number): void {
    if (!this.mapArc) {
      console.error(this.TAG, "mapArc is null, cannot update color");
      return;
    }

    try {
      this.mapArc.setColor(newColor);
      this.arcColor = newColor;
      console.info(this.TAG, `Arc color updated to ${newColor}`);
      
      // 查询更新后的颜色
      let color = this.mapArc.getColor();
      console.info(this.TAG, `Current arc color: ${color}`);
    } catch (e) {
      console.error(this.TAG, `Failed to update arc color: ${e.message}`);
    }
  }

  // 更新弧线宽度
  private updateArcWidth(newWidth: number): void {
    if (!this.mapArc) {
      console.error(this.TAG, "mapArc is null, cannot update width");
      return;
    }

    try {
      this.mapArc.setWidth(newWidth);
      this.arcWidth = newWidth;
      console.info(this.TAG, `Arc width updated to ${newWidth}`);
      
      // 查询更新后的宽度
      let width = this.mapArc.getWidth();
      console.info(this.TAG, `Current arc width: ${width}`);
    } catch (e) {
      console.error(this.TAG, `Failed to update arc width: ${e.message}`);
    }
  }

  // 移除弧线（通过清除所有覆盖物）
  private removeArc(): void {
    if (!this.mapController) {
      console.error(this.TAG, "mapController is null, cannot remove arc");
      return;
    }

    try {
      this.mapController.clear();
      this.mapArc = undefined;
      console.info(this.TAG, "All overlays cleared");
    } catch (e) {
      console.error(this.TAG, `Failed to clear overlays: ${e.message}`);
    }
  }

  build() {
    Stack() {
      // 地图组件
      Column() {
        MapComponent({
          mapOptions: this.mapOptions,
          mapCallback: this.callback
        })
          .width('100%')
          .height('70%');
      }.width('100%')

      // 控制按钮面板
      Column() {
        Row() {
          Button('红色弧线')
            .onClick(() => {
              this.updateArcColor(0xffff0000);
            })
            .margin(5);

          Button('绿色弧线')
            .onClick(() => {
              this.updateArcColor(0xff00ff00);
            })
            .margin(5);

          Button('蓝色弧线')
            .onClick(() => {
              this.updateArcColor(0xff0000ff);
            })
            .margin(5);
        }
        .margin(10);

        Row() {
          Button('宽度10px')
            .onClick(() => {
              this.updateArcWidth(10);
            })
            .margin(5);

          Button('宽度20px')
            .onClick(() => {
              this.updateArcWidth(20);
            })
            .margin(5);

          Button('宽度30px')
            .onClick(() => {
              this.updateArcWidth(30);
            })
            .margin(5);
        }
        .margin(10);

        Row() {
          Button('重新添加弧线')
            .onClick(() => {
              this.addArcToMap();
            })
            .margin(5);

          Button('移除所有覆盖物')
            .onClick(() => {
              this.removeArc();
            })
            .margin(5);
        }
        .margin(10);
      }
      .width('100%')
      .height('30%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center);
    }
    .height('100%')
  }
}