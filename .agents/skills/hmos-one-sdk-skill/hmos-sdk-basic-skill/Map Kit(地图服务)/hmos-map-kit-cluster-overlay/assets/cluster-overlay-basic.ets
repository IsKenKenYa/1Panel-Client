import { map, mapCommon, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct ClusterOverlayBasicDemo {
  private TAG = 'ClusterOverlayBasicDemo';
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private clusterOverlay?: map.ClusterOverlay;

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
        await this.createClusterOverlay();
      } else {
        console.error(this.TAG, `Failed to initialize map, code: ${err.code}, message: ${err.message}`);
      }
    };
  }

  private async createClusterOverlay(): Promise<void> {
    if (!this.mapController) {
      console.error(this.TAG, 'Map controller is null');
      return;
    }

    try {
      let clusterItems: Array<mapCommon.ClusterItem> = this.createClusterItems();
      
      let clusterOverlayParams: mapCommon.ClusterOverlayParams = {
        distance: 100,
        clusterItems: clusterItems
      };

      this.clusterOverlay = await this.mapController.addClusterOverlay(clusterOverlayParams);
      console.info(this.TAG, 'Cluster overlay created successfully');
      
      this.setupEventListeners();
    } catch (error) {
      console.error(this.TAG, `Failed to create cluster overlay, code: ${error.code}, message: ${error.message}`);
    }
  }

  private createClusterItems(): Array<mapCommon.ClusterItem> {
    let items: Array<mapCommon.ClusterItem> = [];
    
    let basePositions = [
      { latitude: 31.98, longitude: 118.7 },
      { latitude: 32.99, longitude: 118.9 },
      { latitude: 31.5, longitude: 118.7 },
      { latitude: 30, longitude: 118.7 },
      { latitude: 29.98, longitude: 117.7 },
      { latitude: 31.98, longitude: 120.7 },
      { latitude: 25.98, longitude: 119.7 },
      { latitude: 30.98, longitude: 110.7 },
      { latitude: 30.98, longitude: 115.7 },
      { latitude: 28.98, longitude: 122.7 }
    ];

    for (let pos of basePositions) {
      items.push({
        position: {
          latitude: pos.latitude,
          longitude: pos.longitude
        }
      });
    }

    for (let index = 0; index < 100; index++) {
      items.push({
        position: {
          latitude: basePositions[0].latitude,
          longitude: basePositions[0].longitude
        }
      });
    }

    for (let index = 0; index < 10; index++) {
      items.push({
        position: {
          latitude: basePositions[1].latitude,
          longitude: basePositions[1].longitude
        }
      });
    }

    return items;
  }

  private setupEventListeners(): void {
    if (!this.clusterOverlay) {
      return;
    }

    let clickCallback = (clusterItems: Array<mapCommon.ClusterItem>) => {
      console.info(this.TAG, `Cluster clicked, contains ${clusterItems.length} items`);
      if (clusterItems.length > 0 && clusterItems[0].position) {
        console.info(this.TAG, `First item position: lat=${clusterItems[0].position.latitude}, lon=${clusterItems[0].position.longitude}`);
      }
    };

    this.clusterOverlay.on('click', clickCallback);

    let markerClickCallback = (markerClusterInfo: map.MarkerClusterInfo) => {
      console.info(this.TAG, 'Marker cluster clicked');
      console.info(this.TAG, `Cluster items count: ${markerClusterInfo.clusterItems.length}`);
    };

    this.clusterOverlay.on('markerClusterClick', markerClickCallback);
  }

  build() {
    Stack() {
      Column() {
        MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
          .width('100%')
          .height('100%');
      }.width('100%')
    }.height('100%')
  }
}