import { mapCommon, map, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct TileOverlayCacheDemo {
  private TAG = 'TileOverlayCacheDemo';
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private tileOverlay?: map.TileOverlay;

  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 48.87278,
          longitude: 2.33016
        },
        zoom: 4
      },
      scaleControlsEnabled: true
    };

    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        console.info(this.TAG, 'Map initialized successfully');

        let options: mapCommon.TileOverlayOptions = {
          tileUrl: 'https://example.com/tiles?x={x}&y={y}&z={z}',
          diskCacheEnabled: true,
          diskCacheSize: 20480,
          diskCachePath: this.getUIContext().getHostContext()?.databaseDir || '/data/storage/el2/database'
        };

        if (this.mapController !== undefined) {
          try {
            this.tileOverlay = this.mapController.addTileOverlay(options);
            console.info(this.TAG, 'TileOverlay with cache added successfully');
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
      console.info(this.TAG, 'Tile cache cleared');
      
      this.tileOverlay.clearDiskCache()
        .then(() => {
          console.info(this.TAG, 'Disk cache cleared successfully');
        })
        .catch((error) => {
          console.error(this.TAG, `Failed to clear disk cache: ${error.message}`);
        });
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