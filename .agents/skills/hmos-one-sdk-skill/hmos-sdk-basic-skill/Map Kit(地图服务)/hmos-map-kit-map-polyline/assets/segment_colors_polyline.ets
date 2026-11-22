import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct SegmentColorsPolylineDemo {
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapPolyline?: map.MapPolyline;

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
        
        let polylineOption: mapCommon.MapPolylineOptions = {
          points: [
            { longitude: 118.78, latitude: 31.975 },
            { longitude: 118.78, latitude: 31.982 },
            { longitude: 118.79, latitude: 31.985 }
          ],
          clickable: true,
          width: 10,
          colors: [0xffffff00, 0xff000000],
          gradient: false,
          visible: true,
          zIndex: 10
        };

        try {
          this.mapPolyline = await this.mapController.addPolyline(polylineOption);
          console.info('Segment colors polyline created successfully');
          
          let colors = [0xffff0000, 0xff00ff00];
          this.mapPolyline.setColors(colors);
          console.info('Segment colors updated successfully');
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