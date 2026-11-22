import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct BubbleClickDemo {
  private TAG = "BubbleClickDemo";
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private bubble?: map.Bubble;
  @State clickCount: number = 0;

  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 39.918,
          longitude: 116.397
        },
        zoom: 14
      }
    };

    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        console.info(this.TAG, 'Map initialized successfully');

        let bubbleOptions: mapCommon.BubbleParams = {
          positions: [[{
            latitude: 39.918,
            longitude: 116.397
          }]],
          icons: [
            'speed_limit_10.png',
            'speed_limit_20.png',
            'speed_limit_30.png',
            'speed_limit_40.png'
          ],
          forceVisible: true,
          priority: 3,
          minZoom: 2,
          maxZoom: 20,
          visible: true,
          zIndex: 1
        };

        try {
          this.bubble = await this.mapController.addBubble(bubbleOptions);
          console.info(this.TAG, 'Bubble added successfully');
          
          this.setupBubbleClickListener();
        } catch (e) {
          console.error(this.TAG, `Failed to create the bubble, code: ${e.code}, message: ${e.message}`);
        }
      } else {
        console.error(this.TAG, `Failed to initialize the map, code: ${err.code}, message: ${err.message}`);
      }
    };
  }

  private setupBubbleClickListener(): void {
    let callback = (bubble: map.Bubble) => {
      this.clickCount++;
      console.info(this.TAG, `Bubble clicked, id: ${bubble.getId()}, count: ${this.clickCount}`);
    };
    this.mapController?.on("bubbleClick", callback);
  }

  build() {
    Stack() {
      Column() {
        MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback });
        
        Text(`Click Count: ${this.clickCount}`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20 })
      }.width('100%')
    }.height('100%')
  }
}