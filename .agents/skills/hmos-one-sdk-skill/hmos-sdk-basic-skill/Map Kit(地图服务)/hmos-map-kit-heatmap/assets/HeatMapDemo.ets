import { map, mapCommon, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct HeatMapDemo {
  private TAG = "OHMapSDK_HeatMapDemo";
  private mapOption?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private heatmap?: map.Heatmap;

  aboutToAppear(): void {
    this.mapOption = {
      position: {
        target: {
          latitude: 31.000000,
          longitude: 118.000000
        },
        zoom: 11
      }
    }

    this.callback = async (err, mapController) => {
      console.info(this.TAG, "mapCallback err=" + JSON.stringify(err) +
        "; mapController=" + JSON.stringify(mapController));
      if (!err) {
        this.mapController = mapController;
        await this.addHeatmap();
      } else {
        console.error(this.TAG, `Failed to initialize map, code:${err.code}, message:${err.message}`);
      }
    }
  }

  private async addHeatmap(): Promise<void> {
    let data: mapCommon.WeightedLatLng[] = [];
    for (let i = 0; i < 500; i++) {
      const latitude = 31.000000 + Math.random() * 1 - 0.25;
      const longitude = 118.000000 + Math.random() * 1 - 0.25;
      
      if (latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude < 180) {
        data.push({
          point: {
            longitude: longitude,
            latitude: latitude
          },
          intensity: 1
        });
      }
    }

    let heatMapOptions: mapCommon.HeatmapParams = {
      id: 'heatmap0001',
      data: data,
      radius: 20,
      intensity: {
        2: 1,
        5: 5,
        8: 10
      },
      opacity: 0.5,
      color: {
        0: 0x00026C39,
        0.15: 0xAA138C4A,
        0.3: 0xFF82CB67,
        0.45: 0xFFE3F399,
        0.6: 0xFFFEDE89,
        0.75: 0xFFF67C4A,
        0.9: 0xFFBE1827,
        1: 0xFFA90426
      },
      radiusUnit: mapCommon.RadiusUnit.PIXEL_UNIT,
      visible: true
    }

    try {
      this.heatmap = await this.mapController?.addHeatmap(heatMapOptions);
      console.info(this.TAG, 'Heatmap added successfully');
    } catch (error) {
      this.handleHeatmapError(error);
    }
  }

  private handleHeatmapError(error: any): void {
    switch (error.code) {
      case 1002601001:
        console.error(this.TAG, 'The object to be operated does not exist');
        if (!this.mapController) {
          console.warn(this.TAG, 'Map controller is not initialized, retry after map loaded');
        }
        break;
      case 1002600015:
        console.error(this.TAG, 'The heatmap ID already exists');
        console.warn(this.TAG, 'Please use a unique heatmap ID');
        break;
      case 401:
        console.error(this.TAG, 'Invalid input parameter');
        console.warn(this.TAG, 'Please check HeatmapParams parameters');
        break;
      default:
        console.error(this.TAG, `Unknown error: code=${error.code}, message=${error.message}`);
    }
  }

  private async updateHeatmapData(): Promise<void> {
    if (!this.heatmap) {
      console.warn(this.TAG, 'Heatmap is not initialized');
      return;
    }

    let newData: mapCommon.WeightedLatLng[] = [];
    for (let i = 0; i < 100; i++) {
      const latitude = 31.000000 + Math.random() * 0.5 - 0.25;
      const longitude = 118.000000 + Math.random() * 0.5 - 0.25;
      
      if (latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude < 180) {
        newData.push({
          point: {
            longitude: longitude,
            latitude: latitude
          },
          intensity: Math.random() * 2 + 0.5
        });
      }
    }

    this.heatmap.setData(newData);
    console.info(this.TAG, 'Heatmap data updated');
  }

  private updateHeatmapColor(): void {
    if (!this.heatmap) {
      console.warn(this.TAG, 'Heatmap is not initialized');
      return;
    }

    let color: Record<number, number> = {
      0: 0x26C3999,
      0.15: 0xFF4D4DFF,
      0.3: 0xFF9999FF,
      0.45: 0xFFE6E6FF,
      0.6: 0xFFFFCCFF,
      0.75: 0xFFFF99FF,
      0.9: 0xFFFF66FF,
      1: 0xFFFF00FF
    };
    this.heatmap.setColor(color);
    console.info(this.TAG, 'Heatmap color updated');
  }

  private updateHeatmapStyle(): void {
    if (!this.heatmap) {
      console.warn(this.TAG, 'Heatmap is not initialized');
      return;
    }

    let intensity: Record<number, number> = {
      2: 0.1,
      5: 0.5,
      10: 1.0
    };
    this.heatmap.setIntensity(intensity);

    let opacity: Record<number, number> = {
      2: 0.1,
      10: 0.8
    };
    this.heatmap.setOpacity(opacity);

    let radius: Record<number, number> = {
      2: 10,
      10: 50
    };
    this.heatmap.setRadius(radius);

    console.info(this.TAG, 'Heatmap style updated');
  }

  private removeHeatmap(): void {
    if (!this.heatmap) {
      console.warn(this.TAG, 'Heatmap is not initialized');
      return;
    }

    this.heatmap.remove();
    console.info(this.TAG, 'Heatmap removed');
    this.heatmap = undefined;
  }

  private getHeatmapInfo(): void {
    if (!this.heatmap) {
      console.warn(this.TAG, 'Heatmap is not initialized');
      return;
    }

    let data = this.heatmap.getData();
    console.info(this.TAG, `Heatmap data count: ${data.length}`);

    let color = this.heatmap.getColor();
    console.info(this.TAG, `Heatmap color: ${JSON.stringify(color)}`);

    let intensity = this.heatmap.getIntensity();
    console.info(this.TAG, `Heatmap intensity: ${JSON.stringify(intensity)}`);

    let opacity = this.heatmap.getOpacity();
    console.info(this.TAG, `Heatmap opacity: ${JSON.stringify(opacity)}`);

    let radius = this.heatmap.getRadius();
    console.info(this.TAG, `Heatmap radius: ${JSON.stringify(radius)}`);

    let visible = this.heatmap.isVisible();
    console.info(this.TAG, `Heatmap visible: ${visible}`);
  }

  build() {
    Stack() {
      Column() {
        MapComponent({ mapOptions: this.mapOption, mapCallback: this.callback })
          .width('100%')
          .height('100%');
      }.width('100%')

      Column() {
        Button('Add Heatmap')
          .onClick(() => this.addHeatmap())
          .width('90%')
          .margin(10)

        Button('Update Data')
          .onClick(() => this.updateHeatmapData())
          .width('90%')
          .margin(10)

        Button('Update Color')
          .onClick(() => this.updateHeatmapColor())
          .width('90%')
          .margin(10)

        Button('Update Style')
          .onClick(() => this.updateHeatmapStyle())
          .width('90%')
          .margin(10)

        Button('Get Info')
          .onClick(() => this.getHeatmapInfo())
          .width('90%')
          .margin(10)

        Button('Remove Heatmap')
          .onClick(() => this.removeHeatmap())
          .width('90%')
          .margin(10)
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .alignItems(HorizontalAlign.Center)
    }
    .height('100%')
  }
}