import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct EventListenerMarkerDemo {
  private TAG = 'EventListenerMarkerDemo';
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
        await this.addMarkerWithEvents();
      } else {
        console.error(`${this.TAG}: Failed to initialize map, code: ${err.code}, message: ${err.message}`);
      }
    };
  }

  async addMarkerWithEvents(): Promise<void> {
    try {
      let markerOptions: mapCommon.MarkerOptions = {
        position: {
          latitude: 31.984410259206815,
          longitude: 118.76625379397866
        },
        clickable: true,
        draggable: true
      };
      
      this.marker = await this.mapController.addMarker(markerOptions);
      console.info(`${this.TAG}: Marker created with ID: ${this.marker.getId()}`);
      
      this.setupEventListeners();
      
    } catch (error) {
      console.error(`${this.TAG}: Failed to create marker, code: ${error.code}, message: ${error.message}`);
    }
  }

  setupEventListeners(): void {
    let clickCallback = (marker: map.Marker) => {
      console.info(`${this.TAG}: Marker clicked, ID: ${marker.getId()}`);
    };
    this.mapEventManager.on('markerClick', clickCallback);

    let dragStartCallback = (marker: map.Marker) => {
      console.info(`${this.TAG}: Marker drag started, ID: ${marker.getId()}`);
    };
    this.mapEventManager.on('markerDragStart', dragStartCallback);

    let dragCallback = (marker: map.Marker) => {
      let pos = marker.getPosition();
      console.info(`${this.TAG}: Marker dragging, ID: ${marker.getId()}, position: (${pos.latitude}, ${pos.longitude})`);
    };
    this.mapEventManager.on('markerDrag', dragCallback);

    let dragEndCallback = (marker: map.Marker) => {
      let pos = marker.getPosition();
      console.info(`${this.TAG}: Marker drag ended, ID: ${marker.getId()}, final position: (${pos.latitude}, ${pos.longitude})`);
    };
    this.mapEventManager.on('markerDragEnd', dragEndCallback);

    let longClickCallback = (markerLong: map.Marker) => {
      console.info(`${this.TAG}: Marker long clicked, ID: ${markerLong.getId()}`);
    };
    this.mapEventManager.onMarkerLongClick(longClickCallback);
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