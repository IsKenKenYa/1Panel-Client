# 事件监听（Event Handling）示例

```typescript
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct EventHandlingDemo {
  private TAG = "EventHandlingDemo";
  private mapController?: map.MapComponentController;
  private mapEventManager?: map.MapEventManager;

  aboutToAppear(): void {
    let mapOptions: mapCommon.MapOptions = {
      position: {
        target: { latitude: 39.9, longitude: 116.4 },
        zoom: 10
      }
    };

    let callback: AsyncCallback<map.MapComponentController> = (err, controller) => {
      if (!err) {
        this.mapController = controller;
        this.mapEventManager = this.mapController.getEventManager();
        this.registerEvents();
      }
    };
  }

  // 注册所有事件监听
  registerEvents(): void {
    // 相机事件
    this.mapEventManager.on("cameraChange", (latLng: mapCommon.LatLng) => {
      console.info(this.TAG, `Camera changed: ${JSON.stringify(latLng)}`);
    });

    this.mapEventManager.on("cameraIdle", () => {
      console.info(this.TAG, "Camera idle");
    });

    this.mapEventManager.on("cameraMove", () => {
      console.info(this.TAG, "Camera moving");
    });

    this.mapEventManager.on("cameraMoveStart", (timestamp: number) => {
      console.info(this.TAG, `Camera move start at ${timestamp}`);
    });

    this.mapEventManager.on("cameraMoveCancel", () => {
      console.info(this.TAG, "Camera move cancelled");
    });

    // 地图事件
    this.mapEventManager.on("mapClick", (latLng: mapCommon.LatLng) => {
      console.info(this.TAG, `Map clicked: ${JSON.stringify(latLng)}`);
    });

    this.mapEventManager.on("mapLongClick", (latLng: mapCommon.LatLng) => {
      console.info(this.TAG, `Map long clicked: ${JSON.stringify(latLng)}`);
    });

    this.mapEventManager.on("mapLoad", () => {
      console.info(this.TAG, "Map loaded");
    });

    // 位置事件
    this.mapEventManager.on("myLocationButtonClick", () => {
      console.info(this.TAG, "My location button clicked");
    });

    this.mapEventManager.on("myLocationClick", (latLng: mapCommon.LatLng) => {
      console.info(this.TAG, `My location clicked: ${JSON.stringify(latLng)}`);
    });

    // POI事件
    this.mapEventManager.on("poiClick", (poi: mapCommon.Poi) => {
      console.info(this.TAG, `POI clicked: ${JSON.stringify(poi)}`);
    });

    // 错误事件
    this.mapEventManager.on("error", (err: Error) => {
      console.error(this.TAG, `Map error: ${err.message}`);
    });
  }

  // 注册标记事件
  registerMarkerEvents(marker: map.Marker): void {
    this.mapEventManager.on("markerClick", (m: map.Marker) => {
      console.info(this.TAG, `Marker clicked: ${m.getTitle()}`);
    });

    this.mapEventManager.on("markerDragStart", (m: map.Marker) => {
      console.info(this.TAG, `Marker drag start: ${m.getTitle()}`);
    });

    this.mapEventManager.on("markerDrag", (m: map.Marker) => {
      console.info(this.TAG, `Marker dragging: ${m.getTitle()}`);
    });

    this.mapEventManager.on("markerDragEnd", (m: map.Marker) => {
      console.info(this.TAG, `Marker drag end: ${m.getTitle()}`);
    });

    this.mapEventManager.on("infoWindowClick", (m: map.Marker) => {
      console.info(this.TAG, `Info window clicked: ${m.getTitle()}`);
    });

    this.mapEventManager.on("infoWindowClose", (m: map.Marker) => {
      console.info(this.TAG, `Info window closed: ${m.getTitle()}`);
    });
  }

  // 注册覆盖物事件
  registerOverlayEvents(): void {
    this.mapEventManager.on("circleClick", (circle: map.MapCircle) => {
      console.info(this.TAG, "Circle clicked");
    });

    this.mapEventManager.on("polylineClick", (polyline: map.MapPolyline) => {
      console.info(this.TAG, "Polyline clicked");
    });

    this.mapEventManager.on("polygonClick", (polygon: map.MapPolygon) => {
      console.info(this.TAG, "Polygon clicked");
    });
  }

  // 注册点标注和气泡事件
  registerPointAnnotationEvents(): void {
    this.mapEventManager.on("pointAnnotationClick", (annotation: map.PointAnnotation) => {
      console.info(this.TAG, "Point annotation clicked");
    });

    this.mapEventManager.on("bubbleClick", (bubble: map.Bubble) => {
      console.info(this.TAG, "Bubble clicked");
    });
  }

  // 取消事件监听
  unregisterEvents(): void {
    this.mapEventManager.off("mapClick");
    this.mapEventManager.off("mapLongClick");
    this.mapEventManager.off("cameraChange");
  }

  // 取消特定回调
  unregisterSpecificCallback(): void {
    let callback = (latLng: mapCommon.LatLng) => {
      console.info(this.TAG, `Specific callback: ${JSON.stringify(latLng)}`);
    };
    this.mapEventManager.off("mapClick", callback);
  }
}
```
