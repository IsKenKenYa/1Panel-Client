import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';

@Entry
@Component
struct CustomIconMarkerDemo {
  private TAG = 'CustomIconMarkerDemo';
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private marker1?: map.Marker;
  private marker2?: map.Marker;
  private marker3?: map.Marker;

  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 32.120750,
          longitude: 118.788765
        },
        zoom: 14
      }
    };

    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        await this.addCustomIconMarkers();
      } else {
        console.error(`${this.TAG}: Failed to initialize map, code: ${err.code}, message: ${err.message}`);
      }
    };
  }

  async addCustomIconMarkers(): Promise<void> {
    try {
      let markerOptions1: mapCommon.MarkerOptions = {
        position: {
          latitude: 32.120750,
          longitude: 118.788765
        },
        icon: 'test.png'
      };
      this.marker1 = await this.mapController.addMarker(markerOptions1);
      console.info(`${this.TAG}: Custom icon marker (rawfile) created`);

      let markerOptions2: mapCommon.MarkerOptions = {
        position: {
          latitude: 32.130750,
          longitude: 118.788765
        },
        icon: $r('app.media.icon')
      };
      this.marker2 = await this.mapController.addMarker(markerOptions2);
      console.info(`${this.TAG}: Custom icon marker (Resource) created`);

      let mContext = this.getUIContext().getHostContext();
      if (mContext) {
        const fileData: Uint8Array = await mContext.resourceManager.getRawFileContent('icon/icon.png');
        let imageSource: image.ImageSource = image.createImageSource(fileData.buffer.slice(0, fileData.buffer.byteLength));
        let pixelMap: PixelMap = await imageSource.createPixelMap();
        
        let markerOptions3: mapCommon.MarkerOptions = {
          position: {
            latitude: 32.140750,
            longitude: 118.788765
          },
          icon: pixelMap
        };
        this.marker3 = await this.mapController.addMarker(markerOptions3);
        console.info(`${this.TAG}: Custom icon marker (PixelMap) created`);
      }

    } catch (error) {
      console.error(`${this.TAG}: Failed to create custom icon markers, code: ${error.code}, message: ${error.message}`);
    }
  }

  build() {
    Stack() {
      Column() {
        MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
          .width('100%')
          .height('100%');
      }.width('100%')
    }.height('100%');
  }
}