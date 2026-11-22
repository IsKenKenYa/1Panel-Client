import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct BubbleAnimationDemo {
  private TAG = "BubbleAnimationDemo";
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private bubble?: map.Bubble;

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
          
          this.setupBubbleAnimation();
        } catch (e) {
          console.error(this.TAG, `Failed to create the bubble, code: ${e.code}, message: ${e.message}`);
        }
      } else {
        console.error(this.TAG, `Failed to initialize the map, code: ${err.code}, message: ${err.message}`);
      }
    };
  }

  private setupBubbleAnimation(): void {
    let animation: map.ScaleAnimation = new map.ScaleAnimation(1, 3, 1, 3);
    
    animation.setDuration(3000);
    
    let callbackStart = () => {
      console.info(this.TAG, 'Animation started');
    };
    animation.on("animationStart", callbackStart);
    
    let callbackEnd = () => {
      console.info(this.TAG, 'Animation ended');
    };
    animation.on("animationEnd", callbackEnd);
    
    animation.setFillMode(map.AnimationFillMode.BACKWARDS);
    animation.setRepeatMode(map.AnimationRepeatMode.REVERSE);
    animation.setInterpolator(Curve.Linear);
    animation.setRepeatCount(100);
    
    this.bubble?.setAnimation(animation);
    this.bubble?.startAnimation();
    
    console.info(this.TAG, 'Animation setup completed');
  }

  build() {
    Stack() {
      Column() {
        MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback });
      }.width('100%')
    }.height('100%')
  }
}