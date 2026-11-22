import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct MapPolygonDemo {
  private TAG = 'MapPolygonDemo';
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapPolygon?: map.MapPolygon;

  aboutToAppear(): void {
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
        this.addPolygonDemo();
      } else {
        console.error(`${this.TAG} Failed to initialize map, code: ${err.code}, message: ${err.message}`);
      }
    };
  }

  private async addPolygonDemo(): Promise<void> {
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
    };

    try {
      this.mapPolygon = await this.mapController?.addPolygon(polygonOptions);
      console.info(`${this.TAG} Polygon added successfully`);
    } catch (error) {
      console.error(`${this.TAG} Failed to add polygon, code: ${error.code}, message: ${error.message}`);
    }
  }

  build() {
    Stack() {
      Column() {
        MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback });
      }.width('100%')
    }.height('100%')
  }
}