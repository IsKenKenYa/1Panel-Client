import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct MapTypeSwitchExample {
  private TAG = 'MapTypeSwitchExample';
  private mapOptions?: mapCommon.MapOptions;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;
  private currentMapType: mapCommon.MapType = mapCommon.MapType.STANDARD;

  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 31.984410259206815,
          longitude: 118.76625379397866
        },
        zoom: 15
      },
      mapType: mapCommon.MapType.STANDARD
    };

    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        this.currentMapType = this.mapController.getMapType();
        console.info(this.TAG, 'Map initialized successfully');
      }
    };
  }

  private switchToStandard(): void {
    if (this.mapController) {
      this.mapController.setMapType(mapCommon.MapType.STANDARD);
      this.currentMapType = mapCommon.MapType.STANDARD;
      console.info(this.TAG, 'Switched to STANDARD map');
    }
  }

  private switchToTerrain(): void {
    if (this.mapController) {
      let cameraPosition = this.mapController.getCameraPosition();
      if (cameraPosition.zoom >= 5 && cameraPosition.zoom <= 14) {
        this.mapController.setMapType(mapCommon.MapType.TERRAIN);
        this.currentMapType = mapCommon.MapType.TERRAIN;
        console.info(this.TAG, 'Switched to TERRAIN map at optimal zoom level');
      } else {
        console.warn(this.TAG, 'Terrain map best viewed at zoom level 5-14');
        this.mapController.setMapType(mapCommon.MapType.TERRAIN);
        this.currentMapType = mapCommon.MapType.TERRAIN;
      }
    }
  }

  private switchToSatellite(): void {
    if (this.mapController) {
      this.mapController.setMapType(mapCommon.MapType.SATELLITE);
      this.currentMapType = mapCommon.MapType.SATELLITE;
      console.info(this.TAG, 'Switched to SATELLITE map');
    }
  }

  private switchToHybrid(): void {
    if (this.mapController) {
      this.mapController.setMapType(mapCommon.MapType.HYBRID);
      this.currentMapType = mapCommon.MapType.HYBRID;
      console.info(this.TAG, 'Switched to HYBRID map');
    }
  }

  private getMapTypeInfo(): void {
    if (this.mapController) {
      let mapType = this.mapController.getMapType();
      let cameraPosition = this.mapController.getCameraPosition();
      console.info(this.TAG, `Current map type: ${mapType}, Zoom: ${cameraPosition.zoom}`);
    }
  }

  build() {
    Column() {
      Stack() {
        MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
          .width('100%')
          .height('70%')
      }

      Row() {
        Button('Standard')
          .onClick(() => this.switchToStandard())
          .width('20%')
        
        Button('Terrain')
          .onClick(() => this.switchToTerrain())
          .width('20%')
        
        Button('Satellite')
          .onClick(() => this.switchToSatellite())
          .width('20%')
        
        Button('Hybrid')
          .onClick(() => this.switchToHybrid())
          .width('20%')
        
        Button('Info')
          .onClick(() => this.getMapTypeInfo())
          .width('20%')
      }
      .width('100%')
      .height('30%')
      .justifyContent(FlexAlign.SpaceAround)
    }
    .height('100%')
  }
}