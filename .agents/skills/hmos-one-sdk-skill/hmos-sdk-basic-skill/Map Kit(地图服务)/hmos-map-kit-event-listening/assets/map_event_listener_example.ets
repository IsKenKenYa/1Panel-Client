import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct MapEventListenerExample {
  private TAG = 'MapEventListenerExample';
  private mapOptions?: mapCommon.MapOptions;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;
  private mapEventManager?: map.MapEventManager;
  
  private clickCount: number = 0;
  private longClickCount: number = 0;
  private cameraMoveCount: number = 0;
  
  aboutToAppear(): void {
    this.initMapOptions();
    this.initMapCallback();
  }
  
  private initMapOptions(): void {
    this.mapOptions = {
      mapType: mapCommon.MapType.STANDARD,
      position: {
        target: {
          latitude: 39.9,
          longitude: 116.4
        },
        zoom: 10
      },
      zoomControlsEnabled: true,
      myLocationControlsEnabled: true,
      compassControlsEnabled: true,
      scaleControlsEnabled: true
    };
  }
  
  private initMapCallback(): void {
    this.callback = async (err, mapController) => {
      if (err) {
        console.error(this.TAG, 'Map initialization failed:', err.message);
        return;
      }
      
      if (!mapController) {
        console.error(this.TAG, 'MapController is null');
        return;
      }
      
      this.mapController = mapController;
      console.info(this.TAG, 'Map initialized successfully');
      
      this.setupAllEventListeners();
    };
  }
  
  private setupAllEventListeners(): void {
    if (!this.mapController) {
      console.error(this.TAG, 'MapController not initialized');
      return;
    }
    
    this.mapEventManager = this.mapController.getEventManager();
    
    if (!this.mapEventManager) {
      console.error(this.TAG, 'Failed to get MapEventManager');
      return;
    }
    
    console.info(this.TAG, 'MapEventManager obtained, setting up listeners...');
    
    this.setupMapClickListener();
    this.setupMapLongClickListener();
    this.setupCameraMoveListeners();
    this.setupMapLoadListener();
    this.setupMyLocationButtonClickListener();
  }
  
  private setupMapClickListener(): void {
    let clickCallback = (position: mapCommon.LatLng) => {
      this.clickCount++;
      console.info(this.TAG, `Map clicked #${this.clickCount}`);
      console.info(this.TAG, `Position: lat=${position.latitude}, lng=${position.longitude}`);
      
      this.validateLatLng(position);
      this.showToast(`点击位置: ${position.latitude.toFixed(4)}, ${position.longitude.toFixed(4)}`);
    };
    
    this.mapEventManager?.on('mapClick', clickCallback);
    console.info(this.TAG, 'Map click listener registered');
  }
  
  private setupMapLongClickListener(): void {
    let longClickCallback = (position: mapCommon.LatLng) => {
      this.longClickCount++;
      console.info(this.TAG, `Map long clicked #${this.longClickCount}`);
      console.info(this.TAG, `Position: lat=${position.latitude}, lng=${position.longitude}`);
      
      this.validateLatLng(position);
      this.showToast(`长按位置: ${position.latitude.toFixed(4)}, ${position.longitude.toFixed(4)}`);
    };
    
    this.mapEventManager?.on('mapLongClick', longClickCallback);
    console.info(this.TAG, 'Map long click listener registered');
  }
  
  private setupCameraMoveListeners(): void {
    let moveStartCallback = (reason: number) => {
      console.info(this.TAG, `Camera move started, reason: ${reason}`);
      this.logCameraMoveReason(reason);
    };
    
    let moveCallback = () => {
      this.cameraMoveCount++;
      if (this.cameraMoveCount % 10 === 0) {
        console.info(this.TAG, `Camera moving, count: ${this.cameraMoveCount}`);
      }
    };
    
    let idleCallback = () => {
      console.info(this.TAG, `Camera move ended, total moves: ${this.cameraMoveCount}`);
      this.cameraMoveCount = 0;
      
      if (this.mapController) {
        let position = this.mapController.getCameraPosition();
        console.info(this.TAG, `Final camera position: lat=${position.target.latitude}, zoom=${position.zoom}`);
      }
    };
    
    this.mapEventManager?.on('cameraMoveStart', moveStartCallback);
    this.mapEventManager?.on('cameraMove', moveCallback);
    this.mapEventManager?.on('cameraIdle', idleCallback);
    
    console.info(this.TAG, 'Camera move listeners registered');
  }
  
  private setupMapLoadListener(): void {
    let loadCallback = () => {
      console.info(this.TAG, 'Map loaded successfully');
      this.showToast('地图加载完成');
    };
    
    this.mapEventManager?.on('mapLoad', loadCallback);
    console.info(this.TAG, 'Map load listener registered');
  }
  
  private setupMyLocationButtonClickListener(): void {
    let myLocationCallback = () => {
      console.info(this.TAG, 'My location button clicked');
      this.showToast('我的位置按钮点击');
    };
    
    this.mapEventManager?.on('myLocationButtonClick', myLocationCallback);
    console.info(this.TAG, 'My location button listener registered');
  }
  
  private validateLatLng(position: mapCommon.LatLng): void {
    if (position.latitude < -90 || position.latitude > 90) {
      console.warn(this.TAG, `Invalid latitude: ${position.latitude}`);
    }
    
    if (position.longitude < -180 || position.longitude >= 180) {
      console.warn(this.TAG, `Invalid longitude: ${position.longitude}`);
    }
  }
  
  private logCameraMoveReason(reason: number): void {
    let reasonDesc: string;
    switch (reason) {
      case 1:
        reasonDesc = 'User gesture';
        break;
      case 2:
        reasonDesc = 'User interaction animation';
        break;
      case 3:
        reasonDesc = 'Developer initiated animation';
        break;
      default:
        reasonDesc = 'Unknown reason';
    }
    console.info(this.TAG, `Camera move reason: ${reasonDesc} (${reason})`);
  }
  
  private showToast(message: string): void {
    console.info(this.TAG, `Toast: ${message}`);
  }
  
  private removeAllListeners(): void {
    if (!this.mapEventManager) {
      console.warn(this.TAG, 'No listeners to remove');
      return;
    }
    
    this.mapEventManager.off('mapClick');
    this.mapEventManager.off('mapLongClick');
    this.mapEventManager.off('cameraMoveStart');
    this.mapEventManager.off('cameraMove');
    this.mapEventManager.off('cameraIdle');
    this.mapEventManager.off('mapLoad');
    this.mapEventManager.off('myLocationButtonClick');
    
    console.info(this.TAG, 'All listeners removed');
    this.showToast('已移除所有监听');
  }
  
  build() {
    Column() {
      Stack() {
        MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
          .width('100%')
          .height('80%')
      }
      
      Row() {
        Button('移除所有监听')
          .onClick(() => {
            this.removeAllListeners();
          })
          .width('50%')
          .height(40)
        
        Button('重新注册监听')
          .onClick(() => {
            this.setupAllEventListeners();
          })
          .width('50%')
          .height(40)
      }
      .width('100%')
      .height('10%')
      .justifyContent(FlexAlign.SpaceEvenly)
      
      Column() {
        Text(`点击次数: ${this.clickCount}`)
          .fontSize(14)
        Text(`长按次数: ${this.longClickCount}`)
          .fontSize(14)
      }
      .width('100%')
      .height('10%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}