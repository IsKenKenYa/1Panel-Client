import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';

@Entry
@Component
struct SegmentTexturePolylineDemo {
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
        
        let customTextures: (ResourceStr | image.PixelMap)[] = [];
        customTextures.push('icon/img.png');
        customTextures.push('icon/img_1.png');
        
        let customTextureIndexes: number[] = [];
        customTextureIndexes.push(0, 0, 1);
        
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
          customTextures: customTextures,
          customTextureIndexes: customTextureIndexes,
          visible: true,
          zIndex: 10
        };

        try {
          this.mapPolyline = await this.mapController.addPolyline(polylineOption);
          console.info('Segment texture polyline created successfully');
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