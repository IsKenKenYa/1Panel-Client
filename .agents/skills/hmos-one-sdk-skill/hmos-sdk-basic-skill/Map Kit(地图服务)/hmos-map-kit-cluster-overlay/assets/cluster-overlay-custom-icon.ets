import { map, mapCommon, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';

export class CustomClusterOverlayParams implements mapCommon.ClusterOverlayParams {
  clusterItems: mapCommon.ClusterItem[] = [];
  distance: number = 100;
  private offCanvas: OffscreenCanvas = new OffscreenCanvas(62, 62);
  private settings: RenderingContextSettings = new RenderingContextSettings(true);

  constructor(clusterItems: mapCommon.ClusterItem[], distance: number) {
    this.clusterItems = clusterItems;
    this.distance = distance;
  }

  async getCustomIcon(clusterItems: mapCommon.ClusterItem[]): Promise<image.PixelMap> {
    let offContext = this.offCanvas.getContext('2d', this.settings);
    offContext.clearRect(0, 0, 62, 62);

    offContext.fillStyle = 0xff990000;
    offContext.beginPath();
    offContext.arc(31, 31, 30, 0, 6.28);
    offContext.stroke();
    offContext.fill();
    offContext.save();

    offContext.font = '20vp sans-serif';
    offContext.textAlign = 'center';
    offContext.textBaseline = 'middle';
    offContext.fillStyle = 0xffffffff;
    offContext.fillText(String(clusterItems.length), 31, 31);
    offContext.restore();

    let iconPixelMap = offContext.getPixelMap(0, 0, 62, 62);
    return iconPixelMap;
  }
}

@Entry
@Component
struct ClusterOverlayCustomIconDemo {
  private TAG = 'ClusterOverlayCustomIconDemo';
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
        await this.createCustomClusterOverlay();
      } else {
        console.error(this.TAG, `Failed to initialize map, code: ${err.code}, message: ${err.message}`);
      }
    };
  }

  private async createCustomClusterOverlay(): Promise<void> {
    if (!this.mapController) {
      console.error(this.TAG, 'Map controller is null');
      return;
    }

    try {
      let clusterItems: Array<mapCommon.ClusterItem> = this.createClusterItems();
      let customParams = new CustomClusterOverlayParams(clusterItems, 100);

      this.clusterOverlay = await this.mapController.addClusterOverlay(customParams);
      console.info(this.TAG, 'Custom cluster overlay created successfully');
    } catch (error) {
      console.error(this.TAG, `Failed to create custom cluster overlay, code: ${error.code}, message: ${error.message}`);
    }
  }

  private createClusterItems(): Array<mapCommon.ClusterItem> {
    let items: Array<mapCommon.ClusterItem> = [];
    
    let basePositions = [
      { latitude: 31.98, longitude: 118.7 },
      { latitude: 32.99, longitude: 118.9 },
      { latitude: 31.5, longitude: 118.7 }
    ];

    for (let pos of basePositions) {
      for (let i = 0; i < 20; i++) {
        items.push({
          position: {
            latitude: pos.latitude + (Math.random() - 0.5) * 0.1,
            longitude: pos.longitude + (Math.random() - 0.5) * 0.1
          }
        });
      }
    }

    return items;
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