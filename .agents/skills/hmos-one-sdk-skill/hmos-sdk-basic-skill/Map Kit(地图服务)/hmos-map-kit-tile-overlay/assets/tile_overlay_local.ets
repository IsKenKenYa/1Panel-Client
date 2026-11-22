import { map, mapCommon, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { resourceManager } from '@kit.LocalizationKit';

@Entry
@Component
struct TileOverlayLocalDemo {
  private TAG = 'TileOverlayLocalDemo';
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private tileOverlay?: map.TileOverlay;
  private context?: Context;

  aboutToAppear(): void {
    this.context = getContext(this);
    
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

        let tileOverlayOption: mapCommon.TileOverlayOptions = {
          tileProvider: this.tileProviderMethod.bind(this),
          fadeIn: true,
          transparency: 0.5,
          visible: true
        };

        if (this.mapController !== undefined) {
          try {
            this.tileOverlay = this.mapController.addTileOverlay(tileOverlayOption);
            console.info(this.TAG, 'Local TileOverlay added successfully');
          } catch (e) {
            console.error(this.TAG, `Failed to add local TileOverlay, code:${e.code}, message:${e.message}`);
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
      console.info(this.TAG, 'TileOverlay removed');
    }
  }

  private async tileProviderMethod(x: number, y: number, z: number): Promise<ArrayBuffer> {
    return new Promise((resolve, reject) => {
      try {
        let tilePath = `tiles/${z}/${x}/${y}.png`;
        console.info(this.TAG, `Loading tile: ${tilePath}`);
        
        let resMgr = resourceManager.getResourceManager(this.context);
        resMgr.getRawFileContent(tilePath, (err, data) => {
          if (!err) {
            resolve(data.buffer);
            console.info(this.TAG, `Tile loaded successfully: ${tilePath}`);
          } else {
            console.error(this.TAG, `Failed to load tile ${tilePath}: ${err.message}`);
            resolve(new ArrayBuffer(0));
          }
        });
      } catch (error) {
        console.error(this.TAG, `Error in tileProvider: ${error.message}`);
        resolve(new ArrayBuffer(0));
      }
    });
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