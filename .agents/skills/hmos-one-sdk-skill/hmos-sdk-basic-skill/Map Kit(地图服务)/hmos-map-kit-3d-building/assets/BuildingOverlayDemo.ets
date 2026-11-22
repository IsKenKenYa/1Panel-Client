import { mapCommon, map, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct BuildingOverlayDemo {
  private TAG = "BuildingOverlayDemo";
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private buildingOverlay?: map.BuildingOverlay;

  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 31.984794,
          longitude: 118.765865
        },
        zoom: 18
      },
      scaleControlsEnabled: true
    };

    this.callback = async (err, mapController) => {
      console.info(this.TAG, "MapComponent initialized");
      if (!err) {
        this.mapController = mapController;
        await this.addBuildingOverlay();
      } else {
        console.error(this.TAG, `Map initialization failed: ${err.code}, ${err.message}`);
      }
    };
  }

  private async addBuildingOverlay(): Promise<void> {
    console.info(this.TAG, "Adding 3D building overlay");

    let points: Array<mapCommon.LatLng> = [
      { latitude: 31.984794, longitude: 118.765865 },
      { latitude: 31.98468, longitude: 118.766076 },
      { latitude: 31.98472, longitude: 118.766116 },
      { latitude: 31.98463, longitude: 118.766292 },
      { latitude: 31.984586, longitude: 118.766251 },
      { latitude: 31.984536, longitude: 118.766344 },
      { latitude: 31.984633, longitude: 118.766446 },
      { latitude: 31.9848, longitude: 118.766285 },
      { latitude: 31.984925, longitude: 118.766312 },
      { latitude: 31.985282, longitude: 118.766661 },
      { latitude: 31.985438, longitude: 118.766419 },
      { latitude: 31.985801, longitude: 118.766755 },
      { latitude: 31.985856, longitude: 118.766504 },
      { latitude: 31.985785, longitude: 118.766434 },
      { latitude: 31.985821, longitude: 118.766278 },
      { latitude: 31.985897, longitude: 118.766311 },
      { latitude: 31.985944, longitude: 118.766095 },
      { latitude: 31.985909, longitude: 118.766069 },
      { latitude: 31.985794, longitude: 118.765989 },
      { latitude: 31.9857, longitude: 118.766029 },
      { latitude: 31.985658, longitude: 118.766164 },
      { latitude: 31.985647, longitude: 118.766271 },
      { latitude: 31.985574, longitude: 118.766297 },
      { latitude: 31.985458, longitude: 118.766285 },
      { latitude: 31.985271, longitude: 118.766002 },
      { latitude: 31.985219, longitude: 118.766002 },
      { latitude: 31.985135, longitude: 118.766029 },
      { latitude: 31.985093, longitude: 118.766083 },
      { latitude: 31.985019, longitude: 118.766109 },
      { latitude: 31.984978, longitude: 118.766083 },
      { latitude: 31.984794, longitude: 118.765865 }
    ];

    points.reverse();

    if (!this.validateBuildingParams(points)) {
      console.error(this.TAG, "Building params validation failed");
      return;
    }

    let buildingOverlayParams: mapCommon.BuildingOverlayParams = {
      points: points,
      totalHeight: 51,
      floorBottomHeight: 33,
      topFaceColor: 0xffa4b8f7,
      sideFaceColor: 0x44a4b8f7,
      floorColor: 0xff000000,
      showLevel: 14,
      animationDuration: 5000,
      sideTexture: { image: $r("app.media.side_tex"), height: 3, width: 3 },
      floorTexture: { image: $r("app.media.floor_tex"), height: 3, width: 3 }
    };

    let cameraUpdate = map.newCameraPosition({
      target: {
        latitude: 31.984794,
        longitude: 118.765865
      },
      zoom: 18,
      tilt: 70
    });

    this.mapController?.moveCamera(cameraUpdate);

    try {
      this.buildingOverlay = await this.mapController?.addBuildingOverlay(buildingOverlayParams);
      if (this.buildingOverlay) {
        console.info(this.TAG, `Building overlay added successfully, ID: ${this.buildingOverlay.getId()}`);
      }
    } catch (error) {
      console.error(this.TAG, `Failed to add building overlay: ${error.code}, ${error.message}`);
      this.handleBuildingError(error);
    }
  }

  private validateBuildingParams(points: Array<mapCommon.LatLng>): boolean {
    if (points.length < 3) {
      console.error(this.TAG, "Insufficient points: must have at least 3 points");
      return false;
    }

    for (let point of points) {
      if (point.latitude < -90 || point.latitude > 90) {
        console.error(this.TAG, `Invalid latitude: ${point.latitude}, range: [-90, 90]`);
        return false;
      }
      if (point.longitude < -180 || point.longitude >= 180) {
        console.error(this.TAG, `Invalid longitude: ${point.longitude}, range: [-180, 180)`);
        return false;
      }
    }

    return true;
  }

  private handleBuildingError(error: any): void {
    switch (error.code) {
      case 401:
        console.error(this.TAG, "Invalid parameters: check points array and params format");
        break;
      case 1002601001:
        console.error(this.TAG, "Map controller not found: ensure map is initialized");
        break;
      default:
        console.error(this.TAG, `Unknown error: ${error.message}`);
    }
  }

  build() {
    Stack() {
      Column() {
        MapComponent({
          mapOptions: this.mapOptions,
          mapCallback: this.callback,
        }).width('100%').height('100%');
      }.width('100%')
    }.height('100%')
  }
}