import { mapCommon, map, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct TraceOverlayDemo {
  private TAG = "TraceOverlayDemo";
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private traceOverlay?: map.TraceOverlay;

  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 31.99227173519985,
          longitude: 118.7622219990476
        },
        zoom: 16
      },
      scaleControlsEnabled: true
    };

    this.callback = async (err, mapController) => {
      console.info(this.TAG, "mapCallback err=" + JSON.stringify(err) +
        "; mapController=" + JSON.stringify(mapController));
      if (!err) {
        this.mapController = mapController;
        await this.createTraceOverlay();
      } else {
        console.error(`Failed to initialize the map, code is：${err.code}, message is ${err.message}`);
      }
    };
  }

  async createTraceOverlay(): Promise<void> {
    try {
      let markerOptions1: mapCommon.MarkerOptions = {
        position: {
          latitude: 31.99227173519985,
          longitude: 118.7622219990476
        },
        icon: $r("app.media.track_setting_sport_map_marker_22"),
        anchorU: 0.5,
        anchorV: 1,
        visible: true
      };

      let markerBoy1 = await this.mapController!.addMarker(markerOptions1);
      let boyImages1: map.PlayImageAnimation = new map.PlayImageAnimation();
      boyImages1.setDuration(1000);

      let resourceArray: Array<Resource> = new Array();
      for (let i = 0; i <= 20; i++) {
        resourceArray.push($r(`app.media.side_${i}`));
      }

      await boyImages1.addImages(resourceArray);
      boyImages1.setRepeatCount(-1);
      markerBoy1.setAnimation(boyImages1);
      markerBoy1.startAnimation();

      let markerOptions2: mapCommon.MarkerOptions = {
        position: {
          latitude: 31.99227173519985,
          longitude: 118.7622219990476
        },
        icon: $r("app.media.track_setting_sport_map_marker_22"),
        anchorU: 0.5,
        anchorV: 1,
        visible: false
      };

      let markerBoy2 = await this.mapController!.addMarker(markerOptions2);
      let boyImages2: map.PlayImageAnimation = new map.PlayImageAnimation();
      boyImages2.setDuration(1000);

      let resourceArray2: Array<Resource> = new Array();
      for (let i = 0; i <= 18; i++) {
        resourceArray2.push($r(`app.media.behavior_front_cycling_boy_${i.toString().padStart(3, '0')}`));
      }

      await boyImages2.addImages(resourceArray2);
      boyImages2.setRepeatCount(-1);
      markerBoy2.setAnimation(boyImages2);
      markerBoy2.startAnimation();

      let points: Array<mapCommon.LatLng> = new Array();
      points.push({ latitude: 31.99685233070878, longitude: 118.75846023442728 });
      points.push({ latitude: 31.99671325810786, longitude: 118.75846738985165 });
      points.push({ latitude: 31.99659191076709, longitude: 118.7585347621686 });
      points.push({ latitude: 31.99648202537233, longitude: 118.7586266510386 });
      points.push({ latitude: 31.99637707201552, longitude: 118.75872004590596 });
      points.push({ latitude: 31.996278207010903, longitude: 118.75880449946251 });
      points.push({ latitude: 31.996187481969695, longitude: 118.7588781960278 });
      points.push({ latitude: 31.996092248919354, longitude: 118.75895330554488 });
      points.push({ latitude: 31.995962740450565, longitude: 118.75904721407304 });
      points.push({ latitude: 31.995792921394, longitude: 118.75916904998051 });
      points.push({ latitude: 31.995601885713416, longitude: 118.7593235241019 });
      points.push({ latitude: 31.995398221178277, longitude: 118.75949998588176 });
      points.push({ latitude: 31.995185902197715, longitude: 118.7596871082939 });
      points.push({ latitude: 31.994983473052656, longitude: 118.75987334062296 });
      points.push({ latitude: 31.99482433699269, longitude: 118.76002095184032 });
      points.push({ latitude: 31.994709073721708, longitude: 118.76012902920532 });
      points.push({ latitude: 31.99460732100702, longitude: 118.76023892576234 });
      points.push({ latitude: 31.99449284962087, longitude: 118.7603694232856 });
      points.push({ latitude: 31.99435358179254, longitude: 118.76053622438056 });
      points.push({ latitude: 31.99420771148339, longitude: 118.76072790126692 });
      points.push({ latitude: 31.994075194901523, longitude: 118.7609100960977 });
      points.push({ latitude: 31.993952686158877, longitude: 118.7610741329013 });
      points.push({ latitude: 31.993840180644217, longitude: 118.7612193418965 });
      points.push({ latitude: 31.993733787150244, longitude: 118.76135383115654 });
      points.push({ latitude: 31.993617206525155, longitude: 118.76150529647698 });

      let traceOptions: mapCommon.TraceOverlayParams = {
        points: points,
        animationDuration: 5000,
        isMapMoving: true,
        color: 0xAAFFAA00,
        width: 20,
        animationCallback: (pointIndex) => {
          if (pointIndex === 10) {
            markerBoy1.setVisible(false);
            markerBoy2.setVisible(true);
          }
        }
      };

      let markers: Array<map.Marker> = new Array();
      markers.push(markerBoy1, markerBoy2);

      this.traceOverlay = await this.mapController!.addTraceOverlay(traceOptions, markers);
      console.info(this.TAG, 'Trace overlay created successfully');
    } catch (e) {
      console.error(this.TAG, `Failed to create the traceOverlay, code is：${e.code}, message is ${e.message}`);
    }
  }

  pauseTrace(): void {
    if (this.traceOverlay) {
      this.traceOverlay.pause();
      console.info(this.TAG, 'Trace overlay paused');
    }
  }

  resumeTrace(): void {
    if (this.traceOverlay) {
      this.traceOverlay.resume();
      console.info(this.TAG, 'Trace overlay resumed');
    }
  }

  removeTrace(): void {
    if (this.traceOverlay) {
      this.traceOverlay.remove();
      console.info(this.TAG, 'Trace overlay removed');
      this.traceOverlay = undefined;
    }
  }

  build() {
    Stack() {
      Column() {
        MapComponent({
          mapOptions: this.mapOptions,
          mapCallback: this.callback,
        }).width('100%').height('70%');

        Row() {
          Button('Pause')
            .onClick(() => this.pauseTrace())
            .width('30%');
          Button('Resume')
            .onClick(() => this.resumeTrace())
            .width('30%');
          Button('Remove')
            .onClick(() => this.removeTrace())
            .width('30%');
        }
        .width('100%')
        .height('30%')
        .justifyContent(FlexAlign.SpaceAround);
      }
      .width('100%');
    }
    .height('100%');
  }
}