import { map, mapCommon, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct ClusterOverlayEventsDemo {
  private TAG = 'ClusterOverlayEventsDemo';
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private clusterOverlay?: map.ClusterOverlay;
  private clickCallback1?: (clusterItems: Array<mapCommon.ClusterItem>) => void;
  private clickCallback2?: (clusterItems: Array<mapCommon.ClusterItem>) => void;
  private markerClickCallback?: (markerClusterInfo: map.MarkerClusterInfo) => void;

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
      let clusterItems: Array<mapCommon.ClusterItem> = [
        { position: { latitude: 31.98, longitude: 118.7 } },
        { position: { latitude: 32.99, longitude: 118.9 } },
        { position: { latitude: 31.5, longitude: 118.7 } }
      ];

      let clusterOverlayParams: mapCommon.ClusterOverlayParams = {
        distance: 100,
        clusterItems: clusterItems
      };

      this.clusterOverlay = await this.mapController.addClusterOverlay(clusterOverlayParams);
      console.info(this.TAG, 'Cluster overlay created successfully');
      
      this.setupMultipleEventListeners();
    } catch (error) {
      console.error(this.TAG, `Failed to create cluster overlay, code: ${error.code}, message: ${error.message}`);
    }
  }

  private setupMultipleEventListeners(): void {
    if (!this.clusterOverlay) {
      return;
    }

    this.clickCallback1 = (clusterItems: Array<mapCommon.ClusterItem>) => {
      console.info(this.TAG, `Callback1: Cluster clicked with ${clusterItems.length} items`);
    };

    this.clickCallback2 = (clusterItems: Array<mapCommon.ClusterItem>) => {
      console.info(this.TAG, `Callback2: Processing cluster items`);
      if (clusterItems.length > 0) {
        console.info(this.TAG, `First item at: ${clusterItems[0].position.latitude}, ${clusterItems[0].position.longitude}`);
      }
    };

    this.clusterOverlay.on('click', this.clickCallback1);
    this.clusterOverlay.on('click', this.clickCallback2);

    this.markerClickCallback = (markerClusterInfo: map.MarkerClusterInfo) => {
      console.info(this.TAG, 'Marker cluster clicked');
      console.info(this.TAG, `Marker position: ${markerClusterInfo.marker.getPosition().latitude}`);
      console.info(this.TAG, `Cluster items: ${markerClusterInfo.clusterItems.length}`);
    };

    this.clusterOverlay.on('markerClusterClick', this.markerClickCallback);
  }

  private removeSpecificListener(): void {
    if (!this.clusterOverlay || !this.clickCallback1) {
      return;
    }
    this.clusterOverlay.off('click', this.clickCallback1);
    console.info(this.TAG, 'Removed callback1');
  }

  private removeAllListeners(): void {
    if (!this.clusterOverlay) {
      return;
    }
    this.clusterOverlay.off('click');
    this.clusterOverlay.off('markerClusterClick');
    console.info(this.TAG, 'Removed all listeners');
  }

  private async addNewClusterItem(): Promise<void> {
    if (!this.clusterOverlay) {
      console.error(this.TAG, 'Cluster overlay is null');
      return;
    }

    try {
      let newItem: mapCommon.ClusterItem = {
        position: {
          latitude: 30.5,
          longitude: 118.0
        }
      };

      await this.clusterOverlay.addItem(newItem);
      console.info(this.TAG, 'New cluster item added successfully');
    } catch (error) {
      console.error(this.TAG, `Failed to add item, code: ${error.code}, message: ${error.message}`);
    }
  }

  private async removeClusterOverlay(): Promise<void> {
    if (!this.clusterOverlay) {
      console.error(this.TAG, 'Cluster overlay is null');
      return;
    }

    try {
      this.removeAllListeners();
      await this.clusterOverlay.remove();
      this.clusterOverlay = undefined;
      console.info(this.TAG, 'Cluster overlay removed successfully');
    } catch (error) {
      console.error(this.TAG, `Failed to remove overlay, code: ${error.code}, message: ${error.message}`);
    }
  }

  build() {
    Stack() {
      Column() {
        MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
          .width('100%')
          .height('70%');

        Row() {
          Button('Add Item')
            .onClick(() => this.addNewClusterItem())
            .margin(5);

          Button('Remove Listener1')
            .onClick(() => this.removeSpecificListener())
            .margin(5);

          Button('Remove All')
            .onClick(() => this.removeAllListeners())
            .margin(5);

          Button('Delete Overlay')
            .onClick(() => this.removeClusterOverlay())
            .margin(5);
        }
        .width('100%')
        .height('30%')
        .justifyContent(FlexAlign.Center);
      }
      .width('100%')
    }
    .height('100%')
  }
}