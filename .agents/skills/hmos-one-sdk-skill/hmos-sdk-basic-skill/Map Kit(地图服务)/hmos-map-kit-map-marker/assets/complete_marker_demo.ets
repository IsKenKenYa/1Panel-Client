import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';

@Entry
@Component
struct CompleteMarkerDemo {
  private TAG = 'CompleteMarkerDemo';
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapEventManager?: map.MapEventManager;
  private marker?: map.Marker;
  private markerCount: number = 0;

  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 31.984410259206815,
          longitude: 118.76625379397866
        },
        zoom: 15
      },
      scaleControlsEnabled: true,
      zoomControlsEnabled: true
    };

    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        this.mapEventManager = this.mapController.getEventManager();
        console.info(`${this.TAG}: Map initialized successfully`);
        await this.createDemoMarkers();
      } else {
        console.error(`${this.TAG}: Failed to initialize map, code: ${err.code}, message: ${err.message}`);
      }
    };
  }

  async createDemoMarkers(): Promise<void> {
    await this.createBasicMarker();
    await this.createCustomIconMarker();
    await this.createInfoWindowMarker();
    await this.createAnimatedMarker();
    this.setupEventListeners();
  }

  async createBasicMarker(): Promise<void> {
    try {
      let markerOptions: mapCommon.MarkerOptions = {
        position: {
          latitude: 31.984410259206815,
          longitude: 118.76625379397866
        },
        rotation: 0,
        visible: true,
        zIndex: 0,
        alpha: 1,
        anchorU: 0.5,
        anchorV: 1,
        clickable: true,
        draggable: true,
        flat: false
      };

      this.marker = await this.mapController?.addMarker(markerOptions);
      console.info(`${this.TAG}: Basic marker created`);
      this.markerCount++;
    } catch (error) {
      console.error(`${this.TAG}: Failed to create basic marker, code: ${error.code}, message: ${error.message}`);
    }
  }

  async createCustomIconMarker(): Promise<void> {
    try {
      let markerOptions: mapCommon.MarkerOptions = {
        position: {
          latitude: 31.994410259206815,
          longitude: 118.77625379397866
        },
        icon: 'custom_icon.png',
        clickable: true
      };

      let customMarker = await this.mapController?.addMarker(markerOptions);
      console.info(`${this.TAG}: Custom icon marker created`);
      this.markerCount++;
    } catch (error) {
      console.error(`${this.TAG}: Failed to create custom icon marker, code: ${error.code}, message: ${error.message}`);
    }
  }

  async createInfoWindowMarker(): Promise<void> {
    try {
      let markerOptions: mapCommon.MarkerOptions = {
        position: {
          latitude: 31.974410259206815,
          longitude: 118.75625379397866
        },
        title: '南京',
        snippet: '华东地区',
        clickable: true
      };

      let infoMarker = await this.mapController?.addMarker(markerOptions);
      infoMarker?.setInfoWindowAnchor(0.5, 1);
      infoMarker?.setInfoWindowVisible(true);
      console.info(`${this.TAG}: Info window marker created`);
      this.markerCount++;
    } catch (error) {
      console.error(`${this.TAG}: Failed to create info window marker, code: ${error.code}, message: ${error.message}`);
    }
  }

  async createAnimatedMarker(): Promise<void> {
    try {
      let markerOptions: mapCommon.MarkerOptions = {
        position: {
          latitude: 31.964410259206815,
          longitude: 118.74625379397866
        }
      };

      let animMarker = await this.mapController?.addMarker(markerOptions);
      
      let animation = new map.RotateAnimation(0, 360);
      animation.setDuration(3000);
      animation.setFillMode(map.AnimationFillMode.BACKWARDS);
      animation.setRepeatMode(map.AnimationRepeatMode.REVERSE);
      animation.setRepeatCount(10);

      let startCallback = () => {
        console.info(`${this.TAG}: Animation started`);
      };
      animation.on('animationStart', startCallback);

      let endCallback = () => {
        console.info(`${this.TAG}: Animation ended`);
      };
      animation.on('animationEnd', endCallback);

      animMarker?.setAnimation(animation);
      animMarker?.startAnimation();
      
      console.info(`${this.TAG}: Animated marker created`);
      this.markerCount++;
    } catch (error) {
      console.error(`${this.TAG}: Failed to create animated marker, code: ${error.code}, message: ${error.message}`);
    }
  }

  setupEventListeners(): void {
    let clickCallback = (marker: map.Marker) => {
      console.info(`${this.TAG}: Marker clicked, ID: ${marker.getId()}`);
      let position = marker.getPosition();
      console.info(`${this.TAG}: Position: lat=${position.latitude}, lng=${position.longitude}`);
    };
    this.mapEventManager?.on('markerClick', clickCallback);

    let dragStartCallback = (marker: map.Marker) => {
      console.info(`${this.TAG}: Marker drag started, ID: ${marker.getId()}`);
    };
    this.mapEventManager?.on('markerDragStart', dragStartCallback);

    let dragCallback = (marker: map.Marker) => {
      let position = marker.getPosition();
      console.info(`${this.TAG}: Marker dragging, position: (${position.latitude}, ${position.longitude})`);
    };
    this.mapEventManager?.on('markerDrag', dragCallback);

    let dragEndCallback = (marker: map.Marker) => {
      let position = marker.getPosition();
      console.info(`${this.TAG}: Marker drag ended, final position: (${position.latitude}, ${position.longitude})`);
    };
    this.mapEventManager?.on('markerDragEnd', dragEndCallback);

    let longClickCallback = (markerLong: map.Marker) => {
      console.info(`${this.TAG}: Marker long clicked, ID: ${markerLong.getId()}`);
    };
    this.mapEventManager?.onMarkerLongClick(longClickCallback);

    console.info(`${this.TAG}: Event listeners setup completed`);
  }

  @BuilderParam customInfoWindow: ($$: map.MarkerDelegate) => void = this.customInfoWindowBuilder;

  @Builder
  customInfoWindowBuilder($$: map.MarkerDelegate) {
    if ($$.marker) {
      Column() {
        Text($$.marker.getTitle())
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)
        
        Text($$.marker.getSnippet())
          .fontSize(14)
          .fontColor(Color.Gray)
        
        Button('详情')
          .fontSize(12)
          .onClick(() => {
            console.info(`${this.TAG}: Detail button clicked for marker ID: ${$$?.marker?.getId()}`);
          })
      }
      .padding(10)
      .backgroundColor(Color.White)
      .borderRadius(8)
      .shadow({ radius: 5, color: Color.Gray, offsetX: 2, offsetY: 2 })
    }
  }

  build() {
    Stack() {
      Column() {
        MapComponent({
          mapOptions: this.mapOptions,
          mapCallback: this.callback,
          customInfoWindow: this.customInfoWindow
        })
          .width('100%')
          .height('100%')
      }
      .width('100%')

      Column() {
        Text(`Markers: ${this.markerCount}`)
          .fontSize(16)
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .padding(5)
          .borderRadius(5)
      }
      .alignItems(HorizontalAlign.End)
      .padding({ top: 10, right: 10 })
    }
    .height('100%')
  }
}