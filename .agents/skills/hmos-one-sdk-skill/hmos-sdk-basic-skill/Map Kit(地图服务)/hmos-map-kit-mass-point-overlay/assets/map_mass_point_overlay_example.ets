import { mapCommon, map, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct MapMassPointOverlayExample {
  private TAG = 'MapMassPointOverlayExample';
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private massPointOverlay?: map.MassPointOverlay;
  private mapEventManager?: map.MapEventManager;

  @State message: string = '海量点图层示例';
  @State currentTimestamp: number = 0;
  @State mapHeight: string = '65%';
  @State mapWidth: string = '100%';
  @State pointCount: number = 1000;
  @State overlayId: string = '';
  @State visibility: boolean = true;

  aboutToAppear(): void {
    hilog.info(0x0000, this.TAG, 'aboutToAppear start');

    this.mapOptions = {
      position: {
        target: {
          latitude: 32.11111,
          longitude: 118.11111
        },
        zoom: 9
      },
      scaleControlsEnabled: true,
      zoomControlsEnabled: true,
      compassControlsEnabled: true
    };

    this.callback = async (err, mapController) => {
      if (!err) {
        hilog.info(0x0000, this.TAG, 'Map initialized successfully');
        this.mapController = mapController;
        this.mapEventManager = this.mapController?.getEventManager();

        this.setupMassPointOverlay();
        this.setupClickEventListener();
      } else {
        hilog.error(0x0000, this.TAG, `Failed to initialize map, code:${err.code}, message:${err.message}`);
      }
    };
  }

  private setupMassPointOverlay(): void {
    hilog.info(0x0000, this.TAG, 'Setting up mass point overlay');

    let items: mapCommon.MassPointItem[] = [];
    for (let i = 0; i < this.pointCount; i++) {
      items.push({
        itemId: 'point_' + i,
        position: {
          longitude: 118.11111 + Math.random() * 1 - 0.5,
          latitude: 32.11111 + Math.random() * 1 - 0.5
        },
        snippet: 'Description for point ' + i,
        title: 'Point ' + i
      });
    }

    let params: mapCommon.MassPointOverlayParams = {
      id: 'mass_points_layer_1',
      items: items,
      icon: 'icon/maps_blue_dot.png',
      anchorU: 0.5,
      anchorV: 0.5
    };

    this.addMassPointOverlay(params);
  }

  private async addMassPointOverlay(params: mapCommon.MassPointOverlayParams): void {
    try {
      hilog.info(0x0000, this.TAG, `Adding mass point overlay with ${params.items.length} points`);
      this.massPointOverlay = await this.mapController?.addMassPointOverlay(params);

      if (this.massPointOverlay) {
        this.overlayId = this.massPointOverlay.getId();
        hilog.info(0x0000, this.TAG, `Mass point overlay added successfully, id:${this.overlayId}`);
        this.message = `已添加${this.pointCount}个海量点`;
      }
    } catch (error) {
      hilog.error(0x0000, this.TAG, `Failed to add mass point overlay, code:${error.code}, message:${error.message}`);
      this.message = `添加失败: ${error.message}`;

      if (error.code === 1002601001) {
        hilog.error(0x0000, this.TAG, 'The object to be operated does not exist');
      }
    }
  }

  private setupClickEventListener(): void {
    hilog.info(0x0000, this.TAG, 'Setting up click event listener');

    let massCallback: map.MassPointOverlayCallback = (overlay, item) => {
      hilog.info(0x0000, this.TAG, `MassPointOverlay clicked: overlayId=${overlay.getId()}, itemId=${item.itemId}`);
      this.message = `点击了: ${item.title || item.itemId}`;
    };

    this.mapEventManager?.on('massPointOverlayClick', massCallback);
  }

  private updateMassPoints(): void {
    hilog.info(0x0000, this.TAG, 'Updating mass points');

    let newItems: mapCommon.MassPointItem[] = [];
    for (let i = 0; i < this.pointCount; i++) {
      newItems.push({
        itemId: 'updated_point_' + i,
        position: {
          longitude: 118.11111 + Math.random() * 0.5,
          latitude: 32.11111 + Math.random() * 0.5
        },
        title: 'Updated Point ' + i,
        snippet: 'Updated description'
      });
    }

    try {
      this.massPointOverlay?.setItems(newItems);
      hilog.info(0x0000, this.TAG, 'Mass points updated successfully');
      this.message = `已更新${newItems.length}个海量点`;
    } catch (error) {
      hilog.error(0x0000, this.TAG, `Failed to update mass points, code:${error.code}, message:${error.message}`);
    }
  }

  private toggleVisibility(): void {
    hilog.info(0x0000, this.TAG, 'Toggling visibility');

    this.visibility = !this.visibility;
    this.massPointOverlay?.setVisible(this.visibility);

    let currentVisibility = this.massPointOverlay?.isVisible() ?? false;
    hilog.info(0x0000, this.TAG, `Visibility set to: ${currentVisibility}`);
    this.message = currentVisibility ? '海量点已显示' : '海量点已隐藏';
  }

  private removeMassPointOverlay(): void {
    hilog.info(0x0000, this.TAG, 'Removing mass point overlay');

    try {
      this.massPointOverlay?.remove();
      this.massPointOverlay = undefined;
      this.overlayId = '';
      hilog.info(0x0000, this.TAG, 'Mass point overlay removed successfully');
      this.message = '海量点已删除';
    } catch (error) {
      hilog.error(0x0000, this.TAG, `Failed to remove mass point overlay, code:${error.code}, message:${error.message}`);
    }
  }

  private updateAnchor(): void {
    hilog.info(0x0000, this.TAG, 'Updating anchor');

    try {
      this.massPointOverlay?.setAnchorU(0.6);
      this.massPointOverlay?.setAnchorV(0.6);

      let anchorU = this.massPointOverlay?.getAnchorU() ?? 0;
      let anchorV = this.massPointOverlay?.getAnchorV() ?? 0;
      hilog.info(0x0000, this.TAG, `Anchor updated: U=${anchorU}, V=${anchorV}`);
      this.message = `锚点已更新: U=${anchorU}, V=${anchorV}`;
    } catch (error) {
      hilog.error(0x0000, this.TAG, `Failed to update anchor, code:${error.code}, message:${error.message}`);
    }
  }

  build() {
    Column() {
      Text(this.message)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 10, bottom: 10 });

      Row() {
        Button('更新数据')
          .fontSize(14)
          .onClick(() => this.updateMassPoints());

        Button('切换可见')
          .fontSize(14)
          .onClick(() => this.toggleVisibility());

        Button('更新锚点')
          .fontSize(14)
          .onClick(() => this.updateAnchor());

        Button('删除图层')
          .fontSize(14)
          .onClick(() => this.removeMassPointOverlay());
      }
      .margin({ bottom: 10 });

      Stack() {
        MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
          .width(this.mapWidth)
          .height(this.mapHeight);
      }
      .height('100%');
    }
    .width('100%')
    .height('100%');
  }
}