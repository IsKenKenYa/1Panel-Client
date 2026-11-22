import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct InfoWindowMarkerDemo {
  private TAG = 'InfoWindowMarkerDemo';
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private marker?: map.Marker;

  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 31.984410259206815,
          longitude: 118.76625379397866
        },
        zoom: 15
      }
    };

    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        await this.addInfoWindowMarker();
      } else {
        console.error(`${this.TAG}: Failed to initialize map, code: ${err.code}, message: ${err.message}`);
      }
    };
  }

  async addInfoWindowMarker(): Promise<void> {
    try {
      let markerOptions: mapCommon.MarkerOptions = {
        position: {
          latitude: 31.984410259206815,
          longitude: 118.76625379397866
        },
        clickable: true
      };
      
      this.marker = await this.mapController.addMarker(markerOptions);
      this.marker.setTitle('南京');
      this.marker.setSnippet('华东地区');
      this.marker.setClickable(true);
      this.marker.setInfoWindowAnchor(0.5, 1);
      this.marker.setInfoWindowVisible(true);
      
      console.info(`${this.TAG}: Info window marker created`);
      
    } catch (error) {
      console.error(`${this.TAG}: Failed to create info window marker, code: ${error.code}, message: ${error.message}`);
    }
  }

  @BuilderParam customInfoWindow: ($$: map.MarkerDelegate) => void = this.customInfoWindowBuilder;

  @Builder
  customInfoWindowBuilder($$: map.MarkerDelegate) {
    if ($$.marker) {
      Column() {
        Text($$.marker.getTitle())
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)
        
        Text($$.marker.getSnippet())
          .fontSize(14)
          .fontColor(Color.Gray)
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
          .height('100%');
      }.width('100%')
    }.height('100%');
  }
}