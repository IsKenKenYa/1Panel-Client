import { mapCommon, map, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct TileOverlayReuseDemo {
  private TAG = 'TileOverlayReuseDemo';
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
      },
      scaleControlsEnabled: true
    };

    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        console.info(this.TAG, 'Map initialized successfully');

        let params: mapCommon.TileOverlayOptions = {
          tileUrl: 'https://example.com/tiles?x={x}&y={y}&z={z}',
          diskCacheEnabled: true,
          diskCacheSize: 20480,
          diskCachePath: '/data/storage/el2/database',
          tileDataReuse: [2, 3, 4, 5, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7]
        };

        if (this.mapController !== undefined) {
          try {
            this.tileOverlay = this.mapController.addTileOverlay(params);
            console.info(this.TAG, 'TileOverlay with reuse config added successfully');
            console.info(this.TAG, 'TileDataReuse config applied for high-level optimization');
          } catch (e) {
            console.error(this.TAG, `Failed to add TileOverlay, code:${e.code}, message:${e.message}`);
          }
        }
      } else {
        console.error(this.TAG, `Failed to initialize map, code:${err.code}, message:${err.message}`);
      }
    };
  }

  aboutToDisappear(): void {
    if (this.tileOverlay) {
      this.tileOverlay.remove();
      this.tileOverlay.clearTileCache();
      console.info(this.TAG, 'TileOverlay removed and cache cleared');
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