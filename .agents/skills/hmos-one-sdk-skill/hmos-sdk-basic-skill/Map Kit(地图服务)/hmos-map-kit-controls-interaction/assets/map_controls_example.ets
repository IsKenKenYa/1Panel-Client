import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct MapControlsDemo {
  private TAG = "MapControlsDemo";
  private mapOptions?: mapCommon.MapOptions;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;
  
  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 39.9,
          longitude: 116.4
        },
        zoom: 10
      },
      zoomControlsEnabled: true,
      myLocationControlsEnabled: false,
      compassControlsEnabled: true,
      scaleControlsEnabled: false
    };
    
    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        this.setupMapControls();
      } else {
        console.error(this.TAG, `Map initialization failed: ${err.message}`);
      }
    };
  }
  
  private setupMapControls(): void {
    try {
      if (!this.mapController) {
        console.error(this.TAG, 'MapController is not initialized');
        return;
      }
      
      this.setupZoomControls();
      this.setupScaleControls();
      this.setupCompassControls();
      this.setupMyLocationControls();
      this.setupMapLogo();
      this.setupApproveNumber();
      
      console.info(this.TAG, 'All map controls setup completed');
    } catch (error) {
      console.error(this.TAG, `Failed to setup controls: ${JSON.stringify(error)}`);
    }
  }
  
  private setupZoomControls(): void {
    this.mapController?.setZoomControlsEnabled(true);
    let isEnabled: boolean = this.mapController?.isZoomControlsEnabled() ?? false;
    console.info(this.TAG, `Zoom controls enabled: ${isEnabled}`);
  }
  
  private setupScaleControls(): void {
    this.mapController?.setScaleControlsEnabled(true);
    
    let point: mapCommon.MapPoint = {
      positionX: 100,
      positionY: 100
    };
    this.mapController?.setScalePosition(point);
    
    this.mapController?.setAlwaysShowScaleEnabled(true);
    
    let height: number = this.mapController?.getScaleControlsHeight() ?? 0;
    let width: number = this.mapController?.getScaleControlsWidth() ?? 0;
    console.info(this.TAG, `Scale controls size: ${width}x${height} vp`);
    
    let level: number = this.mapController?.getScaleLevel() ?? 0;
    console.info(this.TAG, `Current scale level: ${level} meters`);
    
    let isAlwaysShow: boolean = this.mapController?.isAlwaysShowScaleEnabled() ?? false;
    console.info(this.TAG, `Always show scale: ${isAlwaysShow}`);
    
    let isEnabled: boolean = this.mapController?.isScaleControlsEnabled() ?? false;
    console.info(this.TAG, `Scale controls enabled: ${isEnabled}`);
  }
  
  private setupCompassControls(): void {
    this.mapController?.setCompassControlsEnabled(true);
    
    let point: mapCommon.MapPoint = {
      positionX: 10,
      positionY: 10
    };
    this.mapController?.setCompassPosition(point);
    
    let isEnabled: boolean = this.mapController?.isCompassControlsEnabled() ?? false;
    console.info(this.TAG, `Compass controls enabled: ${isEnabled}`);
  }
  
  private setupMyLocationControls(): void {
    this.mapController?.setMyLocationControlsEnabled(true);
    this.mapController?.setMyLocationEnabled(true);
    
    let isControlsEnabled: boolean = this.mapController?.isMyLocationControlsEnabled() ?? false;
    let isLocationEnabled: boolean = this.mapController?.isMyLocationEnabled() ?? false;
    console.info(this.TAG, `My location controls: ${isControlsEnabled}, location: ${isLocationEnabled}`);
  }
  
  private setupMapLogo(): void {
    this.mapController?.setLogoAlignment(mapCommon.LogoAlignment.BOTTOM_END);
    
    let padding: mapCommon.Padding = {
      left: 0,
      top: 0,
      right: 50,
      bottom: 50
    };
    this.mapController?.setLogoPadding(padding);
    console.info(this.TAG, 'Logo alignment set to BOTTOM_END with padding');
  }
  
  private setupApproveNumber(): void {
    this.mapController?.setApproveNumberEnabled(true);
    console.info(this.TAG, 'Approve number enabled (requires API 6.1.0(23)+)');
  }
  
  build() {
    Stack() {
      MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
        .width('100%')
        .height('100%')
    }
    .height('100%')
  }
}