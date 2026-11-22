import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct MapCircleDemo {
  private TAG = 'MapCircleDemo';
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapCircle?: map.MapCircle;

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
        await this.addMapCircle();
      } else {
        console.error(this.TAG, `Failed to initialize map: code=${err.code}, message=${err.message}`);
      }
    };
  }

  async addMapCircle(): Promise<void> {
    if (!this.mapController) {
      console.error(this.TAG, 'Map controller is not initialized');
      return;
    }

    let mapCircleOptions: mapCommon.MapCircleOptions = {
      center: {
        latitude: 39.918,
        longitude: 116.397
      },
      radius: 500,
      clickable: true,
      fillColor: 0xFFFFC100,
      strokeColor: 0xFFFF0000,
      strokeWidth: 10,
      visible: true,
      zIndex: 15
    };

    try {
      this.mapCircle = await this.mapController.addCircle(mapCircleOptions);
      console.info(this.TAG, 'Map circle added successfully');
      this.queryCircleProperties();
    } catch (e) {
      console.error(this.TAG, `Failed to add map circle: code=${e.code}, message=${e.message}`);
    }
  }

  queryCircleProperties(): void {
    if (!this.mapCircle) {
      console.error(this.TAG, 'Map circle is not created');
      return;
    }

    let center = this.mapCircle.getCenter();
    let radius = this.mapCircle.getRadius();
    let fillColor = this.mapCircle.getFillColor();
    let strokeColor = this.mapCircle.getStrokeColor();
    let strokeWidth = this.mapCircle.getStrokeWidth();
    let clickable = this.mapCircle.isClickable();

    console.info(this.TAG, `Circle center: lat=${center.latitude}, lon=${center.longitude}`);
    console.info(this.TAG, `Circle radius: ${radius} meters`);
    console.info(this.TAG, `Fill color: ${fillColor}`);
    console.info(this.TAG, `Stroke color: ${strokeColor}`);
    console.info(this.TAG, `Stroke width: ${strokeWidth} px`);
    console.info(this.TAG, `Clickable: ${clickable}`);
  }

  updateCircleProperties(): void {
    if (!this.mapCircle) {
      console.error(this.TAG, 'Map circle is not created');
      return;
    }

    this.mapCircle.setCenter({
      latitude: 40.0,
      longitude: 116.5
    });

    this.mapCircle.setRadius(1000);
    this.mapCircle.setFillColor(0xFF00FF00);
    this.mapCircle.setStrokeColor(0xFF0000FF);
    this.mapCircle.setStrokeWidth(15);
    this.mapCircle.setClickable(true);

    console.info(this.TAG, 'Circle properties updated successfully');
  }

  build() {
    Stack() {
      Column() {
        MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback });
      }
      .width('100%')
    }
    .height('100%')
  }
}