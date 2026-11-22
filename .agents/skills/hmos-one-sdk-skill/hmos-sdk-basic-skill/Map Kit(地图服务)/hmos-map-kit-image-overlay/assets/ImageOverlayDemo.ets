import { map, mapCommon, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct ImageOverlayDemo {
  private TAG = 'ImageOverlayDemo';
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapEventManager?: map.MapEventManager;
  private imageOverlay?: map.ImageOverlay;

  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: { latitude: 32.2, longitude: 118.2 },
        zoom: 10
      }
    };

    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        this.mapEventManager = this.mapController.getEventManager();
        
        await this.addDefaultImageOverlay();
        this.setupImageOverlayClickListener();
      } else {
        console.error(this.TAG, `Failed to initialize map, code: ${err.code}, message: ${err.message}`);
      }
    };
  }

  private async addDefaultImageOverlay(): Promise<void> {
    let imageOverlayParams: mapCommon.ImageOverlayParams = {
      bounds: {
        southwest: { latitude: 32, longitude: 118 },
        northeast: { latitude: 32.4, longitude: 118.4 }
      },
      image: 'icon/icon.png',
      transparency: 0.3,
      zIndex: 101,
      anchorU: 0.5,
      anchorV: 0.5,
      clickable: true,
      visible: true,
      bearing: 0
    };

    try {
      this.imageOverlay = await this.mapController?.addImageOverlay(imageOverlayParams);
      console.info(this.TAG, 'ImageOverlay added successfully');
    } catch (e) {
      console.error(this.TAG, `Failed to add imageOverlay, code: ${e.code}, message: ${e.message}`);
    }
  }

  private setupImageOverlayClickListener(): void {
    let imageOverlayCallback: Callback<map.ImageOverlay> = (imageOverlay: map.ImageOverlay) => {
      console.info(this.TAG, 'ImageOverlay clicked');
      let bounds = imageOverlay.getBounds();
      let bearing = imageOverlay.getBearing();
      let transparency = imageOverlay.getTransparency();
      
      console.info(this.TAG, `Bounds: SW(${bounds.southwest.latitude}, ${bounds.southwest.longitude}), NE(${bounds.northeast.latitude}, ${bounds.northeast.longitude})`);
      console.info(this.TAG, `Bearing: ${bearing}, Transparency: ${transparency}`);
    };

    this.mapEventManager?.on('imageOverlayClick', imageOverlayCallback);
  }

  private async updateImageOverlay(): Promise<void> {
    if (!this.imageOverlay) {
      console.error(this.TAG, 'ImageOverlay not initialized');
      return;
    }

    try {
      this.imageOverlay.setBearing(180);
      this.imageOverlay.setTransparency(0.5);
      this.imageOverlay.setClickable(true);
      
      let newBounds: mapCommon.LatLngBounds = {
        southwest: { latitude: 32.1, longitude: 118.1 },
        northeast: { latitude: 32.5, longitude: 118.5 }
      };
      this.imageOverlay.setBounds(newBounds);
      
      await this.imageOverlay.setImage('icon/new_icon.png');
      console.info(this.TAG, 'ImageOverlay updated successfully');
    } catch (error) {
      console.error(this.TAG, `Failed to update imageOverlay: ${error.message}`);
    }
  }

  private removeImageOverlay(): void {
    if (!this.imageOverlay) {
      console.error(this.TAG, 'ImageOverlay not initialized');
      return;
    }
    this.imageOverlay.remove();
    console.info(this.TAG, 'ImageOverlay removed');
  }

  build() {
    Stack() {
      Column() {
        MapComponent({
          mapOptions: this.mapOptions,
          mapCallback: this.callback,
        })
          .width('100%')
          .height('100%');
      }.width('100%')
      
      Column() {
        Button('Update Overlay')
          .onClick(() => this.updateImageOverlay())
          .margin(10);
        
        Button('Remove Overlay')
          .onClick(() => this.removeImageOverlay())
          .margin(10);
      }
      .position({ x: 10, y: 10 })
      .width('150px')
    }.height('100%')
  }
}