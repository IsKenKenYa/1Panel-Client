import { map, mapCommon, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct TileOverlayOnlineDemo {
  private TAG = 'TileOverlayOnlineDemo';
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private tileOverlay?: map.TileOverlay;

  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 31.98,
          longitude: 118.7
        },
        zoom: 7
      }
    };

    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        console.info(this.TAG, 'Map initialized successfully');

        let params: mapCommon.TileOverlayOptions = {
          tileUrl: 'https://example.com/tiles?x={x}&y={y}&z={z}',
          transparency: 0.5,
          fadeIn: true
        };

        try {
          this.tileOverlay = this.mapController?.addTileOverlay(params);
          console.info(this.TAG, 'TileOverlay added successfully');
        } catch (e) {
          console.error(this.TAG, `Failed to add TileOverlay, code:${e.code}, message:${e.message}`);
        }
      } else {
        console.error(this.TAG, `Failed to initialize map, code:${err.code}, message:${err.message}`);
      }
    };
  }

  aboutToDisappear(): void {
    if (this.tileOverlay) {
      this.tileOverlay.remove();
      console.info(this.TAG, 'TileOverlay removed');
    }
  }

  build() {
    Stack() {
      Column() {
        MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback });
      }
      .width('100%')
      .height('100%')
    }
    .height('100%')
  }
}