import { map, mapCommon } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct MapGestureControlDemo {
  private TAG = 'MapGestureControlDemo';
  private mapOptions?: mapCommon.MapOptions;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;
  
  aboutToAppear(): void {
    this.initializeMapOptions();
    this.setupMapCallback();
  }
  
  private initializeMapOptions(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 39.9,
          longitude: 116.4
        },
        zoom: 10
      },
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      tiltGesturesEnabled: true,
      zoomControlsEnabled: true
    };
  }
  
  private setupMapCallback(): void {
    this.callback = async (err, mapController) => {
      if (err) {
        console.error(this.TAG, `Map initialization failed: ${err.message}`);
        return;
      }
      
      if (!mapController) {
        console.error(this.TAG, 'MapController is null');
        return;
      }
      
      this.mapController = mapController;
      console.info(this.TAG, 'Map initialized successfully');
    };
  }
  
  private enableZoomGesture(): void {
    if (!this.mapController) {
      console.error(this.TAG, 'MapController not initialized');
      return;
    }
    
    try {
      this.mapController.setZoomGesturesEnabled(true);
      console.info(this.TAG, 'Zoom gestures enabled');
    } catch (error) {
      console.error(this.TAG, `Failed to enable zoom gestures: ${error}`);
    }
  }
  
  private disableZoomGesture(): void {
    if (!this.mapController) {
      console.error(this.TAG, 'MapController not initialized');
      return;
    }
    
    try {
      this.mapController.setZoomGesturesEnabled(false);
      console.info(this.TAG, 'Zoom gestures disabled');
    } catch (error) {
      console.error(this.TAG, `Failed to disable zoom gestures: ${error}`);
    }
  }
  
  private enableScrollGesture(): void {
    if (!this.mapController) {
      console.error(this.TAG, 'MapController not initialized');
      return;
    }
    
    try {
      this.mapController.setScrollGesturesEnabled(true);
      console.info(this.TAG, 'Scroll gestures enabled');
    } catch (error) {
      console.error(this.TAG, `Failed to enable scroll gestures: ${error}`);
    }
  }
  
  private disableScrollGesture(): void {
    if (!this.mapController) {
      console.error(this.TAG, 'MapController not initialized');
      return;
    }
    
    try {
      this.mapController.setScrollGesturesEnabled(false);
      console.info(this.TAG, 'Scroll gestures disabled');
    } catch (error) {
      console.error(this.TAG, `Failed to disable scroll gestures: ${error}`);
    }
  }
  
  private enableRotateGesture(): void {
    if (!this.mapController) {
      console.error(this.TAG, 'MapController not initialized');
      return;
    }
    
    try {
      this.mapController.setRotateGesturesEnabled(true);
      console.info(this.TAG, 'Rotate gestures enabled');
    } catch (error) {
      console.error(this.TAG, `Failed to enable rotate gestures: ${error}`);
    }
  }
  
  private disableRotateGesture(): void {
    if (!this.mapController) {
      console.error(this.TAG, 'MapController not initialized');
      return;
    }
    
    try {
      this.mapController.setRotateGesturesEnabled(false);
      console.info(this.TAG, 'Rotate gestures disabled');
    } catch (error) {
      console.error(this.TAG, `Failed to disable rotate gestures: ${error}`);
    }
  }
  
  private enableTiltGesture(): void {
    if (!this.mapController) {
      console.error(this.TAG, 'MapController not initialized');
      return;
    }
    
    try {
      this.mapController.setTiltGesturesEnabled(true);
      console.info(this.TAG, 'Tilt gestures enabled');
    } catch (error) {
      console.error(this.TAG, `Failed to enable tilt gestures: ${error}`);
    }
  }
  
  private disableTiltGesture(): void {
    if (!this.mapController) {
      console.error(this.TAG, 'MapController not initialized');
      return;
    }
    
    try {
      this.mapController.setTiltGesturesEnabled(false);
      console.info(this.TAG, 'Tilt gestures disabled');
    } catch (error) {
      console.error(this.TAG, `Failed to disable tilt gestures: ${error}`);
    }
  }
  
  private enableAllGestures(): void {
    if (!this.mapController) {
      console.error(this.TAG, 'MapController not initialized');
      return;
    }
    
    try {
      this.mapController.setAllGesturesEnabled(true);
      console.info(this.TAG, 'All gestures enabled');
    } catch (error) {
      console.error(this.TAG, `Failed to enable all gestures: ${error}`);
    }
  }
  
  private disableAllGestures(): void {
    if (!this.mapController) {
      console.error(this.TAG, 'MapController not initialized');
      return;
    }
    
    try {
      this.mapController.setAllGesturesEnabled(false);
      console.info(this.TAG, 'All gestures disabled');
    } catch (error) {
      console.error(this.TAG, `Failed to disable all gestures: ${error}`);
    }
  }
  
  private checkGestureStatus(): void {
    if (!this.mapController) {
      console.error(this.TAG, 'MapController not initialized');
      return;
    }
    
    try {
      const zoomEnabled: boolean = this.mapController.isZoomGesturesEnabled();
      const scrollEnabled: boolean = this.mapController.isScrollGesturesEnabled();
      const rotateEnabled: boolean = this.mapController.isRotateGesturesEnabled();
      const tiltEnabled: boolean = this.mapController.isTiltGesturesEnabled();
      
      console.info(this.TAG, `Gesture Status:
        Zoom: ${zoomEnabled}
        Scroll: ${scrollEnabled}
        Rotate: ${rotateEnabled}
        Tilt: ${tiltEnabled}`);
    } catch (error) {
      console.error(this.TAG, `Failed to check gesture status: ${error}`);
    }
  }
  
  build() {
    Column() {
      Stack() {
        MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
          .width('100%')
          .height('60%')
      }
      
      Scroll() {
        Column({ space: 10 }) {
          Text('手势控制面板')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 10, bottom: 10 })
          
          Row({ space: 10 }) {
            Button('启用缩放')
              .onClick(() => this.enableZoomGesture())
            Button('禁用缩放')
              .onClick(() => this.disableZoomGesture())
          }
          
          Row({ space: 10 }) {
            Button('启用滚动')
              .onClick(() => this.enableScrollGesture())
            Button('禁用滚动')
              .onClick(() => this.disableScrollGesture())
          }
          
          Row({ space: 10 }) {
            Button('启用旋转')
              .onClick(() => this.enableRotateGesture())
            Button('禁用旋转')
              .onClick(() => this.disableRotateGesture())
          }
          
          Row({ space: 10 }) {
            Button('启用倾斜')
              .onClick(() => this.enableTiltGesture())
            Button('禁用倾斜')
              .onClick(() => this.disableTiltGesture())
          }
          
          Row({ space: 10 }) {
            Button('启用所有')
              .onClick(() => this.enableAllGestures())
              .backgroundColor('#4CAF50')
            Button('禁用所有')
              .onClick(() => this.disableAllGestures())
              .backgroundColor('#F44336')
          }
          
          Button('查看手势状态')
            .onClick(() => this.checkGestureStatus())
            .width('100%')
            .backgroundColor('#2196F3')
        }
        .padding(15)
      }
      .height('40%')
    }
    .height('100%')
  }
}