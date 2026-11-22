import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct MapPresentingDemo {
  private TAG = 'MapPresentingDemo';
  private mapOptions?: mapCommon.MapOptions;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;
  private mapEventManager?: map.MapEventManager;

  aboutToAppear(): void {
    console.info(this.TAG, 'aboutToAppear');
    
    this.mapOptions = {
      position: {
        target: {
          latitude: 39.9,
          longitude: 116.4
        },
        zoom: 10
      },
      mapType: mapCommon.MapType.STANDARD,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      tiltGesturesEnabled: true,
      zoomControlsEnabled: true,
      myLocationControlsEnabled: false,
      compassControlsEnabled: true,
      scaleControlsEnabled: false,
      minZoom: 2,
      maxZoom: 20,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true
    };

    this.callback = async (err, mapController) => {
      if (!err) {
        console.info(this.TAG, 'Map initialized successfully');
        this.mapController = mapController;
        this.mapEventManager = this.mapController.getEventManager();

        let mapLoadCallback = () => {
          console.info(this.TAG, 'on-mapLoad');
        };
        this.mapEventManager.on('mapLoad', mapLoadCallback);

        this.customizedMethod();
      } else {
        console.error(`Failed to initialize the map, code is：${err.code}, message is ${err.message}`);
      }
    };
  }

  private customizedMethod(): void {
    console.info(this.TAG, 'customizedMethod');
    
    if (this.mapController) {
      this.mapController.setBuildingEnabled(true);
    }
  }

  onPageShow(): void {
    console.info(this.TAG, 'onPageShow');
    if (this.mapController) {
      this.mapController.show();
    }
  }

  onPageHide(): void {
    console.info(this.TAG, 'onPageHide');
    if (this.mapController) {
      this.mapController.hide();
    }
  }

  build() {
    Stack() {
      MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
        .width('100%')
        .height('100%');
    }
    .height('100%');
  }
}