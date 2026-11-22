import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct BasicMarkerDemo {
  private TAG = 'BasicMarkerDemo';
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapEventManager?: map.MapEventManager;
  private marker?: map.Marker;

  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 31.984410259206815,
          longitude: 118.76625379397866
        },
        zoom: 15
      }
    };

    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        this.mapEventManager = this.mapController.getEventManager();
        await this.addBasicMarker();
      } else {
        console.error(`${this.TAG}: Failed to initialize map, code: ${err.code}, message: ${err.message}`);
      }
    };
  }

  async addBasicMarker(): Promise<void> {
    try {
      let markerOptions: mapCommon.MarkerOptions = {
        position: {
          latitude: 31.984410259206815,
          longitude: 118.76625379397866
        },
        rotation: 0,
        visible: true,
        zIndex: 0,
        alpha: 1,
        anchorU: 0.5,
        anchorV: 1,
        clickable: true,
        draggable: true,
        flat: false
      };

      this.marker = await this.mapController.addMarker(markerOptions);
      console.info(`${this.TAG}: Basic marker created successfully`);
      
      this.marker.setDraggable(true);
      this.marker.setMarkerAnchor(0.5, 1.0);
      
      let position = this.marker.getPosition();
      console.info(`${this.TAG}: Marker position: lat=${position.latitude}, lng=${position.longitude}`);
      
    } catch (error) {
      console.error(`${this.TAG}: Failed to create marker, code: ${error.code}, message: ${error.message}`);
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