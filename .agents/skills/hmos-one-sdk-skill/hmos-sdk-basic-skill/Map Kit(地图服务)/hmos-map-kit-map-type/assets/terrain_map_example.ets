import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct TerrainMapExample {
  private TAG = 'TerrainMapExample';
  private mapOptions?: mapCommon.MapOptions;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;
  private optimalZoomMin: number = 5;
  private optimalZoomMax: number = 14;

  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 31.984410259206815,
          longitude: 118.76625379397866
        },
        zoom: 10
      },
      mapType: mapCommon.MapType.TERRAIN,
      minZoom: this.optimalZoomMin,
      maxZoom: this.optimalZoomMax
    };

    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        console.info(this.TAG, 'Terrain map initialized at optimal zoom level');
        
        this.verifyTerrainDisplay();
      } else {
        console.error(this.TAG, 'Failed to initialize terrain map:', err);
      }
    };
  }

  private verifyTerrainDisplay(): void {
    if (this.mapController) {
      let cameraPosition = this.mapController.getCameraPosition();
      let mapType = this.mapController.getMapType();
      
      console.info(this.TAG, `Map type: ${mapType}`);
      console.info(this.TAG, `Current zoom: ${cameraPosition.zoom}`);
      
      if (cameraPosition.zoom >= this.optimalZoomMin && cameraPosition.zoom <= this.optimalZoomMax) {
        console.info(this.TAG, 'Zoom level is optimal for terrain display');
      } else {
        console.warn(this.TAG, 'Zoom level outside optimal range for terrain');
      }
    }
  }

  private adjustZoomForTerrain(): void {
    if (this.mapController) {
      let cameraPosition = this.mapController.getCameraPosition();
      let targetZoom = 10;
      
      if (cameraPosition.zoom < this.optimalZoomMin) {
        targetZoom = this.optimalZoomMin;
        console.info(this.TAG, `Adjusting zoom to minimum optimal level: ${targetZoom}`);
      } else if (cameraPosition.zoom > this.optimalZoomMax) {
        targetZoom = this.optimalZoomMax;
        console.info(this.TAG, `Adjusting zoom to maximum optimal level: ${targetZoom}`);
      } else {
        console.info(this.TAG, 'Zoom level already optimal, no adjustment needed');
        return;
      }
      
      let target: mapCommon.LatLng = {
        latitude: cameraPosition.target.latitude,
        longitude: cameraPosition.target.longitude
      };
      
      let newCameraPosition: mapCommon.CameraPosition = {
        target: target,
        zoom: targetZoom
      };
      
      let cameraUpdate = map.newCameraPosition(newCameraPosition);
      this.mapController.animateCamera(cameraUpdate, 1000);
    }
  }

  build() {
    Column() {
      Stack() {
        MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
          .width('100%')
          .height('80%')
      }

      Row() {
        Button('Adjust Zoom')
          .onClick(() => this.adjustZoomForTerrain())
          .width('50%')
        
        Button('Verify Display')
          .onClick(() => this.verifyTerrainDisplay())
          .width('50%')
      }
      .width('100%')
      .height('20%')
      .justifyContent(FlexAlign.SpaceAround)
    }
    .height('100%')
  }
}