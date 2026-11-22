import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct MapTypeInitExample {
  private TAG = 'MapTypeInitExample';
  private mapOptions?: mapCommon.MapOptions;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;
  private mapEventManager?: map.MapEventManager;

  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 31.984410259206815,
          longitude: 118.76625379397866
        },
        zoom: 15
      },
      mapType: mapCommon.MapType.STANDARD
    };

    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        this.mapEventManager = this.mapController.getEventManager();
        
        let mapLoadCallback = () => {
          console.info(this.TAG, 'Map loaded with STANDARD type');
          let currentType = this.mapController?.getMapType();
          console.info(this.TAG, `Current map type: ${currentType}`);
        };
        
        this.mapEventManager.on('mapLoad', mapLoadCallback);
      } else {
        console.error(this.TAG, 'Map initialization failed:', err);
      }
    };
  }

  build() {
    Stack() {
      MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
        .width('100%')
        .height('100%')
    }
    .height('100%')
  }
}