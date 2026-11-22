import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct TexturePolylineDemo {
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapPolyline?: map.MapPolyline;

  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 32.0,
          longitude: 118.78
        },
        zoom: 10
      }
    };

    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        
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
          customTexture: 'icon/naviline_arrow.png',
          visible: true,
          zIndex: 10
        };

        try {
          this.mapPolyline = await this.mapController.addPolyline(polylineOption);
          console.info('Texture polyline created successfully');
          
          await this.mapPolyline.setCustomTexture('icon/naviline_arrow.png');
          console.info('Texture updated successfully');
        } catch (e) {
          console.error(`Failed to create polyline, code: ${e.code}, message: ${e.message}`);
        }
      } else {
        console.error(`Failed to initialize map, code: ${err.code}, message: ${err.message}`);
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